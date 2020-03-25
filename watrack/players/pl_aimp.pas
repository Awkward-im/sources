{AIMP player}
unit pl_AIMP;
{$include compilers.inc}

interface

implementation

uses
  windows,messages,
  aimp_api,
  
  common,
  srv_player,
  wat_api;

{
const
  WM_AIMP_COMMAND  = WM_USER + $75;

  WM_AIMP_GET_VERSION = 4;
  WM_AIMP_STATUS_GET  = 1;
  WM_AIMP_STATUS_SET  = 2;
  WM_AIMP_CALLFUNC    = 3;
const
  AIMP_STS_Player = 4;
  AIMP_STS_VOLUME = 1;
  AIMP_STS_POS    = 31;
const
  AIMP_PLAY  = 15;
  AIMP_PAUSE = 16;
  AIMP_STOP  = 17;
  AIMP_NEXT  = 18;
  AIMP_PREV  = 19;

const
  AIMP2_RemoteClass:PAnsiChar = 'AIMP2_RemoteInfo';
const
  AIMP2_RemoteFileSize = 2048;

type
  PAIMP2FileInfo = ^TAIMP2FileInfo;
  TAIMP2FileInfo = packed record
    cbSizeOF    :dword; // deprecated
    //
    nActive     :LongBool;
    nBitRate    :dword;
    nChannels   :dword;
    nDuration   :dword;
    nFileSize   :Int64;
    nRating     :dword;
    nSampleRate :dword;
    nTrackID    :dword;
    //
    nAlbumLen   :dword;
    nArtistLen  :dword;
    nDateLen    :dword;
    nFileNameLen:dword;
    nGenreLen   :dword;
    nTitleLen   :dword;
    // deprecated
    sAlbum      :dword; // size of pointer for 32 bit system
    sArtist     :dword;
    sDate       :dword;
    sFileName   :dword;
    sGenre      :dword;
    sTitle      :dword;
  end;
}

function Check(wnd:HWND; aflags:cardinal):HWND;
begin
  if wnd<>0 then
  begin
    result:=0;
    exit;
  end;
  result:=FindWindowA(AIMPRemoteAccessClass,AIMPRemoteAccessClass);
end;

procedure GetVersionText(Info:UIntPtr;ver:integer);
var
  buf:array [0..15] of AnsiChar;
  i:integer;
begin
  if (ver and $F00)<>0 then
  begin
    buf[0]:=AnsiChar((ver shr 8)+ORD('0'));
    ver:=ver and $FF;
    buf[1]:='.';
    if ver>99 then
    begin
      buf[2]:=AnsiChar((ver div 100)+ORD('0'));
      ver:=ver mod 100;
      i:=3;
    end
    else
      i:=2;
    buf[i  ]:=AnsiChar((ver div 10)+ORD('0'));
    buf[i+1]:=AnsiChar((ver mod 10)+ORD('0'));
    buf[i+2]:=#0;
    WATSetStr(Info,siTextVersion,@buf,CP_UTF8); //CP_ACP
  end;
end;

function GetVersion(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_AIMP_PROPERTY,
      AIMP_RA_PROPERTY_VERSION or AIMP_RA_PROPVALUE_GET,0);
end;

function GetStatus(wnd:HWND):integer;
begin
  result:=SendMessage(wnd,WM_AIMP_PROPERTY,
      AIMP_RA_PROPERTY_PLAYER_STATE or AIMP_RA_PROPVALUE_GET,0);
end;

function GetVolume(wnd:HWND):cardinal;
begin
  result:=SendMessage(wnd,WM_AIMP_PROPERTY,
      AIMP_RA_PROPERTY_VOLUME or AIMP_RA_PROPVALUE_GET,0);
  result:=(result shl 16)+round((result shl 4)/100);
end;

procedure GetFileName(Info:UIntPtr; aflags:cardinal);
var
  buf:array [0..511] of WideChar;
  FFile:THANDLE;
  pStr:pointer;
  s:integer;
  p:PAnsiChar;
  pw,pw1:pWideChar;
