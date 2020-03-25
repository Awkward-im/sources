unit wat_template;

interface

uses
  wat_api;

//----- macro codes, names, descriptions -----

resourcestring
  swndtext    = 'player window title';
  sartist     = 'artist';
  stitle      = 'song title';
  salbum      = 'album';
  sgenre      = 'genre';
  sfile       = 'media file name';
  skbps       = 'bitrate';
  strack      = 'track number';
  schannels   = 'number of channels';
  smono       = '"mono"/"stereo"';
  skhz        = 'samplerate';
  stotal      = 'total song length (sec)';
  syear       = 'song year (date)';
  stime       = 'current song position (sec)';
  spercent    = 'time/length * 100%';
  scomment    = 'comment from tag';
  splayer     = 'player name';
  sversion    = 'player version';
  ssize       = 'media file size';
  stype       = 'media file type';
  svbr        = 'VBR or not (empty)';
  sstatus     = 'player status (stopped,playing,paused)';
  sfps        = 'FPS (frames per second), video only';
  scodec      = 'codec, video only';
  swidth      = 'width, video only';
  sheight     = 'height, video only';
  stxtver     = 'player version in text format';
  slyric      = 'lyric from ID3v2 tag';
  scover      = 'cover file path';
  svolume     = 'player volume (0-15)';
  splayerhome = 'player homepage URL';
  snstatus    = 'player status (not translated)';

const
  numvars = 35;

const
  vars:array [0..numvars-1] of record
    name :AnsiString;
    alias:AnsiString;
    help :AnsiString;
  end = (
{00} (name:'wndtext'   ; alias:''; help:swndtext),
{01} (name:'artist'    ; alias:''; help:sartist),
{02} (name:'title'     ; alias:''; help:stitle),
{03} (name:'album'     ; alias:''; help:salbum),
{04} (name:'genre'     ; alias:''; help:sgenre),
{05} (name:'file'      ; alias:''; help:sfile),
{06} (name:'kbps'      ; alias:''; help:skbps),
{07} (name:'bitrate'   ; alias:''; help:skbps),
{08} (name:'track'     ; alias:''; help:strack),
{09} (name:'channels'  ; alias:''; help:schannels),
{10} (name:'mono'      ; alias:''; help:smono),
{11} (name:'khz'       ; alias:''; help:skhz),
{12} (name:'samplerate'; alias:''; help:skhz),
{13} (name:'total'     ; alias:''; help:stotal),
{14} (name:'length'    ; alias:''; help:stotal),
{15} (name:'year'      ; alias:''; help:syear),
{16} (name:'time'      ; alias:''; help:stime),
{17} (name:'percent'   ; alias:''; help:spercent),
{18} (name:'comment'   ; alias:''; help:scomment),
{19} (name:'player'    ; alias:''; help:splayer),
{20} (name:'version'   ; alias:''; help:sversion),
{21} (name:'size'      ; alias:''; help:ssize),
{22} (name:'type'      ; alias:''; help:stype),
{23} (name:'vbr'       ; alias:''; help:svbr),
{24} (name:'status'    ; alias:''; help:sstatus),
{25} (name:'fps'       ; alias:''; help:sfps),
{26} (name:'codec'     ; alias:''; help:scodec),
{27} (name:'width'     ; alias:''; help:swidth),
{28} (name:'height'    ; alias:''; help:sheight),
{29} (name:'txtver'    ; alias:''; help:stxtver),
{30} (name:'lyric'     ; alias:''; help:slyric),
{31} (name:'cover'     ; alias:''; help:scover),
{32} (name:'volume'    ; alias:''; help:svolume),
{33} (name:'playerhome'; alias:''; help:splayerhome),
{34} (name:'nstatus'   ; alias:''; help:snstatus)
  );

//----- Options -----

const
  tmplLoCaseType  :integer=0;
  tmplWriteCBR    :integer=0;
  tmplReplaceSpc  :integer=0;
  tmplFSizeMode   :integer=1024*1024;
  tmplFSizePost   :integer=2;
  tmplFSPrecision :integer=2;
  tmplPlayerCaps  :integer=0;
  tmplDoTranslate :integer=1;

