{WATrack global datas}
unit wat_basic;

interface

uses
  wat_api;

//----- Options -----

type
  twatOptions = (
    woKeepOld,
    woUseImplant,
    woCheckAll,
    woCheckUnknown,
    woCheckTime,
    woMMKeyEmu,
    woWinampFirst,
    woUseBASS
  );

var
  watOptions : set of twatOptions;

const
  defcoverpaths = 'cover.jpg'#13#10'..\cover.jpg'#13#10'*.jpg'#13#10'..\*.jpg';
  deftmplfile = 'player.ini';

var
  CoverPaths :AnsiString;
  TmplFile:AnsiString;

procedure SaveOpt;
procedure LoadOpt;

//----- Main functions for info obtaining -----

// info from file (mfile member)
function WATGetFileInfo(const fname:AnsiString; aOEM:boolean=false):UIntPtr; overload;
function WATGetFileInfo(      fname:PWideChar ):UIntPtr; overload;
function WATGetMusicInfo(Info:UIntPtr; aflags:cardinal):integer;


implementation

uses
  sysutils,
  common,
  cmemini,
  srv_player,
  srv_format,
  srv_getinfo
  {$include lst_players.inc}
  {$include lst_formats.inc}
  ;

//===== Option save/load =====

//----- section names -----

const
  optWATFormats:PAnsiChar = 'formats';
  optWATPlayers:PAnsiChar = 'players';
  optWATOptions:PAnsiChar = 'options';
  optWATGroups :PAnsiChar = 'groups';

//----- option key names -----

const
  opt_CheckTime  :PAnsiChar = 'checktime';
  opt_coverpaths :PAnsiChar = 'coverpaths';
  opt_Implantant :PAnsiChar = 'useimplantant';
  opt_KeepOld    :PAnsiChar = 'keepold';
  opt_mmkeyemu   :PAnsiChar = 'mmkeyemu';
  opt_CheckAll   :PAnsiChar = 'checkall';
  opt_CheckUnkn  :PAnsiChar = 'checkunknown';
  opt_WinampFirst:PAnsiChar = 'winampfirst';
  opt_UseBASS    :PAnsiChar = 'usebass';
  opt_DefTmplFile:PAnsiChar = 'deftmplfile';

//===== main options =====

procedure IntLoadOpt;
var
  sect:pINISection;
  pc:PAnsiChar;
begin
  sect:=watini.Section[optWATOptions];
  watOptions:=[];

  if sect^.ReadInt(opt_CheckTime  ,1)<>0 then Include(watOptions,woCheckTime);
  if sect^.ReadInt(opt_Implantant ,0)<>0 then Include(watOptions,woUseImplant);
  if sect^.ReadInt(opt_KeepOld    ,0)<>0 then Include(watOptions,woKeepOld);
  if sect^.ReadInt(opt_CheckAll   ,0)<>0 then Include(watOptions,woCheckAll);
  if sect^.ReadInt(opt_CheckUnkn  ,0)<>0 then Include(watOptions,woCheckUnknown);
  if sect^.ReadInt(opt_mmkeyemu   ,0)<>0 then Include(watOptions,woMMKeyEmu);
  if sect^.ReadInt(opt_WinampFirst,0)<>0 then Include(watOptions,woWinampFirst);
  if sect^.ReadInt(opt_UseBASS    ,0)<>0 then Include(watOptions,woUseBASS);

  pc:=sect^.Key[opt_coverpaths];
  if pc=nil then
    CoverPaths:=defcoverpaths
  else
    CoverPaths:=pc;

  pc:=sect^.Key[opt_DefTmplFile];
  if pc=nil then
    TmplFile:=deftmplfile
  else
    TmplFile:=pc;
end;

procedure IntSaveOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[optWATOptions];

  sect^.WriteInt(opt_CheckTime  ,ORD(woCheckTime    in watOptions));
  sect^.WriteInt(opt_Implantant ,ORD(woUseImplant   in watOptions));
  sect^.WriteInt(opt_KeepOld    ,ORD(woKeepOld      in watOptions));
  sect^.WriteInt(opt_CheckAll   ,ORD(woCheckAll     in watOptions));
  sect^.WriteInt(opt_CheckUnkn  ,ORD(woCheckUnknown in watOptions));
  sect^.WriteInt(opt_mmkeyemu   ,ORD(woMMKeyEmu     in watOptions));
  sect^.WriteInt(opt_WinampFirst,ORD(woWinampFirst  in watOptions));
  sect^.WriteInt(opt_UseBASS    ,ORD(woUseBASS      in watOptions));

  sect^.WriteStr(opt_coverpaths ,PAnsiChar(CoverPaths));
  sect^.WriteStr(opt_DefTmplFile,PAnsiChar(TmplFile));