begin
  s:=AIMPRemoteAccessMapFileSize;
  p:=AIMPRemoteAccessClass;
  FFile:=OpenFileMappingA(FILE_MAP_READ,True,p);
  if FFile<>0 then
  begin
    pStr:=MapViewOfFile(FFile,FILE_MAP_READ,0,0,s);
    if pStr<>nil then
    begin
      try
        with PAIMPRemoteFileInfo(pStr)^ do
        begin
          StrCopyW(@buf, //!!
            pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo)+
               (AlbumLength+ArtistLength+DateLength)*SizeOf(WideChar)),
            FileNameLength);

            // Delete rest index (like "filename.cue:3")
            pw:=StrRScanW(@buf,':');
            if pw<>nil then
            begin
              pw1:=StrScanW(@buf,':');
              if pw<>pw1 then
                pw^:=#0;
            end;
        end;
        WATSetStr(Info,siFile,@buf,CP_UTF16);
      except
      end;
      UnmapViewOfFile(pStr);
    end;
    CloseHandle(FFile);
  end;
end;

procedure TranslateRadio(Info:UIntPtr);
var
  title:array [0..511] of AnsiChar;
  pc,pc1:pAnsiChar;
begin
{
  artist - album - title (radio)
}
  if    WATIsEmpty(Info,siArtist) and
    not WATIsEmpty(Info,siTitle) then
  begin
    StrCopy(title,WATGetStr(Info,siTitle));
    // Radio title
    pc1:=StrEnd(@title);
    if (pc1-1)^=')' then
    begin
      pc:=StrRScan(@title,'(');
      if (pc<>nil) and (pc>@title) and ((pc-1)^=' ') then
      begin
         if WATIsEmpty(Info,siComment) then
         begin
           (pc1-1)^:=#0;
           WATSetStr(Info,siComment, pc+1, CP_UTF8);
         end;
         (pc-1)^:=#0;
      end;
    end;
    // artist - title
    pc:=StrPos(@title,' - ');
    if pc<>nil then
    begin
      if WATIsEmpty(Info,siArtist) then
      begin
        pc^:=#0;
        inc(pc,3);
        WATSetStr(Info,siArtist, @title, CP_UTF8);
      end;
      // artist - album - title
      pc1:=StrPos(pc,' - ');
      if pc1<>nil then
      begin
        if WATIsEmpty(Info,siAlbum) then
        begin
          pc1^:=#0;
          WATSetStr(Info,siAlbum, pc, CP_UTF8);
          pc:=pc1+3;
        end;
      end;

      WATSetStr(Info,siTitle, pc, CP_UTF8);
    end;
  end;
end;

function GetInfo(Info:UIntPtr; aflags:cardinal):integer;
var
  FFile,wnd:THANDLE;
  s:integer;
  p:PAnsiChar;
  pStr:PAIMPRemoteFileInfo;
