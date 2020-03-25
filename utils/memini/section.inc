{
  INIFile parameter and section manipulation
}
{$IFDEF Interface}

  pINIParameter = ^tINIParameter;
  tINIParameter = record
    name :PAnsiChar; // points to source (for write only)
    value:PAnsiChar; // points to source? or modified
    flags:cardinal;  // F_NAME, F_VALUE used atm
{$IFDEF UseHash}
    hash :cardinal;  // param name hash
{$ENDIF}
  end;

  pINISection = ^tINISection;
  tINISection = object // record
  private
    parent:pININamespace;
    next  :pINISection;

    FName :PAnsiChar;  // pointer to name

    paramlist   :PAnsiChar;
    FSectionText:PAnsiChar;

    arParameters:array of tINIParameter;
    numparam:integer;

    flags:cardinal;

{$IFDEF UseHash}
    hash:cardinal;   // namespace+section name hash
{$ENDIF}

    function  SearchParameter  (akey:PAnsiChar):pINIParameter;
    function  GetParameterValue(akey:PAnsiChar):PAnsiChar;
    procedure ChangeParameter  (akey:PAnsiChar; avalue:PAnsiChar);

    function  GetParameterList:PAnsiChar;
    function  GetParameterCount:integer;

    function  GetSectionText():PAnsiChar;
  public
    procedure CopyTo(var dst:tINISection); overload;
    procedure CopyTo(dst:PAnsiChar      ); overload;
    procedure Delete();
    procedure Rename(newname:PAnsiChar);

    function  ReadBool   (akey:PAnsiChar; adefault:boolean=false):boolean;
    procedure WriteBool  (akey:PAnsiChar; avalue  :boolean);
    function  ReadInt    (akey:PAnsiChar; adefault:integer=0):integer;
    procedure WriteInt   (akey:PAnsiChar; avalue  :integer);
    function  ReadWide   (akey:PAnsiChar; adefault:PWideChar=nil):PWideChar;
    procedure WriteWide  (akey:PAnsiChar; avalue  :PWideChar);
    function  ReadStr    (akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar;
    procedure WriteStr   (akey:PAnsiChar; avalue  :PAnsiChar);
    function  ReadString (akey:PAnsiChar; const adefault:AnsiString=''):AnsiString;
    procedure WriteString(akey:PAnsiChar; const avalue  :AnsiString);
    function  ReadStruct (akey:PAnsiChar; buf:pointer=nil):pointer;
    procedure WriteStruct(akey:PAnsiChar; avalue:pointer; asize:cardinal);

    property Name:PAnsiChar read FName write Rename;

    property ParameterList :PAnsiChar read GetParameterList;
    property ParameterCount:integer   read GetParameterCount;

    property SectionText:PAnsiChar read GetSectionText;

    property Key[akey:PAnsiChar]:PAnsiChar
             read GetParameterValue write ChangeParameter; default;
  end;

{$ELSE}

//----- parameter value = Spructure encode/decode -----

function StructEncode(out dst:PAnsiChar;src:pointer; len:cardinal):PAnsiChar;
begin
  if (len=0) or (src=nil) then
  begin
    dst:=nil;
    result:=nil;
  end
  else
  begin
    mGetMem(dst, len*2+1);
    result:=dst;

    while len>0 do
    begin
      dst^:=HexDigitChr[PByte(src)^ shr 4]; inc(dst);
      dst^:=HexDigitChr[PByte(src)^ and $0F];

      inc(PByte(src));
      inc(dst);
      dec(len);
    end;

    dst^:=#0;
    dst:=result;
  end;
end;

function StructDecode(out dst:pointer; src:PAnsiChar; alloc:boolean=true):Cardinal;
var
  ldst:PAnsiChar;
begin
  if (src<>nil) and (src^<>#0) then
  begin
    if alloc then
      mGetMem(dst,StrLen(src) div 2);

    ldst:=dst;
    while src^<>#0 do
    begin
      ldst^:=AnsiChar(common.HexToInt(src,2)); // or common.HexToByte(src);
      inc(src,2);
      inc(ldst);
    end;
    result:=PAnsiChar(ldst)-PAnsiChar(dst);
  end
  else
  begin
    if alloc then
      dst:=nil;
    result:=0;
  end;
end;

//----- text creating -----

function GetValueLen(avalue:PAnsiChar):cardinal;
var
  p:PAnsiChar;
  l,llen:integer;
  quotes,crlfs,linebreaks:cardinal;
begin
  if avalue=nil then
  begin
    result:=0;
    exit;
  end;
  quotes    :=0;
  crlfs     :=0;
  linebreaks:=0;
  l:=0;
  p:=avalue;
  llen:=StrLen(avalue);
  inc(avalue,llen);
  while p^<>#0 do
  begin
    if p^ in [#9,' ','''',';',line_separator] then
      quotes:=1;

    if p^ in [#10,#13] then
    begin
      inc(crlfs);
      if ((p+1)^<>p^) and ((p+1)^ in [#10,#13]) then
        inc(p);
      inc(p);

      l:=0;
    end
    else
    begin
      inc(l);
      if l=MaxLineLen then
      begin
        if (avalue-p)>=UnbreakLen then
        begin
          inc(linebreaks);
          l:=0;
        end;
      end;
      inc(p);
    end;
  end;
  result:=llen +
      2*quotes*(crlfs+linebreaks+1) + // reserve - quotes for #9,#32 and '
      6*crlfs +                       // 2 quotes+space+sep+sep+1, if newline is one char
      6*linebreaks;                   // 2 quotes+space+sep+cr+lf
end;

procedure GetValueText(var dst:PAnsiChar; avalue:PAnsiChar);
var
  p:PAnsiChar;
  l:integer;
  quotes:boolean;
begin
  if avalue=nil then exit;

  p:=avalue;
  l:=0;
  quotes:=false;
  while p^<>#0 do
  begin
    if p^ in [#9,' ','''',';',line_separator] then
    begin
      quotes:=true;
      break;
    end;
    inc(p);
  end;
  if quotes then
  begin
    dst^:=''''; inc(dst);
  end;

  p:=avalue;
  avalue:=StrEnd(avalue);
  while p^<>#0 do
  begin
    if p^ in [#10,#13] then
    begin
      if ((p+1)^<>p^) and ((p+1)^ in [#10,#13]) then
        inc(p);
      inc(p);
    end
    else
    begin
      dst^:=p^; inc(dst); inc(p);
      inc(l);

      if (l<MaxLineLen) or ((avalue-p)<UnbreakLen) then
        continue;
    end;

    if quotes then
    begin
      dst^:=''''; inc(dst);
    end;

    dst^:=' '; inc(dst);
    dst^:=line_separator; inc(dst);
    if (p-1)^ in [#10,#13] then
    begin
      dst^:=line_separator; inc(dst);
    end;

    dst^:=#13; inc(dst); dst^:=#10; inc(dst);
    if quotes then
    begin
      dst^:=''''; inc(dst);
    end;
    l:=0;
  end;
  if quotes then
  begin
    dst^:=''''; inc(dst);
  end;
end;

//-----  -----

function tINISection.GetSectionText():PAnsiChar;
var
  p:PAnsiChar;
  i:integer;
{$IFDEF UseStrings}
  s:AnsiString;
  pp:PAnsiChar;
  j,oldsize:integer;
{$ELSE}
  sum:cardinal;
{$ENDIF}
begin
  if (flags and F_VCHANGED)<>0 then
  begin
    mFreeMem(FSectionText);

{$IFDEF UseStrings}    
    p:=nil;
    oldsize:=0;
    s:='';
    for i:=0 to numparam-1 do
    begin
      with arParameters[i] do
      begin
        j:=GetValueLen(value);
        if j>0 then
        begin
          if oldsize<j then
          begin
            mFreeMem(p);
            mGetMem(p,j+2);
            oldsize:=j;
          end;
          pp:=p;
          GetValueText(pp,value); pp^:=#0;
          s := s + name + '=' + p + #13#10;
        end
        else if (self.flags and F_KEEPEMPTY)<>0 then
          s := s + name + '=' + #13#10;
      end;
    end;
    mFreeMem(p);
    StrDup(FSectionText,pointer(s));
{$ELSE}
    sum:=0;
    for i:=0 to numparam-1 do
    begin
      with arParameters[i] do
      begin
        if (value<>nil) or ((self.flags and F_KEEPEMPTY)<>0) then
        begin
          inc(sum,StrLen(name)+1);       // parameter name including "="
          inc(sum,GetValueLen(value)+2); // parameter value with separators, quotes, crlf
        end;
      end;
    end;

    mGetMem(p,sum+1);
    FSectionText:=p;

    for i:=0 to numparam-1 do
    begin
      with arParameters[i] do
      begin
        if (value<>nil) or ((self.flags and F_KEEPEMPTY)<>0) then
        begin
          p:=StrCopyE(p,name);
          p^:='='; inc(p);
          GetValueText(p,value);
          p^:=#13; inc(p); p^:=#10; inc(p);
        end;
      end;
    end;
    p^:=#0;
{$ENDIF}

    flags:=flags and not F_VCHANGED;
  end;
  result:=FSectionText;
end;

//----- Parameters processing -----

function tINISection.GetParameterCount():integer;
var
  i:integer;
begin
  result:=0;

  for i:=0 to numparam-1 do
  begin
    if (arParameters[i].value<>nil) or ((flags and F_KEEPEMPTY)<>0) then
      inc(result);
  end;
end;

function tINISection.GetParameterList():PAnsiChar;
var
  pc:PAnsiChar;
  i:integer;
  lsize:cardinal;
begin
  if (flags and F_NCHANGED)<>0 then
  begin
    mFreeMem(paramlist);

    lsize:=0;
    for i:=0 to numparam-1 do
    begin
      if (arParameters[i].value<>nil) or ((flags and F_KEEPEMPTY)<>0) then
        inc(lsize,StrLen(arParameters[i].name)+1);
    end;

    mGetMem(pc,lsize+1);
    paramlist:=pc;
    if lsize>0 then
    begin
      for i:=0 to numparam-1 do
      begin
        if (arParameters[i].value<>nil) or ((flags and F_KEEPEMPTY)<>0) then
        begin
          pc:=StrCopyE(pc,arParameters[i].name);
          inc(pc);
        end;
      end;
    end;
    pc^:=#0;
    flags:=flags and not F_NCHANGED;
  end;
  result:=paramlist;
end;

function tINISection.SearchParameter(akey:PAnsiChar):pINIParameter;
var
  i:integer;
{$IFDEF UseHash}
  lhash:cardinal;
{$ELSE}
  b:boolean;
{$ENDIF}
begin
{$IFDEF UseHash}
  lhash:=HashOf(akey,(flags and F_CASE)<>0);
  for i:=0 to numparam-1 do
  begin
    if (arParameters[i].hash=lhash) then
    begin
      result:=@arParameters[i];
      exit;
    end;
  end;
{$ELSE}
  for i:=0 to numparam-1 do
  begin
    if (flags and F_CASE)<>0 then
      b:=StrCmp (arParameters[i].name,akey)=0
    else
      b:=StrCmpI(arParameters[i].name,akey)=0;
    if b then
    begin
      result:=@arParameters[i];
      exit;
    end;
  end;
{$ENDIF}
  result:=nil;
end;

function tINISection.GetParameterValue(akey:PAnsiChar):PAnsiChar;
var
  pn:pINIParameter;
begin
  pn:=SearchParameter(akey);
  if pn=nil then
    result:=nil
  else
    result:=pn^.value;
end;

procedure tINISection.ChangeParameter(akey:PAnsiChar; avalue:PAnsiChar);
var
  pn:pINIParameter;
begin
  pn:=SearchParameter(akey);
  if pn=nil then
  begin
    if numparam>High(arParameters) then
      SetLength(arParameters,Length(arParameters)+increment);

    flags:=flags or F_CHANGED;

    pn:=@arParameters[numparam];
    FillChar(pn^,SizeOf(tINIParameter),0);
{$IFDEF UseHash}
    pn^.hash:=HashOf(akey,(flags and F_CASE)<>0);
{$ENDIF}
    if (flags and F_BUFFER)=0 then
    begin
      StrDup(pn^.name ,akey);
      StrDup(pn^.value,avalue);
      pn^.flags:=pn^.flags or F_NAME or F_VALUE;
    end
    else
    begin
      pn^.name :=akey;
      if avalue^=#0 then
        pn^.value:=nil
      else
        pn^.value:=avalue;
    end;
    inc(numparam);
  end
  else
  begin
    if StrCmp(pn^.value,avalue)<>0 then
    begin
      if (pn^.flags and F_VALUE)<>0 then
        mFreeMem(pn^.value);
      if avalue<>nil then
      begin
        StrDup(pn^.value,avalue);
        pn^.flags:=pn^.flags or F_VALUE;
        flags:=flags or F_VCHANGED;
      end
      else
        flags:=flags or F_CHANGED; // really, it mean what parameter will be empty
    end;
  end;
end;

//----- Different value types -----

function tINISection.ReadBool(akey:PAnsiChar; adefault:boolean=false):boolean;
var
  pc:PAnsiChar;
begin
  pc:=Key[akey];
  if pc=nil then
    result:=adefault
  else
    result:=(StrCmp(pc,'true')=0) or (StrToInt(pc)<>0);
end;

function tINISection.ReadInt(akey:PAnsiChar;adefault:integer=0):integer;
var
  pc:PAnsiChar;
begin
  pc:=Key[akey];
  if pc=nil then
    result:=adefault
  else
    result:=StrToInt(pc);
end;

function tINISection.ReadWide(akey:PAnsiChar;adefault:PWideChar=nil):PWideChar;
var
  pc:PAnsiChar;
begin
  pc:=Key[akey];
  if pc=nil then
    StrDupW(result,adefault)
  else
    UTF8ToWide(pc,result);
end;

function tINISection.ReadStr(akey:PAnsiChar;adefault:PAnsiChar=nil):PAnsiChar;
var
  pc:PAnsiChar;
begin
  pc:=Key[akey];
  if pc=nil then
    StrDup(result,adefault)
  else
    StrDup(result,pc); // or UTF8ToAnsi(pc,result)
end;

function tINISection.ReadString(akey:PAnsiChar;const adefault:AnsiString=''):AnsiString;
var
  pc:PAnsiChar;
begin
  pc:=Key[akey];
  if pc=nil then
    result:=adefault
  else
    result:=pc; // or result:=system.UTF8ToAnsi(pc)
end;

procedure tINISection.WriteBool(akey:PAnsiChar; avalue:boolean);
begin

  if (flags and F_SIMPLEBOOL)<>0 then
  begin
    if avalue then
      Key[akey]:='1'
    else
      Key[akey]:='0';
    exit;
  end;

  if avalue then
    Key[akey]:='true'
  else
    Key[akey]:='false';
end;

procedure tINISection.WriteInt(akey:pAnsiChar;avalue:integer);
var
  buf:array [0..31] of AnsiChar;
begin
  Key[akey]:=IntToStr(buf,avalue);
end;

procedure tINISection.WriteWide(akey:PAnsiChar;avalue:PWideChar);
var
  pc:PAnsiChar;
begin
  WideToUTF8(avalue,pc);
  Key[akey]:=pc;
  mFreeMem(pc);
end;

procedure tINISection.WriteStr(akey:PAnsiChar;avalue:PAnsiChar);
begin
  Key[akey]:=avalue;
  { or
  AnsiToUTF8(avalue,pc);
  Key[akey]:=pc;
  mFreeMem(pc);
  }
end;

procedure tINISection.WriteString(akey:PAnsiChar;const avalue:AnsiString);
begin
  Key[akey]:=pointer(avalue);
  { or
  AnsiToUTF8(avalue,pc);
  Key[akey]:=pc;
  mFreeMem(pc);
  }
end;

function tINISection.ReadStruct(akey:PAnsiChar; buf:pointer=nil):pointer;
begin
  if buf=nil then
    StructDecode(result,Key[akey],true)
  else
  begin
    StructDecode(buf,Key[akey],false);
    result:=buf;
  end;
end;

procedure tINISection.WriteStruct(akey:PAnsiChar; avalue:pointer; asize:cardinal);
var
  tmp:PAnsiChar;
begin
  StructEncode(tmp,avalue,asize);
  Key[akey]:=tmp;
  mFreeMem(tmp);
end;

//----- Section processing -----

procedure tINISection.Delete;
var
  i:integer;
begin
  for i:=0 to numparam-1 do
  begin
    with arParameters[i] do
    begin
      if (flags and F_NAME )<>0 then mFreeMem(name);
      if (flags and F_VALUE)<>0 then mFreeMem(value);
    end;
  end;
  SetLength(arParameters,0);

  mFreeMem(paramlist);
  mFreeMem(FSectionText);

  if (flags and F_NAME)<>0 then
    mFreeMem(FName);

  flags:=0;

  parent^.flags:=parent^.flags or F_CHANGED;

//!! find ns, decrease ns refcount, delete if needs
//  parent^.Compress;
end;

procedure tINISection.CopyTo(var dst:tINISection);
var
  pn:pINIParameter;
  i:integer;
begin
  if (@dst<>@self) then
  begin
    for i:=0 to numparam-1 do
    begin
      pn:=@arParameters[i];
      dst.Key[pn^.name]:=pn^.value;
    end;
  end;
end;

procedure tINISection.CopyTo(dst:PAnsiChar);
begin
  CopyTo(parent^.GetSection(dst)^);
end;

procedure tINISection.Rename(newname:PAnsiChar);
var
  sn:pINISection;
begin
  sn:=parent^.FindSection(newname);
  if sn<>nil then
  begin
    CopyTo(sn^);
//    Delete;
  end
  else
  begin
    if (flags and F_NAME)<>0 then
      mFreeMem(FName);
    StrDup(FName,newname);
    flags:=flags or F_NAME;
  {$IFDEF UseHash}
    hash:=HashOf(FName,(flags and F_CASE)<>0);
  {$ENDIF}
    parent^.flags:=parent^.flags or F_CHANGED;
  end;
end;

{$ENDIF}
