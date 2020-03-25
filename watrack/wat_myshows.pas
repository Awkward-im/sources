{}
unit wat_myshows;

interface

const
  msh_login   :pAnsiChar=nil;
  msh_password:pAnsiChar=nil;

type
  TMyShowsData = record
    series      :PAnsiChar;
    series_id   :PAnsiChar;
    kinopoisk_id:PAnsiChar;
    episode     :PAnsiChar;
    episode_id  :PAnsiChar;
    info        :PAnsiChar;
    image       :PAnsiChar;
  end;

var
  msh_tries,
//  msh_timeout,
  msh_scrobpos:integer;

  MSData:TMyShowsData;

procedure LoadMyShowsOpt;
procedure SaveMyShowsOpt;
procedure FreeMyShowsOpt;

function Scrobble:integer;


implementation

uses
  fphttpclient,
  jsontools, // fpjson, jsonparser,
  md5,
  common,
  cmemini,
  wat_api;

//===== Options =====

const
  session_id  :pAnsiChar=nil;
  np_url      :pAnsiChar=nil;
  sub_url     :pAnsiChar=nil;

const
  optLogin   :pAnsiChar='login';
  optPassword:pAnsiChar='password';
  optTries   :pAnsiChar='tries';
//  optTimeout :PAnsiChar='timeout';
  optScrobPos:pAnsiChar='scrobpos';
  optScrobble:pAnsiChar='scrobble';
  WATMyshows :PAnsiChar='myshows';

procedure SaveMyShowsOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATMyshows];
  sect^.Key[optPassword]:=msh_password;
  sect^.Key[optLogin   ]:=msh_login;
  sect^.WriteInt(optTries   ,msh_tries);
  sect^.WriteInt(optScrobPos,msh_scrobpos);
//  sect^.WriteInt(optTries   ,msh_timeout);
end;

procedure LoadMyShowsOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATMyshows];
//  msh_timeout :=sect^.ReadInt(optTimeout ,0);
  msh_scrobpos:=sect^.ReadInt(optScrobPos,30);
  msh_tries   :=sect^.ReadInt(optTries   ,3);
  mFreeMem(msh_login   ); StrDup(msh_login   ,sect^.Key[optLogin]);
  mFreeMem(msh_password); StrDup(msh_password,sect^.Key[optPassword]);
(*
  if (msh_login=nil) or (msh_password=nil) then
    CallService(MS_POPUP_SHOWMESSAGEW,
      WPARAM({TranslateW}('Don''t forget to enter Login and Password to use MyShows service')),
      SM_WARNING);
*)
end;

procedure FreeMyShowsOpt;
begin
  mFreeMem(msh_login);
  mFreeMem(msh_password);

  mFreeMem(session_id);
  mFreeMem(np_url);
  mFreeMem(sub_url);

//  mFreeMem(cookies); //!!
end;

