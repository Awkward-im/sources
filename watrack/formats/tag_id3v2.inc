{ID3v2 tag}

{$IFDEF Interface}

function ReadID3v2(var f:file; Info:UIntPtr):longint;

{$ELSE}

const
  frmTRK = $4B5254;
  frmTT2 = $325454;
  frmTP1 = $315054;
  frmTAL = $4C4154;
  frmTYE = $455954;
  frmCOM = $4D4F43;
  frmTCO = $4F4354;
//  frmTCM = $;'; New: 'TCOM'),
//  frmTEN = $;'; New: 'TENC'),
//  frmTCR = $;'; New: 'TCOP'),
//  frmWXX = $;'; New: 'WXXX'),
  frmTT1 = $315454;
//  frmTLA = $;'; New: 'TLAN'),
  frmTOA = $414F54;
  frmULT = $544C55;
  frmSLT = $544C53;
  frmTXX = $585854;
  frmPIC = $434950;

  frmTIT1 = $31544954; // Content group description
  frmTIT2 = $32544954; // Title/songname/content description
  frmTIT3 = $33544954; // Subtitle/Description refinement
  frmTALB = $424C4154; // Album/Movie/Show title
  frmTOAL = $4C414F54; // Original album/movie/show title
  frmTRCK = $4B435254; // Track number/Position in set
  frmTYER = $52455954; // Year
  frmTDRC = $43524454; // Year
  frmTORY = $59524F54; // Original release year
  frmTPE1 = $31455054; // Lead performer(s)/Soloist(s)
  frmTPE2 = $32455054; // Band/orchestra/accompaniment
  frmTPE3 = $33455054; // Conductor/performer refinement
  frmTPE4 = $34455054; // Interpreted, remixed, or otherwise modified by
  frmTOPE = $45504F54; // Original artist(s)/performer(s)
  frmTCON = $4E4F4354; // Content type
  frmCOMM = $4D4D4F43; // Comments
  frmUSLT = $544C5355; // Unsynchronised lyrics
  frmSYLT = $544C5953; // Synchronised lyrics
  frmTXXX = $58585854; // User defined text
  frmAPIC = $43495041; // Attached picture
const
  TAG2Sign = 'ID3';
const
  ExtIDHdrMask=$40;
  FooterPresent=$10;
type
  TID3v2TagHdr = packed record
    ID     :array [0..2] of AnsiChar;
    Version:word;
    Flags  :byte;
    TagSize:dword;
  end;
  PID3v2TagHdr = ^TID3v2TagHdr;
type
  tID3v2FrameHdr = packed record
    ID:dword;
    Size:dword;
    Flags:word;
  end;
  pID3v2FrameHdr = ^tID3v2FrameHdr;
  tID3v2FrameHdrOld = packed record
    ID  : array [0..2] of byte; { Frame ID }
    Size: array [0..2] of byte; { Size excluding header }
  end;
  pID3v2FrameHdrOld = ^tID3v2FrameHdrOld;

const
  cp: array [0..3] of integer = (CP_ACP, CP_UTF16, CP_UTF16, CP_UTF8);

var
  Unsync:boolean;

function ID3v2_Correct(data:dword):dword;
type
  l2b=packed record
    b:array [0..3] of byte;
  end;
begin
  result:=l2b(data).b[3];
  inc(result,dword(l2b(data).b[0]) shl 21);
  inc(result,dword(l2b(data).b[1]) shl 14);
  inc(result,dword(l2b(data).b[2]) shl 7);
end;

