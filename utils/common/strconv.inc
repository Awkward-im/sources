{
  Text / numbers conversion
}

{$IFDEF Interface}

function IntStrLen(value:int64; base:integer=10):integer;

function IntToHex (dst:PWideChar; value:int64; digits:integer=0):PWideChar; overload;
function IntToHex (dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar; overload;
function IntToBin (dst:PWideChar; value:int64; digits:integer=0):PWideChar; overload;
function IntToBin (dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar; overload;
function IntToOct (dst:PWideChar; value:int64; digits:integer=0):PWideChar; overload;
function IntToOct (dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar; overload;
function IntToStr (dst:PWideChar; value:int64; digits:integer=0):PWideChar; overload;
function IntToStr (dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar; overload;
function IntToBase(dst:PWideChar; value:int64; base:integer=10; digits:integer=0):PWideChar; overload;
function IntToBase(dst:PAnsiChar; value:int64; base:integer=10; digits:integer=0):PAnsiChar; overload;

function StrToInt (src:PWideChar):int64; overload;
function StrToInt (src:PAnsiChar):int64; overload;
function HexToByte(src:PAnsiChar):byte;
function HexToInt (src:PWideChar; len:cardinal=$FFFF):int64; overload;
function HexToInt (src:PAnsiChar; len:cardinal=$FFFF):int64; overload;
function BinToInt (src:PWideChar):int64; overload;
function BinToInt (src:PAnsiChar):int64; overload;
function OctToInt (src:PWideChar):int64; overload;
function OctToInt (src:PAnsiChar):int64; overload;
//function BaseToInt(src:PWideChar; base:integer):int64; overload;
//function BaseToInt(src:PAnsiChar; base:integer):int64; overload;

function NumToInt (src:PWideChar):int64; overload;
function NumToInt (src:PAnsiChar):int64; overload;

{$ELSE}

//--- Int to text

function IntStrLen(value:int64; base:integer=10):integer;
var
  i:uint64;
begin
  result:=0;
  if (base=10) and (value<0) then
    inc(result);
  i:=ABS(value);
  repeat
    i:=i div base;
    inc(result);
  until i=0;
end;

function IntToStr(dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar;
var
  i:uint64;
begin
  if digits<=0 then
  begin
    if value<0 then
      digits:=1
    else
      digits:=0;
    i:=ABS(value);
    repeat
      i:=i div 10;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  i:=ABS(value);
  repeat
    dec(digits);
    dst[digits]:=AnsiChar(ord('0')+(i mod 10));
    i:=i div 10;
    if (value<0) and (digits=1) then
    begin
      dst[0]:='-';
      break;
    end;
  until digits=0;
  result:=dst;
end;

function IntToStr(dst:PWideChar; value:int64; digits:integer=0):PWideChar;
var
  i:uint64;
begin
  if digits<=0 then
  begin
    if value<0 then
      digits:=1
    else
      digits:=0;
    i:=ABS(value);
    repeat
      i:=i div 10;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  i:=ABS(value);
  repeat
    dec(digits);
    dst[digits]:=WideChar(ord('0')+(i mod 10));
    i:=i div 10;
    if (value<0) and (digits=1) then
    begin
      dst[0]:='-';
      break;
    end;
  until digits=0;
  result:=dst;
end;

function IntToBase(dst:pWideChar; value:int64; base:integer=10; digits:integer=0):PWideChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
{
    if (base=10) and (value<0) then
    begin
      inc(digits);
      dst[0]:='-';
      i:=ABS(value);
    else
}
    i:=value;
    repeat
      i:=i div base;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=WideChar(HexDigitChr[value mod base]);
    value:=value div base;
  until digits=0;
  result:=dst;
end;

function IntToBase(dst:pAnsiChar; value:int64; base:integer=10; digits:integer=0):PAnsiChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
{
    if (base=10) and (value<0) then
    begin
      inc(digits);
      dst[0]:='-';
      i:=ABS(value);
    else
}
    i:=value;
    repeat
      i:=i div base;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=HexDigitChr[value mod base];
    value:=value div base;
  until digits=0;
  result:=dst;
end;

function IntToHex(dst:pWideChar; value:int64; digits:integer=0):PWideChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 4;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=WideChar(HexDigitChr[value and $F]);
    value:=value shr 4;
  until digits=0;
  result:=dst;
end;

function IntToHex(dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 4;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=HexDigitChr[value and $F];
    value:=value shr 4;
  until digits=0;
  result:=dst;
end;

function IntToBin(dst:PWideChar; value:int64; digits:integer=0):PWideChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 1;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=WideChar(HexDigitChr[value and 1]);
    value:=value shr 1;
  until digits=0;
  result:=dst;
end;

function IntToBin(dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 1;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=HexDigitChr[value and 1];
    value:=value shr 1;
  until digits=0;
  result:=dst;
end;

function IntToOct(dst:PWideChar; value:int64; digits:integer=0):PWideChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 3;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=WideChar(HexDigitChr[value and $7]);
    value:=value shr 3;
  until digits=0;
  result:=dst;
end;

function IntToOct(dst:PAnsiChar; value:int64; digits:integer=0):PAnsiChar;
var
  i:int64;
begin
  if digits<=0 then
  begin
    digits:=0;
    i:=value;
    repeat
      i:=i shr 3;
      inc(digits);
    until i=0;
  end;
  dst[digits]:=#0;
  repeat
    Dec(digits);
    dst[digits]:=HexDigitChr[value and $7];
    value:=value shr 3;
  until digits=0;
  result:=dst;
end;

//--- Text to int

function StrToInt(src:PWideChar):int64;
var
  sign:boolean;
begin
  result:=0;
  if src<>nil then
  begin
    sign:=src^='-';
    if sign then inc(src);
    while (src^>='0') and (src^<='9') do
    begin
      result:=result*10+ord(src^)-ord('0');
      inc(src);
    end;
    if sign then result:=-result;
  end;
end;

function StrToInt(src:PAnsiChar):int64;
var
  sign:boolean;
begin
  result:=0;
  if src<>nil then
  begin
    sign:=src^='-';
    if sign then inc(src);
    while src^ in ['0'..'9'] do
    begin
      result:=result*10+ord(src^)-ord('0');
      inc(src);
    end;
    if sign then result:=-result;
  end;
end;

function HexToByte(src:PAnsiChar):byte;
begin
  result:=0;
  if src=nil then exit;

  if      (src^>='0') and (src^<='9') then result:=result+ord(src^)-ord('0')
  else if (src^>='A') and (src^<='F') then result:=result+ord(src^)-ord('A')+10
  else if (src^>='a') and (src^<='f') then result:=result+ord(src^)-ord('a')+10
  else exit;

  inc(src);
  result:=result shl 4;

  if      (src^>='0') and (src^<='9') then result:=result+ord(src^)-ord('0')
  else if (src^>='A') and (src^<='F') then result:=result+ord(src^)-ord('A')+10
  else if (src^>='a') and (src^<='f') then result:=result+ord(src^)-ord('a')+10;
end;

function HexToInt(src:PWideChar; len:cardinal=$FFFF):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) and (len>0) do
  begin
    if      (src^>='0') and (src^<='9') then result:=result*16+ord(src^)-ord('0')
    else if (src^>='A') and (src^<='F') then result:=result*16+ord(src^)-ord('A')+10
    else if (src^>='a') and (src^<='f') then result:=result*16+ord(src^)-ord('a')+10
    else
      break;
    inc(src);
    dec(len);
  end;
end;

function HexToInt(src:PAnsiChar; len:cardinal=$FFFF):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) and (len>0) do
  begin
    if      (src^>='0') and (src^<='9') then result:=result*16+ord(src^)-ord('0')
    else if (src^>='A') and (src^<='F') then result:=result*16+ord(src^)-ord('A')+10
    else if (src^>='a') and (src^<='f') then result:=result*16+ord(src^)-ord('a')+10
    else
      break;
    inc(src);
    dec(len);
  end;
end;

function BinToInt(src:PWideChar):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) do
  begin
    if AnsiChar(src^) in sBinNum then
      result:=(result shl 1)+ord(src^)-ord('0');
    inc(src);
  end;
end;

function BinToInt(src:PAnsiChar):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) do
  begin
    if src^ in sBinNum then
      result:=(result shl 1)+ord(src^)-ord('0');
    inc(src);
  end;
end;

function OctToInt(src:PWideChar):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) do
  begin
    if AnsiChar(src^) in sOctNum then
      result:=(result shl 3)+ord(src^)-ord('0');
    inc(src);
  end;
end;

function OctToInt(src:PAnsiChar):int64;
begin
  result:=0;
  if src=nil then exit;

  while (src^<>#0) do
  begin
    if src^ in sOctNum then
      result:=(result shl 3)+ord(src^)-ord('0');
    inc(src);
  end;
end;

function NumToInt(src:PWideChar):int64;
begin
  result:=0;
  if src=nil then exit;

  case src[0] of
    '+','-': begin
      if AnsiChar(src[1]) in sNum then
        result:=StrToInt(src);
    end;
    '1'..'9': result:=StrToInt(src);
    '0': begin
      if (src[1]='x') and (AnsiChar(src[2]) in sHexNum) then
        result:=HexToInt(src+2)
      else
        result:=StrToInt(src);
    end;
    '$': begin
      if (AnsiChar(src[1]) in sHexNum) then
        result:=HexToInt(src+1);
    end;
    '&':  begin
      if AnsiChar(src[1]) in sOctNum then
        result:=OctToInt(src+1);
    end;
    '%': begin
      if AnsiChar(src[1]) in sBinNum then
        result:=BinToInt(src+1);
    end;
    '#': begin
      if AnsiChar(src[1]) in sNum then
        result:=StrToInt(src+1)
      else if (src[1]='$') and (AnsiChar(src[2]) in sHexNum) then
        result:=HexToInt(src+2); // or HexToByte
    end;
    '^': begin
      if AnsiChar(src[1]) in sWordOnly then
        result:=ORD(UpCase(AnsiChar(src[1])))-ORD('A');
    end;
  end;

end;

function NumToInt(src:PAnsiChar):int64;
begin
  result:=0;
  if src=nil then exit;

  case src[0] of
    '+','-': begin
      if src[1] in sNum then
        result:=StrToInt(src);
    end;
    '1'..'9': result:=StrToInt(src);
    '0': begin
      if (src[1]='x') and (src[2] in sHexNum) then
        result:=HexToInt(src+2)
      else
        result:=StrToInt(src);
    end;
    '$': begin
      if (src[1] in sHexNum) then
        result:=HexToInt(src+1);
    end;
    '&':  begin
      if src[1] in sOctNum then
        result:=OctToInt(src+1);
    end;
    '%': begin
      if src[1] in sBinNum then
        result:=BinToInt(src+1);
    end;
    '#': begin
      if src[1] in sNum then
        result:=StrToInt(src+1)
      else if (src[1]='$') and (src[2] in sHexNum) then
        result:=HexToInt(src+2); // or HexToByte
    end;
    '^': begin
      if src[1] in sWordOnly then
        result:=ORD(UpCase(src[1]))-ORD('A');
    end;
  end;
end;

{$ENDIF}
