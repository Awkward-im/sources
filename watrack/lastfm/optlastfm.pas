unit optlastfm;

{$include compilers.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, SpinEx, Buttons,

  wat_lastfm
  ;

type

  { TLastFMForm }

  TLastFMForm = class(TForm)
    bAlbum: TButton;
    bArtist: TButton;
    bbApply: TBitBtn;
    bTrack: TButton;
    cbLanguage: TComboBox;
    gbLogin: TGroupBox;
    gbInfo: TGroupBox;
    imgCover: TImage;
    lScrobble: TLabel;
    lScrobbling: TLabel;
    lAttempts: TLabel;
    leAlbum: TLabeledEdit;
    leArtist: TLabeledEdit;
    leLogin: TLabeledEdit;
    lePassword: TLabeledEdit;
    leTags: TLabeledEdit;
    leTrack: TLabeledEdit;
    lInfo: TLabel;
    lLanguage: TLabel;
    mInfo: TMemo;
    seAttempts: TSpinEdit;
    LastFMTimer: TTimer;
    seScrobblePos: TSpinEdit;
    tbbScrobble: TToggleBox;
    procedure bAlbumClick(Sender: TObject);
    procedure bArtistClick(Sender: TObject);
    procedure bbApplyClick(Sender: TObject);
    procedure bTrackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LastFMTimerTimer(Sender: TObject);
    procedure tbbScrobbleChange(Sender: TObject);
  private
    procedure FillInfo(const data:TLastFMInfo);

  public

  end;

var
  LastFMForm: TLastFMForm;


implementation

uses
  common,
  cmemini,
  wat_api;

{$R *.lfm}

const
  MaxLangs = 11;
  LangArray:array [0..MaxLangs-1] of record
    code:array [0..1] of AnsiChar;
    name:pWideChar;
  end= (
    (code:#0#0 ; name: 'no language';),
    (code:'zh' ; name: 'Chinese'    ;),
    (code:'en' ; name: 'English'    ;),
    (code:'fr' ; name: 'French'     ;),
    (code:'de' ; name: 'German'     ;),
    (code:'hi' ; name: 'Hindi'      ;),
    (code:'it' ; name: 'Italian'    ;),
    (code:'ja' ; name: 'Japanese'   ;),
    (code:'pt' ; name: 'Portuguese' ;),
    (code:'ru' ; name: 'Russian'    ;),
    (code:'es' ; name: 'Spanish'    ;)
  );

{
const
  opt_ModStatus:PAnsiChar = 'module/lastfm';
  WATLastFM    :PAnsiChar = 'lastfm';

function GetModStatus:integer;
var
  sect:pINISection;
begin
  sect:=watini.Sections[WATLastFM];
  result:=sect^.ReadInt(opt_ModStatus,1);
end;

procedure SetModStatus(stat:integer);
var
  sect:pINISection;
begin
  sect:=watini.Sections[WATLastFM];
  sect^.WriteInt(opt_ModStatus,stat);
end;
}

{ TLastFMForm }

resourcestring
  sSimilar       = 'Similar artists';
  sAlbum         = 'Album';
  sStopScrobble  = 'Stop';
  sStartScrobble = 'Start';


procedure TLastFMForm.FormCreate(Sender: TObject);
var
  i,j:integer;
begin
  leLogin.Text       :=lfm_login;
  lePassword.Text    :=lfm_password;
  seAttempts.Value   :=lfm_tries;
  seScrobblePos.Value:=lfm_pos;
  tbbScrobble.Caption:=sStartScrobble;

  j:=0;
  for i:=0 to MaxLangs-1 do
    with LangArray[i] do
    begin
      cbLanguage.Items.Add(name);
      if lfm_lang=word(code) then
        j:=i;
    end;
  cbLanguage.ItemIndex:=j;
end;

function ThScrobble(param:pointer):ptrint;
var
  count:integer;
  npisok:boolean;
begin
  result:=0;

  count:=lfm_tries;
  npisok:=false;
  while count>0 do
  begin
    if not npisok then
      npisok:=SendNowPlaying>=0;
    if Scrobble>=0 then break;
    HandShake(lfm_login,lfm_password, count=1); // just last time
    dec(count);
  end;
  if count=0 then ;
end;

procedure TLastFMForm.LastFMTimerTimer(Sender: TObject);
begin
  LastFMForm.LastFMTimer.Enabled:=false;

  if (lfm_login   <>nil) and (lfm_login^   <>#0) and
     (lfm_password<>nil) and (lfm_password^<>#0) then
    BeginThread(@ThScrobble,nil);
end;

procedure TLastFMForm.tbbScrobbleChange(Sender: TObject);
begin
  tbbScrobble.Checked:=not tbbScrobble.Checked;

  if tbbScrobble.Checked then
    tbbScrobble.Caption:=sStopScrobble
  else
    tbbScrobble.Caption:=sStartScrobble;
end;

procedure TLastFMForm.bbApplyClick(Sender: TObject);
begin
  mFreeMem(lfm_login   );
  StrDup(lfm_login,PAnsiChar(leLogin.Text));
  mFreeMem(lfm_password);
  StrDup(lfm_password,PAnsiChar(lePassword.Text));

  lfm_tries:=seAttempts.Value;
  lfm_lang :=word(LangArray[cbLanguage.ItemIndex].code);
  lfm_pos  :=seScrobblePos.Value;

  SaveLastFMOpt;
end;

procedure ClearData(var data:TLastFMInfo);
begin
  mFreeMem(data.artist);
  mFreeMem(data.album);
  mFreeMem(data.title);
  mFreeMem(data.tags);
  mFreeMem(data.info);
  mFreeMem(data.image);
end;

{
function LoadImageURL(url:PAnsiChar;size:integer=0):HBITMAP;
var
  nlu:TNETLIBUSER;
  req :TNETLIBHTTPREQUEST;
  resp:PNETLIBHTTPREQUEST;
  hNetLib:THANDLE;
  im:TIMGSRVC_MEMIO;
begin
  result:=0;
  if (url=nil) or (url^=#0) then
    exit;

  FillChar(req,SizeOf(req),0);
  req.cbSize     :=NETLIBHTTPREQUEST_V1_SIZE;//SizeOf(req);
  req.requestType:=REQUEST_GET;
  req.szUrl      :=url;
  req.flags      :=NLHRF_NODUMP;

  FillChar(nlu,SizeOf(nlu),0);
  nlu.cbSize          :=SizeOf(nlu);
  nlu.flags           :=NUF_HTTPCONNS or NUF_NOHTTPSOPTION or NUF_OUTGOING or NUF_NOOPTIONS;
  nlu.szSettingsModule:='dummy';
  hNetLib:=CallService(MS_NETLIB_REGISTERUSER,0,lparam(@nlu));

  resp:=pointer(CallService(MS_NETLIB_HTTPTRANSACTION,hNetLib,lparam(@req)));

  if resp<>nil then
  begin
    if resp^.resultCode=200 then
    begin
      im.iLen :=resp^.dataLength;
      im.pBuf :=resp^.pData;
      im.flags:=size shl 16;
      im.fif  :=FIF_JPEG;
      result  :=CallService(MS_IMG_LOADFROMMEM,wparam(@im),0);
//      if result<>0 then
//        DeleteObject(SendMessage(wnd,STM_SETIMAGE,IMAGE_BITMAP,result)); //!!
    end;
    CallService(MS_NETLIB_FREEHTTPREQUESTSTRUCT,0,lparam(resp));
  end;
  CallService(MS_NETLIB_CLOSEHANDLE,hNetLib,0);
end;
}

procedure TLastFMForm.FillInfo(const data:TLastFMInfo);
begin
  leArtist.Text   :=data.artist;
  leTrack.Text    :=data.title;
  leTags.Text     :=data.tags;
  mInfo.Lines.Text:=data.info;

//  imgCover.Picture.LoadFromFile();
{
  bmp:=LoadImageURL(data.image,64);
  if bmp<>0 then
    DeleteObject(SendDlgItemMessage(Dialog,IDC_DATA_PIC,STM_SETIMAGE,IMAGE_BITMAP,bmp));
}
end;

procedure TLastFMForm.bArtistClick(Sender: TObject);
var
  data:TLastFMInfo;
begin
  leAlbum.EditLabel.Caption:=sSimilar;
  StrDup(data.artist,PAnsiChar(leArtist.Text));

  GetArtistInfo(data,lfm_lang);

  leAlbum.Text:=data.similar;
  FillInfo(data);
  ClearData(data);
end;

procedure TLastFMForm.bTrackClick(Sender: TObject);
var
  data:TLastFMInfo;
begin
  leAlbum.EditLabel.Caption:=sAlbum;
  StrDup(data.artist,PAnsiChar(leArtist.Text));
  StrDup(data.title ,PAnsiChar(leTrack.Text));

  GetTrackInfo(data,lfm_lang);

  leAlbum.Text:=data.Album;
  FillInfo(data);
  ClearData(data);
end;

procedure TLastFMForm.bAlbumClick(Sender: TObject);
var
  data:TLastFMInfo;
begin
  leAlbum.EditLabel.Caption:=sAlbum;
  StrDup(data.artist,PAnsiChar(leArtist.Text));
  StrDup(data.album ,PAnsiChar(leAlbum.Text));

  GetAlbumInfo(data,lfm_lang);

  leAlbum.Text:=data.album;
  FillInfo(data);
  ClearData(data);
end;

// ------------ base interface functions -------------

procedure Action(si:PSongInfo;res:integer;extres:cardinal);
begin
  if (res and WAT_RES_NEWFILE)<>0 then
  begin
    LastFMForm.LastFMTimer.Enabled:=false;
    if LastFMForm.tbbScrobble.Checked then
    begin
      LastFMForm.LastFMTimer.Interval:=lfm_pos;
      LastFMForm.LastFMTimer.Enabled :=true;
    end;
  end;

  if (res and WAT_RES_NEWSTATUS)<>0 then
  begin
    case WATGet(si,siStatus) of
      WAT_PLS_STOPPED,
      WAT_PLS_NOTFOUND: begin
        LastFMForm.LastFMTimer.Enabled:=false;
      end;
    end;
  end;
end;

function AddOptionsPage(var cnt:integer):pointer;
begin
  cnt:=0;
  LastFMForm:=TLastFMForm.Create(Application);
  result:=LastFMForm;
end;

function InitProc(aInit:boolean):integer;
begin
  result:=0;

  if aInit then
  begin
    result:=1;

    LoadLastFMOpt;
  end
  else
  begin
    LastFMForm.LastFMTimer.Enabled:=false;

    FreeLastFMOpt;
  end;
end;


var
  last:twModule;

procedure Init;
begin
  last.Next      :=ModuleLink;
  last.Init      :=@InitProc;
  last.AddOption :=@AddOptionsPage;
  last.Action    :=@Action;
  last.ModuleName:='Last.FM';
  ModuleLink     :=@last;
end;


begin
  Init;
end.
