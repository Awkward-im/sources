{$DEFINE UseOffsets}

unit wat_api;

interface

uses
  cmemini;

const
  // tag info
  siArtist      = 0;
  siTitle       = 1;
  siAlbum       = 2;
  siGenre       = 3;
  siYear        = 4;
  siLyric       = 5;
  siCover       = 6;
  siComment     = 7;
  siTrack       = 8;

  // file info
  siFile        = 9;
  siDate        = 10;
  siSize        = 11;
  // player info
  siPlayer      = 12;
  siURL         = 13;
  siTextVersion = 14;
  siVersion     = 15;
  // runtime info
  siCaption     = 16;
  siVolume      = 17;
  siPosition    = 18;

  // track info
  siBitrate     = 19;
  siSamplerate  = 20;
  siChannels    = 21;
  siVBR         = 22;
  siLength      = 23;
  // video part
  siCodec       = 24;
  siWidth       = 25;
  siHeight      = 26;
  siFPS         = 27;
  // changing player info
  siWindow      = 28;
  siWinamp      = 29;
  siStatus      = 30;

// Player status
const
  WAT_PLS_NOTFOUND = 0; // player not found
  WAT_PLS_PLAYING  = 1;
  WAT_PLS_PAUSED   = 2;
  WAT_PLS_STOPPED  = 3; // player stopped, no music even searched
  WAT_PLS_UNKNOWN  = 4; // player found with unknown state

{$IFNDEF FPC}
type
  PUIntPtr = ^UIntPtr;
{$ENDIF}

const
  // really, just 3 "codepages" using: CP_UTF8, CP_UTF16 and CP_ACP. what about CP_OEMCP?
{$IFNDEF FPC}
  CP_NONE  = $FFFF;
  CP_ACP   = 0;
  CP_OEMCP = 1;
  CP_UTF8  = 65001;
  CP_UTF16 = 1200;
{$ENDIF}
  WAT_INF_CP = CP_UTF8;

  WAT_INF_CHANGES = $100;

const
  // result codes
  WAT_RES_STATUS    = $FFFF;

  WAT_RES_UNKNOWN   = -2 and WAT_RES_STATUS;
  WAT_RES_NOTFOUND  = -1 and WAT_RES_STATUS;
  WAT_RES_ERROR     = WAT_RES_NOTFOUND;
  WAT_RES_OK        = 0;
  WAT_RES_ENABLED   = WAT_RES_OK;
  WAT_RES_DISABLED  = 1;

  // Extended status
  WAT_RES_EXTSTATUS = $FFFF0000;

  WAT_RES_NEWFILE   = 1 shl 16;
  WAT_RES_NEWPLAYER = 2 shl 16;
  WAT_RES_NEWSTATUS = 4 shl 16;

// Player control
const
  WAT_CTRL_FIRST = 1;

  WAT_CTRL_PREV  = 1;
  WAT_CTRL_PLAY  = 2;
  WAT_CTRL_PAUSE = 3;
  WAT_CTRL_STOP  = 4;
  WAT_CTRL_NEXT  = 5;
  WAT_CTRL_VOLDN = 6;
  WAT_CTRL_VOLUP = 7;
  WAT_CTRL_SEEK  = 8; // lParam is new position (sec)

  WAT_CTRL_LAST  = 8;

// Service commands
const
  WAT_ACT_REGISTER   = 1;
  WAT_ACT_UNREGISTER = 2;
  WAT_ACT_DISABLE    = 3;
  WAT_ACT_ENABLE     = 4;
  WAT_ACT_GETSTATUS  = 5; // not found/enabled/disabled
  WAT_ACT_SETACTIVE  = 6;
  WAT_ACT_REPLACE    = $10000; // can be combined with WAT_REGISTERFORMAT

