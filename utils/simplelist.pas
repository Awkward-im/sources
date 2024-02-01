unit simplelist;

{.$include mydefs.inc}

interface

{
  TFPSList analog
}
type
  TFPSListCompareFunc = function(Key1, Key2: Pointer): Integer of object;
{$IFNDEF FPC}
  type
    TDirection = (FromBeginning, FromEnd);
{$ENDIF}

type
  pSimpleList = ^tSimpleList;
  tSimpleList = object
    {$IFDEF FPC}
    type
      TDirection = (FromBeginning, FromEnd);
    {$ENDIF}
  private
    FList    : pointer;
    FCount   : cardinal;
    FCapacity: cardinal; { list is one longer sgthan capacity, for temp }
    FItemSize: cardinal;

    function  InternalGet(Index: cardinal): Pointer; {$IFDEF AllowInline} inline; {$ENDIF}
    procedure InternalPut(Index: cardinal; NewItem: Pointer);
    procedure SetCapacity(NewCapacity: cardinal);
    procedure SetCount   (NewCount   : cardinal);

    procedure CopyItem(Src, Dest: Pointer);
    function  Get(Index: cardinal): Pointer;
    procedure Put(Index: cardinal; Item: Pointer);

    property InternalItems[Index: cardinal]: Pointer read InternalGet write InternalPut;
  public

    procedure Init(anItemSize:cardinal=SizeOf(pointer));
    procedure Clear;
    procedure Free;
    procedure Expand;

    function  Add    (Item:pointer):cardinal;
    procedure SetData(var Item; Index:cardinal);
    procedure GetData(var Item; Index:cardinal);
    procedure Delete  (Index:cardinal);
    procedure ToTop   (Index:cardinal);
    procedure ToBottom(Index:cardinal);
    procedure Move    (CurIndex, NewIndex: cardinal);
    procedure Exchange(Index1, Index2: cardinal);
    function  PositionOf(var Item):integer;    // search by address
    function  IndexOf(Item: Pointer; Direction: TDirection=fromBeginning): Integer; // search by content

    procedure Insert(Index: cardinal; Item:pointer); overload;
    function  Insert(Index: cardinal): Pointer;      overload;
    procedure Extract(Item: Pointer; ResultPtr: Pointer);

    procedure Assign (Obj: TSimpleList);
    procedure AddList(Obj: TSimpleList);

    property Capacity: cardinal read FCapacity write SetCapacity;
    property Count   : cardinal read FCount    write SetCount;
    property ItemSize: cardinal read FItemSize;
    property List    : pointer  read FList;

    property Items[Index: cardinal]: Pointer read Get write Put; default;
  end;

  //===== Key-Value pair list =====
{
type
  TDuplicates = (dupIgnore, dupAccept, dupError);
}
type
  TSimpleMap = object(TSimpleList)
  private
    FKeySize : cardinal;
    FDataSize: cardinal;
{
    FDuplicates: TDuplicates;
    FSorted: Boolean;
    procedure SetSorted(Value: Boolean);
}
    FOnKeyPtrCompare : TFPSListCompareFunc;
    FOnDataPtrCompare: TFPSListCompareFunc;
//  protected
    function  BinaryCompareKey (Key1 , Key2 : Pointer): Integer;
    function  BinaryCompareData(Data1, Data2: Pointer): Integer;
    procedure SetOnKeyPtrCompare (Proc: TFPSListCompareFunc);
    procedure SetOnDataPtrCompare(Proc: TFPSListCompareFunc);
    procedure InitOnPtrCompare; {virtual;}

    function LinearIndexOf(AKey: Pointer): Integer;

    procedure CopyKey (Src, Dest: Pointer); {virtual;}
    procedure CopyData(Src, Dest: Pointer); {virtual;}
    function  GetKeyData(AKey: Pointer): Pointer;
    procedure PutKeyData(AKey: Pointer; NewData: Pointer);
    function  GetKey (Index: cardinal): Pointer;
    function  GetData(Index: cardinal): Pointer;
    procedure PutKey (Index: cardinal; AKey : Pointer);
    procedure PutData(Index: cardinal; AData: Pointer);
  public
    procedure Init(AKeySize : cardinal = sizeof(Pointer);
                   ADataSize: cardinal = sizeof(Pointer));
    function Add(AKey, AData: Pointer): Integer; overload;
    function Add(AKey: Pointer): Integer;        overload;
    function IndexOf    (AKey : Pointer): Integer;
    function IndexOfData(AData: Pointer): Integer;
    function  Insert       (Index: cardinal): Pointer;                  overload;
    procedure Insert       (Index: cardinal; out AKey, AData: Pointer); overload;
    procedure InsertKey    (Index: cardinal; AKey: Pointer);
    procedure InsertKeyData(Index: cardinal; AKey, AData: Pointer);
    function Remove(AKey: Pointer): Integer;
{
    function Find(AKey: Pointer; out Index: Integer): Boolean;
    procedure Sort;
}
    property KeySize : cardinal read FKeySize;
    property DataSize: cardinal read FDataSize;
    property Keys   [Index: cardinal]: Pointer read GetKey     write PutKey;
    property Data   [Index: cardinal]: Pointer read GetData    write PutData;
    property KeyData[Key  : Pointer ]: Pointer read GetKeyData write PutKeyData; default;
{
    property Duplicates: TDuplicates read FDuplicates write FDuplicates;
    property Sorted: Boolean read FSorted write SetSorted;
    property OnPtrCompare    : TFPSListCompareFunc read FOnKeyPtrCompare  write SetOnKeyPtrCompare; //deprecated;
}
    property OnKeyPtrCompare : TFPSListCompareFunc read FOnKeyPtrCompare  write SetOnKeyPtrCompare;
    property OnDataPtrCompare: TFPSListCompareFunc read FOnDataPtrCompare write SetOnDataPtrCompare;
  end;


