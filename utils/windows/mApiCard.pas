{service insertion code}
unit mApiCard;

interface

uses
  windows,
  messages,
  cMemIni;

const
  WM_UPDATEHELP = WM_USER+100;

type
  tmApiCard = class
  private
    fParent:HWND;
    fHelpWindow:HWND;

    storage:PINIFile;
    current:PINISection;

    function  GetDescription:PAnsiChar; 
    function  GetWindowStatus:boolean;
    function  GetCardStatus:boolean;
    function  GetTemplateStatus:boolean;
    function  GetNamespace:PAnsiChar;
    procedure SetNamespace(ns:PAnsiChar);

    function HashToName(ahash:longword):PAnsiChar;
  public
    constructor Create(fname:PAnsiChar=nil; aparent:HWND=0);
    destructor  Destroy; override;

    // result must be freed by mFreeMem
    function NameFromList(cb:HWND):PAnsiChar;

    function  FillParams(wnd:HWND;paramname:PAnsiChar):PAnsiChar;
    procedure FillList(combo:HWND;mode:integer=0); virtual;
    procedure Show ; virtual;
    procedure Close; virtual;
    procedure Update;
    function  SelectCard(tmpl:PAnsiChar):boolean;
    function  GetParameter(name:PAnsiChar;default:PAnsiChar=nil):PAnsiChar;
    function  GetCardName():PAnsiChar;

    property Description   :PAnsiChar read GetDescription;
    property IsShown       :boolean   read GetWindowStatus;
    property IsCardSelected:boolean   read GetCardStatus;
    property AreCardsLoaded:boolean   read GetTemplateStatus;
    property Namespace     :PAnsiChar read GetNamespace write SetNamespace;
    property Parent        :HWND      read fParent;
    property HelpWindow    :HWND      read fHelpWindow write fHelpWindow;
  end;


implementation

{
  mirutils unit is for ConvertFileName function only
  m_api is for TranslateW and TrandlateDialogDefault
}
uses
  common,
{$IFDEF Miranda}
  m_api,mirutils,
{$ENDIF}
  wrapper; // GetDlgText, CB_GetData, CB_AddStrData

const
  globalstorage: PINIFile  = nil;
  globalcount  : cardinal = 0;


const
  BufSize = 2048;

const
  ApiHlpFile = 'plugins\services.ini';

//----- base class -----

constructor tmApiCard.Create(fname:PAnsiChar=nil; aparent:HWND=0);
var
  INIFile: array [0..511] of AnsiChar;
begin
  inherited Create;

  storage:=nil;

  if StrCmp(fname,ApiHlpFile)=0 then // force convert to global
    fname:=nil;

  if fname=nil then
    StrCopy(@INIFile,ApiHlpFile)
{$IFDEF Miranda}
  else
   ConvertFileName(fname,@INIFile)
{$ENDIF}
  ;

  if fname=nil then
  begin
    if globalstorage=nil then
      globalstorage:=CreateIniFile(PAnsiChar(@INIFile),true);
    if globalstorage<>nil then
    begin
      storage:=globalstorage;
      inc(globalcount);
    end;
  end
  else
    storage:=CreateIniFile(PAnsiChar(@INIFile),true);

  if storage<>nil then
  begin
    fHelpWindow:=0;
    current:=nil;
    fParent:=aparent;
  end;

end;

destructor tmApiCard.Destroy;
begin
  if storage<>nil then
  begin
    Close;

    if storage<>globalstorage then
    begin
      FreeIniFile(storage);
    end
    else
    begin
      dec(globalcount);
      if globalcount=0 then
      begin
        FreeIniFile(globalstorage);
        globalstorage:=nil;
      end;
    end;
  end;

  inherited;
end;

//----- property helpers -----

function tmApiCard.GetCardName:PAnsiChar;
begin
  if current<>nil then
    result:=current^.Name
  else
    result:=nil;
end;

function tmApiCard.GetDescription:PAnsiChar;
begin
  if current<>nil then
  begin
    StrDup(result,current^.Key['descr']);
  end
  else
    result:=nil;
end;

function tmApiCard.GetTemplateStatus:boolean;
begin
  result:=(storage<>nil);
end;

function tmApiCard.GetCardStatus:boolean;
begin
  result:=(current<>nil);
end;

function tmApiCard.GetWindowStatus:boolean;
begin
  result:=(HelpWindow<>0);
end;

function tmApiCard.GetNamespace:PAnsiChar;
begin
  if storage<>nil then
    result:=storage^.Namespace
  else
    result:=nil;
end;

procedure tmApiCard.SetNamespace(ns:PAnsiChar);
begin
  if storage<>nil then
  begin
    storage^.Namespace:=ns;
  end;
end;

//----- another functions -----

procedure tmApiCard.Update;
begin
  if fHelpWindow<>0 then
    SendMessage(fHelpWindow,WM_UPDATEHELP,0,LPARAM(self));
