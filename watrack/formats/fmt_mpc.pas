{MPC file format}
unit fmt_MPC;
{$include compilers.inc}

interface

function ReadMPC(Info:UIntPtr):boolean;


implementation

uses
  wat_api,
  common,
  tags,srv_format;

const
  DefID = $002B504D;// 'MP+'

function ReadMPC(Info:UIntPtr):boolean;
var
  f:file of byte;
  lbps,lkhz: cardinal;
  tmp:array [0..5] of dword;
  samples,TotalFrames:dword;
  lastframe:dword;
begin
  result:=false;

  AssignFile(f,WATGetStr(Info,siFile));
  Reset(f);
  if IOResult<>0 then
    exit;

  ReadID3v2(f,Info);

  BlockRead(f,tmp,SizeOf(tmp));
  if ((tmp[0] and $FFFFFF)=DefID) and
     (((tmp[0] shr 24) and $0F)>=7) then // sv7-sv8
  begin
    lbps:=0;
    if (tmp[2] and 2)<>0 then
      WATSet(Info,siChannels, 2)
    else
      WATSet(Info,siChannels, 1);
    
    case (tmp[2] and $3000) shr 12 of //C000-14?
      00: lkhz:=44100;
      01: lkhz:=48000;
      02: lkhz:=37800;
      03: lkhz:=32000;
    else
      lkhz:=0;
    end;
    lastframe:=(tmp[5] and $FFF) shr 1;
    samples:=tmp[1]*1152+lastframe;
  end
  else
  begin //4-6
    if not ((tmp[0] and $1FFF) and $3FF) in [4..6] then
      exit;
    lkhz:=44100;
    lbps:=tmp[1] and $1F;
    if ((tmp[0] and $1FFF) and $3FF)=4 then
      TotalFrames:=word(tmp[2])
    else
      TotalFrames:=tmp[2];
    samples:=TotalFrames*1152;
  end;

  if lkhz<>0 then
    WATSet(Info,siLength, samples div lkhz);
  lkhz:=lkhz div 1000;
  if (lbps=0) and (samples<>0) then
// if fs=samples*channels*deep/8 then kbps=khz*deep*channels/1152
// Info.kbps:=(Info.khz*8)*taginfo.FileSize/1152/samples;
    lbps:=(lkhz div 8)*FileSize(f) div samples;  //!!

  WATSet(Info,siBitrate   , lbps);
  WATSet(Info,siSamplerate, lkhz);

  ReadAPEv2(f,Info);
  ReadID3v1(f,Info);

  CloseFile(f);
  result:=true;
end;

var
  LocalFormatLink:twFormat;

procedure InitLink;
begin
  LocalFormatLink.Next:=FormatLink;

  LocalFormatLink.This.proc :=@ReadMPC;
  LocalFormatLink.This.ext  :='MPC';
  LocalFormatLink.This.flags:=0;

  FormatLink:=@LocalFormatLink;
end;

initialization
  InitLink;
end.