//===== Cookies =====
{
const
  cookies:pAnsiChar=nil;

function ExtractCookies(resp:PNETLIBHTTPREQUEST):integer;
var
  cnt,len:integer;
  p,pc:pAnsiChar;
begin
  result:=0;

  mFreeMem(cookies);
  mGetMem(cookies,1024);

  pc:=cookies;
  for cnt:=0 to resp^.headersCount-1 do
  begin
    with resp^.headers^[cnt] do
      if StrCmp(szName,'Set-Cookie')=0 then
      begin
        len:=0;
        p:=szValue;
        while (p^<>#0) and (p^<>';') do
        begin
          inc(p);
          inc(len);
        end;
        if pc<>cookies then
        begin
          pc^:=';'; inc(pc);
          pc^:=' '; inc(pc);
        end;
        pc:=StrCopyE(pc,szValue,len);
        inc(result);
      end;
  end;
end;

function SendRequestCookies(url:PAnsiChar;useCookies:boolean):pAnsiChar;
var
  SS : TStringStream;

  
  nlu:TNETLIBUSER;
  req :TNETLIBHTTPREQUEST;
  resp:PNETLIBHTTPREQUEST;
  hTmpNetLib:THANDLE;
  nlh:array [0..10] of TNETLIBHTTPHEADER;
begin
  SS:=TStringStream.Create('');

  With TFPHTTPClient.Create(nil) do
    try

      if useCookies and (cookies<>nil) then
        Cookies.Text:=mycookies;

      KeepConnection := False;
      Get(AURL,SS);

      Result:=SS.Datastring;

      if not useCookies then
        mycookies:=Cookies.Text;

    finally
      SS.Free;
      Free;
    end;

  
  result:=nil;

  FillChar(req,SizeOf(req),0);
  req.cbSize     :=NETLIBHTTPREQUEST_V1_SIZE;//SizeOf(req);
  req.requestType:=REQUEST_GET;
  req.szUrl      :=url;
  req.flags      :=NLHRF_NODUMP or NLHRF_HTTP11;

  if useCookies and (cookies<>nil) then
  begin
    nlh[0].szName :='Cookie';
    nlh[0].szValue:=cookies;

    req.headers     :=@nlh;
    req.headersCount:=1;
  end;

  FillChar(nlu,SizeOf(nlu),0);
  nlu.cbSize          :=SizeOf(nlu);
  nlu.flags           :=NUF_HTTPCONNS or NUF_NOHTTPSOPTION or NUF_OUTGOING or NUF_NOOPTIONS;
  nlu.szSettingsModule:='dummy';
  hTmpNetLib:=CallService(MS_NETLIB_REGISTERUSER,0,lparam(@nlu));

  resp:=pointer(CallService(MS_NETLIB_HTTPTRANSACTION,hTmpNetLib,lparam(@req)));

  if resp<>nil then
  begin
    if resp^.resultCode=200 then
    begin
      if resp^.pData<>nil then
        StrDup(result,resp^.pData,resp^.dataLength)
      else
        result:=PAnsiChar(200);
      if not useCookies then
        ExtractCookies(resp);
    end
    else
    begin
      result:=pAnsiChar(int_ptr(resp^.resultCode and $0FFF));
    end;
    CallService(MS_NETLIB_FREEHTTPREQUESTSTRUCT,0,lparam(resp));
  end;

  CallService(MS_NETLIB_CLOSEHANDLE,hTmpNetLib,0);
end;
}

//===== MyShows API =====

//type  tDigest = array [0..15] of byte;
(*
const
  client_id  = 'wat';//'wat'; 'tst'
  client_ver = '1.0';
  api_key    = '51f5d25159da31b0814609c3a12900e2';
*)

resourcestring
  sError     = 'MyShows error: ';
  sAuth      = 'Authorization required'; 
  sWrong     = 'User name of password wrong';
  sNotFound  = 'Not found / wrong parameters';
  sQuery     = 'Wrong query parameters';
  sSomething = 'Something wrong!';


const API_URL = 'http://api.myshows.me/';

const
  defreq = API_URL+'profile/login?login=<login>&password=<password>';

procedure ShowError(code:integer);
var
  ppc:PAnsiChar;
begin
  case code of
    401: ppc:=PAnsiChar(sAuth);     // “ребуетс€ авторизаци€
    403: ppc:=PAnsiChar(sWrong);    // »м€ пользовател€ или пароль не подошли
    404: ppc:=PAnsiChar(sNotFound); // Ќе найдено, неправильные параметры
    500: ppc:=PAnsiChar(sQuery);    // параметр запроса отсутствует
  else
    ppc:=PAnsiChar(sSomething);
  end;
  ErrorFunc('MyShows',ppc,true);
end;

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

function Handshake(login, password:PAnsiChar):boolean;
var
  buf:array [0..32] of AnsiChar;
  digest:TMD5Digest;
  request:array [0..511] of AnsiChar;
  res:pAnsiChar;
  stat:TMD5Context;
begin
  result:=false;
  GetMD5Str(MD5Buffer(password,StrLen(password)),@buf);

  MD5Init  (stat);
  MD5Update(stat,buf,32);
  MD5Final (stat,digest);

  StrCopy(@request,defreq);
  StrReplace(@request,'<login>'   ,login);
  StrReplace(@request,'<password>',buf);
{
  res:=SendRequestCookies(request,false);
//  res:=SendRequest(request,REQUEST_GET);
}
  res:=nil;

  if res<>nil then
  begin
    if UIntPtr(res)<$0FFF then
    begin
      ShowError(IntPtr(res));
    end
    else
    begin
      result:=true;
      mFreeMem(res);
    end;
  end;
end;

function Encode(dst,src:pAnsiChar):PAnsiChar;
begin
  if src<>nil then
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

function SendMSRequest(request:pAnsiChar;doShowError:boolean):boolean;
var
  res:pAnsiChar;
begin
  result:=true;
{
  res:=SendRequestCookies(request,true);
}
  res:=nil;

  if (UIntPtr(res)<>200) and (UIntPtr(res)<$0FFF) then
  begin
//!!    if int_ptr(res)=401 then
    begin
      Handshake(msh_login,msh_password);
{
      res:=SendRequestCookies(request,true);
}
    end;
    if (UIntPtr(res)<$0FFF) then
      if (UIntPtr(res)<>200) and doShowError then
      begin
        ShowError(IntPtr(res));
        result:=false;
      end;
  end;
end;

function Scrobble:integer;
var
  buf:array [0..511] of AnsiChar;
//  bufw:array [0..511] of WideChar;
  res,pc:PAnsiChar;
  img,epId,shId:AnsiString;
//  imgw:pWideChar;
  jshow,jd: TJsonNode;
{
  jd:TJSONData;
  jshow:TJSONObject;
}
begin
  result:=WAT_RES_ERROR;

  Encode(@buf,WATGetStr(0,siFile));
  pc:=Extract(buf,true);
  
  // Episode search by filename
  StrCopy(StrCopyE(@buf,API_URL+'shows/search/file/?q='),pc);
  mFreeMem(pc);
  try
    StrDup(res,PAnsiChar(TFPHTTPClient.SimpleGet(buf)));
  except
    res:=nil;
  end;

  if UIntPtr(res)>$0FFF then
  begin
{
    jd:=GetJSON(res);

    jshow:=TJSONObject(jd).Objects['show'];
    shId:=jshow.Elements['id'].AsString;
    epId:=jshow.Objects['episodes'].Names[0];
    img :=jshow.Elements['image'].AsString;

    jd.Free;
}
    jd:=TJsonNode.Create;
    try
      if jd.TryParse(res) then
      begin
        jshow:=jd.Child('show');
        shId:=jshow.Child('id').Value;
        epId:=jshow.Child('episodes').Child(0).Name;

        img:=WatGetString(0,siCover);
        if img='' then
        begin
          img:=jshow.Child('image').AsString;
          if img<>'' then
            WatSetString(0,siCover,img);
        end;
      end;
    finally
      jd.Free;
    end;
  end
  else
  begin
//    if show and (res<>nil) then
      ShowError(IntPtr(res));
    exit;
  end;

(*
  // Show mark as "watching"
  pc:=StrCopyE(@buf,API_URL+'profile/shows/');
  FastWideToAnsiBuf(shId,pc);
  {!!json_free(shId);} mir_free(shId);
  StrCat(pc,'/watching');

  if SendMSRequest(buf,show) then
  begin
    // Episode check
    StrCopy(StrCopyE(@buf,API_URL+'profile/episodes/check/'),epId);
//      json_free(epId);        // !! cause memory error (no need for GetName?)
  //  StrCopy(request,API_URL+'profile/shows/');
    if SendMSRequest(buf,show) then
    begin

{
  TMyShowsData = record
    series      :PAnsiChar;
    series_id   :PAnsiChar;
    kinopoisk_id:PAnsiChar;
    episode     :PAnsiChar;
    episode_id  :PAnsiChar;
    info        :PAnsiChar;
    image       :PAnsiChar;
  end;
}
      //!! add option to show it??
      if ServiceExists(MS_POPUP_SHOWMESSAGEW)<>0 then
      begin
        jn:=json_get(jroot,'show');
        shId:=json_as_string(json_get(jn,'title'));

        jn:=json_get(jn,'episodes');
        jn:=json_get(jn,'episodes');
        pWideChar(epId):=json_as_string(json_get(jn,'title'));

{
  StrDup(MSData.series    ,shId); // +
  StrDup(MSData.series_id ,shId);
  StrDup(MSData.episode   ,epId); // +
  StrDup(MSData.episode_id,epId);
  StrDup(MSData.image     ,img ); //??
}
{
        mGetMem(pc,1024);
        StrCopyW(
          StrCopyEW(
            StrCopyEW(
              StrCopyEW(
                StrCopyEW(pWideChar(pc),'Show "'),
              shId),
            '"'#13#10'episode "'),
          pWideChar(epId)),
        '" checked');
        CallService(MS_POPUP_SHOWMESSAGEW,TWPARAM(pc),SM_NOTIFY);
        mFreeMem(pc);
}
  {!!json_free(shId);} mir_free(shId);
  {!!json_free(epId);} mir_free(epId);
      end;
      result:=true;
    end;
  end;

  json_delete(jroot);
*)
end;

end.
