{TODO: Use UTF8 conversion to save space}
unit Dict;

interface

uses
  TextCache;

{$IF NOT DEFINED(TIntegerDynArray)} type TIntegerDynArray = array of Integer; {$ENDIF}

type
  TElement = record
    hash:dword;
    case boolean of
      false: (name:PWideChar);
      true : (idx :cardinal);
  end;

  { TDictionary }
type
  TDictBase = object
  public
    type
      TSortType  = (byhash,bytext);
      TRGOptions = set of (check_hash, check_text);
  private
    FCache   :TTextCache;
    FTags    :array of TElement;
    FHashIdx :TIntegerDynArray;
    FTagIdx  :TIntegerDynArray;

    FCapacity:cardinal;
    FCount   :cardinal;
    FOptions :TRGOptions;
    FUseCache  :boolean;
    FSorted    :boolean;
    FTextSorted:boolean;

    function  GetHashIndex(akey:dword    ):integer;
    function  GetTextIndex(akey:PWideChar):integer;

    function  GetTextByHash(akey:dword    ):PWideChar;
    function  GetHashByText(akey:PWideChar):dword;
    function  GetTextByIdx (idx :cardinal ):PWideChar;
    function  GetHashByIdx (idx :cardinal ):dword;

    function  TextCompare(const aval:array of TElement; l,r:integer):integer;
    function  HashCompare(const aval:array of TElement; l,r:integer):integer;
    procedure Sort(const aval:array of TElement; var aidx:TIntegerDynArray; asort:TSortType);
    
    procedure SetCapacity(aval:cardinal);
  public
    procedure Init(usecache:boolean=true);
    procedure Clear;
    procedure SortByText;
    procedure SortByHash;
    function  Exists(ahash:dword):boolean;
    // calculates Hash for key = -1
    function  Add(      aval:PWideChar ; akey:dword=dword(-1)):dword;
    function  Add(const aval:AnsiString; akey:dword=dword(-1)):dword;

    property Tag   [akey:dword    ]:PWideChar read GetTextByHash;
    property Hash  [akey:PWideChar]:dword     read GetHashByText;
    property Hashes[idx :cardinal ]:dword     read GetHashByIdx;
    property Tags  [idx :cardinal ]:PWideChar read GetTextByIdx;

    property Capacity:cardinal   read FCapacity write SetCapacity;
    property Count   :cardinal   read FCount;
    property Options :TRGOptions read FOptions  write FOptions;
  end;

  { Dictionary with translation }

type
  TDictTranslate = object(TDictBase)
  private
    FValues:array of TElement;
    FValIdx:TIntegerDynArray;
    FValSorted:boolean;

  private
    function  GetValueByHash(akey:dword   ):PWideChar;
    function  GetValueByIdx (idx :cardinal):PWideChar;

  public
    procedure Clear;
    function  Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;

    property Value [akey:dword   ]:PWideChar read GetValueByHash;
    property Values[idx :cardinal]:PWideChar read GetValueByIdx;
  end;

  { Dictionary with translation and mask }

type
  TDictTransExt = object(TDictTranslate)
  private
    FMasks  :array of TElement;
    FMaskIdx:TIntegerDynArray;
    FMaskSorted:boolean;

  private
    function GetMaskByIdx(idx:cardinal):PWideChar;

  public
    procedure Clear;
    function  Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;

  public
    property Masks[idx:cardinal]:PWideChar read GetMaskByIdx;
  end;

//===== Implementation =====

implementation

const
  FCapStep = 256;

{%REGION Support}

function CalcHash(instr:PWideChar; alen:integer=0):dword;
var
  i:integer;
begin
  if alen=0 then alen:=Length(instr);
  result:=alen;
  for i:=0 to alen-1 do
    result:=(result SHR 27) xor (result SHL 5) xor ORD(instr[i]);
end;

