{Media Player Classic}
unit pl_MPC;
{$include compilers.inc}

interface

implementation

uses
  windows,
  wrapper,
  common,
  srv_player,
  wat_api;

const
  MPCClass98 = 'MediaPlayerClassicA';
  MPCClassXP = 'MediaPlayerClassicW';
  MPCTail    = ' - Media Player Classic';

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  result:=FindWindowEx(0,wnd,MPCClassXP,NIL);
  if result=0 then
    result:=FindWindowEx(0,wnd,MPCClass98,NIL);
end;

function chwnd(awnd:HWND; param:LPARAM):longbool; stdcall;
var
  s:array [0..31] of AnsiChar;
  i:integer;
begin
  FillChar(s,SizeOf(s),0);
  GetWindowTextA(awnd,s,30);
  i:=StrIndex(PAnsiChar(@s),' / ');
  if i<>0 then
  begin
    if PDword(param)^=0 then
    begin
      s[i-1]:=#0;
      pdword(param)^:=TimeToInt(s);
    end
    else
    begin
      pdword(param)^:=TimeToInt(s+i+2);
    end;
    result:=false;
  end
  else
    result:=true;
end;

function GetElapsedTime(wnd:HWND):integer;
begin
  result:=0;
  if EnumChildWindows(wnd,@chwnd,int_ptr(@result)) then
    result:=0;
end;

function GetTotalTime(wnd:HWND):integer;
begin
  result:=1;
  if EnumChildWindows(wnd,@chwnd,int_ptr(@result)) then
    result:=0;
end;

procedure GetWndText(Info:UIntPtr);
var
  p,pc:pWideChar;
begin
  pc:=GetDlgText(WATGet(Info,siWindow));
  if pc<>nil then
  begin
    p:=StrPosW(pc,MPCTail);
    if p<>nil then
      p^:=#0;
    WATSetStr(Info,siCaption, pc, CP_UTF16);
    mFreeMem(pc);
  end;
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
var
  wnd:HWND;
begin
  result:=WAT_RES_OK;

  wnd:=WATGet(Info,siWindow);
  if (aflags and WAT_OPT_CHANGES)<>0 then
  begin
    WATSet(Info,siPosition, GetElapsedTime(wnd));
    GetWndText(Info);
  end
  else if WATIsEmpty(Info,siLength) then
    WATSet(Info,siLength, GetTotalTime(wnd));
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:nil;
    GetName  :nil;
    GetInfo  :@GetInfo;
    Command  :nil;
    Desc     :'MPC';
    URL      :'http://gabest.org/';
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
