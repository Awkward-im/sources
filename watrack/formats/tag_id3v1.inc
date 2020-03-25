{ID3v1 tag}
{$IFDEF Interface}

const
  TAG1Sign = 'TAG';
type
  TID3v1Tag = packed record
    ID:      array [0..2]  of AnsiChar;
    Title:   array [0..29] of AnsiChar;
    Artist:  array [0..29] of AnsiChar;
    Album:   array [0..29] of AnsiChar;
    Year:    array [0..3]  of AnsiChar;
    Comment: array [0..28] of AnsiChar;
    Track:   byte;
    Genre:   byte;
  end;

function ReadID3v1(var f:file; Info:UIntPtr):longint;

{$ELSE}

const
  LyricStart = 'LYRICSBEGIN';
  Lyric1End  = 'LYRICSEND';
  Lyric2End  = 'LYRICS200';
  LyricEndLen = Length(Lyric1End);
const
  fIND = $494E44;
  fLYR = $4C5952;
  fINF = $494E46;
  fAUT = $415554;
  fEAL = $45414C;
  fEAR = $454152;
  fETT = $455454;
  fIMG = $494D47;

procedure ID3v1_TagCorrect(Info,aField:UIntPtr; const tag:array of AnsiChar);
var
  i:integer;
  s:array [0..31] of AnsiChar;
begin
  i:=High(tag);
  move(tag,s,i+1);
  while (i>0) and (tag[i]<=' ') do dec(i);
  if i>0 then
  begin
    s[i+1]:=#0;
    WATSetStr(Info,aField,@s,CP_ACP);
  end;
end;

procedure ID3v1_GetField(Info,aField:UIntPtr; ptr:PAnsiChar; len:integer);
var
  txtfield:array [0..250] of AnsiChar;
begin
  if WATIsEmpty(Info,aField) then
  begin
    move(ptr^,txtfield,len);
    txtfield[len]:=#0;
    WATSetStr(Info,aField,@txtfield,CP_ACP);
  end;
end;

procedure ID3v1_CheckLyric(Info:UIntPtr; var f:file; ofs:integer);
const
  maxlen = 5100;
  EndTagLen = LyricEndLen+6;
var
  buf:array [0..maxlen] of AnsiChar;
  ptr,ptr1:PAnsiChar;
  i,size:integer;
  field:dword;
begin
  Seek(f,ofs-EndTagLen);
  BlockRead(f,buf,EndTagLen); // including possible Lyricsv2 length
  buf[EndTagLen]:=#0;

    // Lyric v1
  if StrCmp(@buf[6],Lyric1End,LyricEndLen)=0 then
  begin
    if WATIsEmpty(Info,siLyric) then
    begin
      Seek(f,ofs-maxlen);
      BlockRead(f,buf,maxlen);
      buf[maxlen]:=#0;
      ptr:=@buf;
      for i:=0 to maxlen-Length(LyricStart) do
      begin
        if ptr^='L' then
          if StrCmp(ptr,LyricStart,Length(LyricStart))=0 then
          begin
            WATSetStr(Info,siLyric,ptr+Length(LyricStart),CP_ACP);
            break;
          end;
        inc(ptr);
      end;
    end;
  end
  // Lyric v2
  else if StrCmp(@buf[6],Lyric2End,LyricEndLen)=0 then
  begin
    size:=ORD(buf[0])*100000+
          ORD(buf[1])*10000+
          ORD(buf[2])*1000+
          ORD(buf[3])*100+
          ORD(buf[4])*10+
          ORD(buf[5]);
    dec(ofs,size+EndTagLen);

    if ofs>0 then // file size control
    begin
      Seek(f,ofs);
      if size>maxlen then
        mGetMem(ptr,size+1)
      else
        ptr:=@buf;
      BlockRead(f,ptr^,size);
      if StrCmp(ptr,LyricStart,Length(LyricStart))=0 then
      begin
        ptr1:=ptr+Length(LyricStart);

        while ptr1<ptr+size do
        begin
          // read tag, size and skip
          field:=ORD(ptr1[0]) shl 16+
                 ORD(ptr1[1]) shl 8+
                 ORD(ptr1[2]);
          i:=ORD(ptr1[3])*10000+
             ORD(ptr1[4])*1000+
             ORD(ptr1[5])*100+
             ORD(ptr1[6])*10+
             ORD(ptr1[7]);
          inc(ptr1,8);

          case field of
            fLYR: if WATIsEmpty(Info,siLyric) then
            begin
              field:=pword(ptr1+i)^; // save stack space, keep value in existing variable
              pword(ptr1+i)^:=0;
              if (pword(ptr1)^=$FFFE) or ((pword(ptr1)^=$FEFF)) then
              begin
                WATSetStr(Info,siLyric, (ptr1+2), CP_UTF16);
{!!!!
                StrDupW(Info.lyric,pWideChar(ptr1));
                ChangeUnicode(Info.lyric);
}
              end
              else
              begin
                WATSetStr(Info,siLyric, ptr1,CP_ACP);
              end;
              pword(ptr1+i)^:=field;
            end;
            fEAL: ID3v1_GetField(Info,siAlbum ,ptr1,i);
            fEAR: ID3v1_GetField(Info,siArtist,ptr1,i);
            fETT: ID3v1_GetField(Info,siTitle ,ptr1,i);
            fINF: ;
            fAUT: ;
            fIMG: ;
          end;
          inc(ptr1,i);
        end;
      end;
      if ptr<>@buf then
        mFreeMem(ptr);
    end;
  end;
end;

function ReadID3v1(var f:file; Info:UIntPtr):longint;
var
  tag:TID3v1Tag;
  ofs:integer;
begin
  result:=0;
  ofs:=FileSize(f)-SizeOf(tag);
  Seek(f,ofs);
  BlockRead(f,tag,SizeOf(tag));
  if tag.ID=TAG1Sign then
  begin
    if WATIsEmpty(Info,siAlbum  ) then ID3v1_TagCorrect(Info,siAlbum  ,tag.Album);
    if WATIsEmpty(Info,siArtist ) then ID3v1_TagCorrect(Info,siArtist ,tag.Artist);
    if WATIsEmpty(Info,siTitle  ) then ID3v1_TagCorrect(Info,siTitle  ,tag.Title);
    if WATIsEmpty(Info,siComment) then ID3v1_TagCorrect(Info,siComment,tag.Comment);
    if WATIsEmpty(Info,siYear   ) then ID3v1_TagCorrect(Info,siYear   ,tag.Year);
    if WATIsEmpty(Info,siGenre  ) then WATSetStr       (Info,siGenre  ,GenreName(tag.Genre),CP_ACP);
    if WATIsEmpty(Info,siTrack  ) then
    begin
      if tag.Track<32 then WATSet(Info,siTrack,tag.Track);
    end;
    result:=1;
  end
  else
    inc(ofs,SizeOf(tag));

  ID3v1_CheckLyric(Info,f,ofs); // +skipAPEtag
end;

{$ENDIF}
