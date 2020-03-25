{BeholderTV}
unit pl_behold;
{$include compilers.inc}

interface

implementation

uses windows,messages,common,wrapper,srv_player,wat_api;

const
  WM_BHCMD            = WM_USER+200;
  WMBH_CHNLUP         = WM_USER+203; // ����������� �� ��������� �����
  WMBH_CHNLDOWN       = WM_USER+204; // ����������� �� ���������� �����
  WMBH_VOLUMEUP       = WM_USER+210; // ��������� ��������� �������
  WMBH_VOLUMEDOWN     = WM_USER+211; // ��������� ��������� �������
  WMBH_FREEZE         = WM_USER+232; // ������� ����-�����
  WMBH_SETVOLUME      = WM_USER+280; // ���������� ������� ��������� (LParam = 0..65535)
  WMBH_GETVOLUME      = WM_USER+281; // �������� ������� ������� ��������� (������������ SendMessage, Result = 0..65535)
  WMBH_GETVERSION     = WM_USER+285; // �������� ����� ������ �� (������������ SendMessage)

const
  TitleWndClass = 'TApplication';
  EXEName       = 'BEHOLDTV.EXE';

var
  TitleWnd:HWND;

function enumproc(wnd:HWND; alParam:LPARAM):bool; stdcall;
var
  buf:array [0..64] of AnsiChar;
begin
  result:=true;
  if GetClassNameA(wnd,@buf,63)<>0 then
  begin
    if StrCmp(buf,TitleWndClass)=0 then
    begin
      TitleWnd:=wnd;
      result:=false;
    end
  end;
end;

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow('TMain','BeholdTV');
  if result<>0 then
    EnumThreadWindows(GetWindowThreadProcessId(result,nil),@enumproc,0);
end;

function GetVersion(wnd:HWND):integer;
begin
  result:=dword(SendMessage(wnd,WM_BHCMD,WMBH_GETVERSION,0));
  result:=((result shr 16) shl 8)+LoWord(result);
end;

function GetVersionText(ver:integer):PWideChar; //!!
begin
  mGetMem(result,10*SizeOf(WideChar));
  IntToStr(result+1,ver);
  result[0]:=result[1];
  result[1]:='.';
end;

function Pause(wnd:HWND):integer;
begin
  result:=0;
  PostMessage(wnd,WM_BHCMD,WMBH_FREEZE,0);
end;

function Next(wnd:HWND):integer;
begin
  result:=0;
  PostMessage(wnd,WM_BHCMD,WMBH_CHNLUP,0);
end;

function Prev(wnd:HWND):integer;
begin
  result:=0;
  PostMessage(wnd,WM_BHCMD,WMBH_CHNLDOWN,0);
end;

function GetVolume(wnd:HWND):cardinal;
begin
  result:=word(SendMessage(wnd,WM_BHCMD,WMBH_GETVOLUME,0));
  result:=(result shl 16)+(result shr 12);
end;

procedure SetVolume(wnd:HWND; value:cardinal);
begin
  SendMessage(wnd,WM_BHCMD,WMBH_SETVOLUME,value shl 12);
end;

function VolDn(wnd:HWND):integer;
begin
  result:=word(SendMessage(wnd,WM_BHCMD,WMBH_VOLUMEDOWN,0));
end;

function VolUp(wnd:HWND):integer;
begin
  result:=word(SendMessage(wnd,WM_BHCMD,WMBH_VOLUMEUP,0));
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
begin
  result:=0;
  if (aflags and WAT_OPT_PLAYERDATA)<>0 then
  begin
    if SongInfo.plyver=0 then
    begin
      SongInfo.plyver:=GetVersion    (SongInfo.plwnd);
      SongInfo.txtver:=GetVersionText(SongInfo.plyver);
    end;
    exit;
  end;

  if (aflags and WAT_OPT_CHANGES)<>0 then
    SongInfo.wndtext:=GetDlgText(TitleWnd);
end;

function Command(wnd:HWND; cmd:integer; value:IntPtr):IntPtr;
begin
  case cmd of
    WAT_CTRL_PREV : result:=Prev(wnd);
//    WAT_CTRL_PLAY : result:=Play(wnd,pWideChar(value));
    WAT_CTRL_PAUSE: result:=Pause(wnd);
//    WAT_CTRL_STOP : result:=Stop(wnd);
    WAT_CTRL_NEXT : result:=Next(wnd);
    WAT_CTRL_VOLDN: result:=VolDn(wnd);
    WAT_CTRL_VOLUP: result:=VolUp(wnd);
//    WAT_CTRL_SEEK : result:=Seek(wnd,value);
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
    Desc     :'BeholdTV';
    URL      :'';
    Notes    :'Still experimental, no tested. Can work not properly';
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
