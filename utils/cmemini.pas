{$i mydefs.inc}

{.$DEFINE UseHash}   // Use hashes for section/key search
{.$DEFINE UseStrings}

unit cmemini;

interface

{$DEFINE Interface}

type
  tINIOptions = set of (
//    AUTOSAVE,         // (realtime) ?? autosave on free
    USENAMESPACE,     // (realtime) top level - uses namespaces
    CHECKCOMBO,       // (realtime) top level - Check section name for NS:Section / combine to it
    CASESENSITIVE,    // (startup)  global - case sensitive for names
    SIMPLEBOOL,       // (realtime) parameter - save boolean as 0/1 or false/true
    KEEPEMPTY         // (startup)  almost global - keep empty parameter at output
  );

const
  DefaultSectionName = '-default-';

type
  pINIFile = ^tINIFile;
  pININamespace = ^tININamespace;

{$include memini\section.inc}

{$include memini\namespace.inc}

{$include memini\inifile.inc}

procedure CreateIniFile(out ini:tINIFile;use_namespace:boolean=false);          overload;
function  CreateIniFile(                 use_namespace:boolean=false):pINIFile; overload;

procedure CreateIniFile(out ini:tINIFile;const afname:AnsiString;use_ns:boolean=false); overload;
procedure CreateIniFile(out ini:tINIFile;      afname:PAnsiChar ;use_ns:boolean=false); overload;
procedure CreateIniFile(out ini:tINIFile;      afname:PWideChar ;use_ns:boolean=false); overload;

function  CreateIniFile(const afname:AnsiString;use_ns:boolean=false):pINIFile; overload;
function  CreateIniFile(      afname:PAnsiChar ;use_ns:boolean=false):pINIFile; overload;
function  CreateIniFile(      afname:PWideChar ;use_ns:boolean=false):pINIFile; overload;

procedure FreeIniFile(    ini:pINIFile); overload;
procedure FreeIniFile(var ini:tINIFile); overload;

{$UNDEF Interface}

implementation

uses
  common;

const
  MaxLineLen = 60;
  UnbreakLen = 5;
const
  ns_separator   = ':';
  line_separator = '\';
const
  increment  = 8;
const
  F_NAME       = $02;   // (section/parameter) name was allocated
  F_VALUE      = $04;   // (parameter) value was allocated
  F_USED       = $08;   // (section) section is not empty

  F_IGNORENS   = $100;  // (global)
  // defined in code but it ok
  F_BUFFER     = $200;  // (file reading) translate content from buffer (no allocate needs)
  // defined in code
  F_COMBOCHK   = $400;  //?? Check section name for NS:Section / combine to it
  F_KEEPEMPTY  = $2000; // keep empty params
  // not realized
  F_CASE       = $4000; // case sensitive
  F_SIMPLEBOOL = $8000; // save boolean as 0/1 or false/true

{
  section   - (param list)     param name changed / param added / param deleted
  section   - (text export)    param value changed
  namespace - (section list)   section name changed / section added / section deleted
  file      - (namespace list) namespace name changed / namespace added / namespace deleted
}
  F_NCHANGED  = $40;   // parameter / Section list changed
  F_VCHANGED  = $80;   // parameter values changed (need to rebuild text representation)
  F_CHANGED   = F_NCHANGED + F_VCHANGED;
  F_FLUSH     = $10;   //!! not realized yet. Has changed, need to flush 
  // content changed (need rebuild or not?), filename changed

//----- Support functions -----

{$IFDEF UseHash}
function HashOf(txt:PAnsiChar; acase:boolean):cardinal;
var
  buf:array [0..255] of AnsiChar;
  i,j:integer;
begin
  if (txt=nil) or (txt^=#0) then
    result:=0
  else
  begin
    j:=StrLen(txt);
    if acase then
      result:=Hash(txt,j)
    else
    begin
      StrCopy(buf,txt);
      for i:=0 to j-1 do
        if buf[i] in ['a'..'z'] then buf[i]:=AnsiChar(ORD(buf[i])-ORD('a')+ORD('A'));
      result:=Hash(@buf,j);
    end;
  end;
end;
{$ENDIF}

//===== Section object =====

{$include memini\section.inc}

//===== INI file namespaces =====

{$include memini\namespace.inc}

//===== INI file processing =====

{$include memini\inifile.inc}

//----- Object creation -----

procedure OpenFileStorage(var ini:tINIFile);
var
  f:tmifile;
  tmp:PAnsiChar;
  size:integer;
begin
  if ini.FileName=nil then
    exit;

  AssignFile(f,ini.FileName);
{$IFOPT I-}
  Reset(f);
  if IOResult()=0 then
  begin
{$ELSE}
  try
    Reset(f);
{$ENDIF}
    size:=system.FileSize(f);
    if size>0 then
    begin
      mGetMem  (  tmp ,size+1);
      BlockRead(f,tmp^,size);
      tmp[size]:=#0;
      ini.Text:=tmp;
      mFreeMem(tmp);
    end;
    CloseFile(f);
{$IFOPT I-}
  end
  else
  begin
{$ELSE}
  except
{$ENDIF}
  end;
end;

procedure CreateIniFile(out ini:tINIFile;use_namespace:boolean=false);
begin
  FillChar(ini,SizeOf(ini),0);
  ini.AddNamespace(nil);
  if not use_namespace then
    ini.flags:=F_IGNORENS;
end;

function CreateIniFile(use_namespace:boolean=false):pINIFile;
begin
  New(result);
  if result<>nil then
    CreateIniFile(result^,use_namespace);
{
  FillChar(result^,SizeOf(result^),0);
  if not use_namespace then
    result^.flags:=F_IGNORENS;
}
end;

procedure CreateIniFile(out ini:tINIFile;const afname:AnsiString;use_ns:boolean=false);
begin
  CreateIniFile(ini,use_ns);
  StrDup(ini.ffilename,pointer(afname));
  OpenFileStorage(ini);
end;

procedure CreateIniFile(out ini:tINIFile;afname:PAnsiChar;use_ns:boolean=false);
begin
  CreateIniFile(ini,use_ns);
  StrDup(ini.ffilename,afname);
  OpenFileStorage(ini);
end;

procedure CreateIniFile(out ini:tINIFile;afname:PWideChar;use_ns:boolean=false);
begin
  CreateIniFile(ini,use_ns);
  WideToAnsi(afname,ini.ffilename);
  OpenFileStorage(ini);
end;

function CreateIniFile(afname:PWideChar;use_ns:boolean=false):pINIFile;
begin
  result:=CreateIniFile(use_ns);
  if result<>nil then
  begin
    WideToAnsi(afname,result^.ffilename);
    OpenFileStorage(result^);
  end;
end;

function CreateIniFile(afname:PAnsiChar;use_ns:boolean=false):pINIFile;
begin
  result:=CreateIniFile(use_ns);
  if result<>nil then
  begin
    StrDup(result^.ffilename,afname);
    OpenFileStorage(result^);
  end;
end;

function CreateIniFile(const afname:AnsiString;use_ns:boolean=false):pINIFile;
begin
  result:=CreateIniFile(use_ns);
  if result<>nil then
  begin
    StrDup(result^.ffilename,pointer(afname));
    OpenFileStorage(result^);
  end;
end;

procedure FreeIniFile(ini:pINIFile);
begin
  if ini<>nil then
  begin
    ini^.Free;
    Dispose(ini);
  end;
end;

procedure FreeIniFile(var ini:tINIFile);
begin
  ini.Free;
//??  FillChar(ini,SizeOf(ini),0);
end;

end.
