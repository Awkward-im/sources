function TTags.LoadFromBASS(Channel: Cardinal): Integer;
Const
  // BASS_ChannelGetTags types : what's returned
  BASS_TAG_ID3        = 0; // ID3v1 tags : TAG_ID3 structure
  BASS_TAG_ID3V2      = 1; // ID3v2 tags : variable length block
  BASS_TAG_OGG        = 2; // OGG comments : series of null-terminated UTF-8 strings
  BASS_TAG_HTTP       = 3; // HTTP headers : series of null-terminated ANSI strings
  BASS_TAG_ICY        = 4; // ICY headers : series of null-terminated ANSI strings
  BASS_TAG_META       = 5; // ICY metadata : ANSI string
  BASS_TAG_APE        = 6; // APEv2 tags : series of null-terminated UTF-8 strings
  BASS_TAG_MP4        = 7; // MP4/iTunes metadata : series of null-terminated UTF-8 strings
  BASS_TAG_VENDOR     = 9; // OGG encoder : UTF-8 string
  BASS_TAG_LYRICS3    = 10; // Lyric3v2 tag : ASCII string
  BASS_TAG_CA_CODEC   = 11;	// CoreAudio codec info : TAG_CA_CODEC structure
  BASS_TAG_MF         = 13;	// Media Foundation tags : series of null-terminated UTF-8 strings
  BASS_TAG_WAVEFORMAT = 14;	// WAVE format : WAVEFORMATEEX structure
  BASS_TAG_RIFF_INFO  = $100; // RIFF "INFO" tags : series of null-terminated ANSI strings
  BASS_TAG_RIFF_BEXT  = $101; // RIFF/BWF "bext" tags : TAG_BEXT structure
  BASS_TAG_RIFF_CART  = $102; // RIFF/BWF "cart" tags : TAG_CART structure
  BASS_TAG_RIFF_DISP  = $103; // RIFF "DISP" text tag : ANSI string
  BASS_TAG_APE_BINARY = $1000; // + index #, binary APEv2 tag : TAG_APE_BINARY structure
  BASS_TAG_MUSIC_NAME = $10000;	// MOD music name : ANSI string
  BASS_TAG_MUSIC_MESSAGE = $10001; // MOD message : ANSI string
  BASS_TAG_MUSIC_ORDERS = $10002; // MOD order list : BYTE array of pattern numbers
  BASS_TAG_MUSIC_INST = $10100;	// + instrument #, MOD instrument name : ANSI string
  BASS_TAG_MUSIC_SAMPLE = $10300; // + sample #, MOD sample name : ANSI string
  BASS_TAG_WMA        = 8; // WMA header tags : series of null-terminated UTF-8 strings
  BASS_TAG_DSD_ARTIST          = $13000; // DSDIFF artist : ASCII string
  BASS_TAG_DSD_TITLE           = $13001; // DSDIFF title : ASCII string
  BASS_TAG_DSD_COMMENT         = $13100; // + index, DSDIFF comment : TAG_DSD_COMMENT structure

type
  PTAG_DSD_COMMENT = ^TAG_DSD_COMMENT;
  TAG_DSD_COMMENT = packed record
	timeStampYear: Word; // creation year
	TimeStampMonth: Byte; // creation month
	timeStampDay: Byte; // creation day
	timeStampHour: Byte; // creation hour
	timeStampMinutes: Byte; // creation minutes
	cmtType: Word; // comment type
	cmtRef: Word; // comment reference
	count: DWORD; // string length
	commentText: Array[0..MaxInt div 2 - 1] of Byte; // text
  end;

Const
{$IFDEF MSWINDOWS}
  bassdll = 'bass.dll';
{$ENDIF}
{$IFDEF LINUX}
  bassdll = 'libbass.so';
{$ENDIF}
{$IFDEF MACOS}
  bassdll = 'libbass.dylib';
{$ENDIF}
{$IFDEF ANDROID}
  bassdll = 'libbass.so';
{$ENDIF}
{$IFDEF IOS}
  bassdll = 'libbass.dylib';
{$ENDIF}

