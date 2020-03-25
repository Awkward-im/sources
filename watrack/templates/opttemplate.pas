unit OptTemplate;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Buttons, Spin, EditBtn, Grids;

type

  { TTemplateForm }

  TTemplateForm = class(TForm)
    bbApply: TBitBtn;
    btnFile: TButton;
    cbLowType: TCheckBox;
    cbReplace: TCheckBox;
    cbTranslate: TCheckBox;
    edFile: TEdit;
    gbOptions: TGroupBox;
    gbFormat: TGroupBox;
    lbGridHelp: TLabel;
    lbPrecision: TLabel;
    rbBytes: TRadioButton;
    rbkbhh: TRadioButton;
    rbkbhl: TRadioButton;
    rbkbll: TRadioButton;
    rbKilobytes: TRadioButton;
    rbMegabytes: TRadioButton;
    rbnone: TRadioButton;
    rgFileSize: TGroupBox;
    rgLetterCase: TGroupBox;
    rbUppercase: TRadioButton;
    rbNotChange: TRadioButton;
    rbLowercase: TRadioButton;
    rgPostfix: TGroupBox;
    rgVBRmacro: TGroupBox;
    lbTemplate: TLabel;
    memTemplate: TMemo;
    rbVBRempty: TRadioButton;
    rbVBRCBR: TRadioButton;
    dlgFile: TSaveDialog;
    sePrecision: TSpinEdit;
    sgMacros: TStringGrid;
    procedure bbApplyClick(Sender: TObject);
    procedure btnFileClick(Sender: TObject);
    procedure sgMacrosDblClick(Sender: TObject);
    procedure TemplateFormCreate(Sender: TObject);
  private

  public

  end;

var
  TemplateForm: TTemplateForm;

implementation

uses
  cmemini,
  wat_api,
  wat_template;

{$R *.lfm}

//----- Save/load options -----
resourcestring
  sTemplate = 'I am listening to %artist% - "%title%"';

const
  ExportText  :AnsiString = '';
  ExportFile  :AnsiString = '';

  opt_ExportText:PAnsiChar = 'exporttext';
  opt_ExportFile:PAnsiChar = 'exportfile';

  WATTemplates  :PAnsiChar = 'templates';

procedure LoadOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATTemplates];
  ExportText :=sect^.ReadString(opt_ExportText,sTemplate);
  ExportFile :=sect^.ReadString(opt_ExportFile,'');
  LoadTemplateOpt;
end;

procedure SaveOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATTemplates];
  sect^.WriteString(opt_ExportText,ExportText);
  sect^.WriteString(opt_ExportFile,ExportFile);
  SaveTemplateOpt;
end;

{ TTemplateForm }

procedure TTemplateForm.sgMacrosDblClick(Sender: TObject);
begin

end;

procedure TTemplateForm.btnFileClick(Sender: TObject);
begin
  dlgFile.FileName:=edFile.Text;
  if dlgFile.Execute then
    edFile.Text:=dlgFile.Filename;
end;

procedure TTemplateForm.bbApplyClick(Sender: TObject);
var
  i:integer;
begin
  if cbTranslate.Checked then tmplDoTranslate:=1 else tmplDoTranslate:=0;
  if cbReplace.Checked   then tmplReplaceSpc :=1 else tmplReplaceSpc :=0;
  if cbLowType.Checked   then tmplLoCaseType :=1 else tmplLoCaseType :=0;

  if      rbBytes.Checked     then tmplFSizeMode:=1
  else if rbKilobytes.Checked then tmplFSizeMode:=1024
  else if rbMegabytes.Checked then tmplFSizeMode:=1024*1024;

  tmplFSPrecision:=sePrecision.Value;
  if      rbNone.Checked then tmplFSizePost:=0
  else if rbkbll.Checked then tmplFSizePost:=1
  else if rbkbhl.Checked then tmplFSizePost:=2
  else if rbkbhh.Checked then tmplFSizePost:=3;

  if      rbUppercase.Checked then tmplPlayerCaps:=2
  else if rbNotChange.Checked then tmplPlayerCaps:=0
  else if rbLowercase.Checked then tmplPlayerCaps:=1;

  if      rbVBRempty.Checked then tmplWriteCBR:=0
  else if rbVBRCBR.Checked   then tmplWriteCBR:=1;

  ExportText:=memTemplate.Lines.Text;
  ExportFile:=edFile.Text;

  sgMacros.RowCount:=numvars;
  for i:=0 to numvars-1 do
  begin
    if vars[i].name<>sgMacros.Cells[0,i] then
      vars[i].alias:=sgMacros.Cells[0,i]
    else
      vars[i].alias:='';
  end;

  SaveOpt;