const
  // attributes (not changing)
  WAT_OPT_PLAYERINFO  = $00000004; // [players] song info from player
  WAT_OPT_WINAMPAPI   = $00000008; // [players] Winamp API support
  WAT_OPT_HASURL      = $00000400; // [players] URL field present
  WAT_OPT_APPCOMMAND  = $00001000; // [players] Special (multimedia) key support
  WAT_OPT_SINGLEINST  = $00010000; // [players] Single player instance
  WAT_OPT_ONLYONE     = $00000002; // [formats,players] code can't be overwriten
  WAT_OPT_CONTAINER   = $00040000; // [formats] format is container (need to check full)
  WAT_OPT_VIDEO       = $00000020; // [formats] format is video
//  WAT_OPT_BUILTINTAG  = $00100000; // [formats] tag info built in file (no separate tag)
  WAT_OPT_LAST        = $00000040; // (internal-Winamp Clone) put to the end of queue
  WAT_OPT_FIRST       = $00000080; // (internal)
  WAT_OPT_TEMPLATE    = $00000100; // (internal)
  WAT_OPT_INTERNAL    = $80000000; // (internal) for memory manager choosing

  // options
  WAT_OPT_DISABLED    = $00000001; // [formats,players,options] registered but disabled
  WAT_OPT_CHECKTIME   = $00000010; // [options] check file time for changes
  WAT_OPT_IMPLANTANT  = $00000200; // [options] use process implantation
  WAT_OPT_CHECKALL    = $00002000; // [options] Check all players
  WAT_OPT_KEEPOLD     = $00004000; // [options] Keep Old opened file
  WAT_OPT_UNKNOWNFMT  = $00080000; // [options] check unknown (not disabled) formats (info from player)
//  WAT_OPT_MULTITHREAD = $00008000; // [options] Use multithread scan

  // realtime
  WAT_OPT_PLAYERDATA  = $00020000; // [realtime] to obtain player data
  WAT_OPT_CHANGES     = $00000800; // [realtime] obtain only chaged values
                                   // (volume, status, window text, elapsed time)


//----- Modules links -----

type
  pwModule = ^twModule;
  twModule = record
    Next      :pwModule;
    Init      :function (aInit:boolean):integer;
    AddOption :function (var cnt:integer):pointer;
    Action    :procedure(Info:UIntPtr; res:integer);
    ModuleName:PAnsiChar;
  end;

const
  ModuleLink:pwModule=nil;

//----- INI-file with settings related -----
var
  watini:tINIFile;

//----- Global functions -----

var
  ErrorFunc   :function(amodule:PAnsiChar; amsg:PAnsiChar; critical:boolean=false):integer;
  TemplateFunc:function(Info:UIntPtr; const aTmpl:AnsiString):AnsiString;

// support

function WATAssignStr(in_str:pointer; enc:integer=CP_NONE):pointer;

// get/set data

procedure WATClearStr (Info:UIntPtr; afield:UIntPtr);
procedure WATSet      (Info:UIntPtr; afield:UIntPtr; adata:UIntPtr);
procedure WATSetStr   (Info:UIntPtr; afield:UIntPtr; adata:pointer; acp:integer{=CP_ACP});
procedure WATSetString(Info:UIntPtr; afield:UIntPtr; const adata:AnsiString);
function  WATGet      (Info:UIntPtr; afield:UIntPtr):UIntPtr;
function  WATGetStr   (Info:UIntPtr; afield:UIntPtr):pointer;
function  WATGetString(Info:UIntPtr; afield:UIntPtr):AnsiString;
function  WATIsEmpty  (Info:UIntPtr; afield:UIntPtr):boolean;

procedure WATSetIfEmpty   (Info:UIntPtr; afield:UIntPtr; adata:UIntPtr);
procedure WATSetStrIfEmpty(Info:UIntPtr; afield:UIntPtr; adata:pointer; acp:integer{=CP_ACP});

// initialization

function  WATCreate:UIntPtr;
procedure WATFree(var Info:UIntPtr);

// cleanup

