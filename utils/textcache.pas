{TODO: create option for not autocompact buffer}
{TODO: create import/export as text list}
{TODO: create import/export as list with multiline support}
{TODO: add ref and text length to indexes}
{TODO: add option like 'no_changes' for add (not change) text only}
{TODO: search for same text in full list, not previous text only (if 'no chages')}
unit textcache;

interface

type
  tTextCache = object
  private
    fptrs    :array of integer;
    fbuffer  :PAnsiChar;
    fcursize :integer;
    fcapacity:integer;
    fcount   :integer;
    fcharsize:integer;

    procedure SetCount   (aval:integer);
    procedure SetCapacity(aval:integer);
    function  GetText(idx:cardinal):pointer;
    procedure PutText(idx:cardinal; astr:pointer);
  public
    procedure Init(isAnsi:boolean=true);
    procedure Clear;
    function Append(astr:pointer):integer;
    procedure SaveToFile  (const fname:PAnsiChar);
    procedure LoadFromFile(const fname:PAnsiChar);

    property data[idx:cardinal]:pointer read GetText write PutText; default;
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
  if (idx<Length(fptrs)) and (fptrs[idx]<>0) then // [0] = nil or #0 ?
    result:=fbuffer+fptrs[idx]
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
    lsame:=((idx>0          ) and (fptrs[idx]=fptrs[idx-1])) or
           ((idx<High(fptrs)) and (fptrs[idx]=fptrs[idx+1]));

    if fcharsize=1 then
      newlen:=Length(PAnsiChar(astr))
    else
      newlen:=Length(PWideChar(astr))*SizeOf(WideChar);

    // old was nil = just append new text
    if (fptrs[idx]=0) or lsame then
    begin
      if newlen>0 then
      begin
        fptrs[idx]:=fptrs[Append(astr)];
        dec(fcount);
      end;
      exit;
    end;

    lptr:=fbuffer+fptrs[idx];
    if fcharsize=1 then
      curlen:=Length(PAnsiChar(lptr))
    else
      curlen:=Length(PWideChar(lptr));

    dlen:=newlen-curlen*fcharsize;

    // expand
    if dlen>0 then
    begin
      Capacity:=fcursize+dlen;

      lptr:=fbuffer+fptrs[idx]; // buffer can be changed
      move(lptr^,(lptr+dlen)^,fcursize-fptrs[idx]);
      inc(fcursize,dlen);
    end
    // shrink
    else if dlen<0 then
    begin
      if newlen=0 then dec(dlen); // final #0
      inc(fcursize,dlen);
      move((lptr-dlen)^,lptr^,fcursize-fptrs[idx]);
    end;

    // fix indexes
    for i:=(idx+1) to (fcount-1) do
      if fptrs[i]<>0 then
        fptrs[i]:=fptrs[i]+dlen;

    // set text
    if newlen>0 then
      move(astr^,lptr^,newlen+1)
    else
      fptrs[idx]:=0;
  end;
end;

function tTextCache.Append(astr:pointer):integer;
var
  lp:pointer;
  len:integer;
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
    len:=Length(PAnsiChar(astr))+1
  else
    len:=(Length(PWideChar(astr))+1)*SizeOf(WideChar);

  if len>fcharsize then
  begin
    ltmp:=false;

    if (fcount>0) and (fcharsize=1) then
    begin
      lp:=fbuffer+fptrs[fcount-1];
      // Same as previous
      if CompareChar0(astr,lp,len)=0 then
      begin
        fptrs[fcount]:=fptrs[fcount-1];
        ltmp:=true;
      end;
    end;

    if not ltmp then
    begin
      Capacity:=fcursize+len;

      move(astr^,(fbuffer+fcursize)^,len);
      fptrs[fcount]:=fcursize;
      inc(fcursize,len);
    end;
  end
  else
    fptrs[fcount]:=0;

  result:=fcount;
  inc(fcount);
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
    BlockWrite(f,fptrs[0],fcount*SizeOf(integer));
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
      BlockRead(f,fptrs[0],fcount*SizeOf(integer));
    fcharsize:=0;
    BlockRead(f,fcharsize,1);
    CloseFile(f);
  end;
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


initialization
  //tTextCache.Init;

finalization
 // tTextCache.Clear;

end.
