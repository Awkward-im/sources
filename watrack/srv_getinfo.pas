{
  Get Info separated by parts
}
{$IFNDEF FPC}
  {$DEFINE Windows}
{$ENDIF}

unit srv_getinfo;

interface

uses wat_api;

//----- support procedures -----

{
  Fill winamp-API level info
}
procedure WinampGetInfo(Info:UIntPtr; aflags:cardinal);

{
  Search player and get current player info 
  plwnd,player,url
  winampwnd,plyver,txtver
}
function GetPlayerInfo(Info:UIntPtr; flags:cardinal):integer;
{
  WAT_RES_OK
  WAT_RES_NEWPLAYER
  WAT_RES_NOTFOUND
}

{
  Get file info from current player
  mfile,date,size
}
function GetFileInfo(Info:UIntPtr; flags:cardinal; timeout:cardinal):integer;
{
  WAT_RES_OK
  WAT_RES_NEWFILE
  WAT_RES_UNKNOWN
  WAT_RES_NOTFOUND
}

{
  Get changing info from current player
  wndtext,time,volume
}
function GetChangingInfo(Info:UIntPtr; flags:cardinal):integer;
{
  WAT_RES_OK
}

{
  Get track info from file in dst.mfile
}
function GetFileFormatInfo(Info:UIntPtr):integer;
{
  WAT_RES_OK
  WAT_RES_NOTFOUND
}

{
  Get track info from active player and file in dst.mfile
  (used GetFileFormatInfo)
}
function GetInfo(Info:UIntPtr; flags:cardinal):integer;
{
  WAT_RES_OK
  WAT_RES_NEWFILE
}


implementation

uses
{$IFDEF Windows}
  windows,
  msninfo,   // GetMSNInfo + tMSNInfo
  syswin,    // GetFileFromWnd
  winampapi, // WinampGetInfo
{$ENDIF}
  SysUtils,
  common,
  srv_player, srv_format;

//----- Winamp helpers -----

procedure WinampGetInfo(Info:UIntPtr; aflags:cardinal);
var
  pcw:PWideChar;
  buf:array [0..31] of AnsiChar;
  wnd:HWND;
begin
  wnd:=WATGet(Info,siWinamp);
  if wnd=0 then
    wnd:=WATGet(Info,siWindow);

  if (aflags and WAT_OPT_PLAYERDATA)<>0 then
  begin
    if WATIsEmpty(Info,siVersion) then
    begin
      WATSet   (Info,siVersion    ,winampapi.GetVersion(wnd));
      WATSetStr(Info,siTextVersion,winampapi.GetVersionText(wnd,@buf),CP_ACP);
    end;
  end
  else if (aflags and WAT_OPT_CHANGES)<>0 then
  begin
    if WATGet(Info,siStatus)<>WAT_PLS_STOPPED then
      WATSet(Info,siPosition,winampapi.GetElapsedTime(wnd));
    WATSet   (Info,siVolume, winampapi.GetVolume(wnd));
    pcw:=WinampGetWindowText(wnd);
    WATSetStr(Info,siCaption,pcw,CP_UTF16);
    mFreeMem(pcw);
  end
  else
  begin
    if WATIsEmpty(Info,siBitrate   ) then WATSet(Info,siBitrate   ,winampapi.GetBitrate   (wnd));
    if WATIsEmpty(Info,siSamplerate) then WATSet(Info,siSamplerate,winampapi.GetSamplerate(wnd));
    if WATIsEmpty(Info,siChannels  ) then WATSet(Info,siChannels  ,winampapi.GetChannels  (wnd));
    if WATIsEmpty(Info,siLength    ) then WATSet(Info,siLength    ,winampapi.GetTotalTime (wnd));
  end;
end;


//----- get player info -----

function DefGetVersionText(ver:cardinal):AnsiString;
var
  buf:array [0..31] of AnsiChar;
begin
  if ver<>0 then
  begin
    IntToHex(buf,ver);
    result:=buf;
  end
  else
    result:='';
end;


function GetPlayerInfo(Info:UIntPtr;flags:cardinal):integer;
var
  plwnd:THANDLE;
  pl:pPlayerCell;
  lstatus:integer;
  PlayerChanged:boolean;
begin
  plwnd:=CheckAllPlayers(flags,lstatus,PlayerChanged);
  WATSet(Info,siStatus,lstatus);

  if plwnd<>THANDLE(WAT_RES_NOTFOUND) then
  begin
    if PlayerChanged then
    begin
      ClearPlayerInfo(Info);

      pl:=GetActivePlayer;
      WATSet   (Info,siWindow,plwnd);
      WATSetStr(Info,siPlayer,pl^.Desc,CP_ACP);
      WATSetStr(Info,siURL   ,pl^.URL ,CP_ACP);

      if pl^.GetInfo<>nil then
        tInfoProc(pl^.GetInfo)(Info,flags or WAT_OPT_PLAYERDATA)
{$IFDEF Windows}
      else if (pl^.flags and WAT_OPT_WINAMPAPI)<>0 then
        WinampGetInfo(Info,flags or WAT_OPT_PLAYERDATA);
{$ELSE}
;
{$ENDIF}
        
     if WATIsEmpty(Info,siVersion) then
     begin
