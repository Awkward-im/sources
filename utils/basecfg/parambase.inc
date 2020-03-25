{
  parameter manipulation
}
{$IFDEF Interface}

type
  pParameter = ^tParameter;
  tParameter = object
  private
    FName :PAnsiChar; // points to source (for write only)
    value: record
      case atype:AnsiChar of
        'a': (ValString:PAnsiChar;);
        'b': (
          data:pointer;
          size:cardinal;
        );
        'd': (ValDateTime:tDateTime;);
        'f': (ValFloat   :Double;);
        'i': (ValInteger :IntPtr;);
        'l': (ValBoolean :boolean;); // really, can be saved as '1'#0#0 or '0'#0#0
        'p': (ValPointer :pointer;);
        'n': (); // special mean NULL
    end;

  private
    function  ReadBool     ():boolean;
    procedure WriteBool    (avalue:boolean);
    function  ReadInt      ():IntPtr;
    procedure WriteInt     (avalue:IntPtr);
    function  ReadFloat    ():Double;
    procedure WriteFloat   (avalue:Double);
    function  ReadDateTime ():TDateTime;
    procedure WriteDateTime(avalue:TDateTime);
    function  ReadPointer  ():pointer;
    procedure WritePointer (avalue:pointer);

    function  ReadStr      ():PAnsiChar;
    procedure WriteStr     (avalue:PAnsiChar);
    function  ReadString   ():AnsiString;
    procedure WriteString  (const avalue:AnsiString);

    procedure SetType(newtype:AnsiChar);

  public
    procedure Init(aname:PAnsiChar);
    procedure Free();
    procedure Clear();
    procedure CopyTo(var dst:tParameter);
    function  IsEmpty():boolean;

    function  ReadBinary (buf:pointer=nil):pointer;
    procedure WriteBinary(avalue:pointer; asize:cardinal);
    procedure WriteWide  (avalue:PWideChar);
    procedure AssignStr  (avalue:PAnsiChar);

    property _Type:AnsiChar read value.atype write SetType;
    property Name:PAnsiChar read FName;

    property AsBoolean :Boolean    read ReadBool     write WriteBool;
    property AsInteger :IntPtr     read ReadInt      write WriteInt;
    property AsFloat   :Double     read ReadFloat    write WriteFloat;
    property AsDateTime:TDateTime  read ReadDateTime write WriteDateTime;
    property AsPointer :pointer    read ReadPointer  write WritePointer;
    property AsText    :PAnsiChar  read ReadStr      write WriteStr;
    property AsString  :AnsiString read ReadString   write WriteString;
  end;

{$ELSE}


procedure tParameter.Init(aname:PAnsiChar);
begin
  StrDup(FName,aname);
  value.atype:='n';
end;

procedure tParameter.Free();
begin
  Clear();
  mFreeMem(FName);
end;

procedure tParameter.Clear();
begin
  case value.atype of
    'a': mFreeMem(value.ValString);
    'b': if value.size>SizeOf(pointer) then mFreeMem(value.data);
  end;
  value.atype:='n';
end;

function tParameter.IsEmpty():boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=value.atype='n';
end;

//----- Parameter processing -----

procedure tParameter.CopyTo(var dst:tParameter);
begin
  case value.atype of
    'a': dst.AsText    :=value.ValString;
    'b': dst.WriteBinary(value.data,value.size);
    'd': dst.AsDateTime:=value.ValDateTime;
    'f': dst.AsFloat   :=value.ValFloat;
    'i': dst.AsInteger :=value.ValInteger;
    'l': dst.AsBoolean :=value.ValBoolean;
    'p': dst.AsPointer :=value.ValPointer;
  else
    dst.Clear();
  end;
end;

procedure tParameter.SetType(newtype:AnsiChar);
var
  buf:array [0..63] of AnsiChar;
  ls:AnsiString;
  p:PAnsiChar;
  pp:pointer;
{$IFDEF UseSysUtils}
  dt:TDateTime;
  fl:Double;
{$ENDIF}
  lsize:integer;