procedure ClearInfoData    (Info:UIntPtr);
procedure ClearPlayerInfo  (Info:UIntPtr);
procedure ClearFileInfo    (Info:UIntPtr);
procedure ClearChangingInfo(Info:UIntPtr);
procedure ClearTrackInfo   (Info:UIntPtr);


//=================== implementation =====================

implementation

uses
  common;

//----- Combined info, high level processing -----
{
  type 0: integer
  type 1: text
  type 2: handle
}
const
  SIDArray: array [0..30] of record
    dofs : word;
    dtype: word;
  end = (
  {siArtist     } (dofs:0; dtype:1),
  {siTitle      } (dofs:0; dtype:1),
  {siAlbum      } (dofs:0; dtype:1),
  {siGenre      } (dofs:0; dtype:1),
  {siYear       } (dofs:0; dtype:1),
  {siLyric      } (dofs:0; dtype:1),
  {siCover      } (dofs:0; dtype:1),
  {siComment    } (dofs:0; dtype:1),
  {siTrack      } (dofs:0; dtype:0),
  {siFile       } (dofs:0; dtype:1),
  {siDate       } (dofs:0; dtype:0),
  {siSize       } (dofs:0; dtype:0),
  {siPlayer     } (dofs:0; dtype:1),
  {siURL        } (dofs:0; dtype:1),
  {siTextVersion} (dofs:0; dtype:1),
  {siVersion    } (dofs:0; dtype:0),
  {siCaption    } (dofs:0; dtype:1),
  {siVolume     } (dofs:0; dtype:0),
  {siPosition   } (dofs:0; dtype:0),
  {siBitrate    } (dofs:0; dtype:0),
  {siSamplerate } (dofs:0; dtype:0),
  {siChannels   } (dofs:0; dtype:0),
  {siVBR        } (dofs:0; dtype:0),
  {siLength     } (dofs:0; dtype:0),
  {siCodec      } (dofs:0; dtype:0),
  {siWidth      } (dofs:0; dtype:0),
  {siHeight     } (dofs:0; dtype:0),
  {siFPS        } (dofs:0; dtype:0),
  {siWindow     } (dofs:0; dtype:2),
  {siWinamp     } (dofs:0; dtype:2),
  {siStatus     } (dofs:0; dtype:0)
  );

type
  pSongInfo = ^tSongInfo;
  tSongInfo = record
    // tag info
    artist    :pointer;
    title     :pointer;
    album     :pointer;
    genre     :pointer;
    comment   :pointer;
    year      :pointer;
    lyric     :pointer;
    cover     :pointer;
    track     :cardinal;
    // track info
    bitrate   :cardinal;
    samplerate:cardinal;
    channels  :cardinal;
    vbr       :cardinal;
    length    :cardinal;   // music length
    // video  part
    codec     :cardinal;
    width     :cardinal;
    height    :cardinal;
    fps       :cardinal;
    // file info
    fname     :pointer;    // media file
    date      :cardinal;
    size      :cardinal;   // media file size
    // player info
    player    :pointer;    // player name
    url       :pointer;    // player homepage
    txtver    :pointer;
    version   :cardinal;   // player version
    // changing player info
    window    :THANDLE;    // player window
    winamp    :THANDLE;
    status    :cardinal;   // WAT_PLS_*
    // runtime info
    caption   :pointer;    // window title
    volume    :cardinal;
    position  :cardinal;   // elapsed time
  end;

//----- Dummy Global functions -----

function DummyTemplate(Info:UIntPtr; const atmpl:AnsiString):AnsiString;
begin
  result:=atmpl;
end;

function DummyError(amodule:PAnsiChar; amsg:PAnsiChar; critical:boolean=false):integer;
begin
  if critical then
    result:=WAT_RES_ERROR
  else
    result:=WAT_RES_OK;
end;

//----- Service functions -----

function WATAssignStr(in_str:pointer; enc:integer=CP_NONE):pointer;
begin
  result:=nil;
  if in_str<>nil then
    case enc of
      CP_OEMCP: begin
        {$IF WAT_INF_CP=CP_UTF8}
