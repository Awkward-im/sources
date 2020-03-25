unit optStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  wat_stat;

type

  { TStatForm }

  TStatForm = class(TForm)
    bbApply: TBitBtn;
    btnLogFile: TButton;
    btnReportFile: TButton;
    btnTemplateFile: TButton;
    btnDelete: TButton;
    btnSort: TButton;
    btnReport: TButton;
    btnExport: TButton;
    cbOpenReport: TCheckBox;
    cbAddExt: TCheckBox;
    cbFrSong: TCheckBox;
    cbFrArtist: TCheckBox;
    cbFrAlbum: TCheckBox;
    cbFrPath: TCheckBox;
    cbLastPlayed: TCheckBox;
    cbSongTime: TCheckBox;
    cbReverseOrder: TCheckBox;
    edLogFile: TEdit;
    edReportFile: TEdit;
    edTemplateFile: TEdit;
    edAutosortPeriod: TEdit;
    edReportItems: TEdit;
    gbShowInReport: TGroupBox;
    gbSortLogFile: TGroupBox;
    lTemplateFile: TLabel;
    lReportFile: TLabel;
    lStatLogFile: TLabel;
    lAutosortDays: TLabel;
    lReportItems: TLabel;
    rbTitle: TRadioButton;
    rbDate: TRadioButton;
    rbCount: TRadioButton;
    rbPath: TRadioButton;
    rbLength: TRadioButton;
    procedure bbApplyClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnReportClick(Sender: TObject);
    procedure btnSortClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure SetReportMask();
    procedure SetSortMode();

  public

  end;

var
  StatForm: TStatForm;


implementation

uses
  common,
  cmemini,
  wat_api;

{$R *.lfm}

resourcestring
  rsCantCreate  = 'Can''t create file';
  rsSureToClear = 'Are you sure to delete log file?';

const
  WATStats:PAnsiChar = 'statistic';

  opt_LastSort:PAnsiChar = 'lastsort';
var
  LastSort:dword;


{ TStatForm }

procedure TStatForm.SetReportMask();
begin
  ReportMask:=0;
  if cbFrArtist  .Checked then ReportMask:=ReportMask or stArtist;
  if cbFrSong    .Checked then ReportMask:=ReportMask or stCount;
  if cbFrPath    .Checked then ReportMask:=ReportMask or stPath;
  if cbLastPlayed.Checked then ReportMask:=ReportMask or stDate;
  if cbSongTime  .Checked then ReportMask:=ReportMask or stLength;
  if cbFrAlbum   .Checked then ReportMask:=ReportMask or stAlbum;
end;

procedure TStatForm.SetSortMode();
begin
  if      rbTitle .Checked then SortMode:=stArtist
  else if rbDate  .Checked then SortMode:=stDate
  else if rbCount .Checked then SortMode:=stCount
  else if rbPath  .Checked then SortMode:=stPath
  else if rbLength.Checked then SortMode:=stLength;
end;

procedure TStatForm.bbApplyClick(Sender: TObject);
begin
  //--- Paths
  mFreeMem(StatName);
  StrDup(StatName,PAnsiChar(edReportFile));

  mFreeMem(ReportName);
  StrDup(ReportName,PAnsiChar(edReportFile));

  mFreeMem(TmplName);
  StrDup(TmplName,PAnsiChar(edTemplateFile));

  //--- Counts
  AutoSort   :=StrToInt(edAutosortPeriod.Text);
  ReportItems:=StrToInt(edReportItems.Text);
  if ReportItems=0 then
    ReportItems:=1;

  //--- Other
  if cbOpenReport.Checked then DoRunReport:=1 else DoRunReport:=0;
  if cbAddExt    .Checked then DoAddExt   :=1 else DoAddExt   :=0;

  //--- SortMode
  SetSortMode();

  if cbReverseOrder.Checked then
    Direction:=smReverse
  else
    Direction:=smDirect;

  //--- Show in report
  SetReportMask();

  SaveStatOpt;
end;

procedure TStatForm.btnDeleteClick(Sender: TObject);
begin
  if MessageDlg(rsSureToClear,mtWarning,[mbOk],0)=mrOk then
  //!!  DeleteFileA(StatName);
end;

