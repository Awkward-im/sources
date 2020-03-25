{TTA file}
unit fmt_TTA;
{$include compilers.inc}

interface

function ReadTTA(Info:UIntPtr):boolean;


implementation

uses
  wat_api,
  tags,srv_format;

const
  TTA1_SIGN = $31415454;
type
  tTTAHeader = packed record
    id           :dword;
    format       :word;
    channels     :word;
    bitspersample:word;
    samplerate   :dword;
    datalength   :dword;
    crc32        :dword;
  end;

function ReadTTA(Info:UIntPtr):boolean;
var
  f:file of byte;
  hdr:tTTAHeader;
begin
  result:=false;

  AssignFile(f,WATGetStr(Info,siFile));
  Reset(f);
  if IOResult<>0 then
    exit;

  ReadID3v2(f,Info);
  BlockRead(f,hdr,SizeOf(tTTAHeader));
  if hdr.id<>TTA1_SIGN then
    exit;

  WATSet(Info,siChannels  , hdr.channels);
  WATSet(Info,siSamplerate, hdr.samplerate);
  WATSet(Info,siBitrate   , hdr.bitspersample div 1000); //!!
  if hdr.samplerate<>0 then
    WATSet(Info,siLength, hdr.datalength div hdr.samplerate);

  ReadID3v1(f,Info);

  CloseFile(f);
  result:=true;
end;

var
  LocalFormatLink:twFormat;

procedure InitLink;
begin
  LocalFormatLink.Next:=FormatLink;

  LocalFormatLink.This.proc :=@ReadTTA;
  LocalFormatLink.This.ext  :='TTA';
  LocalFormatLink.This.flags:=0;

  FormatLink:=@LocalFormatLink;
end;

initialization
  InitLink;
end.
