{}
unit wat_lastfm;

interface

type
  PLastFMInfo = ^TLastFMInfo;
  // real encoding is UTF8
  TLastFMInfo = record
//    request:cardinal;   // 0 - artist, 1 - album, 2 - track
    artist :PAnsiChar; // artist
    album  :PAnsiChar; // album or similar artists for Artist info request
    title  :PAnsiChar; // track title
    tags   :PAnsiChar; // tags
    info   :PAnsiChar; // artist bio or wiki article
    image  :PAnsiChar; // photo/cover link
    similar:PAnsiChar;
    release:PAnsiChar;
    trknum :cardinal;
  end;

const
  lfm_tries   :integer=0;
  lfm_pos     :integer=3;
  lfm_lang    :integer=0;
  lfm_login   :pAnsiChar=nil;
  lfm_password:pAnsiChar=nil;

procedure SaveLastFMOpt;
procedure LoadLastFMOpt;
procedure FreeLastFMOpt;

function GetArtistInfo(var data:tLastFMInfo;lang:integer):integer;
function GetAlbumInfo (var data:tLastFMInfo;lang:integer):integer;
function GetTrackInfo (var data:tLastFMInfo;lang:integer):integer;

function SendNowPlaying:integer;
function Scrobble:integer;
function HandShake(login, password:PAnsiChar; notify:boolean=false):boolean;


implementation

uses
//  windows,
  datetime,

  fphttpclient,
  md5,
  common,
  cmemini,
  wat_api;

//===== Options =====

const
  optLogin   :pAnsiChar='login';
  optPassword:pAnsiChar='password';
  optTries   :pAnsiChar='tries';
  optPos     :pAnsiChar='pos';
  optScrobble:pAnsiChar='scrobble';
  optLanguage:pAnsiChar='language';
  WATLastFM  :PAnsiChar='lastfmapi';

const
  session_id  :pAnsiChar=nil;
  np_url      :pAnsiChar=nil;
  sub_url     :pAnsiChar=nil;


procedure SaveLastFMOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATLastFM];
  sect^.Key[optPassword]:=lfm_password;
  sect^.Key[optLogin   ]:=lfm_login;
  sect^.WriteInt(optTries   ,lfm_tries);
  sect^.WriteInt(optLanguage,lfm_lang);
  sect^.WriteInt(optPos     ,lfm_pos);
end;

procedure LoadLastFMOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATLastFM];
  lfm_lang :=sect^.ReadInt(optLanguage,0);
  lfm_tries:=sect^.ReadInt(optTries   ,3);
  lfm_pos  :=sect^.ReadInt(optPos     ,3);
  mFreeMem(lfm_login   ); StrDup(lfm_login   ,sect^.Key[optLogin]);
  mFreeMem(lfm_password); StrDup(lfm_password,sect^.Key[optPassword]);
(*
  if (lfm_login=nil) or (lfm_password=nil) then
    CallService(MS_POPUP_SHOWMESSAGEW,
      WPARAM({TranslateW}('Don''t forget to enter Login and Password to use Last.fm service')),
      SM_WARNING);
*)
end;

procedure FreeLastFMOpt;
begin
  mFreeMem(lfm_login);
  mFreeMem(lfm_password);

  mFreeMem(session_id);
  mFreeMem(np_url);
  mFreeMem(sub_url);
end;

//===== LastFM API related =====

{
  Get Info based on currently played song
  wParam: pLastFMInfo
  lParam: int language (first 2 bytes - 2-letters language code)
}

resourcestring
  sError     = 'Last.fm error: ';
  sBanned    = 'Client is banned';
  sBadAuth   = 'Bad Auth. Check login and password';
  sTimestamp = 'Bad TimeStamp';

const
  client_id  = 'wat';//'wat'; 'tst'
  client_ver = '1.0';
  api_key    = '51f5d25159da31b0814609c3a12900e2';

const
  defreq = 'http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=<client-id>&v=<client-ver>&u=<user>&t=<timestamp>&a=<auth>';
  scraddr = 'http://ws.audioscrobbler.com/2.0/';