procedure TStatForm.btnSortClick(Sender: TObject);
begin
  if edLogFile.Text<>'' then
    PackLog(PAnsiChar(edLogFile.Text),false);
end;

procedure TStatForm.btnReportClick(Sender: TObject);
begin
  ReportItems:=StrToInt(edReportItems.Text);
  if ReportItems=0 then ReportItems:=1;
  SetReportMask();
  MakeReport(
    PAnsiChar(edLogFile.Text),
    PAnsiChar(edReportFile.Text),
    PAnsiChar(edTemplateFile.Text));
end;

procedure TStatForm.btnExportClick(Sender: TObject);
var
  f:file of byte;
begin
//!!  if ShowDlg(@buf,TmplName) then
  begin
    //!! check for empty??
    AssignFile(f,edTemplateFile.Text);
    Rewrite(f);
    if IOResult<>0 then
      MessageDlg(rsCantCreate,mtError,[mbOk],0)
    else
    begin
      BlockWrite(f,IntTmpl^,StrLen(IntTmpl));
      CloseFile(f);
    end;
  end;
  exit;
end;

procedure TStatForm.FormCreate(Sender: TObject);
begin
  //--- Paths
  edReportFile  .Text:=ReportName;
  edLogFile     .Text:=StatName;
  edTemplateFile.Text:=TmplName;

  //--- Counts
  edReportItems   .Text:=IntToStr(ReportItems);
  edAutosortPeriod.Text:=IntToStr(AutoSort);

  //--- Other
  cbOpenReport.Checked:=DoRunReport<>0;
  cbAddExt    .Checked:=DoAddExt<>0;

  //--- Sort mode
  rbTitle .Checked:=SortMode=stArtist;
  rbDate  .Checked:=SortMode=stDate;
  rbCount .Checked:=SortMode=stCount;
  rbPath  .Checked:=SortMode=stPath;
  rbLength.Checked:=SortMode=stLength;

  cbReverseOrder.Checked:=Direction=smReverse;

  //--- Show in report
  cbFrArtist  .Checked:=(ReportMask and stArtist)<>0;
  cbFrAlbum   .Checked:=(ReportMask and stAlbum )<>0;
  cbFrSong    .Checked:=(ReportMask and stCount )<>0;
  cbFrPath    .Checked:=(ReportMask and stPath  )<>0;
  cbLastPlayed.Checked:=(ReportMask and stDate  )<>0;
  cbSongTime  .Checked:=(ReportMask and stLength)<>0;
end;

// ------------ base interface functions -------------

procedure Action(si:UIntPtr;res:integer);
var
  sect:pINISection;
  CurTime:dword;
begin
  if (res and WAT_RES_NEWFILE)<>0 then
  begin
    if (StatName<>nil) and (StatName[0]<>#0) then
    begin
      AddToLog(StatName,si);
      if AutoSort>0 then
      begin
//!!        CurTime:=GetCurrentTime;
        if (CurTime-LastSort)>=(86400*AutoSort) then
        begin
          PackLog(StatName);
          LastSort:=CurTime;
          sect:=watini.Section[WATStats];
          sect^.WriteInt(opt_LastSort,LastSort);
        end;
      end;
    end;
  end;

  if (res and WAT_RES_NEWSTATUS)<>0 then
  begin
    case WATGet(si,siStatus) of
      WAT_PLS_STOPPED,
      WAT_PLS_NOTFOUND: begin
      end;
    end;
  end;
end;

procedure LoadOpt();
var
  sect:pINISection;
begin
  sect:=watini.Section[WATStats];
  LastSort:=sect^.ReadInt(opt_LastSort,0);

  LoadStatOpt;
end;

function InitProc(aInit:boolean):integer;
begin
  result:=1;

  if aInit then
  begin
    LoadOpt();
  end
  else
  begin
    FreeStatOpt;
  end;
end;

function AddOptionsPage(var cnt:integer):pointer;
begin
  cnt:=0;
  StatForm:=TStatForm.Create(Application);
  result:=StatForm;
end;

var
  Stat:twModule;

procedure Init;
begin
  Stat.Next      :=ModuleLink;
  Stat.Init      :=@InitProc;
  Stat.AddOption :=@AddOptionsPage;
  Stat.Action    :=@Action;
  Stat.ModuleName:='Statistic';
  ModuleLink     :=@Stat;
end;

begin
  Init;
end.

