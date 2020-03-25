unit optmyshows;

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, SpinEx, Buttons, ComCtrls;

type

  { TMyShowsForm }

  TMyShowsForm = class(TForm)
    bbApply: TBitBtn;
    bScrobbleNow: TButton;
    gbLogin: TGroupBox;
    imgCover: TImage;
    lScrobbling: TLabel;
    lScrobblePos: TLabel;
    lAttempts: TLabel;
    leLogin: TLabeledEdit;
    lePassword: TLabeledEdit;
    seAttempts: TSpinEdit;
    tbScrobblePos: TTrackBar;
    MyshowsTimer: TTimer;
    tbbScrobble: TToggleBox;
    procedure bbApplyClick(Sender: TObject);
    procedure bScrobbleNowClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MyshowsTimerTimer(Sender: TObject);
    procedure tbbScrobbleChange(Sender: TObject);
    procedure tbScrobblePosChange(Sender: TObject);
  private

  public

  end;

var
  MyShowsForm: TMyShowsForm;


implementation

uses
  common,
  cmemini,
  wat_api,
  wat_myshows;

{$R *.lfm}

const
  DefTimerValue = 10*60*1000; // 10 minutes

{
const
  msh_on:integer=0;

const
  WATMyshows :PAnsiChar='myshows';
  opt_ModStatus:PAnsiChar = 'module/myshows';
  optScrobble:pAnsiChar='scrobble';

function GetModStatus:integer;
var
  sect:pINISection;
begin
  sect:=watini.Sections[WATMyshows];
  result:=sect^.ReadInt(opt_ModStatus,1);

  msh_on:=sect^.ReadInt(optScrobble,0);
end;

procedure SetModStatus(stat:integer);
var
  sect:pINISection;
begin
  sect:=watini.Sections[WATMyshows];
  sect^.WriteInt(opt_ModStatus,stat);

  sect^.WriteInt(optScrobble,msh_on and 1);
end;
}
{
const
  kinopoisk_info = 'http://www.kinopoisk.ru/level/1/film/';

procedure ClearData(var MSData:TMyShowsData);
begin
  mFreeMem(MSData.series);
  mFreeMem(MSData.series_id);
  mFreeMem(MSData.kinopoisk_id);
  mFreeMem(MSData.episode);
  mFreeMem(MSData.episode_id);
  mFreeMem(MSData.info);
  mFreeMem(MSData.image);
  FillChar(MSData,SizeOf(MSData),0);
end;
}

{ TMyShowsForm }
resourcestring
  sScrobblePos   = 'Scrobble at ';
  sStopScrobble  = 'Stop';
  sStartScrobble = 'Start';

procedure TMyShowsForm.FormCreate(Sender: TObject);
begin
  leLogin.Text          :=msh_login;
  lePassword.Text       :=msh_password;
  seAttempts.Value      :=msh_tries;
  tbScrobblePos.Position:=msh_scrobpos;
  tbbScrobble.Caption:=sStartScrobble;
end;

function ThScrobble(param:pointer):ptrint;
var
  count:integer;
begin
  result:=0;
  count:=msh_tries;
  repeat
    dec(count);
    if Scrobble({count<=0})<>WAT_RES_ERROR then break;
  until count<=0;
end;

procedure TMyShowsForm.MyshowsTimerTimer(Sender: TObject);
begin
  MyShowsForm.MyShowsTimer.Enabled:=false;

  if (msh_login   <>nil) and (msh_login^   <>#0) and
     (msh_password<>nil) and (msh_password^<>#0) then
    BeginThread(@ThScrobble,nil);
end;

procedure TMyShowsForm.tbbScrobbleChange(Sender: TObject);
begin
  tbbScrobble.Checked:=not tbbScrobble.Checked;

  if tbbScrobble.Checked then
    tbbScrobble.Caption:=sStopScrobble
  else
    tbbScrobble.Caption:=sStartScrobble;
end;

procedure TMyShowsForm.tbScrobblePosChange(Sender: TObject);
begin
  // change label caption
  lScrobblePos.Caption:=sScrobblePos + IntToStr(tbScrobblePos.Position) + '%';
end;

procedure TMyShowsForm.bbApplyClick(Sender: TObject);
begin
  mFreeMem(msh_login   );
  StrDup(msh_login,PAnsiChar(leLogin.Text));
  mFreeMem(msh_password);
  StrDup(msh_password,PAnsiChar(lePassword.Text));

  msh_tries   :=seAttempts.Value;
  msh_scrobpos:=tbScrobblePos.Position;

  SaveMyShowsOpt;
end;

procedure TMyShowsForm.bScrobbleNowClick(Sender: TObject);
begin
  Scrobble;
end;


// ------------ base interface functions -------------

procedure Action(si:UIntPtr;res:integer);
var
  timervalue:integer;
begin
  if (res and WAT_RES_NEWFILE)<>0 then
  begin
    MyShowsForm.MyShowsTimer.Enabled:=false;

    if WATGet(si,siWidth)>0 then // for video only
    begin
      if MyShowsForm.tbbScrobble.Checked then
      begin
        timervalue:=WATGet(si,siLength)*10*msh_scrobpos; // 1000(msec) div 100(%)
        if timervalue=0 then
          timervalue:=DefTimerValue;
        MyShowsForm.MyShowsTimer.Interval:=timervalue;
        MyShowsForm.MyShowsTimer.Enabled :=true;
      end;
    end;
  end;

  if (res and WAT_RES_NEWSTATUS)<>0 then
  begin
    case WATGet(si,siStatus) of
      WAT_PLS_STOPPED,
      WAT_PLS_NOTFOUND: begin
        MyShowsForm.MyShowsTimer.Enabled:=false;
      end;
    end;
  end;
end;

function AddOptionsPage(var cnt:integer):pointer;
begin
  cnt:=0;
  MyShowsForm:=TMyShowsForm.Create(Application);
  result:=MyShowsForm;
end;

function InitProc(aInit:boolean):integer;
begin
  result:=0;
  if aInit then
    LoadMyShowsOpt
  else
  begin
    MyShowsForm.MyShowsTimer.Enabled:=false;

    FreeMyShowsOpt;
  end;
end;

var
  mmyshows:twModule;

procedure Init;
begin
  mmyshows.Next      :=ModuleLink;
  mmyshows.Init      :=@InitProc;
  mmyshows.AddOption :=@AddOptionsPage;
  mmyshows.Action    :=@Action;
  mmyshows.ModuleName:='MyShows.me';
  ModuleLink         :=@mmyshows;
end;

begin
  Init;
end.