function GetMD5Str(const digest:TMD5Digest; buf:pAnsiChar):PAnsiChar;
begin
  buf[00]:=HexDigitChrLo[digest[00] shr 4]; buf[01]:=HexDigitChrLo[digest[00] and $0F];
  buf[02]:=HexDigitChrLo[digest[01] shr 4]; buf[03]:=HexDigitChrLo[digest[01] and $0F];
  buf[04]:=HexDigitChrLo[digest[02] shr 4]; buf[05]:=HexDigitChrLo[digest[02] and $0F];
  buf[06]:=HexDigitChrLo[digest[03] shr 4]; buf[07]:=HexDigitChrLo[digest[03] and $0F];
  buf[08]:=HexDigitChrLo[digest[04] shr 4]; buf[09]:=HexDigitChrLo[digest[04] and $0F];
  buf[10]:=HexDigitChrLo[digest[05] shr 4]; buf[11]:=HexDigitChrLo[digest[05] and $0F];
  buf[12]:=HexDigitChrLo[digest[06] shr 4]; buf[13]:=HexDigitChrLo[digest[06] and $0F];
  buf[14]:=HexDigitChrLo[digest[07] shr 4]; buf[15]:=HexDigitChrLo[digest[07] and $0F];
  buf[16]:=HexDigitChrLo[digest[08] shr 4]; buf[17]:=HexDigitChrLo[digest[08] and $0F];
  buf[18]:=HexDigitChrLo[digest[09] shr 4]; buf[19]:=HexDigitChrLo[digest[09] and $0F];
  buf[20]:=HexDigitChrLo[digest[10] shr 4]; buf[21]:=HexDigitChrLo[digest[10] and $0F];
  buf[22]:=HexDigitChrLo[digest[11] shr 4]; buf[23]:=HexDigitChrLo[digest[11] and $0F];
  buf[24]:=HexDigitChrLo[digest[12] shr 4]; buf[25]:=HexDigitChrLo[digest[12] and $0F];
  buf[26]:=HexDigitChrLo[digest[13] shr 4]; buf[27]:=HexDigitChrLo[digest[13] and $0F];
  buf[28]:=HexDigitChrLo[digest[14] shr 4]; buf[29]:=HexDigitChrLo[digest[14] and $0F];
  buf[30]:=HexDigitChrLo[digest[15] shr 4]; buf[31]:=HexDigitChrLo[digest[15] and $0F];
  buf[32]:=#0;
  result:=@buf;
end;

function HandShake(login, password:PAnsiChar; notify:boolean=false):boolean;
var
  buf:array [0..32] of AnsiChar;
  digest:TMD5Digest;
  stat:TMD5Context;
  timestamp:array [0..31] of AnsiChar;
  request:array [0..511] of AnsiChar;
  tmp,res:pAnsiChar;
