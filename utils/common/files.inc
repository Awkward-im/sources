{
  Files and directories
}

{$IFDEF Interface}

function ChangeExt (src,ext:PAnsiChar):PAnsiChar;
function ChangeExtW(src,ext:PWideChar):PWideChar;

function Extract (s:PAnsiChar; name:Boolean=true):PAnsiChar;
function ExtractW(s:PWideChar; name:Boolean=true):PWideChar;

function GetExt(fname,dst:PWideChar; maxlen:cardinal=100):PWideChar; overload;
function GetExt(fname,dst:PAnsiChar; maxlen:cardinal=100):PAnsiChar; overload;

function isPathAbsolute(path:PWideChar):boolean; overload;
function isPathAbsolute(path:PAnsiChar):boolean; overload;

function FileSize(const aname:AnsiString):cardinal; overload;
procedure Skip(var f:file; count:integer);

{$ELSE}

function ChangeExt(src,ext:PAnsiChar):PAnsiChar;
var
  i,j:integer;
begin
  i:=StrLen(src);
  j:=i;
  while (i>0) and (src[i]<>'\') and (src[i]<>':') and (src[i]<>'.') do dec(i);
  if src[i]<>'.' then
  begin
    i:=j;
    src[i]:='.';
  end;
  if ext=nil then
    ext:='';
  StrCopy(src+i+1,ext);
  result:=src;
end;

function ChangeExtW(src,ext:PWideChar):PWideChar;
var
  i,j:integer;
begin
  i:=StrLenW(src);
  j:=i;
  while (i>0) and (src[i]<>'\') and (src[i]<>':') and (src[i]<>'.') do dec(i);
  if src[i]<>'.' then
  begin
    i:=j;
    src[i]:='.';
  end;
  if ext=nil then
    ext:='';
  StrCopyW(src+i+1,ext);
  result:=src;
end;

function Extract(s:PAnsiChar; name:Boolean=true):PAnsiChar;
var
  i:integer;
begin
  i:=StrLen(s)-1;
//  j:=i;
  while (i>=0) and ((s[i]<>'\') and (s[i]<>'/')) do dec(i);
  if name then
  begin
    StrDup(result,s+i+1);
//    mGetMem(result,(j-i+1));
//    StrCopy(result,s+i+1);
  end
  else
  begin
    StrDup(result,s,i+1);
  end;
end;

function ExtractW(s:PWideChar; name:Boolean=true):PWideChar;
var
  i:integer;
begin
  i:=StrLenW(s)-1;
//  j:=i;
  while (i>=0) and ((s[i]<>'\') and (s[i]<>'/')) do dec(i);
  if name then
  begin
    StrDupW(result,s+i+1);
//    mGetMem(result,(j-i+1)*SizeOf(WideChar));
//    StrCopyW(result,s+i+1);
  end
  else
  begin
    StrDupW(result,s,i+1);
  end;
end;

function GetExt(fname,dst:PWideChar; maxlen:cardinal=100):PWideChar;
var
  ppc,pc:PWideChar;
begin
  result:=dst;
  dst^:=#0;
  if (fname<>nil) and (fname^<>#0) then
  begin
    pc:=StrEndW(fname)-1;
    while (pc>fname) and ((pc^='"') or (pc^=' ')) do dec(pc);
    ppc:=pc+1;
    while (pc>fname) and (pc^<>'.') do
    begin
      if maxlen=0 then exit;
      if not (AnsiChar(pc^) in ['0'..'9','A'..'Z','_','a'..'z']) then exit;
      dec(maxlen);
      dec(pc); //empty name not allowed!
    end;
    if pc>fname then
    begin
      repeat
        inc(pc);
        if pc=ppc then
        begin
          dst^:=#0;
          break;
        end;
        if (pc^>='a') and (pc^<='z') then
          dst^:=WideChar(ord(pc^)-$20)
        else
          dst^:=pc^;
        inc(dst);
      until false;
    end;
  end;
end;

function GetExt(fname,dst:PAnsiChar; maxlen:cardinal=100):PAnsiChar;
var
  ppc,pc:PAnsiChar;
begin
  result:=dst;
  dst^:=#0;
  if (fname<>nil) and (fname^<>#0) then
  begin
    pc:=StrEnd(fname)-1;
    while (pc>fname) and ((pc^='"') or (pc^=' ')) do dec(pc);
    ppc:=pc+1;
    while (pc>fname) and (pc^<>'.') do
    begin
      if maxlen=0 then exit;
      if not (AnsiChar(pc^) in ['0'..'9','A'..'Z','_','a'..'z']) then exit;
      dec(maxlen);
      dec(pc); //empty name not allowed!
    end;
    if pc>fname then
    begin
      repeat
        inc(pc);
        if pc=ppc then
        begin
          dst^:=#0;
          break;
        end;
        if (pc^>='a') and (pc^<='z') then
          dst^:=AnsiChar(ord(pc^)-$20)
        else
          dst^:=pc^;
        inc(dst);
      until false;
    end;
  end;
end;

function isPathAbsolute(path:PWideChar):boolean;
begin
  result:=((path[1]=':') and (path[2]='\')) or ((path[0]='\') {and (path[1]='\')}) or
          (StrPosW(path,'://')<>nil);
end;

function isPathAbsolute(path:PAnsiChar):boolean;
begin
  result:=((path[1]=':') and (path[2]='\')) or ((path[0]='\') {and (path[1]='\')}) or
          (StrPos(path,'://')<>nil);
end;

function FileSize(const aname:AnsiString):cardinal;
var
  f:File of byte;
begin
  result:=0;
  AssignFile(f,aname);
  {$IFOPT I-}
  Reset(f);
  if IOResult()=0 then
  begin
    result:=system.FileSize(f);
  {$ELSE}
  try
    Reset(f);
    result:=system.FileSize(f);
  except
  {$ENDIF}
  end;
  CloseFile(f);
end;

procedure Skip(var f:file; count:integer);
begin
  system.Seek(f,system.FilePos(f)+count);
end;

{$ENDIF}
