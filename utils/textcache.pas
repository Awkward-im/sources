{%TODO create option for not autocompact buffer}
unit textcache;

interface

type
  tTextCache = object
  private
    fptrs    :array of integer; //static;
    fbuffer  :PAnsiChar; //static;
    fcursize :integer;   //static;
    fcapacity:integer;   //static;
    fcount   :integer;   //static;

    {class} procedure SetCapacity(aval:integer);            //static;
    {class} function  GetText(idx:integer):PAnsiChar;       //static;
    {class} procedure PutText(idx:integer; astr:PAnsiChar); //static;
  public
    {class} procedure Init;  //static;
    {class} procedure Clear; //static;
    {class} function Append(astr:PAnsiChar):integer;

    {class} property data[idx:integer]:PAnsiChar read GetText write PutText; default;
    {class} property Count   :integer read fcount;
    {class} property Size    :integer read fcursize;
    {class} property Capacity:integer read fcapacity write SetCapacity;
  end;


implementation

{$IFNDEF FPC}
uses
  Common;
{$ENDIF}

const
  start_buf = 32768;
  start_arr = 1024;
  delta_buf = 4096;
  delta_arr = 128;

{class} procedure tTextCache.SetCapacity(aval:integer);
var
  newptr:PAnsiChar;
begin
  if aval<start_buf then aval:=start_buf
  else // align
    aval:=((aval+delta_buf-1) div delta_buf)*delta_buf;
//  aval:=aval+delta_buf-(aval mod delta_buf);

  if aval>fcapacity then
  begin
    GetMem(newptr,aval);
    if fcursize>0 then
    begin
      move(fbuffer^,newptr^,fcursize);
      FreeMem(fbuffer);
    end
    else
    begin
      fcursize:=1;
      newptr^:=#0;
    end;
    fbuffer:=newptr;
    fcapacity:=aval;
  end;
end;

{class} function tTextCache.GetText(idx:integer):PAnsiChar;
begin
  if (idx>=0) and (idx<Length(fptrs)) and (fptrs[idx]<>0) then // [0] = nil or #0 ?
    result:=fbuffer+fptrs[idx]
  else
    result:=nil;
end;

{class} procedure tTextCache.PutText(idx:integer; astr:PAnsiChar);
var
  lptr:PAnsiChar;
  newlen,curlen,dlen,i:integer;
  lsame:boolean;
begin
  if (idx>=0) and (idx<Length(fptrs)) then
  begin
    lsame:=((idx>0          ) and (fptrs[idx]=fptrs[idx-1])) or
           ((idx<High(fptrs)) and (fptrs[idx]=fptrs[idx+1]));

    newlen:=StrLen(astr);
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
    curlen:=StrLen(lptr);
    dlen:=newlen-curlen;

    if dlen>0 then
    begin
      Capacity:=fcursize+dlen;

      lptr:=fbuffer+fptrs[idx]; // buffer can be changed
      move(lptr^,(lptr+dlen)^,fcursize-fptrs[idx]);
      inc(fcursize,dlen);
    end

    else if dlen<0 then
    begin
      if newlen=0 then dec(dlen); // final #0
      inc(fcursize,dlen);
      move((lptr-dlen)^,lptr^,fcursize-fptrs[idx]);
    end;

    for i:=(idx+1) to (fcount-1) do
      if fptrs[i]<>0 then
        fptrs[i]:=fptrs[i]+dlen;

    if (astr<>nil) and (astr^<>#0) then
      move(astr^,lptr^,newlen+1)
    else
      fptrs[idx]:=0;
  end;
end;

{class} function tTextCache.Append(astr:PAnsiChar):integer;
var
  lp:PAnsiChar;
  len:integer;
begin
  if fcount>=High(fptrs) then
  begin
    if Length(fptrs)=0 then
      SetLength(fptrs,start_arr)
    else
      SetLength(fptrs,Length(fptrs)+delta_arr);
  end;

  if (astr<>nil) and (astr^<>#0) then
  begin
    len:=StrLen(astr)+1;
    lp:=fbuffer+fptrs[fcount-1];
    if (fcount>0) and
{$IFDEF FPC}
       (CompareChar0(astr,lp,len)=0)
{$ELSE}
       (StrCmp(astr,lp,len)=0)
{$ENDIF}
    then
    begin
      fptrs[fcount]:=fptrs[fcount-1];
    end
    else
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

{class} procedure tTextCache.Init;
begin
  SetLength(fptrs,start_arr);
  fcount:=0;

  SetCapacity(start_buf);
end;

{class} procedure tTextCache.Clear;
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
