{MediaMonkey player}
unit pl_mmonkey;
{$include compilers.inc}

interface

implementation

uses
  windows,messages,
  mComObj,
  winampapi,
  common,
  srv_player,
  srv_getinfo,
  wat_api;

const
  COMName:PWideChar = 'SongsDB.SDBApplication';

const
  WM_WA_IPC      = WM_USER;
  IPC_GETVERSION = 0;

{
const
  MMonkeyName = 'MediaMonkey';
}
function Check(wnd:HWND; aflags:cardinal):HWND;
//var
//  i:integer;
{
  EXEName:pWideChar;
  tmp:pWideChar;
}
//  v:Variant;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow('TFMainWindow','MediaMonkey');
  if result=0 then
    result:=FindWindow('TFMainWindow.UnicodeClass','MediaMonkey');
{
  wnd:=FindWindow(WinAmpClass,NIL);
  if wnd<>0 then
  begin
    if (SendMessage(wnd,WM_WA_IPC,0,IPC_GETVERSION) and $FF0F)<>$990B then
      wnd:=result;
  end;
}
{
  wnd:=FindWindow(WinAmpClass,NIL);
  if wnd<>0 then
  begin
    i:=SendMessage(wnd,WM_WA_IPC,0,IPC_GETVERSION) and $FF0F;
    if i=$990B then
    begin

      try
//        v:=GetActiveOleObject(COMName);
        v:=CreateOleObject(COMName);
        if not v.IsRunning then
          wnd:=0;
      except
      end;
      v:=varNull;

    end
    else
      wnd:=0;
  end;
  result:=wnd;
}
{
  begin
    EXEName:=GetEXEByWnd(wnd);
    tmp:=Extract(EXEName,true);
    mFreeMem(EXEName);
    result:=StrCmpW(tmp,MMonkeyName,length(MMonkeyName))=0;
    mFreeMem(tmp);
  end;
}
end;

function GetVersion(const v:variant):integer;
begin
  try
    result:=(v.VersionHi shl 8)+(v.VersionLo shl 4)+v.VersionRelease;
  except
    result:=0;
  end;
end;

procedure GetVersionText(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siTextVersion, pointer(WideString(v.VersionString)), CP_UTF16);
  except
  end;
end;

procedure GetFileName(Info:UIntPtr; aflags:cardinal);
var
  v:Variant;
begin
  try
//    SDB:=GetActiveOleObject(COMName);
    v:=CreateOleObject(COMName);
    WATSetStr(Info,siFile, pointer(AnsiString(WideString(v.Player.CurrentSong.Path))), CP_ACP);
  except
  end;
  v:=varNull;
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
var
  v:variant;
begin
  if (aflags and WAT_OPT_PLAYERDATA)<>0 then
  begin
    if WATIsEmpty(Info,siVersion) then
    begin
      try
        v:=CreateOleObject(COMName);
        WATSet(Info,siVersion, GetVersion(v));
        GetVersionText(Info, v);
      except
      end;
      v:=varNull;
    end;
  end;
  WinampGetInfo(Info,aflags);

  result:=WAT_RES_OK;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:nil;
    GetName  :@GetFileName;
    GetInfo  :@GetInfo;
    Command  :nil;
    Desc     :'MediaMonkey';
    URL      :'http://www.mediamonkey.com/';
    Notes    :'';
    Group    :0;
    flags    :WAT_OPT_SINGLEINST or WAT_OPT_HASURL or WAT_OPT_WINAMPAPI;
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
