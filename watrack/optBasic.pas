unit optBasic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, CheckLst, Buttons, Spin, EditBtn, Menus;

type

  { TBasicForm }

  TBasicForm = class(TForm)
    bbCheckFormats: TBitBtn;
    bbCheckPlayers: TBitBtn;
    bbApply: TBitBtn;
    bbNotesGroups: TBitBtn;
    bbListReload: TBitBtn;
    btnDefCoverMask: TButton;
    btnTimer: TButton;
    cbAppCommand: TCheckBox;
    cbCheckAll: TCheckBox;
    cbCheckTime: TCheckBox;
    cbImplantant: TCheckBox;
    cbKeepOld: TCheckBox;
    cbWinampFirst: TCheckBox;
    cbUseBASS: TCheckBox;
    cbShowGroup: TCheckBox;
    clbGroups: TCheckListBox;
    clbFormats: TCheckListBox;
    clbPlayers: TCheckListBox;
    cbCheckUnkn: TCheckBox;
    lePlayerListFile: TLabeledEdit;
    lbCoverMask: TLabel;
    lbSettings: TLabel;
    lbFormats: TLabel;
    lbPlayers: TLabel;
    lRefreshTime: TLabel;
    memCoverMasks: TMemo;
    pnlSettings: TPanel;
    pnlFormats: TPanel;
    pnlPlayers: TPanel;
    RefreshTimer: TTimer;
    seRefreshTime: TSpinEdit;
    stPlayerHint: TStaticText;
    procedure bbApplyClick(Sender: TObject);
    procedure bbListReloadClick(Sender: TObject);
    procedure bbNotesGroupsClick(Sender: TObject);
    procedure btnPlayersClick(Sender: TObject);
    procedure btnFormatClick(Sender: TObject);
    procedure cbShowGroupClick(Sender: TObject);
    procedure clbGroupsClickCheck(Sender: TObject);
    procedure clbGroupsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure btnDefCoverMaskClick(Sender: TObject);
    procedure btnTimerClick(Sender: TObject);
    procedure clbPlayersSelectionChange(Sender: TObject; User: boolean);
    procedure FormDestroy(Sender: TObject);
    procedure onRefreshTimer(Sender: TObject);
  private
    procedure FillGroupList;
    procedure FillPlayerList;
    procedure FillFormatList;
    procedure CheckFormatList;
    procedure CheckPlayerList;

  public

  end;

var
  BasicForm: TBasicForm;

implementation

{$R *.lfm}

uses
  lcltype,
  srv_format, srv_player,
  wat_api,
  wat_basic;

resourcestring
  sNone   = 'None';
  sAll    = 'All';
  sAudio  = 'Audio';
  sVideo  = 'Video';
  sNotes  = 'Notes';
  sGroups = 'Groups';
  sStartTimer = 'Start timer';
  sStopTimer  = 'Stop timer';
  sNoSpecialNote = 'No any special notes for this player';

const
  optWATBasic:PAnsiChar = 'basic';
  opt_Timer  :PAnsiChar = 'timer';
  opt_Group  :PAnsiChar = 'show_group';
var
  mTimer:cardinal;
  mShowGroup:Boolean;

{ TBasicForm }

//----- Format list -----

procedure TBasicForm.btnFormatClick(Sender: TObject);
var
  i:integer;
  tmp:boolean;
begin
  tmp:=bbCheckFormats.Tag=3;
  for i:=0 to clbFormats.Items.Count-1 do
  begin
    if (bbCheckFormats.Tag=1) then
      tmp:=(UIntPtr(clbFormats.Items.Objects[i]) and WAT_OPT_VIDEO)=0
    else if (bbCheckFormats.Tag=2) then
      tmp:=(UIntPtr(clbFormats.Items.Objects[i]) and WAT_OPT_VIDEO)<>0;

    clbFormats.Checked[i]:=tmp;
  end;

  case bbCheckFormats.Tag of
    0:begin // 'None' selected
      bbCheckFormats.Tag    :=1;
      bbCheckFormats.Caption:=sAudio;
    end;
    1:begin // 'Audio' selected
      bbCheckFormats.Tag    :=2;
      bbCheckFormats.Caption:=sVideo;
    end;
    2: begin // 'Video' selected
      bbCheckFormats.Tag    :=3;
      bbCheckFormats.Caption:=sAll;
    end;
    3: begin // 'All' selected
      bbCheckFormats.Tag    :=0;
      bbCheckFormats.Caption:=sNone;
    end;
  end;
end;

function enumrf(fmt:pMusicFormat;alParam:pointer):boolean; stdcall;
var
  i:integer;