function ID3v2_ReadTagStr1(var dst:PAnsiChar; ptr:PAnsiChar; alen:integer; enc:integer):PAnsiChar;
begin
  dst:=nil;
  if (enc=0) or (enc=3) then // ANSI or UTF8
  begin
    if ptr^=#0 then
      alen:=0
    else
      while (alen>0) and (ptr[alen-1]=#0) do dec(alen);

    if alen>0 then
    begin
      StrDup(dst,ptr,alen);
    end
  end
  else // Unicode
  begin
    if pword(ptr)^>0 then
    begin
      alen:=alen div SizeOf(WideChar);
      StrDupW(PWideChar(dst),pWideChar(ptr),alen);
      ChangeUnicode(PWideChar(dst));
    end;
  end;
  result:=dst;
end;

function ID3v2_ReadTagStr(var dst:PAnsiChar; ptr:PAnsiChar; alen:integer):PAnsiChar;
var
  enc:byte;
begin
  enc:=ORD(ptr^);
  inc(ptr);
  dec(alen);
  if alen>0 then
    ID3v2_ReadTagStr1(dst,ptr,alen,enc)
  else
    dst:=nil;

  result:=dst;
end;

procedure ID3v2_CheckLyric(Info:UIntPtr; ptr:PAnsiChar; len:integer);
var
  src:PAnsiChar;
  enc:byte;
begin
  if not WATIsEmpty(Info,siLyric) then exit;

  src:=ptr; //??

  enc:=ord(ptr^);
  inc(ptr);

  // Skip language
  inc(ptr,3);

  // Skip Content descriptor
  if (enc=0) or (enc=3) then
  begin
    while ptr^<>#0 do inc(ptr);
    inc(ptr);
  end
  else
  begin
    while pWord(ptr)^<>0 do inc(ptr,2);
    inc(ptr,2);
  end;

  dec(len,ptr-src);
  WATSetStr(Info,siLyric, ID3v2_ReadTagStr1(src, ptr,len,enc), cp[enc]);
  mFreeMem(src);
end;

procedure ID3v2_CheckSyncLyric(Info:UIntPtr; ptr:PAnsiChar; len:integer);
var
  dst:pointer;
  org:PAnsiChar;
  orgw,ptrw:pWideChar;
  enc:byte;
begin
  if not WATIsEmpty(Info,siLyric) then exit;

  enc:=ord(ptr^);
  inc(ptr);

  // Skip language and time stamp format
  inc(ptr,4);
  // Check for Content type = lyric
  if ptr^<>#1 then exit;
  inc(ptr);

  dec(len,6); //??
  mGetMem(dst,len+2);  // Keep 2 bytes for text terminator
  FillChar(dst^,len+2,0);

  // Ansi or UTF8
  if (enc=0) or (enc=3) then
  begin
    // ??
    while ptr^<>#0 do
    begin
      inc(ptr);
      dec(len);
    end;
    inc(ptr);
    dec(len);

    // removing timestamps
    org:=PAnsiChar(dst);
    while len>0 do
    begin
      // Copying content
      while ptr^<>#0 do
      begin
        org^:=ptr^; inc(org); inc(ptr);
        dec(len);
      end;
      // Skip terminator+timestamp
      inc(ptr,1+4);
      dec(len,1+4);
    end;
  end
  // Unicode
  else
  begin
    orgw:=dst;
    //??
    ptrw:=pWideChar(ptr);
    while ptrw^<>#0 do
    begin
      inc(ptrw);
      dec(len,SizeOf(WideChar));
    end;
    inc(ptrw);
    dec(len,SizeOf(WideChar));

    while len>0 do
    begin
      while ptrw^<>#0 do
      begin
        orgw^:=ptrw^; inc(orgw); inc(ptrw);
        dec(len,SizeOf(WideChar));
      end;
      inc(ptrw,1+2); // terminator + timestamp
      dec(len,SizeOf(WideChar)+4);
    end;
  end;

  WATSetStr(Info,siLyric, dst, cp[enc]);
  mFreeMem(dst);
end;

procedure ID3v2_CheckUserLyric(Info:UIntPtr; ptr:PAnsiChar; len:integer);
var
  dst:pointer;
  enc:byte;
begin
  if not WATIsEmpty(Info,siLyric) then exit;

  enc:=ord(ptr^);
  inc(ptr);
  dec(len); //??

  if (enc=0) or (enc=3) then
  begin
    if StrCmp(ptr,'LYRICS')<>0 then
      exit;
    dec(len,7);
    inc(ptr,7);
  end
  else
  begin
    if StrCmpW(PWideChar(ptr),'LYRICS')<>0 then
      exit;
    dec(len,7*SizeOf(WideChar));
    inc(ptr,7*SizeOf(WideChar));
  end;

  WATSetStr(Info,siLyric, ID3v2_ReadTagStr1(dst, ptr,len,enc), cp[enc]);
  mFreeMem(dst);
end;

procedure ID3v2_CheckCover(tag:integer; Info:UIntPtr; ptr:PAnsiChar; len:integer);
var
  org:PAnsiChar;
  ext:dword;
  enc:byte;
begin
  if not WATIsEmpty(Info,siCover) then exit;

  org:=ptr;
  enc:=ord(ptr^); inc(ptr);
  if (pdword(ptr)^ and $FFFFFF)=$3E2D2D then exit; // as '-->'
  if tag=frmAPIC then
  begin
    ext:=GetImageType(nil,ptr);
    repeat inc(ptr) until ptr^=#0; inc(ptr);
  end
  else
  begin
    ext:=pdword(ptr)^ and $FFFFFF;
    inc(ptr,3);
  end;

  if not ord(ptr^) in [0,3,4,6] then exit;
  inc(ptr);
  if (enc=0) or (enc=3) then
  begin
    while ptr^<>#0 do inc(ptr);
    inc(ptr);
  end
  else
  begin
    while pWord(ptr)^<>0 do inc(ptr,2);
    inc(ptr,2);
  end;
  dec(len,ptr-org);

  if ext=0 then
    ext:=GetImageType(pByte(ptr));
  if ext<>0 then
  begin
//    FastAnsiToWideBuf(PAnsiChar(@ext),pWideChar(@extw));
    WATSetStr(Info,siCover, SaveTemporary(ptr,len,PAnsiChar(@ext)),CP_ACP); //!!
  end;
end;

function ID3v2_PreReadTag(var Frm:tID3v2FrameHdr; var src:PAnsiChar; ver:integer):PAnsiChar;
var
  i:cardinal;
  dst:PAnsiChar;
begin
  mGetMem(result,Frm.Size);
  if Unsync or ((Frm.Flags and $0200)<>0) then
  begin
    dst:=result;
    i:=0;
    while i<Frm.Size do
    begin
      dst^:=src^;
      inc(src);
      if (dst^=#$FF) and (src^=#0) then
      begin
        inc(src);
        if ver=4 then inc(i);
      end;
      inc(dst);
      inc(i);
    end
  end
  else
  begin
    move(src^,result^,Frm.Size);
    inc(src,Frm.Size);
  end;
end;

procedure ID3v2_ReadTag2(ver:integer; tag:PAnsiChar; Size:integer; Info:UIntPtr);
var
  Frm:tID3v2FrameHdr;
  FrmOld:tID3v2FrameHdrOld;
  tmp:integer;
  lptr,ptr,buf:PAnsiChar;
  fArtist,fTitle,fAlbum:integer;
  priority:integer;
  enc:integer;
begin
  lptr:=tag+Size;
  fArtist:=0;
  fTitle :=0;
  fAlbum :=0;
  while tag<lptr do
  begin
    // Read frame header
    case ver of
      1,2: begin
        move(tag^,FrmOld,SizeOf(FrmOld));
        Frm.Flags:=0;
        Frm.ID:=FrmOld.ID[0]+(FrmOld.ID[1] shl 8)+(FrmOld.ID[2] shl 16);
        Frm.Size:=(FrmOld.Size[0] shl 16)+(FrmOld.Size[1] shl 8)+FrmOld.Size[2];
        inc(tag,SizeOf(tID3v2FrameHdrOld));
      end;

      3: begin
        move(tag^,Frm,SizeOf(Frm));
        Frm.Size:=BSwap(Frm.Size);
        inc(tag,SizeOf(tID3v2FrameHdr));
      end;

      4: begin
        move(tag^,Frm,SizeOf(Frm));
        Frm.Size:=ID3v2_Correct(Frm.Size);
        inc(tag,SizeOf(tID3v2FrameHdr));
        if (Frm.Flags and $0100)<>0 then
        begin
          Frm.Size:=ID3v2_Correct(pdword(tag)^);
          inc(tag,4);
        end;
      end;
    end;

    if Frm.ID=0 then
      break;
    if Frm.Size=0 then
      continue;
    if (tag+Frm.Size)>lptr then
      break;
    buf:=ID3v2_PreReadTag(Frm,tag,ver);

    // if several tag variants, choosing UTF8/UTF16 (if ASCII presents)
    // next, choosing main tags before secondary
    case ord(buf^) of // set priority
      0:   priority:=1;
      1,2: priority:=3;
      3:   priority:=3;
    end;
    enc:=cp[ord(buf^)];

    ptr:=nil;
    case Frm.ID of
      // Unsynchronised lyric/text transcription
      frmUSLT,frmULT: ID3v2_CheckLyric(Info,buf,Frm.Size);
      // Synchronised lyric/text
      frmSYLT,frmSLT: ID3v2_CheckSyncLyric(Info,buf,Frm.Size);
      // User defined text information frame
      frmTXXX,frmTXX: ID3v2_CheckUserLyric(Info,buf,Frm.Size);
      // Attached picture
      frmAPIC,frmPIC: ID3v2_CheckCover(Frm.ID ,Info,buf,Frm.Size);

      // Lead performer(s)/Soloist(s)
      frmTPE1,frmTP1: begin
        if fArtist<(priority+10) then
        begin
          fArtist:=priority+10;
          WATSetStr(Info,siArtist, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end
      end;
      // Title/songname/content description
      frmTIT2,frmTT2: begin
        if fTitle<(priority+10) then
        begin
          fTitle:=priority+10;
          WATSetStr(Info,siTitle, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end
      end;
      // Album/Movie/Show title
      frmTALB,frmTAL: begin
        if fAlbum<(priority+10) then
        begin
          fAlbum:=priority+10;
          WATSetStr(Info,siAlbum, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end
      end;
      // Year / Recording time
      frmTYER,frmTDRC,frmTYE: begin //!! TYER = 4 chars ALWAYS
        WATSetStr(Info,siYear, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
      end;

      // Original artist(s)/performer(s), Band/orchestra/accompaniment
      // Interpreted, remixed, or otherwise modified by
      frmTOPE,frmTPE2,frmTOA,frmTPE4: begin
        if fArtist<priority then
        begin
          fArtist:=priority;
          WATSetStr(Info,siArtist, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end;
      end;
      // Content group description, Subtitle/Description refinement
      frmTIT1,frmTIT3,frmTT1: begin
        if fTitle<priority then
        begin
          fTitle:=priority;
          WATSetStr(Info,siTitle, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end;
      end;
      // Original album/movie/show title
      frmTOAL: begin
        if fAlbum<priority then
        begin
          fAlbum:=priority;
          WATSetStr(Info,siAlbum, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end;
      end;
      // Original release year
      frmTORY: begin
        if WATIsEmpty(Info,siYear) then // 4 chars always
        begin
          WATSetStr(Info,siYear, ID3v2_ReadTagStr(ptr,buf,Frm.Size), enc);
        end;
      end;

      // Content type
      frmTCON,frmTCO: begin
        if WATIsEmpty(Info,siGenre) then
        begin
          ID3v2_ReadTagStr(ptr, buf,Frm.Size);

          //!! mean ASCII value
          if ptr<>nil then
          begin
            if ptr^='(' then
            begin
              tmp:=StrScan(ptr,')')-ptr+1;
              if tmp=StrLen(ptr) then
              begin
                WATSetStr(Info,siGenre, GenreName(StrToInt(ptr+1)), CP_ACP);
              end
              else if tmp>0 then
                WATSetStr(Info,siGenre, ptr+tmp, CP_ACP);
            end;
          end;
        end;
      end;
      // Comments
      frmCOMM,frmCOM: begin //!!
        if WATIsEmpty(Info,siComment) then
        begin
          lptr:=buf;
          // Skip language
          inc(lptr,3+1);

          // Skip short description
          if (enc=CP_ACP) or (enc=CP_UTF8) then
          begin
            while lptr^<>#0 do inc(lptr);
            inc(lptr);
          end
          else
          begin
            while pWord(lptr)^<>0 do inc(lptr,2);
            inc(lptr,2);
          end;
          dec(Frm.Size,lptr-buf);
          WATSetStr(Info,siComment, ID3v2_ReadTagStr1(ptr,lptr,Frm.Size,ord(buf^)), enc);
        end;
      end;
      // Track number/Position in set
      frmTRCK,frmTRK: begin
        if WATIsEmpty(Info,siTrack) then
        begin
          WATSet(Info,siTrack, StrToInt(ID3v2_ReadTagStr(ptr,buf,Frm.Size)));
        end;
      end;
    end;
    mFreeMem(ptr);
    mFreeMem(buf);
  end;
end;

function ReadID3v2(var f:file; Info:UIntPtr):longint;
var
  TagHdr:TID3v2TagHdr;
  Tag2:PAnsiChar;
  ExtTagSize:dword;
begin
  BlockRead(f,TagHdr,SizeOf(TagHdr));
  if TagHdr.ID=TAG2Sign then
  begin
    TagHdr.TagSize:=ID3v2_Correct(TagHdr.TagSize);
    Unsync:=(TagHdr.Flags and $80)<>0;
    result:=TagHdr.TagSize;
//    if TagHdr.Version>2 then
    begin
      GetMem(Tag2,TagHdr.TagSize);
      BlockRead(f,Tag2^,TagHdr.TagSize);
      ID3v2_ReadTag2(TagHdr.Version,Tag2,TagHdr.TagSize,Info);
      FreeMem(Tag2);
    end;
    if (TagHdr.Flags and ExtIDHdrMask)<>0 then
    begin
      BlockRead(f,ExtTagSize,SizeOf(ExtTagSize));
      inc(result,4+ExtTagSize);
    end;
    if (TagHdr.Flags and FooterPresent)<>0 then
      inc(result,10);
  end
  else
    result:=0;
  Seek(f,result);
end;

{$ENDIF}
