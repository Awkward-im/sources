uses windows;

function GetTitle(wnd:HWND; lParam:IntPtr):bool; stdcall;
var
  lsize:integer;
begin
  result:=true;
  if IsWindowVisible(wnd) then
  begin
    lsize:=GetWindowTextLength(wnd);
    if lsize>0 then
    begin
      inc(lsize);
      GetMem(PWideChar(lParam),lsize*SizeOf(WideChar));
      GetWindowTextW(wnd,pointer(lParam),lsize);
    end;
  end;
end;

procedure WinListEnum;
var
  lParam:IntPtr;
begin
  lParam:=0;
  EnumWindows(@GetTitle,lParam);
end;

procedure WinListCycle;
var
  lwnd:HWND;
  lbuf:array [0..299] of WideChar;
begin
  lwnd:=0;
  repeat
    lwnd:=FindWindowExW(0,lwnd,nil,nil);
    if lwnd=0 then
      break;
    if IsWindowVisible(lwnd) then
      if GetWindowTextW(lwnd,@lbuf,300)>0 then
      begin
//        cbWindowList.AddItem(lbuf,TObject(lwnd));
      end;
  until false;
end;

begin
end.