end;

//===== players =====

//----- write -----

procedure WriteGroups;
var
  sect:pINISection;
  lgroup:PAnsiChar;
  i:integer;
  lstatus:integer;
begin
  sect:=watini.Section[optWATGroups];
  i:=0;
  while GetGroupStatus(i,lgroup,lstatus) do
  begin
    sect^.WriteInt(lgroup,lstatus);
    inc(i);
  end;
end;

function enumwp(desc:PAnsiChar; alParam:pointer):boolean; stdcall;
var
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[optWATPlayers];
  i:=ServicePlayer(WAT_ACT_GETSTATUS,desc);
  if i=WAT_RES_ENABLED then
    i:=1
  else
    i:=0;
  sect^.WriteInt(desc,i);

  result:=true;
end;

//----- read -----

procedure ReadGroups;
var
  sect:pINISection;
  lgroup:PAnsiChar;
begin
  sect:=watini.Section[optWATGroups];
  lgroup:=sect^.ParameterList;
  if lgroup<>nil then
  begin
    while lgroup^<>#0 do
    begin
      SetGroupStatus(lgroup,sect^.ReadInt(lgroup,1));
      lgroup:=StrEnd(lgroup)+1;
    end;
  end;
end;

function enumrp(desc:PAnsiChar; alParam:pointer):boolean; stdcall;
var
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[optWATPlayers];
  i:=sect^.ReadInt(desc,1);
  if i=1 then
    i:=WAT_ACT_ENABLE
  else
    i:=WAT_ACT_DISABLE;
  ServicePlayer(i,desc);

  result:=true;
end;

//===== formats =====

//----- write -----

function enumwf(fmt:pMusicFormat; alParam:pointer):boolean; stdcall;
var
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[optWATFormats];
  if (fmt^.flags and WAT_OPT_DISABLED)=0 then
    i:=1
  else
    i:=0;
  sect^.WriteInt(fmt^.ext,i);

  result:=true;
end;

//----- read -----

function enumrf(fmt:pMusicFormat; alParam:pointer):boolean; stdcall;
var
  sect:pINISection;
  i:integer;
begin
  sect:=watini.Section[optWATFormats];
  i:=sect^.ReadInt(fmt^.ext,1);
  if i=1 then
    i:=WAT_ACT_ENABLE
  else
    i:=WAT_ACT_DISABLE;
  ServiceFormat(i,@(fmt^.ext));

  result:=true;
end;

//===== Main functions =====

procedure SaveOpt;
begin
  IntSaveOpt;
  EnumFormats(@enumwf,nil);
  EnumPlayers(@enumwp,nil);
  WriteGroups();
end;

procedure LoadOpt;
begin
  IntLoadOpt;

  srv_player.LoadFromFile(pointer(TmplFile));

  EnumPlayers(@enumrp,nil);
  EnumFormats(@enumrf,nil);

  ReadGroups();
  ResortGroups;
end;

//===== Services =====

//----- Support functions -----

function GetCover(const mfile:AnsiString):AnsiString;
var
  fdata:TSearchRec;
  wr:AnsiString;
  i,j:integer;
begin
  result:='';
  if CoverPaths='' then exit;

  i:=1;
  repeat
    j:=i;
    while (i<=Length(CoverPaths)) and (CoverPaths[i]>=' ') do inc(i);
    if i>j then
    begin
      wr:=Copy(CoverPaths,j,i-j);
      wr:=TemplateFunc(0,wr);

      if not isPathAbsolute(PAnsiChar(wr)) then
        wr:=ExtractFilePath(mfile)+wr;

      if FindFirst(wr,faAnyFile,fdata)=0 then
      begin
        result:=ExpandFileName(ExtractFilePath(wr)+fdata.Name);
      end;
      FindClose(fdata);
      if result<>'' then break;
    end;

    while (i<Length(CoverPaths)) and (CoverPaths[i]<' ') do inc(i);

  until i>=Length(CoverPaths);