//          AnsiToUTF8(in_str,result);
        {$ELSEIF WAT_INF_CP=CP_UTF16}
//          AnsiToWide(in_str,result);
        {$ELSE}
//          StrDup(result,in_str);
        {$IFEND}{.$ENDIF}
      end;

      CP_ACP: begin
        {$IF WAT_INF_CP=CP_UTF8}
          AnsiToUTF8(in_str,PAnsiChar(result));
        {$ELSEIF WAT_INF_CP=CP_UTF16}
          AnsiToWide(in_str,PWideChar(result));
        {$ELSE}
          StrDup(PAnsiChar(result),in_str);
        {$IFEND}{.$ENDIF}
      end;

      CP_UTF8: begin
        // if is not valid UTF8, get as CP_ACP?
        {$IF WAT_INF_CP=CP_UTF8}
          StrDup(PAnsiChar(result),in_str);
        {$ELSEIF WAT_INF_CP=CP_UTF16}
          UTF8ToWide(in_str,PWideChar(result));
        {$ELSE}
          UTF8ToAnsi(in_str,PAnsiChar(result));
        {$IFEND}{.$ENDIF}
      end;

      CP_UTF16: begin
        {$IF WAT_INF_CP=CP_UTF8}
          WideToUTF8(in_str,PAnsiChar(result));
        {$ELSEIF WAT_INF_CP=CP_UTF16}
          StrDupW(PWideChar(result),in_str);
        {$ELSE}
          WideToAnsi(in_str,PAnsiChar(result));
        {$IFEND}{.$ENDIF}
      end;
    end;
end;

var
  GlobalWATData:pSongInfo;

//----- Get/Set data -----

function WATGetAddress(Info:UIntPtr; afield:UIntPtr):pointer;
begin
  if Info=0 then Info:=UIntPtr(GlobalWATData);
{$IFDEF UseOffsets}
  result:=pointer(Info+SIDArray[afield].dofs);
{$ELSE}
  case afield of
    siArtist     : result:=@pSongInfo(Info)^.artist;
    siTitle      : result:=@pSongInfo(Info)^.title;
    siAlbum      : result:=@pSongInfo(Info)^.album;
    siGenre      : result:=@pSongInfo(Info)^.genre;
    siYear       : result:=@pSongInfo(Info)^.year;
    siLyric      : result:=@pSongInfo(Info)^.lyric;
    siCover      : result:=@pSongInfo(Info)^.cover;
    siComment    : result:=@pSongInfo(Info)^.comment;
    siTrack      : result:=@pSongInfo(Info)^.track;
    siFile       : result:=@pSongInfo(Info)^.fname;
    siDate       : result:=@pSongInfo(Info)^.date;
    siSize       : result:=@pSongInfo(Info)^.size;
    siPlayer     : result:=@pSongInfo(Info)^.player;
    siURL        : result:=@pSongInfo(Info)^.url;
    siTextVersion: result:=@pSongInfo(Info)^.txtver;
    siVersion    : result:=@pSongInfo(Info)^.version;
    siCaption    : result:=@pSongInfo(Info)^.caption;
    siVolume     : result:=@pSongInfo(Info)^.volume;
    siPosition   : result:=@pSongInfo(Info)^.position;
    siBitrate    : result:=@pSongInfo(Info)^.bitrate;
    siSamplerate : result:=@pSongInfo(Info)^.samplerate;
    siChannels   : result:=@pSongInfo(Info)^.channels;
    siVBR        : result:=@pSongInfo(Info)^.vbr;
    siLength     : result:=@pSongInfo(Info)^.length;
    siCodec      : result:=@pSongInfo(Info)^.codec;
    siWidth      : result:=@pSongInfo(Info)^.width;
    siHeight     : result:=@pSongInfo(Info)^.height;
    siFPS        : result:=@pSongInfo(Info)^.fps;
    siWindow     : result:=@pSongInfo(Info)^.window;
    siWinamp     : result:=@pSongInfo(Info)^.winamp;
    siStatus     : result:=@pSongInfo(Info)^.status;
  end;
{$ENDIF}
end;