begin
  with TBasicForm(alParam).clbFormats do
  begin
    i:=Items.AddObject(fmt^.ext,TObject(UIntPtr(fmt^.flags)));
    Checked[i]:=(fmt^.flags and WAT_OPT_DISABLED)=0;
  end;

  result:=true;
end;

procedure TBasicForm.FillFormatList;
begin
  clbFormats.Items.Clear;

  EnumFormats(@enumrf,self);
end;

procedure TBasicForm.CheckFormatList;
var
  i,lstatus:integer;
begin
  for i:=0 to clbFormats.Count-1 do
  begin
    if clbFormats.Checked[i] then
      lstatus:=WAT_ACT_ENABLE
    else
      lstatus:=WAT_ACT_DISABLE;
    ServiceFormat(lstatus,PAnsiChar(clbFormats.Items[i]));
  end;
end;

//----- Player list -----
{
function SetPlayerIcons(const fname:AnsiString):integer;
var
  i,j:integer;
  buf:array [0..255] of AnsiChar;
  p,pp:pAnsiChar;
  lhIcon:HICON;
  lh:TLibHandle;
begin
  lh:=LoadLibrary(fname);
  if lh<>NilHandle then
  begin
    p:=StrCopyE(@buf,'Player_');
    i:=0;
    while i<PlyNum do
    begin
      with plyLink^[i] do
      begin
        pp:=p;
        for j:=1 to Length(Desc) do
        begin
          if Desc[j] in sLatWord then
            pp^:=UpCase(Desc[j])
          else
            pp^:='_';
          inc(pp);
        end;
        pp^:=#0;
        lhIcon:=LoadImageA(result,buf,IMAGE_ICON,16,16,0);
        if lhIcon>0 then
        begin
          if Icon<>0 then
            DestroyIcon(Icon);
          Icon:=lhIcon;
        end;
      end;
      inc(i);
    end;
    FreeLibrary(lh);
  end;
end;
}
procedure TBasicForm.clbPlayersSelectionChange(Sender: TObject; User: boolean);
var
  p:AnsiString;
begin
  if clbPlayers.ItemIndex>=0 then
    p:=GetPlayerNote(pointer(clbPlayers.Items[clbPlayers.ItemIndex]))
  else
    p:='';
  if p='' then
    p:=sNoSpecialNote;

  stPlayerHint.Caption:=p;
end;

procedure TBasicForm.btnPlayersClick(Sender: TObject);
var
//  i:integer;
  stat:TCheckBoxState;
begin
  if bbCheckPlayers.Tag=0 then
  begin
    bbCheckPlayers.Tag:=1;
    bbCheckPlayers.Caption:=sAll;
    stat:=cbUnchecked;
  end
  else
  begin
    bbCheckPlayers.Tag:=0;
    bbCheckPlayers.Caption:=sNone;
    stat:=cbChecked;
  end;
  clbPlayers.CheckAll(stat);
{
  for i:=0 to clbPlayers.Items.Count-1 do
    clbPlayers.Checked[i]:= not clbPlayers.Checked[i];
}
end;

function enumrp(desc:PAnsiChar;alParam:pointer):boolean; stdcall;
var
  ldesc:PAnsiChar;
  i,lstatus:integer;
begin
  lstatus:=ServicePlayer(WAT_ACT_GETSTATUS,desc);
  if TBasicForm(alParam).cbShowGroup.Checked then
    ldesc:=desc
  else
  begin
    ldesc:=StrScan(desc,':');
    if ldesc=nil then ldesc:=desc else inc(ldesc);
  end;
  i:=TBasicForm(alParam).clbPlayers.Items.AddObject(ldesc,nil);

  TBasicForm(alParam).clbPlayers.Checked[i]:=(lstatus=WAT_RES_ENABLED);

  result:=true;
end;

procedure TBasicForm.FillPlayerList;
begin
{
  il:=ImageList_Create(16,16,ILC_COLOR32 or ILC_MASK,0,1); //!!
  while i<PlyNum do
  begin
    item.iImage:=ImageList_AddIcon(il,plyLink^[i].Icon);
    item.iItem:=i;
    item.pszText:=plyLink^[i].Desc;
    newItem:=SendMessageA(hwndList,LVM_INSERTITEMA,0,UIntPtr(@item));
    if newItem>=0 then
    begin
      if (plyLink^[i].flags and WAT_OPT_DISABLED)=0 then
        ListView_SetCheckState(hwndList,newItem,TRUE);
    end;
    inc(i);
  end;
  ImageList_Destroy(SendMessage(hwndList,LVM_SETIMAGELIST,LVSIL_SMALL,il)); //!!
}
  clbPlayers.Items.Clear;

  EnumPlayers(@enumrp,self,true);
end;