var
    BASSDLLHandle: THandle;
    BASS_ChannelGetTags: function (Handle: Cardinal; Tags: DWORD): PByte; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    PTags: PByte;
    Bytes: TBytes;
    TagList: TStrings;
    PDSDTags: PTAG_DSD_COMMENT;

    function PCharLength(PCharPointer: PByte): Integer;
    begin
        Result := 0;
        repeat
            Inc(Result);
            Inc(PCharPointer);
        until PCharPointer^ = 0;
    end;

    procedure ParseTags;
    var
        Counter: Integer;
    begin
        TagList.Clear;
        repeat
            SetLength(Bytes, PCharLength(PTags));
            Counter := 0;
            repeat
                Bytes[Counter] := PTags^;
                Inc(Counter);
                Inc(PTags);
            until PTags^ = 0;
            TagList.Append(TEncoding.UTF8.GetString(Bytes));
            Inc(PTags);
        until PTags^ = 0;
    end;

    function BytesToString(P: PByte; MaxBytes: Integer): String;
    var
        Counter: Integer;
        Bytes: TBytes;
    begin
        SetLength(Bytes, MaxBytes);
        Counter := 0;
        repeat
            Bytes[Counter] := P^;
            Inc(Counter);
            Inc(P);
        until (Counter > MaxBytes - 1)
        OR (Bytes[Counter - 1] = 0);
        if Counter > MaxBytes - 1 then begin
            SetLength(Bytes, MaxBytes);
        end else begin
            SetLength(Bytes, Counter - 1);
        end;
        Result := TEncoding.UTF8.GetString(Bytes);
    end;

