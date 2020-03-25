unit clipboard;

interface

uses windows;

procedure CopyToClipboard(txt:pointer; Ansi:bool);
function PasteFromClipboard(Ansi:boolean;cp:dword=CP_ACP):pointer;


implementation

uses common;

procedure CopyToClipboard(txt:pointer; Ansi:bool);
var
  s:pointer;
  fh:THANDLE;
begin
  if pointer(txt)=nil then
    exit;
  if Ansi then 
  begin
    if PAnsiChar(txt)^=#0 then exit
  end
  else
    if PWideChar(txt)^=#0 then exit;

  if OpenClipboard(0) then
  begin
    if Ansi then
    begin
      fh:=GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE,(StrLen(PAnsiChar(txt))+1));
      s:=GlobalLock(fh);
      StrCopy(s,PAnsiChar(txt));
    end
    else
    begin
      fh:=GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE,
          (StrLenW(PWideChar(txt))+1)*SizeOf(WideChar));
      s:=GlobalLock(fh);
      StrCopyW(s,PWideChar(txt));
    end;
    GlobalUnlock(fh);
    EmptyClipboard;
    if Ansi then
      SetClipboardData(CF_TEXT,fh)
    else
      SetClipboardData(CF_UNICODETEXT,fh);
    CloseClipboard;
  end;
end;

function PasteFromClipboard(Ansi:boolean;cp:dword=CP_ACP):pointer;
var
  p:PWideChar;
  fh:THANDLE;
begin
  result:=nil;
  if OpenClipboard(0) then
  begin
    if not Ansi then
    begin
      fh:=GetClipboardData(CF_UNICODETEXT);
      if fh<>0 then
      begin
        p:=GlobalLock(fh);
        StrDupW(PWideChar(result),p);
      end
      else
      begin
        fh:=GetClipboardData(CF_TEXT);
        if fh<>0 then
        begin
          p:=GlobalLock(fh);
          AnsiToWide(PAnsiChar(p),PWideChar(result),cp);
        end;
      end;
    end
    else
    begin
      fh:=GetClipboardData(CF_TEXT);
      if fh<>0 then
      begin
        p:=GlobalLock(fh);
        StrDup(PAnsiChar(result),PAnsiChar(p));
      end;
    end;
    if fh<>0 then
      GlobalUnlock(fh);
    CloseClipboard;
  end
end;

end.
