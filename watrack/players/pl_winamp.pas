{Winamp-like - base class}
unit pl_WinAmp;
{$include compilers.inc}

interface

implementation

uses
  windows,messages,
  syswin,
  winampapi,
  common,
  srv_player,
  srv_getinfo,
  wat_api;

{
#define IPC_GETPLAYLISTTITLE 212
/* (requires Winamp 2.04+, only usable from plug-ins (not external apps))
** char *name=SendMessage(hwnd_winamp,WM_WA_IPC,index,IPC_GETPLAYLISTTITLE);
**
** IPC_GETPLAYLISTTITLE gets the title of the playlist entry [index].
** returns a pointer to it. returns NULL on error.
*/
}
// class = BaseWindow_RootWnd
// title = Main Window

// ---------- check player ------------

function Check(wnd:HWND; aflags:cardinal):HWND;
var
  tmp,EXEName:PAnsiChar;
begin
  result:=FindWindowEx(0,wnd,WinampClass,NIL);
  if result<>0 then
  begin
    tmp:=Extract(GetEXEByWnd(result,EXEName),true);
    if lstrcmpia(tmp,'WINAMP.EXE')<>0 then
      result:=0;
    mFreeMem(tmp);
    mFreeMem(EXEName);
  end;
end;

function WAnyCheck(wnd:HWND; aflags:cardinal):HWND;
begin
  result:=FindWindowEx(0,wnd,WinampClass,NIL);
end;

// ----------- Get info ------------

function GetWidth(wnd:HWND):integer;
begin
  result:=WORD(SendMessage(wnd,WM_WA_IPC,3,IPC_GETINFO));
end;

function GetHeight(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,3,IPC_GETINFO) shr 16;
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
var
  wnd:HWND;
  pcw:PWideChar;
begin
  result:=WAT_RES_OK;

  wnd:=WATGet(Info,siWindow);
  WATSet(Info,siWinamp, wnd);
  WinampGetInfo(Info,aflags);
  if (aflags and WAT_OPT_CHANGES)<>0 then
  begin
    pcw:=WinampGetWindowText(wnd);
    WATSetStr(Info,siCaption,pcw,CP_UTF16);
    mFreeMem(pcw);
  end
  else
  begin
{
    if ((word(plyver) shr 12)>=5) and 
       (SendMessage(wnd,WM_WA_IPC,0,IPC_IS_PLAYING_VIDEO)>1) then
    begin
      if WATIsEmpty(Info,siWidth ) then WATSet(Info,siWidth , GetWidth (wnd));
      if WATIsEmpty(Info,siHeight) then WATSet(Info,siHeight, GetHeight(wnd));
    end;
}
  end;
end;

// ------- In-process code -------

procedure GetFileName(Info:UIntPtr; aflags:cardinal);
var
  buf:array [0..1023] of AnsiChar;
  fpos,fname:IntPtr;
  wnd:HWND;
  op:THANDLE;
  tmp:UIntPtr;
  pid:dword;
begin
  if (aflags and WAT_OPT_IMPLANTANT)<>0 then
  begin
    wnd:=WATGet(Info,siWinamp);
    if SendMessage(wnd,WM_WA_IPC,0,IPC_ISPLAYING)<>WAT_PLS_STOPPED then
    begin
      fpos :=SendMessage(wnd,WM_USER,0   ,IPC_GETLISTPOS);
      fname:=SendMessage(wnd,WM_USER,fpos,IPC_GETPLAYLISTFILE);
      GetWindowThreadProcessId(wnd,@pid);
      op:=OpenProcess(PROCESS_VM_READ,false,pid);
      if op<>0 then
      begin
        ReadProcessMemory(op,PByte(fname),@buf,SizeOf(buf),tmp);
        CloseHandle(op);
        if tmp<>0 then
          WATSetStr(Info,siFile,@buf,CP_ACP);
      end;
    end;
  end;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:nil;
    GetName  :@GetFileName;
    GetInfo  :@GetInfo;
    Command  :nil;
    Desc     :'Winamp';
    URL      :'http://www.winamp.com/';
    Notes    :'';
    Group    :0;
    flags    :WAT_OPT_ONLYONE or WAT_OPT_WINAMPAPI or WAT_OPT_HASURL;
  );

const
  plRecClone:tPlayerCell=(
    Check    :@WAnyCheck;
    Init     :nil;
    GetStatus:nil;
    GetName  :nil;
    GetInfo  :@WinampGetInfo;
    Command  :nil;
    Desc     :'Winamp Clone';
    URL      :'';
    Notes    :'All "unknown" players using Winamp API';
    Group    :0;
    flags    :WAT_OPT_ONLYONE or WAT_OPT_WINAMPAPI or WAT_OPT_LAST;
  );

var
  LocalPlayerLink,
  LocalPlayerLinkC:twPlayer;

procedure InitLink;
begin
  LocalPlayerLink.Next:=PlayerLink;
  LocalPlayerLink.This:=@plRec;
  PlayerLink          :=@LocalPlayerLink;

  LocalPlayerLinkC.Next:=PlayerLink;
  LocalPlayerLinkC.This:=@plRecClone;
  PlayerLink           :=@LocalPlayerLinkC;
end;

initialization
  InitLink;
end.