procedure WATSetIfEmpty(Info:UIntPtr; afield:UIntPtr; adata:UIntPtr);
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: if PCardinal(dataptr)^=0 then PCardinal(dataptr)^:=adata;
    1: ;
    2: if PUIntPtr (dataptr)^=0 then PUIntPtr(dataptr)^:=adata;
  else
  end;
end;

procedure WATSetStrIfEmpty(Info:UIntPtr; afield:UIntPtr; adata:pointer; acp:integer{=CP_ACP});
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: if PCardinal(dataptr)^=0 then 
    begin
      if acp=CP_UTF16 then
        PCardinal(dataptr)^:=StrToInt(PWideChar(adata))
      else
        PCardinal(dataptr)^:=StrToInt(PAnsiChar(adata));
    end;

    1: if PPointer(dataptr)^=nil then
    begin
      PPAnsiChar(dataptr)^:=WATAssignStr(adata,acp);
    end;

    2: if PUIntPtr(dataptr)^=0 then
    begin
      if acp=CP_UTF16 then
        PUIntPtr(dataptr)^:=StrToInt(PWideChar(adata))
      else
        PUIntPtr(dataptr)^:=StrToInt(PAnsiChar(adata));
    end;
  end;
end;

procedure WATSet(Info:UIntPtr; afield:UIntPtr; adata:UIntPtr);
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: PCardinal(dataptr)^:=adata;
    1: ;
    2: PUIntPtr (dataptr)^:=adata;
  end;
end;

procedure WATSetStr(Info:UIntPtr; afield:UIntPtr; adata:pointer; acp:integer{=CP_ACP});
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: if acp=CP_UTF16 then
      PCardinal(dataptr)^:=StrToInt(PWideChar(adata))
    else
      PCardinal(dataptr)^:=StrToInt(PAnsiChar(adata));

    1: begin
      WATClearStr(Info, afield);
      PPAnsiChar(dataptr)^:=WATAssignStr(adata,acp);
    end;

    2: if acp=CP_UTF16 then
      PUIntPtr(dataptr)^:=StrToInt(PWideChar(adata))
    else
      PUIntPtr(dataptr)^:=StrToInt(PAnsiChar(adata));
  end;
end;

procedure WATSetString(Info:UIntPtr; afield:UIntPtr; const adata:AnsiString);
begin
  WATSetStr(Info, afield, pointer(adata), CP_UTF8);
end;

function WATGet(Info:UIntPtr; afield:UIntPtr):UIntPtr;
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: result:=PCardinal(dataptr)^;

    1: {$IF WAT_INF_CP=CP_UTF16}
       result:=StrToInt(PPWideChar(dataptr)^);
       {$ELSE}
       result:=StrToInt(PPAnsiChar(dataptr)^);
       {$IFEND}{.$ENDIF}

    2: result:=PUIntPtr(dataptr)^;
  else
    result:=0;
  end;
end;

function WATGetStr(Info:UIntPtr; afield:UIntPtr):pointer;
var
  dataptr:pointer;
begin
  if SIDArray[afield].dtype = 1 then
  begin
    dataptr:=WATGetAddress(Info,afield);
    {$IF WAT_INF_CP=CP_UTF16}
    result:=PPWideChar(dataptr)^;
    {$ELSE}
    result:=PPAnsiChar(dataptr)^;
    {$IFEND}{.$ENDIF}
  end
  else
    result:=nil;
end;

function WATGetString(Info:UIntPtr; afield:UIntPtr):AnsiString;
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: Str(PCardinal(dataptr)^,result);

    1: {$IF WAT_INF_CP=CP_UTF16}
       result:=PPWideChar(dataptr)^;
       {$ELSE}
       result:=PPAnsiChar(dataptr)^;
       {$IFEND}{.$ENDIF}

    2: Str(PUIntPtr(dataptr)^,result);
  else
    result:='';
  end;