begin
  if value.atype = newtype then exit;

  with value do
    case newtype of
      'a': case atype of
        'b': begin
          mGetMem(p,size*2+1);
          BinaryEncode(p,data,size);
          // avoid additional memory allocation
          Clear();
          atype    :='a';
          ValString:=p;
        end;
{$IFDEF UseSysUtils}
        'd': AsString:=DateTimeToStr(ValDateTime);
{$ENDIF}
        'f': begin
          Str(ValFloat:0:decimals,ls);
          AsString:=ls;
        end;
        'i': begin
          IntToStr(buf,ValInteger);
          AsText:=@buf;
        end;
        'l': if ValBoolean then AsText:='1' else AsText:='0';
        'p': begin
          buf[0]:='0'; buf[1]:='x';
          IntToHex(@buf[2],UIntPtr(ValPointer));
          AsText:=@buf;
        end;
      end;

      'b': case atype of
        'a': begin
           lsize:=StrLen(ValString) div 2;
           if lsize<=SizeOf(pointer) then
           begin
             pp:=@p;
             BinaryDecode(pp,ValString,false);
           end
           else
             lsize:=BinaryDecode(pointer(p),ValString,true);
          // avoid additional memory allocation
           Clear();
           data :=p;
           size :=lsize;
           atype:='b';
         end;
         'p': WriteBinary(ValPointer,SizeOf(pointer));
      end;

      'd': case atype of
        'a': begin
{$IFNDEF UseSysUtils}
           AsDateTime:=0;
{$ELSE}
           TryStrToDateTime(ValString,dt);
           AsDateTime:=dt;
{$ENDIF}
        end;
        'f': AsDateTime:=ValFloat;
        'i': AsDateTime:=ValInteger;
      end;

      'f': case atype of
        'a': begin
{$IFNDEF UseSysUtils}
          AsFloat:=0;
{$ELSE}
          TryStrToFloat(ValString,fl);
          AsFloat:=fl;
{$ENDIF}
        end;
        'd': AsFloat:=ValDateTime;
        'i': AsFloat:=ValInteger;
        'l': if ValBoolean then AsFloat:=1 else AsFloat:=0;
      end;

      'i': case atype of
        'a': AsInteger:=NumToInt(ValString);
        'b': AsInteger:=size;
        'f': AsInteger:=Round(ValFloat);
        'l': if ValBoolean then AsInteger:=1 else AsInteger:=0;
        'p': AsInteger:=IntPtr(ValPointer);
      end;

      'l': case atype of
        'a': AsBoolean:=(StrCmpI(ValString,'true')=0) or (StrToInt(ValString)<>0);
        'b': AsBoolean:=true;
        'd': AsBoolean:=ValDateTime<>0;
        'f': AsBoolean:=ValFloat   <>0;
        'i': AsBoolean:=ValInteger <>0;
      end;

      'p': case atype of
        'a': AsPointer:=pointer(NumToInt(ValString));
        'b': AsPointer:=data;
        'i': AsPointer:=pointer(ValInteger);
      end;

    else
      Clear();
    end;
end;

//----- Different value types -----

//--- Simple types

function tParameter.ReadBool():boolean;
begin
  if value.atype='l' then
    result:=value.ValBoolean
  else
    result:=false;
end;

function tParameter.ReadInt():IntPtr;
begin
  if      value.atype='b' then result:=value.size
  else if value.atype='i' then result:=value.ValInteger
  else
    result:=0;
end;

function tParameter.ReadFloat():Double;
begin
  if value.atype='f' then
    result:=value.ValFloat
  else
    result:=0;
end;

function tParameter.ReadDateTime():TDateTime;
begin
  if value.atype='d' then
    result:=value.ValDateTime
  else
    result:=0;
end;

function tParameter.ReadPointer():pointer;
begin
  if value.atype='p' then
    result:=value.ValPointer
  else
    result:=nil;
end;

//--- Text types

function tParameter.ReadStr():PAnsiChar;
begin
  if value.atype='a' then
    result:=value.ValString
  else
    result:=nil;
end;

function tParameter.ReadString():AnsiString;
begin
  if value.atype='a' then
    result:=value.ValString
  else
    result:='';
end;

//----- Write

//--- Simple types

procedure tParameter.WriteBool(avalue:boolean);
begin
  Clear();

  value.atype:='l';
  value.ValBoolean:=avalue;
end;

procedure tParameter.WriteInt(avalue:IntPtr);
begin
  Clear();

  value.atype:='i';
  value.ValInteger:=avalue;
end;

procedure tParameter.WriteFloat(avalue:Double);
begin
  Clear();

  value.atype:='f';
  value.ValFloat:=avalue;
end;

procedure tParameter.WriteDateTime(avalue:TDateTime);
begin
  Clear();

  value.atype:='d';
  value.ValDateTime:=avalue;
end;

procedure tParameter.WritePointer(avalue:pointer);
begin
  Clear();

  value.atype:='p';
  value.ValPointer:=avalue;
end;

//--- Text types

procedure tParameter.WriteWide(avalue:PWideChar);
begin
  Clear();

  if (avalue<>nil) and (avalue^<>#0) then
  begin
    value.atype:='a';
    WideToUTF8(avalue,value.ValString);
  end;
end;

procedure tParameter.WriteStr(avalue:PAnsiChar);
begin
  Clear();

  if (avalue<>nil) and (avalue^<>#0) then
  begin
    value.atype:='a';
    StrDup(value.ValString,avalue);
  end;
end;

procedure tParameter.AssignStr(avalue:PAnsiChar);
begin
  Clear();

  if (avalue<>nil) then
  begin
    if (avalue^<>#0) then
    begin
      value.atype:='a';
      value.ValString:=avalue;
    end
    else
      mFreeMem(avalue);
  end;
end;

procedure tParameter.WriteString(const avalue:AnsiString);
begin
  Clear();

  if avalue<>'' then
  begin
    value.atype:='a';
    StrDup(value.ValString,pointer(avalue));
  end;
end;

//--- Binary

function tParameter.ReadBinary(buf:pointer=nil):pointer;
begin
  if value.atype<>'b' then
    result:=nil
  else
  begin
    if value.size<=SizeOf(pointer) then
    begin
      if buf<>nil then
        move(value.data,PByte(buf)^,value.size)
      else
        result:=@value.data;
    end
    else
    begin
      if buf<>nil then
      begin
        move(PByte(value.data)^,PByte(buf)^,value.size);
        result:=buf;
      end
      else
        result:=value.data;
    end;
  end;
end;

procedure tParameter.WriteBinary(avalue:pointer; asize:cardinal);
begin
  Clear();

  if (avalue<>nil) and (asize>0) then
  begin
    value.atype:='b';
    value.size:=asize;

    if asize<=SizeOf(pointer) then
      value.data:=avalue
    else
    begin
      mGetMem(value.data,asize);
      move(PByte(avalue)^,PByte(value.data)^,asize);
    end;
  end;
end;

{$ENDIF}
