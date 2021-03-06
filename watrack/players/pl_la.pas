{LightAlloy player}
unit pl_la;
{$include compilers.inc}

interface

implementation

uses
  windows,messages,
  common,
  srv_player,
  wat_api;

const
  LAClass = 'LightAlloyFront';
const
  WM_LACMD    = WM_APP + 2504;
  LAC_VERSION = 000;

  LAC_FILE_OPEN          = 050;
  LAC_PLAYBACK_STOP      = 100;
  LAC_PLAYBACK_PLAY      = 101;
  LAC_PLAYBACK_STOP_PLAY = 102;
  LAC_PLAYLIST_NEXT      = 250;
  LAC_PLAYLIST_PREV      = 251;
  LAC_PLAYLIST_PLAY      = 252;
  LAC_SOUND_VOLUME_INC   = 401;
  LAC_SOUND_VOLUME_DEC   = 402;

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow(LAClass,NIL);
end;

function GetVersion(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_VERSION,0)
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
begin
  result:=0;
  if (aflags and WAT_OPT_PLAYERDATA)<>0 then
  begin
    if WATIsEmpty(Info,siVersion) then
    begin
      WATSet(Info,siVersion, GetVersion(WATGet(Info,siWindow)));
    end;
  end;
end;

function Play(wnd:HWND; fname:PWideChar=nil):integer;
var
  cds:COPYDATASTRUCT;
begin
  if (fname<>nil) and (fname^<>#0) then
  begin
    cds.dwData:=LAC_FILE_OPEN;
    WideToAnsi(fname,PAnsiChar(cds.lpData));
    cds.cbData:=StrLen(PAnsiChar(cds.lpData))+1;
    SendMessage(wnd,WM_COPYDATA,0,lparam(@cds));
    mFreeMem(cds.lpData);
  end;
  result:=SendMessage(wnd,WM_LACMD,LAC_PLAYLIST_PLAY,0) // LAC_PLAYLIST_PLAY
end;

function Pause(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_PLAYBACK_STOP_PLAY,0)
end;

function Stop(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_PLAYBACK_STOP,0)
end;

function Next(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_PLAYLIST_NEXT,0)
end;

function Prev(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_PLAYLIST_PREV,0)
end;

function VolDn(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_SOUND_VOLUME_DEC,0);
end;

function VolUp(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_LACMD,LAC_SOUND_VOLUME_INC,0);
end;

function Command(wnd:HWND; cmd:integer; value:IntPtr):IntPtr;
begin
  case cmd of
    WAT_CTRL_PREV : result:=Prev (wnd);
    WAT_CTRL_PLAY : result:=Play (wnd,pWideChar(value));
    WAT_CTRL_PAUSE: result:=Pause(wnd);
    WAT_CTRL_STOP : result:=Stop (wnd);
    WAT_CTRL_NEXT : result:=Next (wnd);
    WAT_CTRL_VOLDN: result:=VolDn(wnd);
    WAT_CTRL_VOLUP: result:=VolUp(wnd);
  else
    result:=0;
  end;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:nil;
    GetName  :nil;
    GetInfo  :@GetInfo;
    Command  :@Command;
    Desc     :'LightAlloy';
    URL      :'http://www.softella.com/';
    Notes    :'';
    Group    :0;
    flags    :WAT_OPT_HASURL;
  );

var
  LocalPlayerLink:twPlayer;

procedure InitLink;
begin
  LocalPlayerLink.Next:=PlayerLink;
  LocalPlayerLink.This:=@plRec;
  PlayerLink          :=@LocalPlayerLink;
end;

initialization
  InitLink;
end.