procedure LoadTemplateOpt;
procedure SaveTemplateOpt;
procedure FreeTemplateOpt; // not needs really (AnsiString is autofree)

//----- Service function -----

function WATReplace(Info:UIntPtr; const atmpl:AnsiString):AnsiString;


implementation

uses
  sysutils,
  common,cmemini;

// --- data ---
const
  mn_wndtext    = 0;
  mn_artist     = 1;
  mn_title      = 2;
  mn_album      = 3;
  mn_genre      = 4;
  mn_file       = 5;
  mn_kbps       = 6;
  mn_bitrate    = 7;
  mn_track      = 8;
  mn_channels   = 9;
  mn_mono       = 10;
  mn_khz        = 11;
  mn_samplerate = 12;
  mn_total      = 13;
  mn_length     = 14;
  mn_year       = 15;
  mn_time       = 16;
  mn_percent    = 17;
  mn_comment    = 18;
  mn_player     = 19;
  mn_version    = 20;
  mn_size       = 21;
  mn_type       = 22;
  mn_vbr        = 23;
  mn_status     = 24;
  mn_fps        = 25;
  mn_codec      = 26;
  mn_width      = 27;
  mn_height     = 28;
  mn_txtver     = 29;
  mn_lyric      = 30;
  mn_cover      = 31;
  mn_volume     = 32;
  mn_playerhome = 33;
  mn_nstatus    = 34;


//===== Options =====

const
  opt_LoCaseType:PAnsiChar = 'locase';
  opt_FSPrec    :PAnsiChar = 'precision';
  opt_FSizePost :PAnsiChar = 'fsizepost';
  opt_FSizeMode :PAnsiChar = 'fsizemode';
  opt_WriteCBR  :PAnsiChar = 'writecbr';
  opt_ReplaceSpc:PAnsiChar = 'replacespc';
  opt_PlayerCaps:PAnsiChar = 'playercaps';
  opt_Translate :PAnsiChar = 'translate';

  WATTemplates  :PAnsiChar = 'templates';
  WATAliases    :PAnsiChar = 'alias';

//----- Aliases -----

// maybe use names for aliases, not numbers?
procedure SaveAliases;
var
  buf:array [0..31] of AnsiChar;
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[WATAliases];
  for i:=0 to numvars-1 do
  begin
    sect^.WriteString(IntToStr(buf,i),vars[i].alias);
  end;
end;

procedure LoadAliases;
var
  buf:array [0..31] of AnsiChar;
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[WATAliases];
  for i:=0 to numvars-1 do
    vars[i].alias:=sect^.ReadString(IntToStr(buf,i),'');
end;

//----- Main options -----

procedure LoadTemplateOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATTemplates];

  tmplPlayerCaps :=sect^.ReadInt(opt_PlayerCaps,0);
  tmplLoCaseType :=sect^.ReadInt(opt_LoCaseType,0);
  tmplReplaceSpc :=sect^.ReadInt(opt_ReplaceSpc,1);
  tmplFSPrecision:=sect^.ReadInt(opt_FSPrec    ,0);
  tmplFSizePost  :=sect^.ReadInt(opt_FSizePost ,0);
  tmplFSizeMode  :=sect^.ReadInt(opt_FSizeMode ,1);
  tmplWriteCBR   :=sect^.ReadInt(opt_WriteCBR  ,0);
  tmplDoTranslate:=sect^.ReadInt(opt_Translate ,0);

  LoadAliases;
end;

procedure SaveTemplateOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATTemplates];

  sect^.WriteInt(opt_PlayerCaps,tmplPlayerCaps);
  sect^.WriteInt(opt_LoCaseType,tmplLoCaseType);
  sect^.WriteInt(opt_ReplaceSpc,tmplReplaceSpc);
  sect^.WriteInt(opt_FSPrec    ,tmplFSPrecision);
  sect^.WriteInt(opt_FSizePost ,tmplFSizePost);
  sect^.WriteInt(opt_FSizeMode ,tmplFSizeMode);
  sect^.WriteInt(opt_WriteCBR  ,tmplWriteCBR);
  sect^.WriteInt(opt_Translate ,tmplDoTranslate);

  SaveAliases;
