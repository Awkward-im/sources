{Winamp-like - base class}
unit winampapi;
{$include compilers.inc}

interface

uses
  windows,messages
  ,wat_api; // WAT_CTRL_* consts for WinampCommand

const
  WinampClass = 'Winamp v1.x';
  WinampTail  = ' - Winamp';

function WinampGetStatus(wnd:HWND):integer;
function WinampGetWindowText(wnd:HWND):pWideChar;
function WinampFindWindow(wnd:HWND):HWND;
function WinampCommand(wnd:HWND;alParam:LPARAM):int_ptr;

function GetVersion    (wnd:HWND):cardinal;
function GetVersionText(wnd:HWND; dst:PAnsiChar):PAnsiChar;
function GetElapsedTime(wnd:HWND):integer;
function GetVolume     (wnd:HWND):integer;

function GetBitrate   (wnd:HWND):integer;
function GetSamplerate(wnd:HWND):integer;
function GetChannels  (wnd:HWND):integer;
function GetTotalTime (wnd:HWND):integer;
function GetVideoSize (wnd:HWND):integer;
function GetWidth     (wnd:HWND):integer;
function GetHeigh     (wnd:HWND):integer;

const
  WM_WA_IPC = WM_USER;
  IPC_GETVERSION       = 0;
  IPC_PLAYFILE         = 100;
  IOC_DELETE           = 101; // Clear playlist
  IPC_STARTPLAY        = 102;
  IPC_ISPLAYING        = 104;
  IPC_GETOUTPUTTIME    = 105;
  IPC_JUMPTOTIME       = 106;
  IPC_WRITEPLAYLIST    = 120;
  IPC_SETPLAYLISTPOS   = 121;
  IPC_SETVOLUME        = 122; // -666 returns the current volume.
  IPC_GETLISTLENGTH    = 124;
  IPC_GETLISTPOS       = 125;
  IPC_GETINFO          = 126; // 0 - samplerate; 1 - bitreate; 2 - channels
  IPC_GETPLAYLISTFILE  = 211;
  IPC_GETPLAYLISTTITLE = 212;
  IPC_INETAVAILABLE    = 242; //!!
  IPC_GET_SHUFFLE      = 250;
  IPC_GET_REPEAT       = 251;
  IPC_SET_SHUFFLE      = 252;
  IPC_SET_REPEAT       = 253;
  IPC_ISFULLSTOP       = 400; //!!

  IPC_IS_PLAYING_VIDEO = 501;

const
  WINAMP_PREV       = 40044;
  WINAMP_PLAY       = 40045;
  WINAMP_PAUSE      = 40046;
  WINAMP_STOP       = 40047;
  WINAMP_NEXT       = 40048;
  WINAMP_VOLUMEUP   = 40058; // turns the volume up a little
  WINAMP_VOLUMEDOWN = 40059; // turns the volume down a little


implementation

uses
  common;

function WinampFindWindow(wnd:HWND):HWND;
var
  pr,pr1:dword;
begin
  GetWindowThreadProcessId(wnd,@pr);
  result:=0;
  repeat
    result:=FindWindowEx(0,result,WinampClass,nil);
    if result<>0 then
    begin
      GetWindowThreadProcessId(result,@pr1);
      if pr=pr1 then
        break;
    end
    else
      break;
  until false;
end;

// ----------- Get player info ------------

function WinampGetStatus(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,0,IPC_ISPLAYING);
  // 0 - stopped, 1 - playing
  case result of
    0: result:=WAT_PLS_STOPPED;
    1: result:=WAT_PLS_PLAYING;
  else
    if result>1 then
      result:=WAT_PLS_PAUSED;
  end;
{
  if result=0 then // !! only for remote media!
  begin
    result:=SendMessage(wnd,WM_WA_IPC,0,IPC_ISFULLSTOP);
    if result<>0 then
      result:=WAT_PLS_STOPPED
    else
      result:=WAT_PLS_PLAYING;
  end;
}
end;

function WinampGetWindowText(wnd:HWND):pWideChar;
var
  a:cardinal;
  pc:pWideChar;
begin
  a:=GetWindowTextLengthW(wnd);
  mGetMem(result,(a+1)*SizeOf(WideChar));
  if GetWindowTextW(wnd,result,a+1)>0 then
  begin
    pc:=StrPosW(result,WinampTail);
    if pc<>nil then
    begin
      pc^:=#0;
      pc:=StrPosW(result,'. ');
      if pc<>nil then
        StrCopyW(result,pc+2);
    end;
  end;
end;

function GetVersion(wnd:HWND):cardinal;
begin
  result:=SendMessage(wnd,WM_WA_IPC,0,IPC_GETVERSION);
end;

function GetVersionText(wnd:HWND; dst:PAnsiChar):PAnsiChar;
var
  ver:integer;
  p:PAnsiChar;
begin
  result:=dst;
  ver:=GetVersion(wnd);
  p:=dst;
  IntToStr(p,ver shr 12);
  while p^<>#0 do inc(p);
  p^:='.';
  IntToStr(p+1,(ver shr 4) and $F);
  while p^<>#0 do inc(p);
  p^:='.';
  IntToStr(p+1,ver and $F);
end;

function GetElapsedTime(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,0,IPC_GETOUTPUTTIME) div 1000;
end;

function GetVolume(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,-666,IPC_SETVOLUME);
  result:=(result shl 16)+(result shr 4);
end;

// --------- Get track info ----------

function GetSamplerate(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,0,IPC_GETINFO);
  if result>1000 then
    result:=result div 1000;
end;

function GetBitrate(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,1,IPC_GETINFO);
  if result>1000 then
    result:=result div 1000;
end;

function GetChannels(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,2,IPC_GETINFO);
end;

function GetVideoSize(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,3,IPC_GETINFO);
end;

function GetWidth(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,3,IPC_GETINFO) and $FFFF;
end;

function GetHeigh(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,3,IPC_GETINFO) shr 16;
end;

function GetTotalTime(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,1,IPC_GETOUTPUTTIME);
end;

// ------- Commands ----------

function Play(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_PLAY,0);
end;

function Pause(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_PAUSE,0);
end;

function Stop(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_STOP,0);
end;

function Next(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_NEXT,0);
end;

function Prev(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_PREV,0);
end;

function VolDn(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_VOLUMEDOWN,0);
end;

function VolUp(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_COMMAND,WINAMP_VOLUMEUP,0);
end;

procedure SetVolume(wnd:HWND; value:cardinal);
begin
  SendMessage(wnd,WM_WA_IPC,value shl 4,IPC_SETVOLUME);
end;

function Seek(wnd:HWND; value:integer):integer;
begin
  result:=SendMessage(wnd,WM_WA_IPC,0,IPC_GETOUTPUTTIME) div 1000;
    SendMessage(wnd,WM_WA_IPC,value*1000,IPC_JUMPTOTIME);
end;

function WinampCommand(wnd:HWND; alParam:LPARAM):IntPtr;
begin
  case LoWord(alParam) of
    WAT_CTRL_PREV : result:=Prev (wnd);
    WAT_CTRL_PLAY : result:=Play (wnd);
    WAT_CTRL_PAUSE: result:=Pause(wnd);
    WAT_CTRL_STOP : result:=Stop (wnd);
    WAT_CTRL_NEXT : result:=Next (wnd);
    WAT_CTRL_VOLDN: result:=VolDn(wnd);
    WAT_CTRL_VOLUP: result:=VolUp(wnd);
    WAT_CTRL_SEEK : result:=Seek (wnd,alParam shr 16);
  else
    result:=0;
  end;
end;

end.
