{Dummy (playlist) file}
unit fmt_Dummy;
{$include compilers.inc}

interface

function ReadDummy(Info:UIntPtr):boolean;


implementation

uses
  wat_api,
  srv_format;

function ReadDummy(Info:UIntPtr):boolean;
begin
  result:=true;
end;

var
  LocalFormatLinkCUE:twFormat;

procedure InitLink;
begin
  LocalFormatLinkCUE.Next:=FormatLink;

  LocalFormatLinkCUE.This.proc :=@ReadDummy;
  LocalFormatLinkCUE.This.ext  :='CUE';
  LocalFormatLinkCUE.This.flags:=WAT_OPT_CONTAINER;

  FormatLink:=@LocalFormatLinkCUE;
end;

initialization
  InitLink;
end.