end;

procedure FreeTemplateOpt;
var
  i:integer;
begin
  for i:=0 to numvars-1 do
    vars[i].alias:='';
end;

//===== Macro processing =====

resourcestring
  ssplStopped = 'stopped';
  ssplPlaying = 'playing';
  ssplPaused  = 'paused';
  schMono     = 'mono';
  schStereo   = 'stereo';
const
  splStopped:AnsiString = 'stopped';
  splPlaying:AnsiString = 'playing';
  splPaused :AnsiString = 'paused';
  chMono    :AnsiString = 'mono';
  chStereo  :AnsiString = 'stereo';
  ch51      :AnsiString = '5.1';
  chVBR     :AnsiString = 'VBR';
  chCBR     :AnsiString = 'CBR';

{
 11025
 22050
 44100
 48000

 64
 96
 112
 128
 160
 224
 256
 288
 320
}

procedure CharReplace(var dst:AnsiString;old,new:AnsiChar);
var
  i:integer;
begin
  if dst<>'' then
  begin
    for i:=1 to Length(dst) do
    begin
      if dst[i]=old then dst[i]:=new;
    end;
  end;
end;

procedure Replace(var dst:AnsiString; amacro:integer; const avalue:AnsiString);
var
  pc:AnsiString;
begin
  with vars[amacro] do
    if alias='' then
      pc:=name
    else
      pc:=alias;

  dst:=StringReplace(dst,'%'+pc+'%',avalue,[rfReplaceAll]);
end;

function ReplaceAll(Info:UIntPtr; const s:AnsiString):AnsiString;
var
  las:array [0..31] of AnsiChar;
  pp:AnsiString;
  ls:AnsiString;
  tmpstr:AnsiString;
  i:integer;
  tmp:integer;
