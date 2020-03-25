{AVI file format}
unit fmt_AVI;
{$include compilers.inc}

interface

function ReadAVI(Info:UIntPtr):boolean;


implementation

uses
  wat_api,
  common,
  srv_format;

type
  FOURCC = array [0..3] of AnsiChar;
type
  TBitmapInfoHeader = record
     biSize         : dword;
     biWidth        : longint;
     biHeight       : longint;
     biPlanes       : word;
     biBitCount     : word;
     biCompression  : dword;
     biSizeImage    : dword;
     biXPelsPerMeter: longint;
     biYPelsPerMeter: longint;
     biClrUsed      : dword;
     biClrImportant : dword;
  end;

type
  tChunkHeader = packed record
    case byte of
      0: (Lo,Hi:dword);  {Common}
      1: (ID:FOURCC;     {RIFF}
          Length:dword);
  end;

const
  sRIFF = $46464952;
  sLIST = $5453494C;
  savih = $68697661; { avi header }
  sstrf = $66727473; { stream format }
  sstrh = $68727473; { stream header }
const
  smovi = $69766F6D; {movi list type}
const
  svids = $73646976; {video}
  sauds = $73647561; {audio}
const
  sIART = $54524149; {director}
  sICMT = $544D4349; {comment}
  sICRD = $44524349; {creation date}
  sIGNR = $524E4749; {genre}
  sINAM = $4D414E49; {title}
  sIPRT = $54525049; {part}
  sIPRO = $4F525049; {produced by}
  sISBJ = $4A425349; {subject description}

type
  tWaveFormatEx = packed record
    wFormatTag     :word;
    nChannels      :word;
    nSamplesPerSec :dword;
    nAvgBytesPerSec:dword;
    nBlockAlign    :word;
    wBitsPerSample :word;
    cbSize         :word;

    Reserved1      :word;
    wID            :word;
    fwFlags        :word;
    nBlockSize     :word;
    nFramesPerBlock:word;
    nCodecDelay    :word; {ms}
  end;

