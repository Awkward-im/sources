{iTunes player}
unit pl_iTunes;
{$include compilers.inc}

interface

implementation

uses
  windows,
  mComObj,
  common,
  srv_player,
  wat_api;

const
  iTunesClass = 'iTunes';
  iTunesTitle = 'iTunes';
  COMName = 'iTunes.Application';

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindow(iTunesClass,iTunesTitle);
end;

procedure GetFileName(Info:UIntPtr; aflags:cardinal);
var
  v:variant;
begin
  try
    v:=CreateOleObject(COMName);
    WATSetStr(Info,siFile,PWideChar(WideString(v.CurrentTrack.Location)),CP_UTF16);
  except
  end;
  v:=varNull;
end;

function SplitVersion(p:pWideChar):integer;
begin
  result:=StrToInt(p);
  while (p^>='0') and (p^<='9') do inc(p); inc(p);
  result:=result*16+StrToInt(p);
  while (p^>='0') and (p^<='9') do inc(p); inc(p);
  result:=(result*16+StrToInt(p))*16;
  while (p^>='0') and (p^<='9') do inc(p); inc(p);
  result:=result*16+StrToInt(p);
end;

function GetVersion(const ver:pWideChar):integer;
begin
  if (ver<>nil) and (ver^<>#0) then
    result:=SplitVersion(ver)
  else
    result:=0;
end;

function GetVersionText(const v:variant):PWideChar;
begin
  try
    StrDupW(result,PWideChar(WideString(v.Version)));
  except
    result:=nil;
  end;
end;

function GetTotalTime(const v:variant):integer;
begin
  try
    result:=v.CurrentTrack.Duration;
  except
    result:=0;
  end;
end;

function GetElapsedTime(const v:variant):integer;
begin
  try
    result:=v.PlayerPosition;
  except
    result:=0;
  end;
end;

function GetStatus(wnd:HWND):integer;
var
  tmp:integer;
  v:variant;
begin
  try
    v:=CreateOleObject(COMName);
    tmp:=v.PlayerState;
    if tmp=1 then
      result:=WAT_PLS_PLAYING
    else
      result:=WAT_PLS_STOPPED;
  except
    result:=WAT_PLS_UNKNOWN;
  end;
  v:=varNull;
end;

function GetBitrate(const v:variant):integer;
begin
  try
    result:=v.CurrentTrack.BitRate;
  except
    result:=0;
  end;
end;

function GetSamplerate(const v:variant):integer;
begin
  try
    result:=v.CurrentTrack.SampleRate;
  except
    result:=0;
  end;
end;

function GetTrack(const v:variant):integer;
begin
  try
    result:=v.CurrentTrack.TrackNumber;
  except
    result:=0;
  end;
end;

procedure GetAlbum(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siAlbum,PWideChar(WideString(v.CurrentTrack.Album)),CP_UTF16);
  except
  end;
end;

procedure GetYear(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siYear,PWideChar(WideString(v.CurrentTrack.Year)),CP_UTF16);
  except
  end;
end;

procedure GetGenre(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siGenre,PWideChar(WideString(v.CurrentTrack.Genre)),CP_UTF16);
  except
  end;
end;

procedure GetArtist(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siArtist,PWideChar(WideString(v.CurrentTrack.Artist)),CP_UTF16);
  except
  end;
end;

procedure GetTitle(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siTitle,PWideChar(WideString(v.CurrentStreamTitle)),CP_UTF16);
  except
  end;
end;

procedure GetComment(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siComment,PWideChar(WideString(v.CurrentTrack.Comment)),CP_UTF16);
  except
  end;
end;

procedure GetWndText(Info:UIntPtr; const v:variant);
begin
  try
    WATSetStr(Info,siCaption,PWideChar(WideString(v.Windows.Name)),CP_UTF16);
  except
  end;
end;

function Play(const v:variant; fname:PWideChar=nil):integer;
begin
  try
//    v.PlayFile(fname);
    v.BackTrack;
    result:=v.Play;
  except
    result:=0;
  end;
end;

function Pause(const v:variant):integer;
begin
  try
    result:=v.PlayPause;
  except
    result:=0;
  end;
end;

function Stop(const v:variant):integer;
begin
  try
    result:=v.Stop;
  except
    result:=0;
  end;
end;

function Next(const v:variant):integer;
begin
  try
    result:=v.NextTrack;
  except
    result:=0;
  end;
end;

function Prev(const v:variant):integer;
begin
  try
    result:=v.PreviousTrack;
  except
    result:=0;
  end;
end;

function Seek(const v:variant; value:integer):integer;
begin
  try
    result:=v.PlayerPosition;
    if value>0 then
      v.PlayerPosition:=value
    else
      result:=0;
  except
    result:=0;
  end;
end;

function GetVolume(const v:variant):cardinal;
begin
  try
    result:=v.SoundVolume;
    result:=(result shl 16)+round((result shl 4)/100);
  except
    result:=0;
  end;
end;

procedure SetVolume(const v:variant; value:cardinal);
begin
  try
    v.SoundVolume:=integer((value*100) shr 4);
  except
  end;
end;

function VolDn(const v:variant):integer;
var
  val:integer;
begin
  result:=GetVolume(v);
  val:=loword(result);
  if val>0 then
    SetVolume(v,val-1);
end;

function VolUp(const v:variant):integer;
var
  val:integer;
begin
  result:=GetVolume(v);
  val:=loword(result);
  if val<16 then
    SetVolume(v,val+1);
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
var
  v:variant;
begin
  result:=0;
  try
    v:=CreateOleObject(COMName);
    if (aflags and WAT_OPT_PLAYERDATA)<>0 then
    begin
      if WATIsEmpty(Info,siVersion) then
      begin
        GetVersionText(Info,v);
//!!        WATSet(Info,siVersion,GetVersion(txtver));
      end;
    end
    else if (aflags and WAT_OPT_CHANGES)<>0 then
    begin
      WATSet(Info,siVolume,GetVolume(v));
      if WATGet(Info,siStatus)<>WAT_PLS_STOPPED then
        WATSet(Info,siTime,GetElapsedTime(v));
    end
    else
    begin
      if WATIsEmpty(Info,siLengh     ) then WATSet(Info,siLength    , GetTotalTime (v));
      if WATIsEmpty(Info,siTrack     ) then WATSet(Info,siTrack     , GetTrack     (v));
      if WATIsEmpty(Info,siBitrate   ) then WATSet(Info,siBitrate   , GetBitrate   (v));
      if WATIsEmpty(Info,siSamplerate) then WATSet(Info,siSamplerate, GetSamplerate(v));
      if WATIsEmpty(Info,siYear      ) then GetYear   (Info,v);
      if WATIsEmpty(Info,siGenre     ) then GetGenre  (Info,v);
      if WATIsEmpty(Info,siArtist    ) then GetArtist (Info,v);
      if WATIsEmpty(Info,siAlbum     ) then GetAlbum  (Info,v);
      if WATIsEmpty(Info,siComment   ) then GetComment(Info,v);
    end;
//      GetWndText(Info,v);
  except
  end;
  v:=varNull;
//    if WATIsEmpty(Info,siTitle) then GetTitle(Info,v); // only for streaming audio
end;

function Command(wnd:HWND; cmd:integer; value:IntPtr):IntPtr;
var
  v:Variant;
begin
  result:=0;
  try
    v:=CreateOleObject(COMName);
    case cmd of
      WAT_CTRL_PREV : result:=Prev (v);
      WAT_CTRL_PLAY : result:=Play (v,pWideChar(value));
      WAT_CTRL_PAUSE: result:=Pause(v);
      WAT_CTRL_STOP : result:=Stop (v);
      WAT_CTRL_NEXT : result:=Next (v);
      WAT_CTRL_VOLDN: result:=VolDn(v);
      WAT_CTRL_VOLUP: result:=VolUp(v);
      WAT_CTRL_SEEK : result:=Seek (v,value);
    end;
  except
  end;
  v:=varNull;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:@GetStatus;
    GetName  :@GetFileName;
    GetInfo  :@GetInfo;
    Command  :@Command;
    Desc     :'iTunes';
    URL      :'http://www.itunes.com/';
    Notes    :'';
    Group    :0;
    flags    :WAT_OPT_SINGLEINST or WAT_OPT_HASURL;
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
