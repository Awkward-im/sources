unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Windows;

type

  { TWindowRenameForm }

  TWindowRenameForm = class(TForm)
    bRefresh: TButton;
    bPWSelect: TButton;
    bRename: TButton;
    cbWindowList: TComboBox;
    edWindowTitle: TEdit;
    lNewName: TLabel;
    lWindowList: TLabel;
    procedure bRefreshClick(Sender: TObject);
    procedure bRenameClick(Sender: TObject);
    procedure bPWSelectClick(Sender: TObject);
    procedure cbWindowListChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    CurrentWindow:HWND;
  public

  end;

var
  WindowRenameForm: TWindowRenameForm;

implementation

{$R *.lfm}

{ TWindowRenameForm }

procedure TWindowRenameForm.bRefreshClick(Sender: TObject);
var
  lwnd:HWND;
  lbuf:array [0..299] of WideChar;
begin
  cbWindowList.Clear;

  lwnd:=0;
  repeat
    lwnd:=FindWindowExW(0,lwnd,nil,nil);
    if lwnd=0 then
      break;
    if IsWindowVisible(lwnd) then
      if GetWindowTextW(lwnd,@lbuf,300)>0 then
      begin
        cbWindowList.AddItem(lbuf,TObject(lwnd));
      end;
  until false;
  cbWindowList.ItemIndex:=0;

  bPWSelectClick(Sender);
end;

procedure TWindowRenameForm.bRenameClick(Sender: TObject);
begin
  SetWindowTextW(CurrentWindow,PWideChar(WideString(edWindowTitle.Text)));
  cbWindowList.Items[cbWindowList.ItemIndex]:=edWindowTitle.Text;
end;

procedure TWindowRenameForm.bPWSelectClick(Sender: TObject);
var
  i:integer;
begin
   for i:=0 to cbWindowList.Items.Count-1 do
   begin
     if cbWindowList.Items[i]='Perfect World' then
     begin
       cbWindowList.ItemIndex:=i;
       cbWindowListChange(Sender);
     end;
   end;
end;

procedure TWindowRenameForm.cbWindowListChange(Sender: TObject);
begin
  CurrentWindow:=HWND(cbWindowList.Items.Objects[cbWindowList.ItemIndex]);
  edWindowTitle.Text:=cbWindowList.Items        [cbWindowList.ItemIndex];
end;

procedure TWindowRenameForm.FormCreate(Sender: TObject);
begin
  bRefreshClick(Sender);
end;

end.