end;

function GetLyric(const mfile:AnsiString):AnsiString;
var
  f:file of byte;
  size:integer;
begin
  result:='';

  AssignFile(f,ChangeFileExt(mfile,'.txt'));
  {$I-}
  {$IFOPT I-}
  Reset(f);
  if IOResult()<>0 then
  begin
  {$ELSE}
  try
    Reset(f);
  except
  {$ENDIF}
    exit;
  end;

  size:=FileSize(f);
  if size>0 then
  begin
    SetLength(result,size+1);
    BlockRead(f,result[1],size);
    result[size+1]:=#0;
  end;
  CloseFile(f);
end;

//===== main services =====

// Get file info (name in dst.mfile), return info in same structure
function WATIntGetFileInfo(Info:UIntPtr):UIntPtr;
var
  fname:AnsiString;
begin
  if GetFileFormatInfo(Info)<>WAT_RES_NOTFOUND then
  begin
    fname:=WATGetString(Info,siFile);

    WATSet(Info,siDate,FileAge (fname));
    WATSet(Info,siSize,FileSize(fname));
    if WATIsEmpty(Info,siCover) then WATSetString(Info,siCover,GetCover(fname));
    if WATIsEmpty(Info,siLyric) then WATSetString(Info,siLyric,GetLyric(fname));
    result:=WAT_RES_OK;
  end
  else
    result:=UIntPtr(WAT_RES_ERROR);
end;

function WATGetFileInfo(const fname:AnsiString; aOEM:boolean=false):UIntPtr;
var
  Info:UIntPtr;
  cp:integer;
begin
  result:=UIntPtr(WAT_RES_ERROR);

  if fname='' then exit;

  Info:=WATCreate();

  if aOEM then
    cp:=CP_OEMCP
  else if IsTextUTF8(pointer(fname)) then
  	cp:=CP_UTF8
  else
    cp:=CP_ACP;
  WATSetStr(Info,siFile, pointer(fname),cp);
{
  if IsLatin(pointer(fname)) then
    WATSetStr(Info,siFile, pointer(fname),CP_UTF8)
  else
  begin
    WATSetStr(Info,siFile, pointer(fname),CP_ACP);
  end;
}
  if WATIntGetFileInfo(Info)=WAT_RES_OK then
    result:=Info
  else
    WATFree(Info);
end;

function WATGetFileInfo(fname:PWideChar):UIntPtr;
var
  Info:UIntPtr;
begin
  result:=UIntPtr(WAT_RES_ERROR);

  if fname=nil then exit;

  Info:=WATCreate();

  WATSetStr(Info,siFile, fname,CP_UTF16);

  if WATIntGetFileInfo(Info)=WAT_RES_OK then
    result:=Info
  else
    WATFree(Info);
end;

// fill si with current song info; aflags can be WAT_INF_* values
function WATGetMusicInfo(Info:UIntPtr; aflags:cardinal):integer;
const
  giused:cardinal=0;
var
  p,lcover:AnsiString;
  flags:cardinal;

  isnewplayer,
  isnewstatus,
  isnewtrack :longbool;

  NewPlStatus,OldPlStatus:integer;
begin
  result:=WAT_RES_NOTFOUND;

  //----- Return old info if main timer -----
  if giused<>0 then
  begin
    result:=WAT_RES_OK;