procedure TBasicForm.CheckPlayerList;
var
  i,lstatus:integer;
begin
  for i:=0 to clbPlayers.Count-1 do
  begin
    if clbPlayers.Checked[i] then
      lstatus:=WAT_ACT_ENABLE
    else
      lstatus:=WAT_ACT_DISABLE;
    ServicePlayer(lstatus,pointer(clbPlayers.Items[i]));
  end;
end;

procedure TBasicForm.cbShowGroupClick(Sender: TObject);
begin
  FillPlayerList;
end;

//----- Group list -----

procedure TBasicForm.FillGroupList;
var
  lgroup:PAnsiChar;
  i:integer;
  lstatus:integer;
begin
  clbGroups.Items.BeginUpdate;
  clbGroups.Items.Clear;
  i:=0;
  // groups MUST BE resorted!!
  while GetGroupStatus(i,lgroup,lstatus) do
  begin
    clbGroups.Items.Add(lgroup);
    clbGroups.Checked[i]:=(lstatus>0);
    inc(i);
  end;
  clbGroups.Items.EndUpdate;
end;

procedure TBasicForm.clbGroupsClickCheck(Sender: TObject);
var
  lstatus:integer;
begin
  lstatus:=clbGroups.ItemIndex+1;
  if not clbGroups.Checked[clbGroups.ItemIndex] then
    lstatus:=-lstatus;
  SetGroupStatus(Pointer(clbGroups.Items[clbGroups.ItemIndex]),lstatus);
  FillPlayerList;
end;

procedure TBasicForm.clbGroupsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  i,idx:integer;
begin
  // screen changes
  if Shift=[ssCtrl] then
  begin
    idx:=clbGroups.ItemIndex;
    if Key=VK_UP then
    begin
      if idx>0 then
        dec(idx)
      else
        exit;
    end
    else if key=VK_DOWN then
    begin
      if idx<(clbGroups.Count-1) then
        inc(idx)
      else
        exit;
    end
    else
      exit;

    clbGroups.Items.Move(clbGroups.ItemIndex,idx);
//    clbGroups.ItemIndex:=idx;

    // group order changes
    for i:=0 to clbGroups.Count-1 do
    begin
      if clbGroups.Checked[i] then
        idx:=i+1
      else
        idx:=-i-1;
      SetGroupStatus(pointer(clbGroups.Items[i]),idx);
    end;
  end;
end;

//----- Timer functions -----

procedure TBasicForm.onRefreshTimer(Sender: TObject);
var
  si:UIntPtr;
  ptr:pwModule;
  res:integer;
begin
  si:=0;
  res:=WATGetMusicInfo(si,0);

  ptr:=ModuleLink;
  while ptr<>nil do
  begin
    if (ptr^.Action)<>nil then
    begin
      ptr^.Action(si,res);
    end;
    ptr:=ptr^.Next;
  end;
end;

procedure TBasicForm.btnTimerClick(Sender: TObject);
var
  ptr:pwModule;
  si:UIntPtr;
  res:integer;
  extres:integer;
begin
  si:=0;
  if RefreshTimer.Enabled then
  begin
    RefreshTimer.Enabled:=false;
    btnTimer.Caption:=sStartTimer;

    ptr:=ModuleLink;
    while ptr<>nil do
    begin
      if (ptr^.Action)<>nil then
      begin
        ptr^.Action(0,WAT_RES_DISABLED or WAT_RES_NEWSTATUS);
      end;
      ptr:=ptr^.Next;
    end;
  end
  else
  begin
    RefreshTimer.Interval:=mTimer*1000;
    RefreshTimer.Enabled :=true;
    btnTimer.Caption:=sStopTimer;
{
  can't simply call onRefreshTimer or wait
  coz no "new track/status/player" event will raise
}
    res:=WATGetMusicInfo(0,0);
    if (res=WAT_RES_OK) then
    begin
      extres:=WAT_RES_NEWFILE+WAT_RES_NEWPLAYER;
    end
    else if (res=WAT_RES_NOTFOUND) then
    begin
      extres:=WAT_RES_NEWSTATUS;
    end
    else
      extres:=0;

    if extres<>0 then
    begin
      ptr:=ModuleLink;
      while ptr<>nil do
      begin
        if (ptr^.Action)<>nil then
        begin
          ptr^.Action(si,res or extres);
        end;
        ptr:=ptr^.Next;
      end;
    end;
  end;
end;

//----- Common functions -----