function CopyWide(asrc:PWideChar; alen:integer=0):PWideChar;
begin
  if (asrc=nil) or (asrc^=#0) then exit(nil);

  if alen=0 then
    alen:=Length(asrc);
  GetMem(    result ,(alen+1)*SizeOf(WideChar));
  move(asrc^,result^, alen   *SizeOf(WideChar));
  result[alen]:=#0;
end;

procedure CopyWide(var adst:PWideChar; asrc:PWideChar; alen:integer=0);
begin
  adst:=CopyWide(asrc,alen);
end;

function CompareWide(s1,s2:PWideChar; alen:integer=0):integer;
begin
  if s1=s2  then exit(0);
  if s1=nil then if s2^=#0 then exit(0) else exit(-1);
  if s2=nil then if s1^=#0 then exit(0) else exit( 1);

  repeat
    if s1^>s2^ then exit( 1);
    if s1^<s2^ then exit(-1);
    if s1^=#0  then exit( 0);
    dec(alen);
    if alen=0  then exit( 0);
    inc(s1);
    inc(s2);
  until false;
end;

{%ENDREGION Support}

{%REGION Dictionary}

procedure TDictBase.Init(usecache:boolean=true);
begin
  FCapacity:=0;
  FCount   :=0;
  FOptions :=[];
  FUseCache:=usecache;
  if FUseCache then FCache.Init(false);
end;

procedure TDictBase.Clear;
var
  i:integer;
begin
  if FUseCache then FCache.Clear;

  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FTags[i].name);
    FCount:=0;

    SetLength(FTags   ,0);
    SetLength(FHashIdx,0);
    SetLength(FTagIdx ,0);
    FCapacity:=0;
  end;
end;

procedure TDictBase.SetCapacity(aval:cardinal);
begin
  if aval<=FCapacity then exit;

  if FCapacity=0 then
  begin
    FCapacity:=aval;
  end
  else
  begin
    FOptions:=[check_hash];
    if aval>FCapacity then
      aval:=aval div 2;
    FCapacity:=FCount+aval;
  end;

  {!! Useful for base object only, not for TDictTranslate and DictTransExt
      coz size must be multiplied }
  if FUseCache then
  begin
    FCache.Count   :=FCapacity;
    FCache.Capacity:=FCapacity*16;
  end;
end;

//----- Sort (Shell method) -----

type TCompareFunc = function (const aval:array of TElement; l,r:integer):integer of object;

function TDictBase.TextCompare(const aval:array of TElement; l,r:integer):integer;
begin
  if FUseCache then
    result:=CompareWide(FCache[aval[l].idx],FCache[aval[r].idx])
  else
    result:=CompareWide(aval[l].name,aval[r].name);
end;

function TDictBase.HashCompare(const aval:array of TElement; l,r:integer):integer;
begin
  result:=aval[l].hash-aval[r].hash;
end;

procedure TDictBase.Sort(const aval:array of TElement; var aidx:TIntegerDynArray; asort:TSortType);
var
  fn:TCompareFunc;
  ltmp:integer;
  i,j,gap:longint;
begin
  if FCount=0 then exit;
 
  if asort=bytext then fn:=@TextCompare
                  else fn:=@HashCompare;
  
  if FCapacity>Length(aidx) then
    SetLength(aidx,FCapacity);

  for i:=0 to FCount-1 do
    aidx[i]:=i;

  gap:=FCount shr 1;
  while gap>0 do
  begin
    for i:=gap to FCount-1 do
    begin
      j:=i-gap;
      while (j>=0) and (fn(aval, aidx[j], aidx[j+gap])>0) do
      begin
        ltmp       :=aidx[j+gap];
        aidx[j+gap]:=aidx[j];
        aidx[j]    :=ltmp;
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
end;

procedure TDictBase.SortByText;
begin
  if FTextSorted then exit;

  Sort(FTags,FTagIdx,bytext);

  FTextSorted:=true;
end;

procedure TDictBase.SortByHash;
begin
  if FSorted then exit;

  Sort(FTags,FHashIdx,byhash);

  FSorted:=true;
end;

//--- Getters ---

function TDictBase.GetHashIndex(akey:dword):integer;
var
  L,R,i:integer;
begin
  result:=-1;

  // Binary Search

  if FSorted then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      if akey>FTags[FHashIdx[i]].hash then
        L:=i+1
      else
      begin
        if akey=FTags[FHashIdx[i]].hash then
        begin
          result:=FHashIdx[i];
          break;
        end
        else
          R:=i-1;
      end;
    end;
  end
  else
  begin
    for i:=0 to FCount-1 do
    begin
      if FTags[i].hash=akey then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

function TDictBase.GetTextIndex(akey:PWideChar):integer;
var
  L,R,i,ltmp:integer;
begin
  result:=-1;

  // Binary Search

  if FTextSorted then
  begin
    L:=0;
    R:=FCount-1;
    while (L<=R) do
    begin
      i:=L+(R-L) div 2;
      ltmp:=CompareWide(akey,Tags[FTagIdx[i]]);
      if ltmp>0 then
        L:=i+1
      else
      begin
        if ltmp=0 then
        begin
          result:=FTagIdx[i];
          break;
        end
        else
          R:=i-1;
      end;
    end;
  end
  else
  begin
    for i:=0 to FCount-1 do
    begin
      if CompareWide(Tags[i],akey)=0 then
      begin
        result:=i;
        break;
      end;
    end;
  end;