end;

function WATIsEmpty(Info:UIntPtr; afield:UIntPtr):boolean;
var
  dataptr:pointer;
begin
  dataptr:=WATGetAddress(Info,afield);

  case SIDArray[afield].dtype of
    0: result:=PCardinal(dataptr)^=0;
    1: result:=PPointer (dataptr)^=nil;
    2: result:=PUIntPtr (dataptr)^=0;
  else
    result:=true;
  end;
end;

procedure WATClearStr(Info:UIntPtr; afield:UIntPtr);
begin
  if SIDArray[afield].dtype = 1 then
  begin
    mFreeMem(PPansiChar(WATGetAddress(Info,afield))^);
  end;
end;

//----- Cleaning -----

// changing data
procedure ClearChangingInfo(Info:UIntPtr);
begin
  WATSet(Info,siPosition,0);
  WATSet(Info,siVolume  ,0);

  WATClearStr(Info,siCaption);
end;

// file data
procedure ClearFileInfo(Info:UIntPtr);
begin
  WATClearStr(Info,siFile);

  WATSet(Info,siSize,0);
  WATSet(Info,siDate,0);
end;

// player data
procedure ClearPlayerInfo(Info:UIntPtr);
begin
  WATClearStr(Info,siPlayer);
  WATClearStr(Info,siTextVersion);
  WATClearStr(Info,siURL);

  WATSet(Info,siVersion,0);
  WATSet(Info,siWindow ,0);
  WATSet(Info,siWinamp ,0);
end;

// track data
procedure ClearTrackInfo(Info:UIntPtr);
begin
  // tag info
  WATClearStr(Info,siArtist);
  WATClearStr(Info,siTitle);
  WATClearStr(Info,siAlbum);
  WATClearStr(Info,siGenre);
  WATClearStr(Info,siComment);
  WATClearStr(Info,siYear);
  WATClearStr(Info,siLyric);
  WATClearStr(Info,siCover);

  WATSet(Info,siTrack,0);
  // track info
  WATSet(Info,siBitrate   ,0);
  WATSet(Info,siSamplerate,0);
  WATSet(Info,siChannels  ,0);
  WATSet(Info,siLength    ,0);
  WATSet(Info,siVbR       ,0);
  // video info
  WATSet(Info,siCodec ,0);
  WATSet(Info,siWidth ,0);
  WATSet(Info,siHeight,0);
  WATSet(Info,siFPS   ,0);
end;

procedure ClearInfoData(Info:UIntPtr);
begin
  ClearPlayerInfo  (Info);
  ClearChangingInfo(Info);
  ClearFileInfo    (Info);
  ClearTrackInfo   (Info);
end;

//----- Initialization functions -----

function WATCreate:UIntPtr;
begin
  GetMem  (pByte(result) ,SizeOf(tSongInfo));
  FillChar(pByte(result)^,SizeOf(tSongInfo),0);
end;

procedure WATFree(var Info:UIntPtr);
begin
  ClearInfoData(Info);
  FreeMem(pSongInfo(Info));
  Info:=0;
end;

