{Last.fm Player}
unit pl_LastFM;

interface

implementation

uses
  windows,messages,
  syswin,
  common,
  srv_player,
  wat_api;


const
  LFMName  = 'Last.fm Player';
  LFMText  = 'Last.fm';
  LFMClass = 'QWidget';

const
  UserName:pWideChar=nil;

function Check(wnd:HWND; aflags:cardinal):HWND;
var
  tmp,EXEName:PAnsiChar;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow(LFMClass,nil{LFMName});
  if result<>0 then
  begin
    tmp:=Extract(GetEXEByWnd(result,EXEName),true);
    if lstrcmpia(tmp,'LASTFM.EXE')<>0 then
      result:=0;
    mFreeMem(tmp);
    mFreeMem(EXEName);
    if result<>0 then
      result:=GetWindow(result,GW_OWNER);
  end;
  if result=0 then
    mFreeMem(UserName);
end;

function GetWndText(wnd:HWND):pWideChar;
var
  ps:array [0..255] of WideChar;
  p:pWideChar;
begin
  SendMessageW(wnd,WM_GETTEXT,255,lparam(@ps));
  p:=StrPosW(ps,' | ');
  if p<>nil then
  begin
    mFreeMem(UserName);
    StrDupW(UserName,p+3);
    p^:=#0;
  end;
  StrDupW(result,ps);
end;

procedure GetFileName(wnd:HWND; aflags:cardinal; aname:PAnsiChar);
var
  buf:array [0..1023] of WideChar;
  p:pWideChar;
begin
  aname^:=#0;
//  lstrcpyw(buf,'http://');
buf[0]:=#0;
  p:=GetWndText(wnd);
  StrCatW(buf,p);
  StrCatW(buf,'.mp3');
  StrDupW(result,buf);
  mFreeMem(p);
end;

function GetStatus(wnd:HWND):integer;
var
  txt:pWideChar;
begin
  txt:=GetWndText(wnd);
  if StrCmpW(txt,LFMText,Length(LFMText))<>0 then
    result:=WAT_PLS_PLAYING
  else
    result:=WAT_PLS_STOPPED;
  mFreeMem(txt);
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
begin
  result:=0;
  with SongInfo do
  begin
    fsize:=1;
    if (aflags and WAT_OPT_CHANGES)<>0 then
    begin
      wndtext:=GetWndText(plwnd);
    end
    else
    begin
    end;
  end;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:@GetStatus;
    GetName  :@GetFileName;
    GetInfo  :@GetInfo;
    Command  :nil;
    Desc     :'Last.fm';
    URL      :'http://www.lastfm.com/';
    Notes    :'Works by window title analysing only';
    Group    :0;
    flags    :WAT_OPT_LAST or WAT_OPT_SINGLEINST or WAT_OPT_HASURL;
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