end;

function TDictBase.GetTextByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(akey);
  if i<0 then
    result:=nil
  else
    result:=Tags[i];
end;

function TDictBase.GetHashByText(akey:PWideChar):dword;
var
  i:integer;
begin
  i:=GetTextIndex(akey);
  if i>=0 then
    result:=FTags[i].hash
  else
  begin
    Val(akey,result,i);
    if i>0 then
      result:=dword(-1);
  end;
end;

function TDictBase.GetTextByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
   if FUseCache then
     result:=FCache[FTags[idx].idx]
   else
     result:=FTags[idx].name;
end;

function TDictBase.GetHashByIdx(idx:cardinal):dword;
begin
  if idx>=FCount then result:=dword(-1)
  else result:=FTags[idx].hash;
end;


function TDictBase.Exists(ahash:dword):boolean; inline;
begin
  result:=GetHashIndex(ahash)>=0;
end;

function TDictBase.Add(aval:PWideChar; akey:dword=dword(-1)):dword;
var
  i:integer;
begin
  if (akey=dword(-1)) then akey:=CalcHash(aval);// TTextCache.Hash[aval];

  if (check_hash in FOptions) then
  begin
    if GetHashIndex(akey)>=0 then Exit(akey);
  end;

  if (check_text in FOptions) then
  begin
    i:=GetTextIndex(aval);
    if i>=0 then Exit(FTags[i].hash);
  end;

  // Add new element
  FSorted    :=false;
  FTextSorted:=false;

  if FCount=FCapacity then
  begin
    FCapacity:=Align(FCapacity+FCapStep,FCapStep);
    SetLength(FTags,FCapacity);
  end;

  FTags[FCount].hash :=akey;
  if FUseCache then
    FTags[FCount].idx:=FCache.Append(aval)
  else
    CopyWide(FTags[FCount].name,aval);

  inc(FCount);
  result:=akey;
end;

function TDictBase.Add(const aval:AnsiString; akey:dword=dword(-1)):dword;
begin
  result:=Add(pointer(UTF8Decode(aval)), akey);
end;

{%ENDREGION Dictionary}

{%REGION Dictionary with translation}

procedure TDictTranslate.Clear;
var
  i:integer;
begin
  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FValues[i].name);

    FCount:=0;
    SetLength(FValues,0);
    SetLength(FValIdx,0);
  end;

  inherited Clear;
end;

function TDictTranslate.GetValueByHash(akey:dword):PWideChar;
var
  i:integer;
begin
  i:=GetHashIndex(akey);
  if i<0 then
    result:=nil
  else
    result:=Values[i];
end;

function TDictTranslate.GetValueByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
   if FUseCache then
     result:=FCache[FValues[idx].idx]
   else
     result:=FValues[idx].name;
end;

function TDictTranslate.Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;
begin
  result:=inherited Add(atext, akey);

  if Length(FValues)<FCapacity then
    SetLength(FValues,FCapacity);

  if FUseCache then
    FValues[FCount-1].idx:=FCache.Append(aval)
  else
    CopyWide(FValues[FCount-1].name,aval);

  FValSorted:=false;
end;

{%ENDREGION Dictionary with translation}

{%REGION Dictionary with translation and mask}

procedure TDictTransExt.Clear;
var
  i:integer;
begin
  if FCapacity>0 then
  begin
    if not FUseCache then
      for i:=0 to FCount-1 do
        FreeMem(FMasks[i].name);

    FCount:=0;
    SetLength(FMasks  ,0);
    SetLength(FMaskIdx,0);
  end;

  inherited Clear;
end;

function TDictTransExt.GetMaskByIdx(idx:cardinal):PWideChar;
begin
  if idx>=FCount then result:=nil
  else
   if FUseCache then
     result:=FCache[FMasks[idx].idx]
   else
     result:=FMasks[idx].name;
end;

function TDictTransExt.Add(atext, aval:PWideChar; akey:dword=dword(-1)):dword;
begin
  result:=inherited Add(atext, aval, akey);

  if Length(FMasks)<FCapacity then
    SetLength(FMasks,FCapacity);

  if FUseCache then
    FMasks[FCount].idx:=FCache.Append(aval)
  else
    CopyWide(FMasks[FCount].name,aval);

  FMaskSorted:=false;
end;

{%ENDREGION Dictionary with translation and mask}


initialization

finalization

end.