procedure TBasicForm.bbApplyClick(Sender: TObject);
begin
  watOptions:=[];
  if cbCheckTime.Checked   then Include(watOptions, woCheckTime);
  if cbKeepOld.Checked     then Include(watOptions, woKeepOld);
  if cbAppCommand.Checked  then Include(watOptions, woMMKeyEmu);
  if cbImplantant.Checked  then Include(watOptions, woUseImplant);
  if cbCheckAll.Checked    then Include(watOptions, woCheckAll);
  if cbCheckUnkn.Checked   then Include(watOptions, woCheckUnknown);
  if cbWinampFirst.Checked then Include(watOptions, woWinampFirst);

  CoverPaths:=memCoverMasks.Lines.Text;

  TmplFile:=lePlayerListFile.Text;
  if TmplFile='' then
  begin
    TmplFile:=deftmplfile;
    lePlayerListFile.Text:=TmplFile;
  end;
  CheckPlayerList;
  CheckFormatList;

  SaveOpt;

  mTimer:=seRefreshTime.Value;
  watini.Section[optWATBasic]^.WriteInt(opt_Timer,mTimer);
  mShowGroup:=cbShowGroup.Checked;
  watini.Section[optWATBasic]^.WriteBool(opt_Group,mShowGroup);
end;

procedure TBasicForm.bbListReloadClick(Sender: TObject);
begin
  // player templates reload
  if srv_player.LoadFromFile(pointer(lePlayerListFile.Text))>0 then
  begin
    ResortGroups;
    FillPlayerList;
  end;
end;

procedure TBasicForm.bbNotesGroupsClick(Sender: TObject);
begin
  if bbNotesGroups.Tag=0 then
  begin
    bbNotesGroups.Tag:=1;
    bbNotesGroups.Caption:=sGroups;
//    stat:=cbUnchecked;
  end
  else
  begin
    bbNotesGroups.Tag:=0;
    bbNotesGroups.Caption:=sNotes;
//    stat:=cbChecked;
  end;
  stPlayerHint.Visible:=bbNotesGroups.Tag<>0;
  clbGroups   .Visible:=bbNotesGroups.Tag=0;
end;

procedure TBasicForm.btnDefCoverMaskClick(Sender: TObject);
begin
  memCoverMasks.Lines.Text:=defcoverpaths;
end;

//----- base form functions -----

procedure TBasicForm.FormCreate(Sender: TObject);
begin
  seRefreshTime.Value  :=mTimer;
  cbCheckTime.Checked  :=(woCheckTime    in watOptions);
  cbKeepOld.Checked    :=(woKeepOld      in watOptions);
  cbAppCommand.Checked :=(woMMKeyEmu     in watOptions);
  cbImplantant.Checked :=(woUseImplant   in watOptions);
  cbCheckAll.Checked   :=(woCheckAll     in watOptions);
  cbCheckUnkn.Checked  :=(woCheckUnknown in watOptions);
  cbWinampFirst.Checked:=(woWinampFirst  in watOptions);
  memCoverMasks.Lines.Text:=CoverPaths;

  lePlayerListFile.Text:=TmplFile;
  FillGroupList;
  FillPlayerList;
  FillFormatList;

  btnTimer.Caption:=sStartTimer;
  bbCheckFormats.Caption:=sNone;
  bbCheckPlayers.Caption:=sNone;
  bbNotesGroups .Caption:=sNotes;
end;

procedure TBasicForm.FormDestroy(Sender: TObject);
begin
  ClearFormats;
  ClearPlayers;
  RefreshTimer.Enabled:=false;
end;

//----- Module interface functions -----

procedure Action(si:UIntPtr;res:integer);
begin
  if (res and WAT_RES_STATUS)=WAT_RES_OK then
  begin
    if (res and WAT_RES_NEWFILE)<>0 then   // rebuild format list
    begin
      // add check for format change?
//??      FillFormatList;
    end;
    
    if (res and WAT_RES_NEWPLAYER)<>0 then // rebuild player list
//??      FillPlayerList;
  end;
end;

function InitProc(aInit:boolean):integer;
begin
  result:=0;
  if aInit then
  begin

    LoadOpt;

    mTimer:=watini.Section[optWATBasic]^.ReadInt(opt_Timer,5);

    mShowGroup:=watini.Section[optWATBasic]^.ReadBool(opt_Group,false);
  end
  else
  begin
  end;
end;

function AddOptionsPage(var cnt:integer):pointer;
begin
  cnt:=0;
  BasicForm:=TBasicForm.Create(Application);
  result:=BasicForm;
end;

var
  Basic:twModule;

procedure Init;
begin
  Basic.Next      :=ModuleLink;
  Basic.Init      :=@InitProc;
  Basic.AddOption :=@AddOptionsPage;
  Basic.Action    :=@Action;
  Basic.ModuleName:='Basic';
  ModuleLink      :=@Basic;
end;

begin
  Init;
end.