begin
  result:=false;
  GetMD5Str(MD5Buffer(password,StrLen(password)),@buf);

  MD5Init(stat);
  MD5Update(stat,buf,32);
  IntToStr(PAnsiChar(@timestamp),GetCurrentTimestamp);
  MD5Update(stat,timestamp,StrLen(timestamp));
  MD5Final(stat,digest);

  GetMD5Str(digest,buf);
  StrCopy(@request,defreq);
  StrReplace(request,'<client-id>' ,client_id);
  StrReplace(request,'<client-ver>',client_ver);
  StrReplace(request,'<user>'      ,login);
  StrReplace(request,'<timestamp>' ,timestamp);
  StrReplace(request,'<auth>'      ,buf);

  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(request)));

  if (res<>nil) and (UIntPtr(res)>$0FFF) then
  begin
    if StrCmp(CharReplace(res,#10,#0),'OK')=0 then
    begin
      result:=true;
      tmp:=StrEnd(res)+1; StrDup(session_id,tmp);
      tmp:=StrEnd(tmp)+1; StrDup(np_url    ,tmp);
      tmp:=StrEnd(tmp)+1; StrDup(sub_url   ,tmp);
    end
    else if notify then
    begin
      tmp:=StrCopyE(request,PAnsiChar(sError));
      if      StrCmp(res,'BANNED'  )=0 then StrCopy(tmp,PAnsiChar(sError))
      else if StrCmp(res,'BADAUTH' )=0 then StrCopy(tmp,PAnsiChar(sBadAuth))
      else if StrCmp(res,'BADTIME' )=0 then StrCopy(tmp,PAnsiChar(sTimeStamp))
      else if StrCmp(res,'FAILED',6)=0 then StrCopy(tmp,res+7);

      ErrorFunc('Last.FM',@request,true);
    end;
    mFreeMem(res);
  end;
end;

function Encode(dst,src:pAnsiChar):PAnsiChar;
begin
  while src^<>#0 do
  begin
    if not (src^ in [' ','%','+','&','?',#128..#255]) then
      dst^:=src^
    else
    begin
      dst^:='%'; inc(dst);
      dst^:=HexDigitChr[ord(src^) shr 4]; inc(dst);
      dst^:=HexDigitChr[ord(src^) and $0F];
    end;
    inc(src);
    inc(dst);
  end;
  dst^:=#0;
  result:=dst;
end;

function SendNowPlaying:integer;
var
  si:pSongInfo;
  buf    :array [0..31  ] of AnsiChar;
  args   :array [0..1023] of AnsiChar;
  res,pc:PAnsiChar;
begin
  result:=-1;
  if session_id<>nil then
  begin
//!!    si:=0;

    pc:=@args;
{}  pc:=StrCopyE(@args,np_url); pc^:='?'; inc(pc);

    pc:=StrCopyE(pc,'s='); pc:=StrCopyE(pc,session_id); //'?s='
    pc:=StrCopyE(pc,'&a=');

    if si^.artist=nil then pc:=StrCopyE(pc,'Unknown')
    else                   pc:=Encode(pc,si^.artist);
    pc:=StrCopyE(pc,'&t=');

    if si^.title =nil then pc:=StrCopyE(pc,'Unknown')
    else                   pc:=Encode(pc,si^.title);

    pc:=StrCopyE(pc,'&b='); pc:=Encode(pc,si^.album);

    pc:=StrCopyE(pc,'&l=');
    if si^.total>0 then
      pc:=StrCopyE(pc,IntToStr(PAnsiChar(@buf),si^.total));
    pc:=StrCopyE(pc,'&n=');
    if si^.track<>0 then
      {pc:=}StrCopyE(pc,IntToStr(PAnsiChar(@buf),si^.track));

{}  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(args)));
{
    res:=SendRequest(np_url,REQUEST_POST,args);
}

    if (res<>nil) and (UIntPtr(res)>$0FFF) then
    begin
      if StrCmp(CharReplace(res,#10,#0),'OK')=0 then
        result:=1
      else if StrCmp(res,'BADSESSION')=0 then
        result:=-1;
      mFreeMem(res);
    end;
  end;
end;

function Scrobble:integer;
var
  si:pSongInfo;
  buf,timestamp:array [0..31] of AnsiChar;
  args   :array [0..1023] of AnsiChar;
  res,pc:PAnsiChar;
begin
  result:=WAT_RES_ERROR;

  if session_id<>nil then
  begin
//!!    si:=GlobalInfoFunc(CP_UTF8);
    IntToStr(PAnsiChar(@timestamp),GetCurrentTimestamp);

    pc:=@args;
{}  pc:=StrCopyE(@args,sub_url); pc^:='?'; inc(pc);
    pc:=StrCopyE(pc,'s='  ); pc:=StrCopyE(pc,session_id);

    pc:=StrCopyE(pc,'&a[0]=');
    if si^.artist=nil then pc:=StrCopyE(pc,'Unknown')
    else                   pc:=Encode(pc,si^.artist);

    pc:=StrCopyE(pc,'&t[0]=');
    if si^.title =nil then pc:=StrCopyE(pc,'Unknown')
    else                   pc:=Encode(pc,si^.title);

    pc:=StrCopyE(pc,'&b[0]='); pc:=Encode(pc,si^.album);

    pc:=StrCopyE(pc,'&i[0]='); pc:=StrCopyE(pc,timestamp);
    pc:=StrCopyE(pc,'&r[0]=&m[0]=');
    pc:=StrCopyE(pc,'&l[0]=');
    if si^.total>0 then
    begin
      pc:=StrCopyE(pc,IntToStr(PAnsiChar(@buf),si^.total));
      pc:=StrCopyE(pc,'&o[0]=P');
    end
    else
    begin
      pc:=StrCopyE(pc,'&o[0]=R');
    end;
    pc:=StrCopyE(pc,'&n[0]=');
    if si^.track<>0 then
      {pc:=}StrCopyE(pc,IntToStr(PAnsiChar(@buf),si^.track));

{}  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(args)));
{
    res:=SendRequest(sub_url,REQUEST_POST,args);
}
    res:=nil;

    if (res<>nil) and (UIntPtr(res)>$0FFF) then
    begin
      if StrCmp(CharReplace(res,#10,#0),'OK')=0 then
        result:=1
      else if StrCmp(res,'BADSESSION')=0 then
      begin
        result:=-1;
      end
      else if StrCmp(res,'FAILED',6)=0 then
      begin
        StrCopy(StrCopyE(@args,PAnsiChar(sError)),res+7);
        ErrorFunc('Last.FM',@args);
        result:=0;
      end;
      mFreeMem(res);
    end;

  end;
end;

//----- Get Info service functions -----

function FullEncode(dst,src:pAnsiChar):PAnsiChar;
begin
  while src^<>#0 do
  begin
    if src^ in ['A'..'Z','a'..'z','0'..'9'] then
      dst^:=src^
    else
    begin
      dst^:='%'; inc(dst);
      dst^:=HexDigitChr[ord(src^) shr 4]; inc(dst);
      dst^:=HexDigitChr[ord(src^) and $0F];
    end;
    inc(src);
    inc(dst);
  end;
  dst^:=#0;
  result:=dst;
end;

function FixInfo(Info:pWideChar):pWideChar;
var
  pc,ppc:pWideChar;
  cnt:cardinal;
  need:boolean;
begin
  pc:=Info;
  cnt:=0;
  need:=false;
  while pc^<>#0 do
  begin
    if pc^=#$0D then
    begin
      inc(cnt);
      inc(pc);
      if pc^<>#$0A then
        need:=true;
    end
    else
      inc(pc);
  end;
  if need then
  begin
    mGetMem(result,(StrLenW(Info)+1+cnt)*SizeOf(WideChar));
    pc:=Info;
    ppc:=result;
    while pc^<>#0 do
    begin
      ppc^:=pc^;
      if pc^=#$0D then
      begin
        inc(ppc);
        ppc^:=#$0A;
      end;
      inc(pc);
      inc(ppc);
    end;
    ppc^:=#0;
  end
  else
    StrDupW(result,Info);
end;

{
var
  xmlparser:TXML_API_W;
}

function GetArtistInfo(var data:tLastFMInfo;lang:integer):integer;
var
  si:pSongInfo;
  res,pc:pAnsiChar;
  request:array [0..1023] of AnsiChar;
//  root,actnode,node,nnode:HXML;
  i:integer;
  pcw,p,pp:PWideChar;
  artist:pAnsiChar;
begin
  result:=0;

  if data.artist=nil then
  begin
//!!    si:=GlobalInfoFunc(CP_UTF8);
    artist:=si^.artist;
  end
  else
    artist:=data.artist;
  if artist=nil then
    exit;
  pc:=FullEncode(StrCopyE(@request,
      'http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key='+api_key+'&artist='),
      artist);

  if lang<>0 then
    StrCopyE(StrCopyE(pc,'&lang='),pAnsiChar(@lang));

  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(request)));

  if (res<>nil) and (UIntPtr(res)>$0FFF) then
  begin
    UTF8ToWide(res,pcw);
    mFreeMem(res);
{
    xml:=awkXML.CreateDocument;
    xmlRd.LoadFromBuffer(res,xml);

    actnode:=pNodeType(xml^.FirstChild)^.FirstChild; // "artist"

    if data.artist=nil then
      StrDupW(data.artist,actnode^.child['name']. {getText(GetNthChild(actnode,'name',0)))};

    i:=0;
    repeat
      node:=GetNthChild(actnode,'image',i);
      if node=0 then break;
      if StrCmpW(GetAttrValue(node,'size'),'medium')=0 then
      begin
        WideToUTF8(GetText(node),data.image);
        break;
      end;
      inc(i);
    until false;
}
    // bio
    // or search corresponding node with ntCData type
    p:=StrPosW(pcw,'<content><![CDATA[');
    if p<>nil then
    begin
      inc(p,18);
      pp:=StrPosW(p,']]');
      if pp<> nil then pp^:=#0;
      data.info:=FixInfo(p);
    end;
{
    // similar
    i:=0;
    pcw:=pWideChar(@request); pcw^:=#0;
    // node:=GetNthChild(actnode,'similar',0);
    node:=actnode^.child['similar'];
    repeat
      nnode:=GetNthChild(GetNthChild(node,'artist',i),'name',0);
      if nnode=0 then break;
      if pcw<>@request then
      begin
        pcw^:=','; inc(pcw);
        pcw^:=' '; inc(pcw);
      end;
        pcw:=StrCopyEW(pcw,GetText(nnode));
      inc(i);
    until false;
    pcw:=#0;
    StrDupW(data.similar,pWideChar(@request));

    // tags
    i:=0;
    pcw:=pWideChar(@request); pcw^:=#0;
//    node:=GetNthChild(actnode,'tags',0);
    node:=actnode^.child['tags'];
    repeat
      nnode:=GetNthChild(GetNthChild(node,'tag',i),'name',0);
      if nnode=0 then break;
      if pcw<>@request then
      begin
        pcw^:=','; inc(pcw);
        pcw^:=' '; inc(pcw);
      end;
        pcw:=StrCopyEW(pcw,GetText(nnode));
      inc(i);
    until false;
    pcw:=#0;
    StrDupW(data.tags,pWideChar(@request));
    DestroyNode(root);
}
  end;
end;

function GetAlbumInfo(var data:tLastFMInfo;lang:integer):integer;
var
  si:pSongInfo;
  res,pc:pAnsiChar;
  request:array [0..1023] of AnsiChar;
//  root,actnode,node,nnode:HXML;
  i:integer;
  p,pp,pcw:PWideChar;
  album,artist:pAnsiChar;
begin
  result:=0;

  si:=nil;
  if data.album=nil then
  begin
//!!    si:=GlobalInfoFunc(CP_UTF8);
    album:=si^.album;
  end
  else
    album:=data.album;
  if album=nil then
    exit;

  pc:=FullEncode(StrCopyE(@request,
     'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key='+api_key+'&album='),
     album);

  if data.artist=nil then
  begin
    if si=nil then
//!!      si:=GlobalInfoFunc(CP_UTF8);
    artist:=si^.artist;
  end
  else
    artist:=data.artist;
  if artist<>nil then
  begin
    pc:=FullEncode(StrCopyE(pc,'&artist='),artist);
  end;

  if lang<>0 then
    StrCopyE(StrCopyE(pc,'&lang='),pAnsiChar(@lang));

  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(request)));

  if res<>nil then
  begin
    UTF8ToWide(res,pcw);
    mFreeMem(res);
{
    xmlparser.cbSize:=SizeOf(TXML_API_W);
    CallService(MS_SYSTEM_GET_XI,0,lparam(@xmlparser));
    with xmlparser do
    begin
      i:=StrLenW(pcw)*SizeOf(WideChar);
      root:=parseString(pcw,@i,nil);

      actnode:=getChild(getChild(root,0),0); // "album"

      if data.album=nil then
        StrDupW(data.album,getText(GetNthChild(actnode,'name',0)));
      StrDupW(data.release,getText(GetNthChild(actnode,'releasedate',0)));
      if data.artist=nil then
        StrDupW(data.artist,getText(GetNthChild(actnode,'artist',0)));

      i:=0;
      repeat
        node:=GetNthChild(actnode,'image',i);
        if node=0 then break;
        if StrCmpW(GetAttrValue(node,'size'),'medium')=0 then
        begin
          WideToUTF8(GetText(node),data.image);
          break;
        end;
        inc(i);
      until false;
}
      p:=StrPosW(pcw,'<content><![CDATA[');
      if p<>nil then
      begin
        inc(p,18);
        pp:=StrPosW(p,']]');
        if pp<> nil then pp^:=#0;
        data.info:=FixInfo(p);
      end;
{
      // tags
      i:=0;
      pcw:=pWideChar(@request); pcw^:=#0;
      node:=GetNthChild(actnode,'toptags',0);
      repeat
        nnode:=GetNthChild(GetNthChild(node,'tag',i),'name',0);
        if nnode=0 then break;
        if pcw<>@request then
        begin
          pcw^:=','; inc(pcw);
          pcw^:=' '; inc(pcw);
        end;
          pcw:=StrCopyEW(pcw,GetText(nnode));
        inc(i);
      until false;
      pcw:=#0;
      StrDupW(data.tags,pWideChar(@request));

      DestroyNode(root);
    end;
}
  end;

