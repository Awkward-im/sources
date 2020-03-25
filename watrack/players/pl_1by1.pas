{1by1 player}
unit pl_1by1;
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
  ObOClass = '1by1WndClass';

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow(ObOClass,NIL);
end;

{
  need to set 'Elapsed time in title bar'
          and 'Show : instead of ' as minute char'
}
function GetElapsedTime(wnd:HWND):integer;
var
  s,p:PAnsiChar;
begin
  result:=0;
  s:=GetDlgText(wnd,true);
  if s<>nil then
  begin
    if (s^>='0') and (s^<='9') then
    begin
      p:=StrScan(s,' ');
      if p<>nil then
        p^:=#0;
      result:=TimeToInt(s)
    end;
    mFreeMem(s);
  end;
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
begin
  result:=0;
  if (aflags and WAT_OPT_CHANGES)<>0 then
    WATSet(Info,siPosition, GetElapsedTime(WATGet(Info,siWindow)));
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:nil;
    GetName  :nil;
    GetInfo  :@GetInfo;
    Command  :nil;
    Desc     :'1by1';
    URL      :'http://www.mpesch3.de/';
    Notes    :'To get elapsed time, needs to set "Elapsed time in title bar" and '#13#10+
              '"Show : instead of '#39' as minute char" in player settings "Display" tab.';
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
