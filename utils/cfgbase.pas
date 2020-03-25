{$i mydefs.inc}
{.$DEFINE UseSysUtils}
unit cfgbase;

interface

{$DEFINE Interface}

//----- Options (not realized yet) -----

{
  save on changes or manually?
}
type
  tCfgOption = (
    CFG_USENAMESPACE,     // (startup) uses namespaces
    CFG_CHECKCOMBO,       // (runtime) Check section name for NS:Section / combine to it
    CFG_CASESENSITIVE,    // (startup) case sensitive for names
    CFG_COMPLEXBOOL,      // (runtime) parameter - save boolean as 0/1 or false/true
    CFG_KEEPEMPTY         // (runtime) keep empty parameter at output
  );
  tCfgOptions = set of tCfgOption;

const
  ns_separator = ':';

//----- Log -----

const
  //can be several
  cldNamespace = $01;
  cldSection   = $02;
  cldParameter = $04;
  cldComment   = $08;
  cldObject    = $FF;

  // can be one only
  cldChange    =   0 shl 8; // 0, coz always (dummy)
  cldCreate    =   1 shl 8;
  cldRename    =   2 shl 8;
  cldDelete    =   3 shl 8;
  cldChanged   =   4 shl 8;
  cldAction    = $FF shl 8;

const
  cldtText     =   0 shl 16;
  cldtInteger  =   1 shl 16;
  cldtBoolean  =   2 shl 16;
  cldtBinary   =   3 shl 16;
  cldtFloat    =   4 shl 16;
  cldtDateTime =   5 shl 16;
  cldtUnicode  =   6 shl 16;
  cldtPointer  =   7 shl 16;
  cldtData     = $FF shl 16;

type
  tCfgEvent = function(ans,asection,akey:PAnsiChar; aevent:cardinal):integer of object;

{$include basecfg\parambase.inc}
{$include basecfg\sectbase.inc}
{$include basecfg\nsbase.inc}
{$include basecfg\cfgbase.inc}

// use_namespace:boolean=false -> tINIOptions 
procedure CreateConfig(out cfg:tCfgBase;opt:tCfgOptions=[]);          overload;
function  CreateConfig(                 opt:tCfgOptions=[]):pCfgBase; overload;

procedure FreeConfig(    cfg:pCfgBase); overload;
procedure FreeConfig(var cfg:tCfgBase); overload;

{$UNDEF Interface}

implementation

uses
{$IFDEF UseSysUtils}
  SysUtils,
{$ENDIF}
  common;

const
  DefaultSectionName = '-default-';
  DefaultParamName   = 'default';
const
  decimals  = 6;
  increment = 8;

//----- Support -----

function BinaryDecode(out dst:pointer; src:PAnsiChar; alloc:boolean=true):Cardinal;
var
  ldst:PAnsiChar;
begin
  if (src<>nil) and (src^<>#0) then
  begin
    if alloc then
      mGetMem(dst,StrLen(src) div 2);

    ldst:=dst;
    while src^<>#0 do
    begin
      ldst^:=AnsiChar(common.HexToInt(src,2)); // or common.HexToByte(src);
      inc(src,2);
      inc(ldst);
    end;
    result:=PAnsiChar(ldst)-PAnsiChar(dst);
  end
  else
  begin
    if alloc then
      dst:=nil;
    result:=0;
  end;
end;

function BinaryEncode(dst:PAnsiChar; src:pointer; len:cardinal):PAnsiChar;
begin
  if (len=0) or (src=nil) then
  begin
    result:=nil;
  end
  else
  begin
    result:=dst;

    while len>0 do
    begin
      dst^:=HexDigitChr[PByte(src)^ shr 4]; inc(dst);
      dst^:=HexDigitChr[PByte(src)^ and $0F];

      inc(PByte(src));
      inc(dst);
      dec(len);
    end;
    dst^:=#0;
  end;
end;

//===== Parameter object =====

{$include basecfg\parambase.inc}

//===== Section object =====

{$include basecfg\sectbase.inc}

//===== INI file namespaces =====

{$include basecfg\nsbase.inc}

//===== INI file processing =====

{$include basecfg\cfgbase.inc}

//----- Object creation -----

procedure CreateConfig(out cfg:tCfgBase; opt:tCfgOptions=[]);
begin
  FillChar(cfg,SizeOf(cfg),0);
  cfg.AddNamespace(nil);
  cfg.Section[nil,nil];
  cfg.Options:=opt;
end;

function CreateConfig(opt:tCfgOptions=[]):pCfgBase;
begin
  New(result);
  if result<>nil then
    CreateConfig(result^,opt);
end;

procedure FreeConfig(cfg:pCfgBase);
begin
  if cfg<>nil then
  begin
    cfg^.Free;
    Dispose(cfg);
  end;
end;

procedure FreeConfig(var cfg:tCfgBase);
begin
  cfg.Free;
end;

end.