end;

function GetTrackInfo(var data:tLastFMInfo;lang:integer):integer;
var
  si:pSongInfo;
  res,pc:pAnsiChar;
  request:array [0..1023] of AnsiChar;
//  root,actnode,node,anode:HXML;
  i:integer;
  p,pp,pcw:PWideChar;
  title,artist:pAnsiChar;
begin
  result:=0;

  si:=nil;
  if data.title=nil then
  begin
//!!    si:=GlobalInfoFunc(CP_UTF8);
    PAnsiChar(title):=si^.title;
  end
  else
    PAnsiChar(title):=data.title;
  if title=nil then
    exit;
  pc:=FullEncode(StrCopyE(@request,
     'http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key='+api_key+'&track='),
     title);

  if data.artist=nil then
  begin
    if si=nil then
//!!      si:=GlobalInfoFunc(CP_UTF8);
    artist:=si^.artist;
  end
  else
    artist:=data.artist;
  if artist<>nil then
  begin
    pc:=FullEncode(StrCopyE(pc,'&artist='),artist);
  end;

  if lang<>0 then
    StrCopyE(StrCopyE(pc,'&lang='),pAnsiChar(@lang));

  StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(request)));

  if res<>nil then
  begin
    UTF8ToWide(res,pcw);
    mFreeMem(res);
{
    xmlparser.cbSize:=SizeOf(TXML_API_W);
    CallService(MS_SYSTEM_GET_XI,0,lparam(@xmlparser));
    with xmlparser do
    begin
      i:=StrLenW(pcw)*SizeOf(WideChar);
      root:=parseString(pcw,@i,nil);

      actnode:=getChild(getChild(root,0),0); // "track"
      if data.artist=nil then
        StrDupW(data.artist,getText(GetNthChild(GetNthChild(actnode,'artist',0),'name',0)));

      anode:=GetNthChild(actnode,'album',i);

      if data.album=nil then
        StrDupW(data.album,getText(GetNthChild(anode,'title',0)));

      data.trknum:=StrToInt(getAttrValue(anode,'position'));
      if data.title=nil then
        StrDupW(data.title,getText(GetNthChild(actnode,'name',0)));

      i:=0;
      repeat
        node:=GetNthChild(anode,'image',i);
        if node=0 then break;
        if StrCmpW(GetAttrValue(node,'size'),'medium')=0 then
        begin
          WideToUTF8(GetText(node),data.image);
          break;
        end;
        inc(i);
      until false;
}
      p:=StrPosW(pcw,'<content><![CDATA[');
      if p<>nil then
      begin
        inc(p,18);
        pp:=StrPosW(p,']]');
        if pp<> nil then pp^:=#0;
        data.info:=FixInfo(p);
      end;
{
      // tags
      i:=0;
      pcw:=pWideChar(@request); pcw^:=#0;
      node:=GetNthChild(actnode,'toptags',0);
      repeat
        anode:=GetNthChild(GetNthChild(node,'tag',i),'name',0);
        if anode=0 then break;
        if pcw<>@request then
        begin
          pcw^:=','; inc(pcw);
          pcw^:=' '; inc(pcw);
        end;
        pcw:=StrCopyEW(pcw,GetText(anode));
        inc(i);
      until false;
      pcw:=#0;
      StrDupW(data.tags,pWideChar(@request));

      DestroyNode(root);
    end;
}
  end;

end;

//=====  =====
{
function SrvLastFMInfo(awParam:WPARAM;alParam:LPARAM):integer;
var
  data:tLastFMInfo;
begin
  case awParam of
    0: result:=GetArtistInfo(data,alParam);
    1: result:=GetAlbumInfo (data,alParam);
    2: result:=GetTrackInfo (data,alParam);
  else
    result:=0;
  end;
end;
}
end.