// http://forum.lazarus.freepascal.org/index.php?topic=13957
// http://wiki.freepascal.org/Show_Application_Title,_Version,_and_Company
     end;

     if (pl^.flags and WAT_OPT_PLAYERINFO)=0 then
       if WATIsEmpty(Info,siTextVersion) then
         WATSetString(Info,siTextVersion,DefGetVersionText(WATGet(Info,siVersion)));

      result:=WAT_RES_NEWPLAYER;
    end
    else
    begin
      WATSet(Info,siWindow,plwnd); // to prevent same player, another instance
      result:=WAT_RES_OK;
    end
  end
  else
    result:=WAT_RES_NOTFOUND;
end;

//----- get file info -----

type
  pCheckRecord = ^tCheckRecord;
  tCheckRecord = record
    ext:array [0..31] of AnsiChar;
    res:boolean;
  end;

function enumcf(fmt:pMusicFormat;cr:pointer):boolean; stdcall;
begin
  if StrCmp(fmt^.ext,pCheckRecord(cr)^.ext)=0 then
  begin
    pCheckRecord(cr)^.res:=(fmt^.flags and WAT_OPT_DISABLED)=0;
    result:=false;
  end
  else
    result:=true;
end;

function KnownFileType(fname:PWideChar):boolean;
var
  ext:array [0..31] of WideChar;
  cr:tCheckRecord;
begin
  cr.res:=false;
  GetExt(fname,ext);
  FastWideToAnsiBuf(ext,cr.ext);
  EnumFormats(@enumcf,@cr);
  result:=cr.res;
{
  result:=false;

  i:=FindExt(AnsiString(WideString(fname)));
  if i<>WAT_RES_NOTFOUND then
  begin
    if ((fmtLink^[i].flags and WAT_OPT_DISABLED)=0) then
      result:=true;
  end;
}
end;

//----- Get file info -----

function GetFileInfo(Info:UIntPtr; flags:cardinal; timeout:cardinal):integer;
var
  ftime:int64;
  fname:AnsiString;
  pl:pPlayerCell;
  remote,FileChanged:boolean;
  tmp:integer;
begin
  pl:=GetActivePlayer;

  if pl^.GetName<>nil then
  begin
    tNameProc(pl^.GetName)(Info,flags);
    fname:=WATGetString(Info,siFile);
  end
  else
    fname:='';

  if (fname='') and not WATIsEmpty(Info,siWindow) then
  begin
{$IFDEF Windows}
// SysWin
   tmp:=0;
   if (flags and WAT_OPT_KEEPOLD)<>0 then tmp:=tmp or gffdOld;
   fname:=GetFileFromWnd(WATGet(Info,siWindow),@KnownFileType,tmp,timeout);
{$ENDIF}
  end;

  ftime:=0;
  if fname<>'' then
  begin
    remote:=Pos('://',fname)<>0;
    // file changing time (local/lan only)
    if not remote then
      ftime:=FileAge(fname);

    // same file
    if WATIsEmpty(Info,siFile) and (AnsiCompareFileName(WATGetString(Info,siFile),fname)=0) then
    begin
      if (not remote) and ((flags and WAT_OPT_CHECKTIME)<>0) then
        FileChanged:=WATGet(Info,siDate)<>ftime
      else
        FileChanged:=false;
    end
    else  // new filename
    begin
      FileChanged:=true;
    end;

    // if not proper ext (we don't working with it)
    //!!!! check for remotes
    if (not remote) and (CheckExt(fname)=WAT_RES_NOTFOUND) then
    begin
      if (flags and WAT_OPT_UNKNOWNFMT)<>0 then
      begin
        ClearFileInfo(Info);

        WATSetString(Info,siFile,fname);
        WATSet      (Info,siDate,ftime);
        WATSet      (Info,siSize,FileSize(fname));

        result:=WAT_RES_UNKNOWN;
      end
      else
      begin
        fname:='';
        result:=WAT_RES_NOTFOUND;
      end;
    end
    else if FileChanged {or isContainer(fname)} then
    begin
      ClearFileInfo(Info);

//      WATSetString(Info,siFile,fname); //!! must be when format recognized or remote
//!! Same as ?
      WATSetStr(Info,siFile,pointer(fname),CP_UTF8);

      WATSet      (Info,siDate,ftime); //!!
      WATSet      (Info,siSize,FileSize(fname));

      result:=WAT_RES_NEWFILE;
    end
    else
    begin
      fname:='';
      result:=WAT_RES_OK;
    end;
  end
  else
  begin
    result:=WAT_RES_NOTFOUND;
  end;
end;

//----- get changing info -----

function GetChangingInfo(Info:UIntPtr;flags:cardinal):integer;
var
  pl:pPlayerCell;
