{$Include mydefs.inc}
{$INCLUDE compilers.inc}
unit common;

interface

{$DEFINE Interface}

const
  SIGN_UNICODE    = $FEFF;
  SIGN_REVERSEBOM = $FFFE;
  SIGN_UTF8       = $BFBBEF;

Const {- Character sets -}
  sBinNum   = ['0'..'1'];
  sOctNum   = ['0'..'7'];
  sNum      = ['0'..'9'];
  sHexNum   = ['0'..'9','A'..'F','a'..'f'];
  sWord     = ['0'..'9','A'..'Z','a'..'z','_',#128..#255];
  sIdFirst  = ['A'..'Z','a'..'z','_'];
  sLatWord  = ['0'..'9','A'..'Z','a'..'z','_'];
  sWordOnly = ['A'..'Z','a'..'z'];
  sSpace    = [#9,' '];
  sEmpty    = [#9,#10,#13,' '];

const
  HexDigitChrLo: array [0..15] of AnsiChar = ('0','1','2','3','4','5','6','7',
                                              '8','9','a','b','c','d','e','f');

  HexDigitChr  : array [0..15] of AnsiChar = ('0','1','2','3','4','5','6','7',
                                              '8','9','A','B','C','D','E','F');

function MakeMethod(Data, Code:Pointer):TMethod;

//----- Conditions -----

{$i common\cond.inc}

function GetImageType (buf:pointer;mime:PAnsiChar=nil):cardinal;
function GetImageTypeW(buf:pointer;mime:PWideChar=nil):int64;

//----- Memory -----

function  mGetMem (out dst;size:integer):pointer;
procedure mFreeMem(var aptr);
function  mReallocMem(var dst; size:integer):pointer;
procedure FillWord(var buf;count:cardinal;value:word); register;
function CompareMem(P1, P2: pointer; len: integer): Boolean;

function BSwap(value:cardinal):cardinal;

function Hash(s:pointer; len:integer): LongWord; overload;
function Hash(s:PAnsiChar           ): LongWord; overload;
function Hash(const s:AnsiString    ): LongWord; overload;

type
  tSortProc = function (First,Second:integer):integer;
  {0=equ; 1=1st>2nd; -1=1st<2nd }
procedure ShellSort(size:integer;Compare,Swap:tSortProc);

//----- String processing -----

{$i common\strform.inc}

//----- Encoding conversion -----

{$IFNDEF FPC}
const
  CP_ACP = 0;
{$ENDIF}

{$i common\strenc.inc}

// encode/decode text (URL coding)
function Encode(dst,src:PAnsiChar):PAnsiChar;
function Decode(dst,src:PAnsiChar):PAnsiChar;
// '\n'(#13#10) and '\t' (#9) (un)escaping
function UnEscape(buf:PAnsiChar):PAnsiChar;
function Escape  (buf:PAnsiChar):PAnsiChar;
procedure UpperCase(src:PWideChar);
procedure LowerCase(src:PWideChar);

//----- base strings functions -----

{$i common\strbase.inc}

//----- String/number conversion -----

{$i common\strconv.inc}

//----- Date and Time -----

function TimeToInt(stime:PAnsiChar):integer; overload;
function TimeToInt(stime:PWideChar):integer; overload;
function IntToTime(dst:PWideChar;Time:integer):PWideChar; overload;
function IntToTime(dst:PAnsiChar;Time:integer):PAnsiChar; overload;

{$i common\files.inc}

{$UNDEF Interface}

//-----------------------------------------------------------------------------

implementation

{$IFDEF UseWinAPI}
uses windows;
{$ENDIF}

{$IFDEF VER130}
type
  uint64 = int64;
  PByte  = ^byte;
  pword  = ^word;
  pcardinal = ^cardinal;
{$ENDIF}

function MakeMethod(Data, Code:Pointer):TMethod;
begin
  Result.Data:=Data;
  Result.Code:=Code;
end;

{$i common\cond.inc}

const
  mimecnt = 5;
  mimes:array [0..mimecnt-1] of record
     mime:PAnsiChar;
     ext:array [0..3] of AnsiChar
  end = (
  (mime:'image/gif' ; ext:'GIF'),
  (mime:'image/jpg' ; ext:'JPG'),
  (mime:'image/jpeg'; ext:'JPG'),
  (mime:'image/png' ; ext:'PNG'),
  (mime:'image/bmp' ; ext:'BMP')
);

function GetImageType(buf:pointer;mime:PAnsiChar=nil):cardinal;
var
  i:integer;
begin
  result:=0;
  if (mime<>nil) and (mime^<>#0) then
  begin
    for i:=0 to mimecnt-1 do
    begin
      if {lstrcmpia}StrCmp(mime,mimes[i].mime)=0 then
      begin
        result:=cardinal(mimes[i].ext);
        exit;
      end;
    end;
  end
  else if buf<>nil then
  begin
    if (pcardinal(buf)^ and $F0FFFFFF)=$E0FFD8FF then result:=$0047504A // 'JPG'
    else if pcardinal(buf)^=$38464947 then result:=$00464947 // 'GIF'
    else if pcardinal(buf)^=$474E5089 then result:=$00474E50 // 'PNG'
    else if pword    (buf)^=$4D42     then result:=$00504D42 // 'BMP'
  end;
end;

function GetImageTypeW(buf:pointer;mime:PWideChar=nil):int64;
var
  i:integer;
  lmime:array [0..63] of AnsiChar;
begin
  result:=0;
  if (mime<>nil) and (mime^<>#0) then
  begin
    FastWideToAnsiBuf(mime,@lmime);
    for i:=0 to mimecnt-1 do
    begin
      if {lstrcmpia}StrCmp(lmime,mimes[i].mime)=0 then
      begin
//        result:=cardinal(mimes[i].ext);
        FastAnsiToWideBuf(mimes[i].ext,PWideChar(@result));
        exit;
      end;
    end;
  end
  else if buf<>nil then
  begin
    if (pcardinal(buf)^ and $F0FFFFFF)=$E0FFD8FF then result:=$000000470050004A // 'JPG'
    else if pcardinal(buf)^=$38464947 then result:=$0000004600490047 // 'GIF'
    else if pcardinal(buf)^=$474E5089 then result:=$00000047004E0050 // 'PNG'
    else if pword    (buf)^=$4D42     then result:=$00000050004D0042 // 'BMP'
  end;
end;

//----- Memory -----

procedure FillWord(var buf;count:cardinal;value:word);
{$IFDEF FPC} inline;
begin
  system.FillWord(buf,count,value)
{$ELSE}
var
  lptr:pword;
  i:integer;
begin
  lptr:=pword(@buf);
  for i:=0 to count-1 do
  begin
    lptr^:=value;
    inc(lptr);
  end;
{$ENDIF}
end;

function CompareMem(P1, P2: pointer; len: integer): Boolean;
{$IFDEF FPC} inline;
begin
  result:=system.CompareByte(P1,P2,len)<>0;
{$ELSE}
var
  i:integer;
begin
  for i:=0 to len-1 do
  begin
    if PByte(P1)^<>PByte(P2)^ then
    begin
      result:=false;
      exit;
    end;
    inc(PByte(P1));
    inc(PByte(P2));
  end;
  result:=true;
{$ENDIF}
end;

function mGetMem(out dst;size:integer):pointer;
begin
  GetMem(pointer(dst),size);
  result:=pointer(dst);
end;

procedure mFreeMem(var aptr);
begin
  if pointer(aptr)<>nil then
  begin
    FreeMem(pointer(aptr));
    pointer(aptr):=nil;
  end;
end;

function mReallocMem(var dst; size:integer):pointer;
begin
  ReallocMem(pointer(dst),size);
  result:=pointer(dst);
end;

function BSwap(value:cardinal):cardinal;
begin
  result:=((value and $000000FF) shl 24) +
          ((value and $0000FF00) shl  8) +
          ((value and $00FF0000) shr  8) +
          ((value and $FF000000) shr 24);
end;

{$IFOPT Q+}
  {$DEFINE QPLUS}
  {$Q-}
{$ENDIF}
// Murmur 2.0
function Hash(s:pointer; len:integer{const Seed: longword=$9747b28c}): longword;
type
  PLongWord = ^longword;
var
  lhash: longword;
  k: longword;
  tmp,data: PByte;
const
  // 'm' and 'r' are mixing constants generated offline.
  // They're not really 'magic', they just happen to work well.
  m = $5bd1e995;
  r = 24;
begin
  //The default seed, $9747b28c, is from the original C library

  // Initialize the hash to a 'random' value
  lhash := {seed xor }len;

  // Mix 4 bytes at a time into the hash
  data := s;

  while(len >= 4) do
  begin
    k := PLongWord(data)^;

    k := k*m;
    k := k xor (k shr r);
    k := k*m;

    lhash := lhash*m;
    lhash := lhash xor k;

    inc(data,4);
    dec(len,4);
  end;

  //   Handle the last few bytes of the input array
  if len = 3 then
  begin
    tmp:=data;
    inc(tmp,2);
    lhash := lhash xor (longword(tmp^) shl 16);
  end;
  if len >= 2 then
  begin
    tmp:=data;
    inc(tmp);
    lhash := lhash xor (longword(tmp^) shl 8);
  end;
  if len >= 1 then
  begin
    lhash := lhash xor (longword(data^));
    lhash := lhash * m;
  end;

  // Do a few final mixes of the hash to ensure the last few
  // bytes are well-incorporated.
  lhash := lhash xor (lhash shr 13);
  lhash := lhash * m;
  lhash := lhash xor (lhash shr 15);

  Result := lhash;
end;

function Hash(s:PAnsiChar): LongWord;
begin
  result:=Hash(s,StrLen(s));
end;

function Hash(const s:AnsiString): LongWord;
begin
  result:=Hash(pointer(s),Length(s));
end;

{$IFDEF QPLUS}
  {$UNDEF QPLUS}
  {$Q+}
{$ENDIF}

procedure ShellSort(size:integer;Compare,Swap:tSortProc);
var
  i,j,gap:longint;
begin
  gap:=size shr 1;
  while gap>0 do
  begin
    for i:=gap to size-1 do
    begin
      j:=i-gap;
      while (j>=0) and (Compare(j,j+gap)>0) do
      begin
        Swap(j,j+gap);
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
end;


//----- String processing -----

{$i common\strform.inc}

// --------- string conversion ----------

{$i common\strenc.inc}



function Encode(dst,src:PAnsiChar):PAnsiChar;
begin
  while src^<>#0 do
  begin
    if not (src^ in [' ','%','+','&','?',#128..#255]) then
      dst^:=src^
    else
    begin
      dst^:='%'; inc(dst);
      dst^:=HexDigitChr[ord(src^) shr 4]; inc(dst);
      dst^:=HexDigitChr[ord(src^) and $0F];
    end;
    inc(src);
    inc(dst);
  end;
  dst^:=#0;
  result:=dst;
end;

function Decode(dst,src:PAnsiChar):PAnsiChar;
begin
  while (src^<>#0) and (src^<>'&') do
  begin
    if (src^='%') and ((src+1)^ in sHexNum) and ((src+2)^ in sHexNum) then
    begin
      inc(src);
      dst^:=AnsiChar(HexToInt(src,2));
      inc(src);
    end
    else
      dst^:=src^;
    inc(dst);
    inc(src);
  end;
  dst^:=#0;
  result:=dst;
end;

function UnEscape(buf:PAnsiChar):PAnsiChar;
begin
  if (buf<>nil) and (buf^<>#0) then
  begin
    StrReplace(buf,PAnsiChar(#$7F'n'),PAnsiChar(#$0D#$0A));
    StrReplace(buf,PAnsiChar(#$7F't'),PAnsiChar(#$09));
  end;
  result:=buf;
end;

function Escape(buf:PAnsiChar):PAnsiChar;
var
  i:integer;
begin
  i:=StrLen(buf);
  if i<>0 then
  begin
    Move(buf^,(buf+1)^,i+1);
    buf^:=#39;
    (buf+i+1)^:=#39;
    (buf+i+2)^:=#0;
    StrReplace(buf,#$0D#$0A,#$7F'n');
    StrReplace(buf,#$09,#$7F't');
  end;
  result:=buf;
end;

procedure UpperCase(src:PWideChar);
var
  c:WideChar;
begin
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      c:=src^;
      if (c>='a') and (c<='z') then
        src^:=WideChar(ord(c)-$20);
      inc(src);
    end;
  end;
end;

procedure LowerCase(src:PWideChar);
var
  c:WideChar;
begin
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      c:=src^;
      if (c>='A') and (c<='Z') then
        src^:=WideChar(ord(c)+$20);
      inc(src);
    end;
  end;
end;

// ----- base string functions -----

{$i common\strbase.inc}

//----- String/number conversion -----

{$i common\strconv.inc}

//----- Date and Time -----

function TimeToInt(stime:PAnsiChar):integer;
var
  hour,minute,sec,len,i:integer;
begin
  len:=StrLen(stime);
  i:=0;
  sec   :=0;
  minute:=0;
  hour  :=0;
  while i<len do
  begin
    if (stime[i]<'0') or (stime[i]>'9') then
    begin
      if minute>0 then
        hour:=minute;
      minute:=sec;
      sec:=0;
    end
    else
      sec:=sec*10+ord(stime[i])-ord('0');
    inc(i);
  end;
  result:=hour*3600+minute*60+sec;
end;

function TimeToInt(stime:PWideChar):integer;
var
  buf:array [0..63] of AnsiChar;
begin
  result:=TimeToInt(FastWideToAnsiBuf(stime,@buf));
end;

function IntToTime(dst:PAnsiChar;Time:integer):PAnsiChar;
var
  day,hour,minute,sec:array [0..7] of AnsiChar;
  d,h:integer;
begin
  result:=dst;
  h:=Time div 3600;
  dec(Time,h*3600);
  IntToStr(PAnsiChar(@sec),(Time mod 60),2);
  d:=h div 24;
  if d>0 then
  begin
    h:=h mod 24;
    IntToStr(PAnsiChar(@day),d);
    dst^:=day[0]; inc(dst);
    if day[1]<>#0 then        // now only 99 days max
    begin
      dst^:=day[1]; inc(dst);
    end;
    dst^:=' '; inc(dst);
  end;
  if h>0 then
  begin
    IntToStr(PAnsiChar(@hour),h);
    IntToStr(PAnsiChar(@minute),(Time div 60),2);
    dst^:=hour[0]; inc(dst);
    if hour[1]<>#0 then
    begin
      dst^:=hour[1]; inc(dst);
    end;
    dst^:=':';    inc(dst);
    dst^:=minute[0]; inc(dst);
    dst^:=minute[1]; inc(dst);
  end
  else
  begin
    IntToStr(PAnsiChar(@minute),Time div 60);
    dst^:=minute[0]; inc(dst);
    if minute[1]<>#0 then
    begin
      dst^:=minute[1]; inc(dst);
    end;
  end;
  dst^:=':';    inc(dst);
  dst^:=sec[0]; inc(dst);
  dst^:=sec[1]; inc(dst);
  dst^:=#0;
end;

function IntToTime(dst:PWideChar;Time:integer):PWideChar;
var
  buf:array [0..63] of AnsiChar;
begin
  result:=FastAnsiToWideBuf(IntToTime(PAnsiChar(@buf),Time),dst);
end;

//----- Files / directories -----

{$i common\files.inc}

end.