implementation

const
  TSAIncrement = 8;

{$IFNDEF FPC}
function CompareByte(const buf1; const buf2; len: integer): integer;
var
  i:integer;
  p1,p2:PAnsiChar;
begin
  result:=0;

  if len<=0 then
    exit;

  p1:=@buf1;
  p2:=@buf2;
  for i:=0 to len-1 do
  begin
    result:=byte(p1^)-byte(p2^);
    if result<>0 then
      exit;
    inc(p1);
    inc(p2);
  end;
end;
{$ENDIF}

//----- [de]initialization -----

procedure tSimpleList.Init(anItemSize:cardinal=SizeOf(pointer));
begin
  FCount   :=0;
  FCapacity:=0;
  FList    :=nil;
  FItemSize:=anItemSize;
end;

procedure TSimpleList.Clear;
begin
  if FList<>nil then
  begin
    SetCount(0);
    SetCapacity(0);
  end;
end;

procedure tSimpleList.Free;
begin
  Clear;
  FreeMem(FList);
end;

//===== property methods =====

procedure TSimpleList.CopyItem(Src, Dest: Pointer);
begin
  System.Move(Src^, Dest^, FItemSize);
end;

//----- InternalItems -----

function TSimpleList.InternalGet(Index: cardinal): Pointer;
begin
  result:=PAnsiChar(FList)+Index*FItemSize;
end;

procedure TSimpleList.InternalPut(Index: cardinal; NewItem: Pointer);
var
  ListItem: Pointer;
begin
  ListItem := InternalItems[Index];
  CopyItem(NewItem, ListItem);
end;

//----- public property methods -----

procedure TSimpleList.Expand;
var
  IncSize : Longint;
begin
  if FCount < FCapacity then exit;
  IncSize := 4;
  if FCapacity > 3 then IncSize := IncSize + 4;
  if FCapacity > 8 then IncSize := IncSize + 8;
  if FCapacity > 127 then Inc(IncSize, FCapacity shr 2);
  SetCapacity(FCapacity + IncSize);
end;