begin
  result:=WAT_RES_OK;

  ClearChangingInfo(Info);

  pl:=GetActivePlayer;

  if pl^.GetInfo<>nil then
    tInfoProc(pl^.GetInfo)(Info,flags or WAT_OPT_CHANGES)
{$IFDEF Windows}
  else if (pl^.flags and WAT_OPT_WINAMPAPI)<>0 then
    WinampGetInfo(Info,flags or WAT_OPT_CHANGES);
{$ELSE}
;
{$ENDIF}
  if (pl^.flags and WAT_OPT_PLAYERINFO)=0 then
    if WATIsEmpty(Info,siCaption) then
      WATSetString(Info,siCaption,
        GetPlayerWindowText(pl,WATGet(Info,siWindow)));
end;

//----- Get track info -----

function GetFileFormatInfo(Info:UIntPtr):integer;
var
  fmt:pMusicFormat;
begin
  result:=CheckExt(WATGetString(Info,siFile));
  if result=WAT_RES_OK then
  begin
    fmt:=GetActiveFormat;
    fmt^.proc(Info);
  end;
end;

//----- get track and player info -----

function GetSeparator(const str:AnsiString):cardinal;
begin
  result:=Pos(' '#$2013' ',str);
  if result=0 then
    result:=Pos(' - ',str);
  if result<>0 then
  begin
    result:=result-1 + (3 SHL 16);
    exit;
  end;
  result:=Pos(#$2013,str);
  if result=0 then
    result:=Pos('-',str);
  if result>0 then
    result:=result-1 + (1 SHL 16);
end;

function DefGetTitle(const fname,wndtxt:AnsiString):AnsiString;
var
  i:cardinal;
begin
  if fname<>'' then
    result:=ExtractFileName(fname)
  else
    result:=wndtxt;

  if result<>'' then
  begin
    i:=GetSeparator(result);
    if i>0 then
      Delete(result,1,Word(i)+(i shr 16));
  end;
end;

function DefGetArtist(const fname,wndtxt:AnsiString):AnsiString;
var
  i:cardinal;
begin
  if fname<>'' then
    result:=ExtractFileName(fname)
  else
    result:=wndtxt;

  if result<>'' then
  begin
    i:=GetSeparator(result);
    if i>0 then
      SetLength(result,word(i));
  end;
end;


function GetInfo(Info:UIntPtr;flags:cardinal):integer;
var
  oldartist,oldtitle:AnsiString;
  tmpstr,fname:AnsiString;
  pl:pPlayerCell;
{$IFDEF Windows}
  lmsnInfo:pMSNInfo;
{$ENDIF}
  remote:boolean;
begin
  result:=WAT_RES_OK;

  remote:=Pos('://',WATGetString(Info,siFile))<>0;

//  if remote or ((plyLink^[0].flags and WAT_OPT_PLAYERINFO)<>0) then
  oldartist:=WATGetString(Info,siArtist);
  oldtitle :=WATGetString(Info,siTitle);

  ClearTrackInfo(Info);

  // info from player
  pl:=GetActivePlayer;
  if pl^.GetInfo<>nil then
    tInfoProc(pl^.GetInfo)(Info,flags and not WAT_OPT_CHANGES)
{$IFDEF Windows}
  else if (pl^.flags and WAT_OPT_WINAMPAPI)<>0 then
    WinampGetInfo(Info,flags and not WAT_OPT_CHANGES);
{$ELSE}
;
{$ENDIF}

  // info from file
  GetFileFormatInfo(Info);

  fname:=WATGetString(Info,siFile);
  if (pl^.flags and WAT_OPT_PLAYERINFO)=0 then
    if remote then
      fname:='';

{$IFDEF Windows}
  if WATIsEmpty(Info,siArtist) or
     WATIsEmpty(Info,siTitle ) or
     WATIsEmpty(Info,siAlbum ) then
  begin
    lmsnInfo:=GetMSNInfo;

    if lmsnInfo<>nil then
    begin
      if WATIsEmpty(Info,siArtist) then WATSetStr(Info,siArtist,lmsnInfo^.msnArtist,CP_UTF16);
      if WATIsEmpty(Info,siTitle ) then WATSetStr(Info,siTitle ,lmsnInfo^.msnTitle ,CP_UTF16);
      if WATIsEmpty(Info,siAlbum ) then WATSetStr(Info,siAlbum ,lmsnInfo^.msnAlbum ,CP_UTF16);
    end;
  end;
{$ENDIF}

  tmpstr:=WATGetString(Info,siCaption);
  if WATIsEmpty(Info,siArtist) then WATSetString(Info,siArtist,DefGetArtist(fname,tmpstr));
  if WATIsEmpty(Info,siTitle ) then WATSetString(Info,siTitle ,DefGetTitle (fname,tmpstr));

  if remote or ((pl^.flags and WAT_OPT_PLAYERINFO)<>0) or isContainer(fname) then
  begin
    if (oldartist=oldtitle) or
       ((oldartist<>'') and (WATGetString(Info,siArtist)<>oldartist)) or
       ((oldtitle <>'') and (WATGetString(Info,siTitle )<>oldtitle )) then
    begin
      result:=WAT_RES_NEWFILE;
    end;
  end;

end;


end.