type
  tMainAVIHeader = packed record {avih}
    dwMicroSecPerFrame   :dword;
    dwMaxBytesPerSec     :dword;
    dwPaddingGranularity :dword;
    dwFlags              :dword;
    dwTotalFrames        :dword;  { # frames in first movi list}
    dwInitialFrames      :dword;
    dwStreams            :dword;
    dwSuggestedBufferSize:dword;
    dwWidth              :dword;
    dwHeight             :dword;
    dwScale              :dword;
    dwRate               :dword;
    dwStart              :dword;
    dwLength             :dword;
  end;

type
  TAVIExtHeader = packed record {dmlh}
    dwGrandFrames:dword;        {total number of frames in the file}
    dwFuture:array[0..60] of dword;
  end;

type
  tAVIStreamHeader = packed record {strh}
    fccType              :FOURCC; {vids|auds}
    fccHandler           :FOURCC;
    dwFlags              :dword;
    wPriority            :word;
    wLanguage            :word;
    dwInitialFrames      :dword;
    dwScale              :dword;
    dwRate               :dword;
    dwStart              :dword;
    dwLength             :dword;
    dwSuggestedBufferSize:dword;
    dwQuality            :dword;
    dwSampleSize         :dword;
    rcFrame: packed record
      left  :word;
      top   :word;
      right :word;
      bottom:word;
    end;
  end;

var
  vora:dword;

procedure SkipOdd(var f:file; bytes:dword);
var
  i:dword;
begin
  i:=FilePos(f);
  if bytes=0 then
  begin
    if odd(i) then
      Seek(f,i+1);
  end
  else
    Seek(f,i+bytes+(bytes mod 2));
end;

procedure ProcessVideoFormat(var f:file; Size:dword; Info:UIntPtr);
var
  bih:TBitmapInfoHeader;
begin
  BlockRead(f,bih,SizeOf(bih));
  WATSet(Info,siCodec , bih.biCompression);
  WATSet(Info,siWidth , bih.biWidth);
  WATSet(Info,siHeight, bih.biHeight);
  SkipOdd(f,Size-SizeOf(bih));
end;

procedure ProcessAudioFormat(var f:file; Size:dword; Info:UIntPtr);
{WAVEFORMATEX or PCMWAVEFORMAT}
var
  AF:tWaveFormatEx;
begin
  BlockRead(f,AF,SizeOf(AF));
  WATSet(Info,siChannels  , AF.nChannels);
  WATSet(Info,siSamplerate, AF.nSamplesPerSec div 1000);
  WATSet(Info,siBitrate   , (AF.nAvgBytesPerSec*8) div 1000);
  SkipOdd(f,Size-SizeOf(AF));
end;

function ProcessASH(var f:file; Info:UIntPtr):dword;
var
  ASH:tAVIStreamHeader;
  lfps:integer;
begin
  BlockRead(f,ASH,SizeOf(ASH));
  with ASH do
  begin
    if dword(fccType)=svids then
    begin
      lfps:=0;
      if ASH.dwScale<>0 then
      begin
        lfps:=(ASH.dwRate*100) div ASH.dwScale;
        WATSet(Info,siFPS, lfps);
      end;
      if lfps<>0 then
        WATSet(Info,siLength, (ASH.dwLength*100) div lfps);
      ProcessASH:=1
    end
    else if dword(fccType)=sauds then ProcessASH:=2
    else ProcessASH:=0;
  end;
end;

procedure ProcessMAH(var f:file; Info:UIntPtr);
var
  MAH:tMainAVIHeader;
begin
  BlockRead(f,MAH,SizeOf(MAH));
//  WATSet(Info,siWidth , MAH.dwWidth);
//  WATSet(Info,siHeight, MAH.dwHeight);
//  WATSet(Info,siFPS   , 100000000 div MAH.dwMicroSecPerFrame);
end;

function ProcessChunk(var f:file; Info:UIntPtr):dword;
var
  lTotal:dword;
  Chunk:tChunkHeader;
  cType:FOURCC;
  ls:PAnsiChar;
begin
  SkipOdd(f,0);
  BlockRead(f,Chunk,SizeOF(Chunk),lTotal);
  if (lTotal=0) or (Chunk.Lo=0) then
  begin
    result:=FileSize(f);
    Seek(f,result);
    exit;
  end;

  result:=Chunk.Length+SizeOf(Chunk);
  case Chunk.Lo of
    sRIFF,sLIST: begin
      BlockRead(f,cType,SizeOf(cType));
      if dword(cType)=smovi then
        SkipOdd(f,Chunk.Length-SizeOf(cType)) // result:=FileSize(f)
      else
      begin
        lTotal:=SizeOf(FOURCC);
        while lTotal<Chunk.Length do
          inc(lTotal,ProcessChunk(f,Info));
      end;
    end;
    sIART,sICMT,sICRD,sIGNR,sINAM,sIPRT,sIPRO,sISBJ: begin
      mGetMem(ls,Chunk.Length);
      BlockRead(f,ls^,Chunk.Length);
      case Chunk.Lo of
        sIART: begin
          WATSetStr(Info,siArtist, ls, CP_ACP);
        end;
        sICMT: begin
          if WATIsEmpty(Info,siComment) then
            WATSetStr(Info,siComment, ls, CP_ACP);
        end;
        sICRD: begin
          WATSetStr(Info,siYear, ls, CP_ACP);
        end;
        sIGNR: begin
          WATSetStr(Info,siGenre, ls, CP_ACP);
        end;
        sINAM: begin
          WATSetStr(Info,siTitle, ls, CP_ACP);
        end;
        sIPRT: begin
          WATSet(Info,siTrack, StrToInt(ls));
        end;
        sIPRO: begin
          if WATIsEmpty(Info,siArtist) then
            WATSetStr(Info,siArtist, ls, CP_ACP);
        end;
        sISBJ: begin
          WATSetStr(Info,siComment, ls, CP_ACP);
        end;
      end;
      mFreeMem(ls);
    end;
    savih: begin
      ProcessMAH(f,Info);
    end;
    sstrh: begin
      vora:=ProcessASH(f,Info);
    end;
    sstrf: begin
      case vora of
        1: ProcessVideoFormat(f,Chunk.Hi,Info);
        2: ProcessAudioFormat(f,Chunk.Hi,Info);
      else
      end;
    end;
    else
      SkipOdd(f,Chunk.Length);
  end;
end;

function ReadAVI(Info:UIntPtr):boolean;
var
  f:file of byte;
begin
  result:=false;
  AssignFile(f,WATGetStr(Info,siFile));
  Reset(f);
  if IOResult<>0 then
    exit;

  ProcessChunk(f,Info);
  CloseFile(f);
  result:=true;
end;

var
  LocalFormatLinkAVI,
  LocalFormatLinkDIVX:twFormat;

procedure InitLink;
begin
  LocalFormatLinkAVI.Next:=FormatLink;

  LocalFormatLinkAVI.This.proc :=@ReadAVI;
  LocalFormatLinkAVI.This.ext  :='AVI';
  LocalFormatLinkAVI.This.flags:=WAT_OPT_VIDEO;

  FormatLink:=@LocalFormatLinkAVI;

  LocalFormatLinkDIVX.Next:=FormatLink;

  LocalFormatLinkDIVX.This.proc :=@ReadAVI;
  LocalFormatLinkDIVX.This.ext  :='DIVX';
  LocalFormatLinkDIVX.This.flags:=WAT_OPT_VIDEO;

  FormatLink:=@LocalFormatLinkDIVX;
end;

initialization
  InitLink;
end.
