{OFR file}
unit fmt_OFR;
{$include compilers.inc}

interface

function ReadOFR(Info:UIntPtr):boolean;


implementation

uses
  wat_api,
  tags,srv_format;

type
  tMain = packed record
    ID         :dword; // 'OFR '
    Size       :dword; // 15
    SamplesLo  :dword;
    SamplesHi  :word;
    SampleType :byte;
    ChannelsMap:byte;
    Samplerate :dword;
    Encoder    :word;
    Compression:byte;
  end;

function ReadOFR(Info:UIntPtr):boolean;
var
  f:file of byte;
  Hdr:tMain;
  lc,ls:integer;
  Samples:int64;
begin
  result:=false;

  AssignFile(f,WATGetStr(Info,siFile));
  Reset(f);
  if IOResult<>0 then
    exit;

  ReadID3v2(f,Info);

  BlockRead(f,Hdr,SizeOf(Hdr));
  Samples:=Hdr.SamplesLo+Hdr.SamplesHi*$10000;
  lc:=Hdr.ChannelsMap+1;
  ls:=Hdr.Samplerate div 1000;
  WATSet(Info,siChannels  , lc);
  WATSet(Info,siSamplerate, ls);
  WATSet(Info,siLength    , (Samples div lc)*ls);

  ReadAPEv2(f,Info);
  ReadID3v1(f,Info);

  CloseFile(f);
  result:=true;
end;

var
  LocalFormatLinkOFR,
  LocalFormatLinkOFS:twFormat;

procedure InitLink;
begin
  LocalFormatLinkOFR.Next:=FormatLink;

  LocalFormatLinkOFR.This.proc :=@ReadOFR;
  LocalFormatLinkOFR.This.ext  :='OFR';
  LocalFormatLinkOFR.This.flags:=0;

  FormatLink:=@LocalFormatLinkOFR;

  LocalFormatLinkOFS.Next:=FormatLink;

  LocalFormatLinkOFS.This.proc :=@ReadOFR;
  LocalFormatLinkOFS.This.ext  :='OFS';
  LocalFormatLinkOFS.This.flags:=0;

  FormatLink:=@LocalFormatLinkOFS;
end;

initialization
  InitLink;
end.