end;

//----- base form functions -----

procedure TTemplateForm.TemplateFormCreate(Sender: TObject);
var
  i:integer;
begin
  cbTranslate.Checked:=tmplDoTranslate<>0;
  cbReplace.Checked  :=tmplReplaceSpc<>0;
  cbLowType.Checked  :=tmplLoCaseType<>0;

  rbBytes.Checked    :=tmplFSizeMode=1;
  rbKilobytes.Checked:=tmplFSizeMode=1024;
  rbMegabytes.Checked:=tmplFSizeMode=1024*1024;

  sePrecision.Value:=tmplFSPrecision;
  rbNone.Checked:=tmplFSizePost=0;
  rbkbll.Checked:=tmplFSizePost=1;
  rbkbhl.Checked:=tmplFSizePost=2;
  rbkbhh.Checked:=tmplFSizePost=3;

  rbUppercase.Checked:=tmplPlayerCaps=2;
  rbNotChange.Checked:=tmplPlayerCaps=0;
  rbLowercase.Checked:=tmplPlayerCaps=1;

  rbVBRempty.Checked:=tmplWriteCBR=0;
  rbVBRCBR.Checked  :=tmplWriteCBR<>0;

  memTemplate.Lines.Text:=ExportText;
  edFile.Text           :=ExportFile;

  sgMacros.RowCount:=numvars;
  for i:=0 to numvars-1 do
  begin
    if vars[i].alias='' then
      sgMacros.Cells[0,i]:=vars[i].name
    else
      sgMacros.Cells[0,i]:=vars[i].alias;
    sgMacros.Cells[1,i]:=vars[i].help;
  end;
  sgMacros.AutoAdjustColumns;
end;

//----- Module interface functions -----

procedure Action(si:UIntPtr;res:integer);
var
  tf:Text;
  exptext:AnsiString;
  dowrite:integer;
begin
  if ExportFile='' then
    exit;

  dowrite:=0;
  exptext:='';
  if (res and WAT_RES_STATUS)=WAT_RES_OK then
  begin
    if (res and WAT_RES_NEWFILE)<>0 then
    begin
      dowrite:=1;
      exptext:=TemplateFunc(0,ExportText);
    end;
  end;
  if (res and WAT_RES_NEWSTATUS)<>0 then
  begin
    if ((res and WAT_RES_STATUS)=WAT_RES_DISABLED) or (WATGet(si,siStatus)=WAT_PLS_STOPPED) then
    begin
      dowrite:=1;
    end;
  end;
  if dowrite<>0 then
  begin
    AssignFile(tf,ExportFile);
    Rewrite(tf);
    Writeln(tf,exptext);
    CloseFile(tf);
  end;
end;

function AddOptionsPage(var cnt:integer):pointer;
begin
  cnt:=0;
  TemplateForm:=TTemplateForm.Create(Application);
  result:=TemplateForm;
end;

function InitProc(aInit:boolean):integer;
begin
  result:=1;
  if aInit then
  begin
    LoadOpt;
  end
  else
  begin
  end;
end;

var
  Tmpl:twModule;

procedure Init;
begin
  Tmpl.Next      :=ModuleLink;
  Tmpl.Init      :=@InitProc;
  Tmpl.AddOption :=@AddOptionsPage;
  Tmpl.Action    :=@Action;
  Tmpl.ModuleName:='Template';
  ModuleLink    :=@Tmpl;
end;

begin
  Init;
end.