procedure TSimpleList.SetCapacity(NewCapacity: cardinal);
begin
  if NewCapacity < FCount then
    exit;

  if NewCapacity = FCapacity then
    exit;

  if NewCapacity>0 then
  begin
    ReallocMem(FList, (NewCapacity+1) * FItemSize);
    // not necessary coz Realloc clear
    if NewCapacity>FCapacity then
      FillChar(InternalItems[FCapacity]^, (NewCapacity-FCapacity+1) * FItemSize, #0);
  end;

  FCapacity := NewCapacity;
end;

procedure TSimpleList.SetCount(NewCount: cardinal);
begin
  if NewCount = FCount then
    exit;

  if NewCount > FCapacity then
    SetCapacity(NewCount);

  if NewCount > FCount then
    FillChar(InternalItems[FCount]^, (NewCount-FCount) * FItemSize, #0)

  else if NewCount < FCount then // reserved for 'clear' method
    ;

  FCount := NewCount;
end;

function TSimpleList.Get(Index: cardinal): Pointer;
begin
  if Index<FCount then
    result := InternalItems[Index]
  else
    result:=nil;
end;

procedure TSimpleList.Put(Index: cardinal; Item: Pointer);
begin
  if Index>=FCapacity then
  begin
    SetCapacity(Index+1);
    FCount:=FCapacity;
  end;

  InternalItems[Index] := Item;
end;

//----- public methods -----

procedure TSimpleList.SetData(var Item; Index:cardinal);
begin
  Items[Index] := @Item;
end;

procedure TSimpleList.GetData(var Item; Index:cardinal);
begin
  if Index<FCount then
    CopyItem(Items[Index],@Item);
end;

function TSimpleList.Add(Item:pointer):cardinal;
begin
  if FCount = FCapacity then
    Expand;
//    SetCapacity(FCapacity+TSAIncrement);

  CopyItem(Item, InternalItems[FCount]);

  result:=FCount;
  inc(FCount);
end;

function TSimpleList.Insert(Index: cardinal): Pointer;
begin
  if Index>=FCapacity then
  begin
    SetCapacity(Index+1);
    FCount:=FCapacity;
  end
  else if FCount = FCapacity then
    Expand;
//    SetCapacity(FCapacity+TSAIncrement);

  Result := InternalItems[Index];

  if Index<FCount then
  begin
//    System.Move(Result^, (Result+FItemSize)^, (FCount - Index) * FItemSize);
    System.Move(InternalItems[Index]^, InternalItems[Index+1]^, (FCount - Index) * FItemSize);
    { clear for compiler assisted types }
    FillChar(InternalItems[Index]^, FItemSize, #0);
  end;
  Inc(FCount);
end;

procedure TSimpleList.Insert(Index: cardinal; Item:pointer);
begin
  CopyItem(Item, Insert(Index));
end;

procedure TSimpleList.Delete(Index:cardinal);
begin
  if Index<FCount then
  begin
    dec(FCount);
    if Index<FCount then // not last
    begin
      System.Move(InternalItems[Index+1]^, InternalItems[Index]^, (FCount-Index) * FItemSize);

      // Shrink the list if appropriate
      if (FCapacity > 256) and (FCount < FCapacity shr 2) then
        SetCapacity(FCapacity shr 1);

      // see fgl.pp for comments
      FillChar(InternalItems[FCount]^, (FCapacity-FCount+1) * FItemSize, #0);
    end;
  end;
end;

function TSimpleList.IndexOf(Item: Pointer; Direction: TDirection=fromBeginning): Integer;
var
  ListItem: Pointer;
begin
  if Direction=fromBeginning then
  begin
    Result := 0;
    ListItem := InternalItems[0];
    while (cardinal(Result) < FCount) and
          (CompareByte(ListItem^, Item^, FItemSize) <> 0) do
    begin
      Inc(Result);
      ListItem := PAnsiChar(ListItem)+FItemSize;
    end;
    if cardinal(Result) >= FCount then Result := -1;
  end
  else
  begin
    ListItem := InternalItems[Count-1];
    Result:=FCount-1;
    while (Result >=0) and
          (CompareByte(ListItem^, Item^, FItemSize) <> 0) do
    begin
      dec(Result);
      ListItem := PAnsiChar(ListItem)-FItemSize;
    end;
  end;
end;

procedure TSimpleList.Extract(Item: Pointer; ResultPtr: Pointer);
var
  i : Integer;
  ListItemPtr : Pointer;
begin
  i := IndexOf(Item);
  if i >= 0 then
  begin
    ListItemPtr := InternalItems[i];
    System.Move(ListItemPtr^, ResultPtr^, FItemSize);
    { fill with zeros, to avoid freeing/decreasing reference on following Delete }
    System.FillChar(ListItemPtr^, FItemSize, #0);
    Delete(i);
  end
  else
    System.FillChar(ResultPtr^, FItemSize, #0);
end;

procedure TSimpleList.Move(CurIndex, NewIndex: cardinal);
var
  CurItem, NewItem, TmpItem, Src, Dest: Pointer;
  MoveCount: cardinal;
begin
  if (CurIndex>=FCount) or (NewIndex>=FCount) or (CurIndex=NewIndex) then
    exit;

  CurItem := InternalItems[CurIndex];
  NewItem := InternalItems[NewIndex];
  TmpItem := InternalItems[FCapacity];

  System.Move(CurItem^, TmpItem^, FItemSize);

  if NewIndex > CurIndex then
  begin
    Src       := InternalItems[CurIndex+1];
    Dest      := CurItem;
    MoveCount := NewIndex - CurIndex;
  end
  else
  begin
    Src       := NewItem;
    Dest      := InternalItems[NewIndex+1];
    MoveCount := CurIndex - NewIndex;
  end;
  System.Move(Src^, Dest^, MoveCount * FItemSize);

  System.Move(TmpItem^, NewItem^, FItemSize);
end;

procedure TSimpleList.ToTop(Index:cardinal);
begin
  if Index>0 then
    Move(Index,0);
end;

procedure TSimpleList.ToBottom(Index:cardinal);
begin
  if Index<(FCount-1) then
    Move(Index,FCount-1);
end;

procedure TSimpleList.Exchange(Index1, Index2: cardinal);
begin
  if (Index1<FCount) and (Index2<FCount) and (Index1<>Index2) then
  begin
    System.Move(InternalItems[Index1]^   , InternalItems[FCapacity]^, FItemSize);
    System.Move(InternalItems[Index2]^   , InternalItems[Index1]^   , FItemSize);
    System.Move(InternalItems[FCapacity]^, InternalItems[Index2]^   , FItemSize);
  end;
end;

function TSimpleList.PositionOf(var Item):integer;
var
  i:integer;
begin
  i:=(PAnsiChar(Item)-PAnsiChar(FList));
  if (i>=0) and
     (cardinal(i)<(FCount*FItemSize)) and
     ((cardinal(i) mod FItemSize)=0) then
    result:=cardinal(i) div FItemSize
  else
    result:=-1;
end;

procedure TSimpleList.AddList(Obj: TSimpleList);
var
  i: Integer;
begin
  if Obj.ItemSize <> FItemSize then
    exit;

  if FCapacity<(FCount + Obj.Count) then
    SetCapacity(FCount + Obj.Count);

  for i := 0 to Obj.Count - 1 do
  begin
    Add(Obj.Items[i]); // Add(Obj[i]) is for FPC only
  end;
end;

procedure TSimpleList.Assign(Obj: TSimpleList);
begin
  if Obj.ItemSize <> FItemSize then
    exit;

  Clear;
  AddList(Obj);
end;


//===== TSimpleMap =====

procedure TSimpleMap.Init(AKeySize: cardinal; ADataSize: cardinal);
begin
  inherited Init(AKeySize+ADataSize);
  FKeySize  := AKeySize;
  FDataSize := ADataSize;
  InitOnPtrCompare;
end;

procedure TSimpleMap.CopyKey(Src, Dest: Pointer);
begin
  System.Move(Src^, Dest^, FKeySize);
end;

procedure TSimpleMap.CopyData(Src, Dest: Pointer);
begin
  System.Move(Src^, Dest^, FDataSize);
end;

function TSimpleMap.GetKey(Index: cardinal): Pointer;
begin
  Result := Items[Index];
end;

function TSimpleMap.GetData(Index: cardinal): Pointer;
begin
  Result := PAnsiChar(Items[Index])+FKeySize;
end;

function TSimpleMap.GetKeyData(AKey: Pointer): Pointer;
var
  I: Integer;
begin
  I := IndexOf(AKey);
  if I >= 0 then
    Result := PAnsiChar(InternalItems[I])+FKeySize
  else
    Result:=nil;
end;

procedure TSimpleMap.PutKey(Index: cardinal; AKey: Pointer);
begin
{
  if FSorted then
    Error(SSortedListError, 0);
}
  CopyKey(AKey, Items[Index]);
end;

procedure TSimpleMap.PutData(Index: cardinal; AData: Pointer);
begin
  CopyData(AData, PAnsiChar(Items[Index])+FKeySize);
end;

procedure TSimpleMap.PutKeyData(AKey: Pointer; NewData: Pointer);
var
  I: Integer;
begin
  I := IndexOf(AKey);
  if I >= 0 then
    Data[I] := NewData
  else
    Add(AKey, NewData);
end;

function TSimpleMap.BinaryCompareKey(Key1, Key2: Pointer): Integer;
begin
  Result := CompareByte(Key1^, Key2^, FKeySize);
end;

function TSimpleMap.BinaryCompareData(Data1, Data2: Pointer): Integer;
begin
  Result := CompareByte(Data1^, Data2^, FDataSize);
end;

procedure TSimpleMap.SetOnKeyPtrCompare(Proc: TFPSListCompareFunc);
begin
{$IFDEF FPC_OBJFPC}
  if Proc <> nil then
    FOnKeyPtrCompare := Proc
  else
    FOnKeyPtrCompare := @BinaryCompareKey;
{$ELSE}
  if @Proc <> nil then
    FOnKeyPtrCompare := Proc
  else
    FOnKeyPtrCompare := BinaryCompareKey;
{$ENDIF}
end;

procedure TSimpleMap.SetOnDataPtrCompare(Proc: TFPSListCompareFunc);
begin
{$IFDEF FPC_OBJFPC}
  if Proc <> nil then
    FOnDataPtrCompare := Proc
  else
    FOnDataPtrCompare := @BinaryCompareData;
{$ELSE}
  if @Proc <> nil then
    FOnDataPtrCompare := Proc
  else
    FOnDataPtrCompare := BinaryCompareData;
{$ENDIF}
end;

procedure TSimpleMap.InitOnPtrCompare;
begin
  SetOnKeyPtrCompare (nil);
  SetOnDataPtrCompare(nil);
end;

function TSimpleMap.Add(AKey: Pointer): Integer;
begin
{
  if Sorted then
  begin
    if Find(AKey, Result) then
      case Duplicates of
        dupIgnore: exit;
        dupError: Error(SDuplicateItem, 0)
      end;
  end
  else
}    Result := Count;
  CopyKey(AKey, inherited Insert(Result));
end;

function TSimpleMap.Add(AKey, AData: Pointer): Integer;
begin
  Result := Add(AKey);
  Data[Result] := AData;
end;

(*
function TSimpleMap.Find(AKey: Pointer; out Index: Integer): Boolean;
{ Searches for the first item <= Key, returns True if exact match,
  sets index to the index of the found string. }
var
  I,L,R,Dir: Integer;
begin
  Result := false;
  Index := -1;
{
  if not Sorted then
    raise EListError.Create(SErrFindNeedsSortedList);
}
  // Use binary search.
  L := 0;
  R := FCount-1;
  while L<=R do
  begin
    I := L + (R - L) div 2;
    Dir := FOnKeyPtrCompare(Items[I], AKey);
    if Dir < 0 then
      L := I+1
    else begin
      R := I-1;
      if Dir = 0 then
      begin
        Result := true;
        if Duplicates <> dupAccept then
          L := I;
      end;
    end;
  end;
  Index := L;
end;

procedure TSimpleMap.SetSorted(Value: Boolean);
begin
  if Value = FSorted then exit;
  FSorted := Value;
  if Value then Sort;
end;

procedure TSimpleMap.Sort;
begin
  inherited Sort(FOnKeyPtrCompare);
end;

*)

function TSimpleMap.LinearIndexOf(AKey: Pointer): Integer;
var
  ListItem: Pointer;
begin
  Result := 0;
  ListItem := InternalItems[0];
  while (cardinal(Result) < FCount) and (FOnKeyPtrCompare(ListItem, AKey) <> 0) do
  begin
    Inc(Result);
    ListItem := PAnsiChar(ListItem)+FItemSize;
  end;
  if cardinal(Result) = FCount then Result := -1;
end;

function TSimpleMap.IndexOf(AKey: Pointer): Integer;
begin
{
  if Sorted then
  begin
    if not Find(AKey, Result) then
      Result := -1;
  end else
}    Result := LinearIndexOf(AKey);
end;

function TSimpleMap.IndexOfData(AData: Pointer): Integer;
var
  ListItem: Pointer;
begin
  Result := 0;
  ListItem := PAnsiChar(InternalItems[0])+FKeySize;
  while (cardinal(Result) < FCount) and (FOnDataPtrCompare(ListItem, AData) <> 0) do
  begin
    Inc(Result);
    ListItem := PAnsiChar(ListItem)+FItemSize;
  end;
  if cardinal(Result) = FCount then Result := -1;
end;

function TSimpleMap.Insert(Index: cardinal): Pointer;
begin
{
  if FSorted then
    Error(SSortedListError, 0);
}
  Result := inherited Insert(Index);
end;

procedure TSimpleMap.Insert(Index: cardinal; out AKey, AData: Pointer);
begin
  AKey  := Insert(Index);
  AData := PAnsiChar(AKey) + FKeySize;
end;

procedure TSimpleMap.InsertKey(Index: cardinal; AKey: Pointer);
begin
  CopyKey(AKey, Insert(Index));
end;

procedure TSimpleMap.InsertKeyData(Index: cardinal; AKey, AData: Pointer);
var
  ListItem: Pointer;
begin
  ListItem := Insert(Index);
  CopyKey (AKey , ListItem);
  CopyData(AData, PAnsiChar(ListItem)+FKeySize);
end;

function TSimpleMap.Remove(AKey: Pointer): Integer;
begin
  Result := IndexOf(AKey);
  if Result >= 0 then
    Delete(Result);
end;


end.