//    if @(si)<>nil then  pointer(si):=ReturnInfo(aflags and $FF);
    exit;
  end;

  giused:=1;

  OldPlStatus:=WATGet(Info,siStatus);

  isnewstatus:=false;
  isnewtrack :=false;

  //----- Checking player -----

  flags:=0;
  if (woCheckAll in watOptions) then flags:=flags or WAT_OPT_CHECKALL;

  result:=GetPlayerInfo(Info,flags);

  NewPlStatus:=WATGet(Info,siStatus);

  isnewplayer:=result=WAT_RES_NEWPLAYER;
  if isnewplayer then
    result:=WAT_RES_OK;

  //----- Checking player status -----

  if result=WAT_RES_OK then
  begin
    // player stopped - no need file info
    if NewPlStatus=WAT_PLS_STOPPED then
    begin
      isnewstatus:=OldPlStatus<>WAT_PLS_STOPPED;
    end
    //----- Get file (no file, new file, maybe new) -----
    else
    begin
      // file info will be replaced (name most important only)
      flags:=0;
      if (woCheckUnknown in watOptions) then flags:=flags or WAT_OPT_UNKNOWNFMT;
      if (woCheckTime    in watOptions) then flags:=flags or WAT_OPT_CHECKTIME;
      if (woUseImplant   in watOptions) then flags:=flags or WAT_OPT_IMPLANTANT;
      if (woKeepOld      in watOptions) then flags:=flags or WAT_OPT_KEEPOLD;

      // requirement - old file name
      result:=GetFileInfo(Info,flags,0);

      if (NewPlStatus=WAT_PLS_UNKNOWN ) and  // player in unknown state
         (result     =WAT_RES_NOTFOUND) then // and known media not found
      begin
        NewPlStatus:=WAT_PLS_STOPPED;
        WATSet(Info,siStatus,WAT_PLS_STOPPED);
      end;

      isnewstatus:=OldPlStatus<>NewPlStatus;

      // now time for changes (window text, volume)
      // just when music presents
      if NewPlStatus<>WAT_PLS_STOPPED then
      begin
        GetChangingInfo(Info,flags);
        // full info requires
        // "no music" case blocked
{??
       WorkSI.status=WAT_PLS_PLAYING and result=WAT_RES_UNKNOWN
}
        p:=WATGetString(Info,siFile);
        if (result=WAT_RES_NEWFILE) or           // new file
           (result=WAT_RES_UNKNOWN) or           // unknown file (enabled by flag in GetFileInfo)
           (
            (result=WAT_RES_OK) and              // if not new but...
            (
             ((aflags and WAT_INF_CHANGES)=0) or // ... ask for full info
             (Pos('://',p)<>0) or                // ... or remote file
             isContainer(p)                      // ... or container like CUE
            )
           ) then
        begin
          // requirement: old artist/title for remote files
          isnewtrack:=result=WAT_RES_NEWFILE;
          result:=GetInfo(Info,flags);
          if not isnewtrack then
            isnewtrack:=result=WAT_RES_NEWFILE;
        end;
      end;
    end;

  end
  //----- Player not found -----
  else
  begin
    if OldPlStatus<>NewPlStatus then
    begin
      NewPlStatus:=WAT_PLS_NOTFOUND;
      WATSet(Info,siStatus,WAT_PLS_NOTFOUND);
      isnewstatus:=true;
    end;
  end;

  //----- Copy all data to public (WorkSI to SongInfo) -----

  if NewPlStatus=WAT_PLS_NOTFOUND then
  begin
    ClearInfoData(Info);
  end
  else
  begin
    if (NewPlStatus=WAT_PLS_STOPPED) or // no music
       (result=WAT_RES_NOTFOUND) then   // or unknown media file
    begin
      ClearFileInfo    (Info);
      ClearChangingInfo(Info);
      ClearTrackInfo   (Info);
    end
    else
    begin
      if isnewtrack then
      begin
        p:=WATGetString(Info,siFile);
        // lyric
        if WATIsEmpty(Info,siLyric) then WATSetString(Info,siLyric,GetLyric(p));

        // covers
        if WATIsEmpty(Info,siCover) then WATSetString(Info,siCover,GetCover(p))
        else
        begin
          lcover:=WATGetString(Info,siCover);
          p:=GetTempDir(true);
          if AnsiStrLComp(PAnsiChar(p),PAnsiChar(lcover),Length(p))=0 then
          begin
            p:=p+'wat_cover'+ExtractFileExt(lcover);
            DeleteFile(p);        // system.Erase (f)
            RenameFile(lcover,p); // system.Rename(f,lcover);
            WATSetString(Info,siCover,p);
          end;
        end;

      end;
    end;

  end;
  
  //----- Set extended status -----

//  if result = WAT_RES_OK then
  begin
    if isnewplayer then result:=result or WAT_RES_NEWPLAYER;
    if isnewstatus then result:=result or WAT_RES_NEWSTATUS;
    if isnewtrack  then result:=result or WAT_RES_NEWFILE;
  end;

  giused:=0;
end;


initialization

  ProcessFormatLink;
  ProcessPlayerLink;

finalization

end.