end;

function tmApiCard.HashToName(ahash:longword):PAnsiChar;
var
  p:PAnsiChar;
begin
  result:=nil;
  if storage<>nil then
  begin
    p:=storage^.SectionList[nil];
    if p<>nil then
      while p^<>#0 do
      begin
        if ahash=Hash(p,StrLen(p)) then
        begin
          StrDup(result,p);
        end;
        while p^<>#0 do inc(p); inc(p);
      end;
  end;
end;

function tmApiCard.NameFromList(cb:HWND):PAnsiChar;
var
  buf:array [0..255] of AnsiChar;
  pc:PAnsiChar;
  idx:integer;
begin
  pc:=GetDlgText(cb,true);
  idx:=SendMessage(cb,CB_GETCURSEL,0,0);
  if idx<>CB_ERR then
  begin
    SendMessageA(cb,CB_GETLBTEXT,idx,lparam(@buf));
    // edit field is text from list
    if StrCmp(pc,@buf)=0 then
    begin
      mFreeMem(pc);
      result:=HashToName(CB_GetData(cb,idx));
      exit;
    end;
  end;
  // no select or changed text
  result:=pc;
end;

procedure tmApiCard.FillList(combo:HWND;mode:integer=0);
var
  p:PAnsiChar;
begin
{
  GetClassNameA(list,@buf,127);
  if StrCmp(@buf,'COMBOBOX')=0 then
  begin
  end
  else if StrCmp(@buf,'SysListView32') then
  begin
  end;
}
  
  if storage<>nil then
  begin
    SendMessage(combo,CB_RESETCONTENT,0,0);
    p:=storage^.SectionList[nil];
    if p<>nil then
      while p^<>#0 do
      begin
        CB_AddStrData(combo,p,Hash(p,StrLen(p)));
        while p^<>#0 do inc(p); inc(p);
      end;
    SendMessage(combo,CB_SETCURSEL,-1,0);
  end;
end;

function tmApiCard.FillParams(wnd:HWND;paramname:PAnsiChar):PAnsiChar;
var
  buf :array [0..2047] of AnsiChar;
  bufw:array [0..2047] of WideChar;
  j:integer;
  p,pp,pc:PAnsiChar;
  tmp:PWideChar;
begin
  if storage=nil then
  begin
    result:=nil;
    exit;
  end;

  StrCopy(@buf,GetParameter(paramname,''));
  StrDup(result,@buf);

  if wnd=0 then
    exit;

  SendMessage(wnd,CB_RESETCONTENT,0,0);
  if buf[0]<>#0 then
  begin
    p:=@buf;
    GetMem(tmp,BufSize*SizeOf(WideChar));
    repeat
      pc:=StrScan(p,'|');
      if pc<>nil then
        pc^:=#0;

      if (p^ in ['0'..'9']) or ((p^='-') and (p[1] in ['0'..'9'])) then
      begin
        j:=0;
        pp:=p;
        repeat
          bufw[j]:=WideChar(pp^);
          inc(j); inc(pp);
        until (pp^=#0) or (pp^=' ');
        if pp^<>#0 then
        begin
          bufw[j]:=' '; bufw[j+1]:='-'; bufw[j+2]:=' '; inc(j,3);
          FastAnsiToWideBuf(pp+1,tmp);
          StrCopyW(bufw+j,{$IFDEF Miranda}TranslateW{$ENDIF}(tmp));
          SendMessageW(wnd,CB_ADDSTRING,0,lparam(@bufw));
        end
        else
          SendMessageA(wnd,CB_ADDSTRING,0,lparam(p));
      end
      else
      begin
        FastAnsiToWideBuf(p,tmp);
        SendMessageW(wnd,CB_ADDSTRING,0,lparam({$IFDEF Miranda}TranslateW{$ENDIF}(tmp)));
        if (p=@buf) and (StrCmp(p,'structure')=0) then
          break;
      end;
      p:=pc+1;
    until pc=nil;
    FreeMem(tmp);
  end;
  SendMessage(wnd,CB_SETCURSEL,0,0);
end;

function tmApiCard.GetParameter(name:PAnsiChar;default:PAnsiChar=nil):PAnsiChar;
begin
  if current<>nil then
    result:=current^.Key[name]
  else
    result:=nil;
  if result=nil then
    result:=default;
end;

function tmApiCard.SelectCard(tmpl:PAnsiChar):boolean;
begin
  if (tmpl=nil) or (tmpl^=#0) then
    current:=nil
  else
    current:=storage^.Sections[tmpl];

  result:=current<>nil;
end;

procedure tmApiCard.Show;
begin
  //dummy
end;

procedure tmApiCard.Close;
begin
  if fHelpWindow<>0 then
  begin
    DestroyWindow(fHelpWindow);
    fHelpWindow:=0;
  end;
end;

end.
