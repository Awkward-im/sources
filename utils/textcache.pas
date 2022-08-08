{TODO: force to/from UTF8 conversion in Wide text case?  (problem with return) but by option?}
{TODO: add #0000 as first element ALWAYS}
{TODO: create option for not autocompact buffer}
{TODO: create import as text list}
{TODO: create import/export as list with multiline support}
{TODO: add ref and text length to indexes}
{TODO: add option like 'no_changes' for add (not change) text only}
{TODO: split one type to Ansi and Wide}
{TODO: split Hash to Ansi an Unicode}
unit textcache;

interface

type
  tTextCache = object
  private
    fptrs:array of record
      offset:integer;
      hash  :longword;
    end;
    fbuffer  :PAnsiChar;
    fcursize :integer;
    fcapacity:integer;
    fcount   :integer;
    fcharsize:integer;

    procedure SetCount   (aval:integer);
    procedure SetCapacity(aval:integer);

    function  GetText(idx:cardinal):pointer;
    procedure PutText(idx:cardinal; astr:pointer);

    function  GetSText(idx:cardinal):AnsiString;
    procedure PutSText(idx:cardinal; const astr:AnsiString);

    function  GetWText(idx:cardinal):WideString;
    procedure PutWText(idx:cardinal; const astr:WideString);

    function  GetHash (idx:cardinal):longword;
    function  GetHash (const astr:AnsiString):longword;
    function  CalcHash(instr:PByte; alen:integer):dword;
  public
    procedure Init(isAnsi:boolean=true);
    procedure Clear;

    function Append(astr:pointer):integer;
    function Add   (astr:pointer):integer;

    procedure SaveToFile  (const fname:PAnsiChar);
    procedure LoadFromFile(const fname:PAnsiChar);
    procedure Export      (const fname:PAnsiChar);

    function IndexOf(astr:pointer):integer;

//    class function StrHash(const astr:AnsiString):longword;

    property str [idx:cardinal]:AnsiString read GetSText write PutSText;
    property wide[idx:cardinal]:WideString read GetWText write PutWText;
    property data[idx:cardinal]:pointer    read GetText  write PutText; default;
    property hash[idx:cardinal]:longword   read GetHash;

    property Count   :integer read fcount    write SetCount;
    // used memory buffer size
    property Size    :integer read fcursize;
    // memory buffer capacity (bytes)
    property Capacity:integer read fcapacity write SetCapacity;
  end;


implementation

const
  start_buf = 32768;
  start_arr = 1024;
  delta_buf = 4096;
  delta_arr = 128;

{$PUSH}
{$Q-}
function tTextCache.CalcHash(instr:PByte; alen:integer):dword;
var
  i:integer;
begin
  result:=alen;
{
  if fcharsize=1 then
  begin
}
    for i:=0 to alen-1 do
      result:=(result SHR 27) xor (result SHL 5) xor ORD(UpCase(AnsiChar(instr[i])));
{
  end
  else
  begin
    for i:=0 to alen-1 do
      result:=(result SHR 27) xor (result SHL 5) xor ORD(UpCase(AnsiChar(instr[i])));
  end;
}
end;
{$POP}
{
class function tTextCache.StrHash(const astr:AnsiString):longword;
begin
  result:=CalcHash(PByte(astr),Length(astr)+1);
end;
}
function tTextCache.GetHash(const astr:AnsiString):longword;
begin
  result:=CalcHash(PByte(astr),Length(astr)+1);
end;

function tTextCache.GetHash(idx:cardinal):longword;
begin
  if (idx<Length(fptrs)) then
    result:=fptrs[idx].hash
  else
    result:=0;
end;

procedure tTextCache.SetCount(aval:integer);
begin
  if aval>Length(fptrs) then
    SetLength(fptrs,Align(aval,delta_arr));
end;

// Set text buffer size (bytes)
procedure tTextCache.SetCapacity(aval:integer);
begin
  if aval<(start_buf*fcharsize) then aval:=start_buf*fcharsize
  else
    aval:=Align(aval,delta_buf*fcharsize);

  if aval>fcapacity then
  begin
    ReallocMem(fbuffer,aval);
    fcapacity:=aval;
    // first text is empty
    if fcursize<=0 then
    begin
      fcursize:=fcharsize;
      PWideChar(fbuffer)^:=#0;
    end;
  end;
end;

function tTextCache.GetText(idx:cardinal):pointer;
begin
  if (idx<Length(fptrs)) and (fptrs[idx].offset<>0) then // [0] = nil or #0 ?
    result:=fbuffer+fptrs[idx].offset
  else
    result:=nil;
end;

// anyway, will be used (if only) in very rare cases
procedure tTextCache.PutText(idx:cardinal; astr:pointer);
var
  lptr:PAnsiChar;
  newlen,curlen,dlen,i:integer;
  lsame:boolean;
begin
  if idx<Length(fptrs) then
  begin
    lsame:=((idx>0          ) and (fptrs[idx].offset=fptrs[idx-1].offset)) or
           ((idx<High(fptrs)) and (fptrs[idx].offset=fptrs[idx+1].offset));

    if fcharsize=1 then
      newlen:=Length(PAnsiChar(astr))
    else
      newlen:=Length(PWideChar(astr))*SizeOf(WideChar);

    // old was nil = just append new text
    if (fptrs[idx].offset=0) or lsame then
    begin
      if newlen>0 then
      begin
        fptrs[idx].offset:=fptrs[Append(astr)].offset;
        dec(fcount);
      end;
      exit;
    end;

    lptr:=fbuffer+fptrs[idx].offset;
    if fcharsize=1 then
      curlen:=Length(PAnsiChar(lptr))
    else
      curlen:=Length(PWideChar(lptr));

    dlen:=newlen-curlen*fcharsize;

    // expand
    if dlen>0 then
    begin
      Capacity:=fcursize+dlen;

      lptr:=fbuffer+fptrs[idx].offset; // buffer can be changed
      move(lptr^,(lptr+dlen)^,fcursize-fptrs[idx].offset);
      inc(fcursize,dlen);
    end
    // shrink
    else if dlen<0 then
    begin
      if newlen=0 then dec(dlen); // final #0
      inc(fcursize,dlen);
      move((lptr-dlen)^,lptr^,fcursize-fptrs[idx].offset);
    end;

    // fix indexes
    for i:=(idx+1) to (fcount-1) do
      if fptrs[i].offset<>0 then
        fptrs[i].offset:=fptrs[i].offset+dlen;

    // set text
    if newlen>0 then
      move(astr^,lptr^,newlen+1)
    else
      fptrs[idx].offset:=0;
  end;
end;

function tTextCache.GetSText(idx:cardinal):AnsiString;
begin
  if fcharsize=1 then
    result:=PAnsiChar(GetText(idx))
  else
    result:=PWideChar(GetText(idx));
end;

procedure tTextCache.PutSText(idx:cardinal; const astr:AnsiString);
begin
  if fcharsize=1 then
    PutText(idx,pointer(astr))
  else
    PutText(idx,pointer(WideString(astr)));
end;

function tTextCache.GetWText(idx:cardinal):WideString;
begin
  if fcharsize=1 then
    result:=PAnsiChar(GetText(idx))
  else
    result:=PWideChar(GetText(idx));
end;

procedure tTextCache.PutWText(idx:cardinal; const astr:WideString);
begin
  if fcharsize=2 then
    PutText(idx,pointer(astr))
  else
    PutText(idx,pointer(AnsiString(astr)));
end;

function tTextCache.IndexOf(astr:pointer):integer;
var
  p,lp:PWideChar;
  i,llen:integer;
  lhash:longword;
begin
  if astr=nil then exit(0); //!!

  result:=-1;

  if fcharsize=1 then
  begin
    if PAnsiChar(astr)^=#0 then exit(0);

    llen:=Length(PAnsiChar(astr))+1;
    lhash:=CalcHash(PByte(astr),llen);
    for i:=0 to fcount-1 do
    begin
      if fptrs[i].hash=lhash then
//        if CompareChar0(data[i],astr,llen)=0 then
        if CompareChar0(data[i]^,PByte(astr)^,llen)=0 then
          exit(i);
    end;
  end
  else
  begin
    if PWideChar(astr)^=#0 then exit(0);

    llen:=Length(PWideChar(astr))+1;
    lhash:=CalcHash(PByte(astr),llen*SizeOf(WideChar));
    for i:=0 to fcount-1 do
    begin
      if fptrs[i].hash=lhash then
      begin
        p :=data[i];
        lp:=astr;
        repeat
          if lp^<>p^ then break;
          if lp^=#0 then exit(i);
          dec(llen);
          if llen=0 then exit(i);
          inc(lp);
          inc(p);
        until false;
      end;
    end;
  end;
end;

function tTextCache.Append(astr:pointer):integer;
var
//  lp:pointer;
  len:integer;
  lhash:longword;
  ltmp:boolean;
begin
  // Check indexes
  if fcount>=High(fptrs) then
  begin
    if Length(fptrs)=0 then
      SetLength(fptrs,start_arr)
    else
      SetLength(fptrs,Length(fptrs)+delta_arr);
  end;

  if fcharsize=1 then
  begin
    len:=Length(PAnsiChar(astr))+1;
    if len>1 then lhash:=CalcHash(PByte(astr),len);
  end
  else
  begin
    len:=(Length(PWideChar(astr))+1)*SizeOf(WideChar);
    if len>SizeOf(WideChar) then lhash:=CalcHash(PByte(astr),len);
  end;

  if len>fcharsize then
  begin
    ltmp:=false;

    // Check for same as previous
    if (fcount>0) and (Capacity>0) and (fcharsize=1) then
    begin
//      lp:=fbuffer+fptrs[fcount-1].offset;
//      if CompareChar0(astr^,lp^,len)=0 then
//      if CompareByte(astr,lp,len)=0 then
      if CompareChar0(PByte(astr)^,PByte(fbuffer+fptrs[fcount-1].offset)^,len)=0 then
      begin
        fptrs[fcount].offset:=fptrs[fcount-1].offset;
        fptrs[fcount].hash  :=fptrs[fcount-1].hash;
        ltmp:=true;
      end;
    end;

    if not ltmp then
    begin
      Capacity:=fcursize+len;

      move(astr^,(fbuffer+fcursize)^,len);
      fptrs[fcount].offset:=fcursize;
      fptrs[fcount].hash  :=lhash;
      inc(fcursize,len);
    end;
  end
  else
    fptrs[fcount].offset:=0;

  result:=fcount;
  inc(fcount);
end;

function tTextCache.Add(astr:pointer):integer;
begin
  result:=IndexOf(astr);
  if result<0 then result:=Append(astr);
end;

procedure tTextCache.Export(const fname:PAnsiChar);
var
  t:Text;
  i:integer;
begin
  AssignFile(t,fname);
  ReWrite(t);
  if IOResult=0 then
  begin
    for i:=0 to fcount-1 do
    begin
      Writeln(t,'  {',i:5,'} ',str[i]);
    end;
    CloseFile(t);
  end;
end;

procedure tTextCache.SaveToFile(const fname:PAnsiChar);
var
  f:file of byte;
begin
  AssignFile(f,fname);
  ReWrite(f);
  if IOResult=0 then
  begin
    BlockWrite(f,fcursize,SizeOf(integer));
    BlockWrite(f,fBuffer^,fcursize);
    BlockWrite(f,fcount,4);
    BlockWrite(f,PByte(@fptrs[0])^,fcount*SizeOf(fptrs[0]));
    BlockWrite(f,fcharsize,1);
    CloseFile(f);
  end;
end;

procedure tTextCache.LoadFromFile(const fname:PAnsiChar);
var
  f:file of byte;
begin
  AssignFile(f,fname);
  ReSet(f);
  if IOResult=0 then
  begin
    Clear;
    BlockRead(f,fcursize,SizeOf(integer));
    SetCapacity(fcursize);
    BlockRead(f,fBuffer^,fcursize);
    BlockRead(f,fcount,4);
    SetLength(fptrs,fcount);
    if fcount>0 then
      BlockRead(f,PByte(@fptrs[0])^,fcount*SizeOf(fptrs[0]));
    fcharsize:=0;
    BlockRead(f,fcharsize,1);
    CloseFile(f);
  end;
end;

procedure tTextCache.Clear;
begin
  SetLength(fptrs,0);
  FreeMem(fbuffer);
//  FillChar(self^,SizeOf(tTextCache),0);

  fbuffer  :=nil;
  fcount   :=0;
  fcapacity:=0;
  fcursize :=0;
end;

procedure tTextCache.Init(isAnsi:boolean=true);
begin
  if isAnsi then
    fcharsize:=1
  else
    fcharsize:=SizeOf(WideChar);

  fbuffer:=nil;
  Clear;
{
  SetLength(fptrs,start_arr);
  fcount:=0;

  SetCapacity(start_buf*fcharsize);
}
end;


initialization
  //tTextCache.Init;

finalization
 // tTextCache.Clear;

end.
