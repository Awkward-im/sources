{APE tag}
{$IFDEF Interface}

function ReadAPEv2(buf:PAnsiChar; alen:cardinal; Info:UIntPtr):longint; overload;
function ReadAPEv2(var f:file   ; Info:UIntPtr):longint; overload;

{$ELSE}

const
  APESign  = 'APETAGEX';
type
  pAPEHeader = ^tAPEHeader;
  tAPEHeader = packed record
    ID       :array [0..7] of AnsiChar;
    Version  :dword;
    TagSize  :dword; //footer + all items
    ItemCount:dword;
    TagFlags :dword;
    Reserved :array [0..7] of byte;
  end;

procedure ReadAPEValue(const value:PAnsiChar; Info,aField:UIntPtr; len,cp:integer);
var
  ptr:PAnsiChar;
begin
  if WATIsEmpty(Info,aField) then
  begin
    // check for list
    ptr:=value;

    while true do
    begin
      while ptr^<>#0 do inc(ptr);
      if (ptr-value)<(len-1) then // +1 = my reserve for ending zero
      begin
        ptr^:=';';
      end
      else break;
    end;

    WATSetStr(Info,aField,value,cp);
  end;
end;

function ReadAPEv2(buf:PAnsiChar; alen:cardinal; Info:UIntPtr):longint;
var
  APE:pAPEHeader;
  ptr,key:PAnsiChar;
  flag:dword;
  count,len:integer;
  cp:integer;
  b:AnsiChar;
begin
  result:=0;
  // check footer
  APE:=pAPEHeader(buf+alen-SizeOf(tAPEHeader));
  if APE^.ID=APESign then
  begin
    count:=APE^.ItemCount;
    if APE^.Version>1000 then
      cp:=CP_UTF8
    else
      cp:=CP_ACP;
  end
  else
    exit;

  while count>0 do
  begin
    len :=pdword(buf)^; inc(buf,4);
    flag:=pdword(buf)^; inc(buf,4);
    key:=buf;
    // translate key to upcase and move pointer to value
    while buf^<>#0 do
    begin
      if buf^ in ['a'..'z'] then
        buf^:=AnsiChar(ORD(buf^)-$20);
      inc(buf);
    end;
    inc(buf);

    ptr:=buf+len;
    b:=ptr^;
    ptr^:=#0;

    if      StrCmp(key,'TITLE'  )=0 then ReadAPEValue(buf,Info,siTitle,len,cp)
    else if StrCmp(key,'ALBUM'  )=0 then ReadAPEValue(buf,Info,siAlbum,len,cp)
    else if StrCmp(key,'YEAR'   )=0 then ReadAPEValue(buf,Info,siYear ,len,cp)
    else if StrCmp(key,'TRACK'  )=0 then
    begin
      if WATIsEmpty(Info,siTrack) then WATSet(Info,siTrack,StrToInt(buf))
    end

    // can be list
    else if StrCmp(key,'ARTIST' )=0 then ReadAPEValue(buf,Info,siArtist ,len,cp)
    else if StrCmp(key,'COMMENT')=0 then ReadAPEValue(buf,Info,siComment,len,cp)
    else if StrCmp(key,'GENRE'  )=0 then ReadAPEValue(buf,Info,siGenre  ,len,cp)

    // not in list (must preserve multipart)
    else if StrCmp(key,'LYRICS' )=0 then ReadAPEValue(buf,Info,siLyric,len,cp)
    else if (StrCmp(key,'COVER ART',9)=0) or
            (StrCmp(key,'APIC'       )=0) then
    begin
      if WATIsEmpty(Info,siCover) then
      begin
        while buf^<>#0 do inc(buf); inc(buf); // point to data now
        flag:=GetImageType(pByte(buf));
        if flag<>0 then
        begin
          key:=SaveTemporary(buf,ptr-buf,PAnsiChar(@flag));
          WATSetStr(Info,siCover,key,CP_ACP);
          mFreeMem(key);
        end;
      end;
    end;
    ptr^:=b;
    buf:=ptr;
    dec(count);
  end;
end;

function ReadAPEv2FromFile(var f:file; fpos:cardinal; Info:UIntPtr):longint;
var
  APE:tAPEHeader;
  buf:PAnsiChar;
begin
  result:=0;

  Seek(f,fpos);

  // read APEv1/2 Header/Footer
  BlockRead(f,APE,SizeOf(APE));

//  if APE.ID=APESign then
  if StrCmp(APE.ID,APESign,Length(APESign))=0 then
  begin
    if (APE.Version=1000) or (APE.Version=2000) then
    begin
      // Footer - seek to first item, Header - points already
      if (APE.TagFlags and (1 shl 29))=0 then
        Seek(f,fpos-APE.TagSize);

      GetMem(buf,APE.TagSize);
      BlockRead(f,buf^,APE.TagSize);
      result:=ReadAPEv2(buf,APE.TagSize,Info);
      FreeMem(buf);
    end;
  end;
end;

function ReadAPEv2(var f:file; Info:UIntPtr):longint;
var
  fpos:cardinal;
  TagID:array [1..3] of AnsiChar;
begin
  result:=0;

  // Skip ID3v1 if presents
  fpos:=FileSize(f);
  Seek(f,fpos-SizeOf(TID3v1Tag));
  BlockRead(f,TagID,3);
  if TagID=TAG1Sign then
    dec(fpos,SizeOf(TID3v1Tag));

  // 1 - trying to load from end
  result:=ReadAPEv2FromFile(f,fpos-SizeOf(tAPEHeader),Info);
  if result=0 then
  begin
    // 2 - trying to load from start
    result:=ReadAPEv2FromFile(f,0,Info);
  end;
end;

{$ENDIF}