begin
  result:=0;

  if (aflags and WAT_OPT_PLAYERDATA)<>0 then
  begin
    if WATIsEmpty(Info,siVersion) then
    begin
      s:=GetVersion(WATGet(Info,siWindow));
      WATSet(Info,siVersion,s);
      GetVersionText(Info,s);
    end;
    exit;
  end;

  if (aflags and WAT_OPT_CHANGES)=0 then
  begin
    s:=AIMPRemoteAccessMapFileSize;
    p:=AIMPRemoteAccessClass;
    FFile:=OpenFileMappingA(FILE_MAP_READ,True,p);
    if FFile<>0 then
    begin
      pStr:=MapViewOfFile(FFile,FILE_MAP_READ,0,0,s);
      if pStr<>nil then
      begin
        try
          with pStr^ do
          begin
            if WATIsEmpty(Info,siChannels  ) then WATSet(Info,siChannels  ,Channels);
            if WATIsEmpty(Info,siBitrate   ) then WATSet(Info,siBitrate   ,BitRate    div 1000);
            if WATIsEmpty(Info,siSamplerate) then WATSet(Info,siSamplerate,SampleRate div 1000);
            if WATIsEmpty(Info,siLength    ) then WATSet(Info,siLength    ,Duration);
            if WATIsEmpty(Info,siSize      ) then WATSet(Info,siSize      ,FileSize);
            if WATIsEmpty(Info,siTrack     ) then WATSet(Info,siTrack     ,TrackNumber);

            with PAIMPRemoteFileInfo(pStr)^ do
            begin
              if WATIsEmpty(Info,siArtist) and (ArtistLength>0) then
              begin
                WATSetStr(Info,siArtist,
                  pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo))+
                     AlbumLength,
                  CP_UTF16);
              end;

              if WATIsEmpty(Info,siAlbum) and (AlbumLength>0) then
              begin
                WATSetStr(Info,siAlbum,
                  pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo)),
                  CP_UTF16);
              end;

              if WATIsEmpty(Info,siTitle) and (TitleLength>0) then
              begin
                WATSetStr(Info,siTitle,
                  pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo))+
                     AlbumLength+ArtistLength+DateLength+FileNameLength+GenreLength,
                  CP_UTF16);
              end;

              if WATIsEmpty(Info,siYear) and (DateLength>0) then
              begin
                WATSetStr(Info,siYear,
                  pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo))+
                     AlbumLength+ArtistLength,
                  CP_UTF16);
              end;

              if WATIsEmpty(Info,siGenre) and (GenreLength>0) then
              begin
                WATSetStr(Info,siGenre,
                  pWideChar(PAnsiChar(pStr)+SizeOf(TAIMPRemoteFileInfo))+
                     AlbumLength+ArtistLength+DateLength+FileNameLength,
                  CP_UTF16);
              end;

              if StrPos(WATGetStr(Info,siFile),'://')<>nil then
                TranslateRadio(Info);
            end;
          end;
        except
        end;
        UnmapViewOfFile(pStr);
      end;
      CloseHandle(FFile);
    end;
  end
  else // request AIMP changed data: volume
  begin
    wnd:=WATGet(Info,siWindow);
    WATSet(Info,siPosition,
      SendMessage(wnd,WM_AIMP_PROPERTY,
                  AIMP_RA_PROPERTY_PLAYER_POSITION or AIMP_RA_PROPVALUE_GET,0));
    WATSet(Info,siVolume,GetVolume(wnd));
  end;
end;

//----- Commands -----

procedure SetVolume(wnd:HWND; value:cardinal);
begin
  SendMessage(wnd,WM_AIMP_PROPERTY,
      AIMP_RA_PROPERTY_VOLUME or AIMP_RA_PROPVALUE_SET,
      value);
end;

function VolDn(wnd:HWND):integer;
var
  val:dword;
begin
  result:=GetVolume(wnd);
  val:=loword(result);
  if val>0 then
    SetVolume(wnd,val-1);
end;

function VolUp(wnd:HWND):integer;
var
  val:dword;
begin
  result:=GetVolume(wnd);
  val:=loword(result);
  if val<16 then
    SetVolume(wnd,val+1);
end;

function Command(wnd:HWND; cmd:integer; value:IntPtr):IntPtr;
begin
  result:=WAT_RES_OK;
  case cmd of
    WAT_CTRL_PREV : SendMessage(wnd,WM_AIMP_COMMAND,AIMP_RA_CMD_PREV ,0);
    WAT_CTRL_PLAY : SendMessage(wnd,WM_AIMP_COMMAND,AIMP_RA_CMD_PLAY ,0);
    WAT_CTRL_PAUSE: SendMessage(wnd,WM_AIMP_COMMAND,AIMP_RA_CMD_PAUSE,0);
    WAT_CTRL_STOP : SendMessage(wnd,WM_AIMP_COMMAND,AIMP_RA_CMD_STOP ,0);
    WAT_CTRL_NEXT : SendMessage(wnd,WM_AIMP_COMMAND,AIMP_RA_CMD_NEXT ,0);
    WAT_CTRL_VOLDN: result:=VolDn(wnd);
    WAT_CTRL_VOLUP: result:=VolUp(wnd);
    WAT_CTRL_SEEK : SendMessage(wnd,AIMP_RA_CMD_BASE,
        AIMP_RA_PROPERTY_PLAYER_POSITION or AIMP_RA_PROPVALUE_SET,
        value);
  end;
end;

const
  plRec:tPlayerCell=(
    Check    :@Check;
    Init     :nil;
    GetStatus:@GetStatus;
    GetName  :@GetFileName;
    GetInfo  :@GetInfo;
    Command  :@Command;
    Desc     :'AIMP';
    URL      :'http://www.aimp.ru/';
    Notes    :'';
    Group    :0;
    flags    :WAT_OPT_APPCOMMAND or WAT_OPT_HASURL or WAT_OPT_WINAMPAPI or WAT_OPT_SINGLEINST;
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
