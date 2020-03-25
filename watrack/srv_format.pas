{format service}
{$include compilers.inc}
unit srv_format;

interface

//----- direct work with formats -----

const
  MaxExtLen = 15;
type
  tReadFormatProc = function(Info:UIntPtr):boolean;
  pMusicFormat = ^tMusicFormat;
  tMusicFormat = record
    proc :tReadFormatProc;
    ext  :array [0..MaxExtLen] of AnsiChar;
    flags:cardinal;
  end;

function ServiceFormat(code:cardinal;data:pointer):IntPtr;
{
  RegisterFormat calls ServiceFormat with parameters:
  awParam=WAT_ACT_REGISTER
  alParam=pMusicFormat
}

type
  TMusEnumProc = function(param:pMusicFormat;alParam:pointer):boolean;stdcall;

function EnumFormats(param:TMusEnumProc;alParam:pointer):longbool;

function GetActiveFormat:pMusicFormat;

//----- additional functions -----

function CheckExt   (const fname:AnsiString):integer;
function isContainer(const fname:AnsiString):boolean;

//----- init/free procedures -----

procedure ClearFormats;

type
  pwFormat = ^twFormat;
  twFormat = record
    This:tMusicFormat;
    Next:pwFormat;
  end;

const
  FormatLink:pwFormat=nil;

function ProcessFormatLink:integer;


//=================== implementation =====================

implementation

uses
  wat_api,common,simplelist;

var
  fmtLink:TSimpleList;

//----- direct work with formats -----

function GetActiveFormat:pMusicFormat; {$IFDEF AllowInline}inline;{$ENDIF}
begin
//  if fmtLink<>nil then
    result:=fmtLink.Items[0]
//  else result:=nil;
end;

{
  Enum format list, copy - to avoid conflict with adding/deleting formats while enums
}
function EnumFormats(param:TMusEnumProc;alParam:pointer):longbool;
var
  tmpa:TSimpleList;
  i:integer;
begin
  if {(fmtLink<>nil) and} (fmtLink.Count>0) and (@param<>nil) then
  begin
    tmpa.Init(SizeOf(TMusicFormat));
    tmpa.AddList(fmtLink);

    for i:=0 to tmpa.Count-1 do
    begin
      pMusicFormat(tmpa.Items[i])^.proc:=nil;
      if not param(tmpa.Items[i],alParam) then break;
    end;

    tmpa.Free;
    result:=true;
  end
  else
    result:=false;
end;

function FindFormat(ext:PAnsiChar):integer;
var
  i:cardinal;
begin
//  if fmtLink<>nil then
  begin
    i:=0;
    while i<fmtLink.Count do
    begin
      if StrCmp(pMusicFormat(fmtLink.Items[i])^.ext,ext)=0 then
      begin
        result:=i;
        exit;
      end;
      inc(i);
    end;
  end;
  result:=WAT_RES_NOTFOUND;
end;

//!! case-sensitive (but GetExt return Upper case ext)
function CheckExt(const fname:AnsiString):integer;
var
  ext:array [0..MaxExtLen] of AnsiChar;
  i:integer;
begin
{
  ext:=UpCase(ExtractFileExt(fname));
  if ext<>'' then
}
  GetExt(PAnsiChar(fname),PAnsiChar(@ext));
  if ext[0]<>#0 then
  begin
    i:=FindFormat(PAnsiChar(@ext));
  end
  else
    i:=WAT_RES_NOTFOUND;
  
  
  if i<>WAT_RES_NOTFOUND then
  begin
    if (pMusicFormat(fmtLink.Items[i])^.flags and WAT_OPT_DISABLED)=0 then
    begin
      fmtLink.ToTop(i);
      result:=WAT_RES_OK;
    end
    else
      result:=WAT_RES_DISABLED;
  end
  else
    result:=WAT_RES_NOTFOUND;
end;

function isContainer(const fname:AnsiString):boolean;
begin
  if CheckExt(fname)=WAT_RES_OK then
  begin
    result:=(GetActiveFormat^.flags and WAT_OPT_CONTAINER)<>0;
  end
  else
    result:=false;
end;

//----- Main service -----

function ServiceFormat(code:cardinal;data:pointer):IntPtr;
var
  p:integer;
begin
  result:=WAT_RES_NOTFOUND;

  //-- main service, format register
  if word(code)=WAT_ACT_REGISTER then
  begin
    if @pMusicFormat(data)^.proc=nil then
      exit;

    p:=FindFormat(pMusicFormat(data)^.ext);
    if (p=WAT_RES_NOTFOUND) or ((code and WAT_ACT_REPLACE)<>0) then
    begin
      if (p<>WAT_RES_NOTFOUND) and 
         ((pMusicFormat(fmtLink.Items[p])^.flags and WAT_OPT_ONLYONE)<>0) then
        exit;

      if p=WAT_RES_NOTFOUND then
      begin
        result:=WAT_RES_OK;
        fmtLink.Add(data);
      end
      else
      begin
        result:=IntPtr(@PMusicFormat(fmtLink.Items[p])^.proc);
        fmtLink.Items[p]:=data;
      end;

    end;
  end
  else
  begin
    p:=FindFormat(PAnsiChar(data));
    if p<>WAT_RES_NOTFOUND then
      case word(code) of

        WAT_ACT_UNREGISTER: begin
          fmtLink.Delete(p);
          result:=WAT_RES_OK;
        end;
        
        WAT_ACT_DISABLE: begin
          // SetFlag(pMusicFormat(fmtLink[p])^.flags, WAT_OPT_DISABLED);
          pMusicFormat(fmtLink.Items[p])^.flags:=pMusicFormat(fmtLink.Items[p])^.flags or WAT_OPT_DISABLED;
          result:=WAT_RES_DISABLED;
        end;
        
        WAT_ACT_ENABLE: begin
          // ClearFlag(pMusicFormat(plyLink[p])^.flags, WAT_OPT_DISABLED);
          pMusicFormat(fmtLink.Items[p])^.flags:=pMusicFormat(fmtLink.Items[p])^.flags and not WAT_OPT_DISABLED;
          result:=WAT_RES_ENABLED;
        end;

        WAT_ACT_GETSTATUS: begin
          if (pMusicFormat(fmtLink.Items[p])^.flags and WAT_OPT_DISABLED)<>0 then
            result:=WAT_RES_DISABLED
          else
            result:=WAT_RES_ENABLED;
        end;

      end;

  end;
end;

//----- Init/Free procedures -----

function ProcessFormatLink:integer;
var
  lptr:pwFormat;
begin
  result:=0;
  fmtLink.Init(SizeOf(TMusicFormat));
  lptr:=FormatLink;
  while lptr<>nil do
  begin
    lptr^.This.flags:=lptr^.This.flags or WAT_OPT_INTERNAL;
    ServiceFormat(WAT_ACT_REGISTER,@(lptr^.This));
    inc(result);
    lptr:=lptr^.Next;
  end;
end;

procedure ClearFormats;
begin
  fmtLink.Free;
end;

end.