begin
  ls:=StringReplace(s,'{tab}',#9,[rfReplaceAll]);

  //----- Physical data -----

  Replace(ls,mn_height ,IntToStr(las,WATGet(Info,siHeight)));
  Replace(ls,mn_width  ,IntToStr(las,WATGet(Info,siWidth)));

  // fps
  tmp:=WATGet(Info,siFPS);
  IntToStr(las,tmp div 100);
  i:=0;
  repeat
    inc(i);
  until las[i]=#0;
  las[i]:='.';
  IntToStr(PAnsiChar(@las[i+1]),tmp mod 100);
  Replace(ls,mn_fps,las);

  // bitrate
  Replace(ls,mn_kbps,IntToStr(las,WATGet(Info,siBitrate)));
  Replace(ls,mn_bitrate,las);
  // vbr
  if WATGet(Info,siVBR)<>0 then
    tmpstr:=chVBR
  else if tmplWriteCBR=0 then
    tmpstr:=''
  else
    tmpstr:=chCBR;
  Replace(ls,mn_vbr,tmpstr);

  // samplerate
  Replace(ls,mn_khz,IntToStr(las,WATGet(Info,siSamplerate)));
  Replace(ls,mn_samplerate,las);

  // channels
  tmp:=WATGet(Info,siChannels);
  Replace(ls,mn_channels,IntToStr(las,tmp));
  case tmp of
    1:   if tmplDoTranslate<>0 then tmpstr:=schMono   else tmpstr:=chMono;
    2:   if tmplDoTranslate<>0 then tmpstr:=schStereo else tmpstr:=chStereo;
    5,6: tmpstr:=ch51;
  end;
  Replace(ls,mn_mono,tmpstr);

  //----- Tag data -----

  Replace(ls,mn_year ,WATGetString(Info,siYear));
  Replace(ls,mn_genre,WATGetString(Info,siGenre));
  Replace(ls,mn_track,IntToStr(las,WATGet(Info,siTrack)));
  Replace(ls,mn_lyric,WATGetString(Info,siLyric));
  Replace(ls,mn_cover,WATGetString(Info,siCover));

  tmpstr:=WATGetString(Info,siArtist);
  if tmplReplaceSpc<>0 then CharReplace(tmpstr ,'_',' ');
  Replace(ls,mn_artist,tmpstr);

  tmpstr:=WATGetString(Info,siTitle);
  if tmplReplaceSpc<>0 then CharReplace(tmpstr ,'_',' ');
  Replace(ls,mn_title,tmpstr);

  tmpstr:=WATGetString(Info,siAlbum);
  if tmplReplaceSpc<>0 then CharReplace(tmpstr ,'_',' ');
  Replace(ls,mn_album,tmpstr);

  tmpstr:=WATGetString(Info,siComment);
  if tmplReplaceSpc<>0 then CharReplace(tmpstr ,'_',' ');
  Replace(ls,mn_comment,tmpstr);

  //----- Player -----

  // player version
  Replace(ls,mn_txtver ,WATGetString(Info,siTextVersion));
  Replace(ls,mn_version,IntToHex(las,WATGet(Info,siVersion)));

  // player name
  tmpstr:=WATGetString(Info,siPlayer);
  case tmplPlayerCaps of
    1: Replace(ls,mn_player,system.LowerCase(tmpstr));
    2: Replace(ls,mn_player,UpCase(tmpstr));
  else
    Replace(ls,mn_player,tmpstr);
  end;
  Replace(ls,mn_playerhome,WATGetString(Info,siURL));

  // player status
  case WATGet(Info,siStatus) of
    WAT_PLS_PLAYING: begin
      if tmplDoTranslate<>0 then tmpstr:=ssplPlaying else tmpstr:=splPlaying;
      pp:=splPlaying;
    end;
    WAT_PLS_PAUSED : begin
      if tmplDoTranslate<>0 then tmpstr:=ssplPaused  else tmpstr:=splPaused;
      pp:=splPaused;
    end;
  else {WAT_PLS_STOPPED:}
      if tmplDoTranslate<>0 then tmpstr:=ssplStopped else tmpstr:=splStopped;
      pp:=splStopped;
  end;
  Replace(ls,mn_status ,tmpstr);
  Replace(ls,mn_nstatus,pp);

  // volume
  Replace(ls,mn_volume,IntToStr(las,word(WATGet(Info,siVolume))));

  //----- File data -----

  // file size
  Replace(ls,mn_size,
    IntToK(las,WATGet(Info,siSize),
    tmplFSizeMode,tmplFSPrecision,tmplFSizePost));

  // file name
  tmpstr:=WATGetString(Info,siFile);
  Replace(ls,mn_file,tmpstr);

  // file type
  GetExt(PAnsiChar(tmpstr),las);
  if tmplLoCaseType<>0 then
    system.LowerCase(las)
  else
    system.UpCase(las);
  Replace(ls,mn_type,las);

  // codec
  tmp:=WATGet(Info,siCodec);
  las[0]:=AnsiChar( tmp and $FF);
  las[1]:=AnsiChar((tmp shr  8) and $FF);
  las[2]:=AnsiChar((tmp shr 16) and $FF);
  las[3]:=AnsiChar((tmp shr 24) and $FF);
  las[4]:=#0;
  Replace(ls,mn_codec,las);

  // track length
  tmp:=WATGet(Info,siLength);
  Replace(ls,mn_length,IntToTime(las,tmp));
  Replace(ls,mn_total,las);

  //----- Realtime -----

  i:=WATGet(Info,siPosition);
  Replace(ls,mn_time,IntToTime(las,i));
  if tmp>0 then
    tmp:=(i*100) div tmp
  else
    tmp:=0;
  Replace(ls,mn_percent,IntToStr(las,tmp));

  tmpstr:=WATGetString(Info,siCaption);
  if tmplReplaceSpc<>0 then CharReplace(tmpstr ,'_',' ');
  Replace(ls,mn_wndtext,tmpstr);

  result:=ls;
end;

//===== Service functions =====

function WATReplace(Info:UIntPtr; const atmpl:AnsiString):AnsiString;
begin
  if atmpl<>'' then
  begin
    result:=ReplaceAll(Info,atmpl);
  end
  else
    result:='';
end;

initialization
  TemplateFunc:=@WATReplace;

end.
