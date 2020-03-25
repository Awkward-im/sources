unit utils;

interface

function SaveTemporary(ptr:pointer;size:dword;ext:PAnsiChar=nil):PAnsiChar;

implementation

uses
  sysutils,
  common;

function SaveTemporary(ptr:pointer;size:dword;ext:PAnsiChar=nil):PAnsiChar;
var
  dir:AnsiString;
  buf:array [0..MAX_PATH-1] of AnsiChar;
  f:file of byte;
begin
  dir:=GetTempDir();
  GetTempFileName(pointer(dir),'wat',GetTickCount64,@buf);
  ChangeExt(buf,ext);

  AssignFile(f,@buf);
  ReWrite(f);
  BlockWrite(f,PByte(ptr)^,size);
  CloseFile(f);

  StrDup(result,buf);
end;

end.
