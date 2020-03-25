unit optMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Menus, ExtCtrls, Buttons;

type

  { TMainOptForm }

  TMainOptForm = class(TForm)
    MainMenu: TMainMenu;
    miMain: TMenuItem;
    miAction: TMenuItem;
    miExit: TMenuItem;
    miAbout: TMenuItem;
    miFile: TMenuItem;
    miHelp: TMenuItem;
    miLoadSettings: TMenuItem;
    miSaveSettings: TMenuItem;
    PageControl: TPageControl;
    sbMain: TStatusBar;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miLoadSettingsClick(Sender: TObject);
    procedure miMainClick(Sender: TObject);
    procedure miSaveSettingsClick(Sender: TObject);
  private
    procedure AddPages;
    procedure InitModules;

  public

  end;

var
  OptForm: TMainOptForm;

implementation

{$R *.lfm}

uses
  cmemini,
  wat_api,
  wat_basic;

resourcestring
  sNoPlaying = 'No music playing';
  sNoCheck   = 'No automatic check';

//----- Menu processing -----

procedure TMainOptForm.miLoadSettingsClick(Sender: TObject);
begin

end;

procedure TMainOptForm.miSaveSettingsClick(Sender: TObject);
begin
  watini.Flush(PAnsiChar(nil));
end;

procedure TMainOptForm.miMainClick(Sender: TObject);
begin
  //  res:=WATGetMusicInfo(2,si);

  if not (WATGet(0,siStatus) in [WAT_PLS_NOTFOUND]) then
    Application.MessageBox(
      PAnsiChar(WATGetStr(0,siTitle)),
      PAnsiChar(WATGetString(0,siArtist) + ' - ' +
                WATGetString(0,siPlayer)))
  else
    Application.MessageBox(PAnsiChar(sNoPlaying),'');
end;

procedure TMainOptForm.miExitClick(Sender: TObject);
begin
  Close;
end;

//----- base form functions -----

procedure TMainOptForm.InitModules;
var
  ptr:pwModule;
begin
  ptr:=ModuleLink;
  while ptr<>nil do
  begin
    if (ptr^.Init)<>nil then
      ptr^.Init(true);
    ptr:=ptr^.Next;
  end;
end;

procedure TMainOptForm.AddPages;
var
  ptr:pwModule;
  ts:TTabSheet;
  tf:TForm;
  cnt:integer;
begin
  if PageControl.Images=nil then
    PageControl.Images:=TImageList.Create(PageControl);

  ptr:=ModuleLink;
  cnt:=0;
  while ptr<>nil do
  begin
    if (ptr^.AddOption)<>nil then
    begin
      tf:=TForm(ptr^.AddOption(cnt));
      if tf<>nil then
      begin
        ts:=TTabSheet.Create(PageControl);
        ts.PageControl:=PageControl;
        ts.Caption    :=tf.Caption;
        if tf.Icon.Count>0 then
          ts.ImageIndex:=PageControl.Images.AddIcon(tf.Icon)
        else
          ts.ImageIndex:=-1;

        tf.Parent      := ts;
        tf.Align       := alClient;
        tf.BorderStyle := bsNone;
        tf.Visible     := true;
      end;
      if cnt>0 then continue;
    end;
    ptr:=ptr^.Next;
  end;
end;

procedure TMainOptForm.FormCreate(Sender: TObject);
begin
  InitModules;
  AddPages;
  sbMain.Panels[0].Text:=sNoPlaying;
end;

procedure TMainOptForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  ptr:pwModule;
begin
  ptr:=ModuleLink;
  while ptr<>nil do
  begin
    if (ptr^.Init)<>nil then
      ptr^.Init(false);
    ptr:=ptr^.Next;
  end;
end;

//----- Module interface functions -----

procedure Action(si:UIntPtr;res:integer);
begin
  if ((res and WAT_RES_STATUS)=WAT_RES_OK) and ((res and WAT_RES_NEWFILE)<>0) then
  begin
    optForm.sbMain.Panels[0].Text:=
      'Artist: '   +WATGetString(si,siArtist)+
      '; Title: '  +WATGetString(si,siTitle)+
      '; Program: '+WATGetString(si,siPlayer);
  end

  else if (res and WAT_RES_STATUS)=WAT_RES_DISABLED then
  begin
    optForm.sbMain.Panels[0].Text:=sNoCheck;
  end

  else if ((res and WAT_RES_NEWSTATUS)<>0) and
          (WATGet(si,siStatus)=WAT_PLS_STOPPED) then
  begin
    optForm.sbMain.Panels[0].Text:=sNoPlaying;
{
  end
  else if res=WAT_RES_NOTFOUND then
  begin
    if optForm.sbMain.Panels[0].Text=sNoCheck then
      optForm.sbMain.Panels[0].Text:=sNoPlaying;
}
  end;
end;

var
  Main:twModule;

procedure Init;
begin
  Main.Next      :=ModuleLink;
  Main.Init      :=nil;
  Main.AddOption :=nil;
  Main.Action    :=@Action;
  Main.ModuleName:='Main';
  ModuleLink     :=@Main;
end;

initialization
  Init;
end.