{$IFDEF UseOffsets}
procedure InitIndexes;
begin
  // tag info
  SIDArray[siArtist     ].dofs := PByte(@GlobalWATData^.artist    )-PByte(GlobalWATData);
  SIDArray[siTitle      ].dofs := PByte(@GlobalWATData^.title     )-PByte(GlobalWATData);
  SIDArray[siAlbum      ].dofs := PByte(@GlobalWATData^.album     )-PByte(GlobalWATData);
  SIDArray[siGenre      ].dofs := PByte(@GlobalWATData^.genre     )-PByte(GlobalWATData);
  SIDArray[siYear       ].dofs := PByte(@GlobalWATData^.year      )-PByte(GlobalWATData);
  SIDArray[siLyric      ].dofs := PByte(@GlobalWATData^.lyric     )-PByte(GlobalWATData);
  SIDArray[siCover      ].dofs := PByte(@GlobalWATData^.cover     )-PByte(GlobalWATData);
  SIDArray[siComment    ].dofs := PByte(@GlobalWATData^.comment   )-PByte(GlobalWATData);
  SIDArray[siTrack      ].dofs := PByte(@GlobalWATData^.track     )-PByte(GlobalWATData);
  // file info
  SIDArray[siFile       ].dofs := PByte(@GlobalWATData^.fname     )-PByte(GlobalWATData);
  SIDArray[siDate       ].dofs := PByte(@GlobalWATData^.date      )-PByte(GlobalWATData);
  SIDArray[siSize       ].dofs := PByte(@GlobalWATData^.size      )-PByte(GlobalWATData);
  // player info
  SIDArray[siPlayer     ].dofs := PByte(@GlobalWATData^.player    )-PByte(GlobalWATData);
  SIDArray[siURL        ].dofs := PByte(@GlobalWATData^.url       )-PByte(GlobalWATData);
  SIDArray[siTextVersion].dofs := PByte(@GlobalWATData^.txtver    )-PByte(GlobalWATData);
  SIDArray[siVersion    ].dofs := PByte(@GlobalWATData^.version   )-PByte(GlobalWATData);
  // runtime info
  SIDArray[siCaption    ].dofs := PByte(@GlobalWATData^.caption   )-PByte(GlobalWATData);
  SIDArray[siVolume     ].dofs := PByte(@GlobalWATData^.volume    )-PByte(GlobalWATData);
  SIDArray[siPosition   ].dofs := PByte(@GlobalWATData^.position  )-PByte(GlobalWATData);
  // track info
  SIDArray[siBitrate    ].dofs := PByte(@GlobalWATData^.bitrate   )-PByte(GlobalWATData);
  SIDArray[siSamplerate ].dofs := PByte(@GlobalWATData^.samplerate)-PByte(GlobalWATData);
  SIDArray[siChannels   ].dofs := PByte(@GlobalWATData^.channels  )-PByte(GlobalWATData);
  SIDArray[siVBR        ].dofs := PByte(@GlobalWATData^.vbr       )-PByte(GlobalWATData);
  SIDArray[siLength     ].dofs := PByte(@GlobalWATData^.length    )-PByte(GlobalWATData);
  // video part
  SIDArray[siCodec      ].dofs := PByte(@GlobalWATData^.codec     )-PByte(GlobalWATData);
  SIDArray[siWidth      ].dofs := PByte(@GlobalWATData^.width     )-PByte(GlobalWATData);
  SIDArray[siHeight     ].dofs := PByte(@GlobalWATData^.height    )-PByte(GlobalWATData);
  SIDArray[siFPS        ].dofs := PByte(@GlobalWATData^.fps       )-PByte(GlobalWATData);
  // changing player info
  SIDArray[siWindow     ].dofs := PByte(@GlobalWATData^.window    )-PByte(GlobalWATData);
  SIDArray[siWinamp     ].dofs := PByte(@GlobalWATData^.winamp    )-PByte(GlobalWATData);
  SIDArray[siStatus     ].dofs := PByte(@GlobalWATData^.status    )-PByte(GlobalWATData);
end;
{$ENDIF}

initialization
  CreateIniFile(watini,PAnsiChar('watrack.ini'),true);

  TemplateFunc  :=@DummyTemplate;
  ErrorFunc     :=@DummyError;

  GlobalWATData:=pSongInfo(WATCreate());
{$IFDEF UseOffsets}
  InitIndexes;
{$ENDIF}

finalization
  WATFree(UIntPtr(GlobalWATData));

  //----- Close INI file -----
  watini.Flush;
  FreeIniFile(watini);
end.