begin
    Clear;
    Loaded := False;
    WAVTag.BEXT.Loaded := False;
    WAVTag.CART.Loaded := False;
    // Dynamic BASS API linking
    BASSDLLHandle := GetModuleHandle(bassdll);
    if BASSDLLHandle = 0 then begin
        Result := TAGSLIBRARY_ERROR_BASS_NOT_LOADED;
        Exit;
    end;
    BASS_ChannelGetTags := GetProcAddress(BASSDLLHandle, 'BASS_ChannelGetTags');
    if NOT Assigned(BASS_ChannelGetTags) then begin
        Result := TAGSLIBRARY_ERROR_BASS_ChannelGetTags_NOT_FOUND;
        Exit;
    end;
    TagList := TStringList.Create;
    try
        //* Query BASS for ID3v1 tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_ID3);
        if Assigned(PTags) then begin
            ID3v1Tag.LoadFromMemory(PTags);
        end;
        //* Query BASS for ID3v2 tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_ID3V2);
        if Assigned(PTags) then begin
            ID3v2Tag.LoadFromMemory(PTags);
        end;
        //* Query BASS for OGG tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_OGG);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('OGG TAG', TagList);
        end;
        //* Query BASS for HTTP tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_HTTP);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('HTTP TAG', TagList);
        end;
        //* Query BASS for ICY tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_ICY);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('ICY TAG', TagList);
        end;
        //* Query BASS for META tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_META);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('META TAG', TagList);
        end;
        //* Query BASS for APE tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_APE);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('APE TAG', TagList);
        end;
        //* Query BASS for MP4 tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_MP4);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('MP4 TAG', TagList);
        end;
        //* Query BASS for LYRICS3 tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_LYRICS3);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('LYRICS3 TAG', TagList);
        end;
        //* Query BASS for MF tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_MF);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('MF TAG', TagList);
        end;
        //* Query BASS for RIFF INFO tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_RIFF_INFO);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedWAVRIFFINFOStrings(TagList);
        end;
        //* Query BASS for RIFF BEXT tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_RIFF_BEXT);
        if Assigned(PTags) then begin
            //FillChar(Pointer(@BEXT)^, SizeOf(BEXT), 0);
            //Move(PTags^, BEXT.Description[0], SizeOf(BEXT));
            //ParseTagsBEXT;
            WAVTag.BEXT.Clear;
            Move(PTags^, WAVTag.BEXT.BEXTChunk.Description[0], SizeOf(TAG_BEXT));
            Inc(PTags, SizeOf(TAG_BEXT));
            //TagList.Append(BEXT_CodingHistory + '=' + BytesToString(PTags, PCharLength(PTags)));
            //LoadNullTerminatedStrings('BEXT TAG', TagList);
            WAVTag.BEXT.CodingHistory := BytesToString(PTags, PCharLength(PTags));
            WAVTag.BEXT.Loaded := True;
        end;
        //* Query BASS for RIFF CART tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_RIFF_CART);
        if Assigned(PTags) then begin
            //FillChar(Pointer(@CART)^, SizeOf(CART), 0);
            //Move(PTags^, CART.Version[1], SizeOf(CART));
            //ParseTagsCART;
            WAVTag.CART.Clear;
            Move(PTags^, WAVTag.CART.CARTChunk.Version[0], SizeOf(TAG_CART));
            Inc(PTags, SizeOf(TAG_CART));
            //TagList.Append(CART_TagText + '=' + BytesToString(PTags, PCharLength(PTags)));
            //LoadNullTerminatedStrings('CART TAG', TagList);
            WAVTag.CART.TagText := BytesToString(PTags, PCharLength(PTags));
            WAVTag.CART.Loaded := True;
        end;
        //* Query BASS for RIFF DISP tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_RIFF_DISP);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('RIFF DISP TAG', TagList);
        end;
        //* Query BASS for MOD music name
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_MUSIC_NAME);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('MOD MUSIC NAME', TagList);
        end;
        //* Query BASS for WMA tags
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_WMA);
        if Assigned(PTags) then begin
            ParseTags;
            LoadNullTerminatedStrings('WMA TAG', TagList);
        end;
        //* Query BASS for DSD comment tags
        PDSDTags := PTAG_DSD_COMMENT(BASS_ChannelGetTags(Channel, BASS_TAG_DSD_COMMENT));
        if Assigned(PDSDTags) then begin
            TagList.Clear;
            TagList.Append('RECORDINGDATE='
                + IntToStr(PDSDTags.timeStampYear) + '-'
                + IntToStr(PDSDTags.TimeStampMonth) + '-'
                + IntToStr(PDSDTags.timeStampDay) + ' '
                + IntToStr(PDSDTags.timeStampHour) + ':'
                + IntToStr(PDSDTags.timeStampMinutes)
            );
            SetLength(Bytes, PDSDTags.count);
            Move(PDSDTags.commentText[0], Bytes[0], PDSDTags.count);
            TagList.Append('COMMENT=' + TEncoding.ANSI.GetString(Bytes));
            LoadNullTerminatedStrings('DSD IFF TAG', TagList);
        end;
        //* Query BASS for DSD artist tag
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_DSD_ARTIST);
        if Assigned(PTags) then begin
            TagList.Clear;
            SetLength(Bytes, PCharLength(PTags));
            Move(PTags, Bytes[0], Length(Bytes));
            TagList.Append('ARTIST=' + TEncoding.ANSI.GetString(Bytes));
            LoadNullTerminatedStrings('DSD IFF TAG', TagList);
        end;
        //* Query BASS for DSD artist tag
        PTags := BASS_ChannelGetTags(Channel, BASS_TAG_DSD_TITLE);
        if Assigned(PTags) then begin
            TagList.Clear;
            SetLength(Bytes, PCharLength(PTags));
            Move(PTags, Bytes[0], Length(Bytes));
            TagList.Append('TITLE=' + TEncoding.ANSI.GetString(Bytes));
            LoadNullTerminatedStrings('DSD IFF TAG', TagList);
        end;
    finally
        //* TODO: process the list
        FreeAndNil(TagList);
    end;
    LoadTags;
    Result := TAGSLIBRARY_SUCCESS;
end;
