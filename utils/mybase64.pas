unit myBase64;

interface

{ Base64 encode and decode a string }
function Base64Encode(src:pointer;len:integer):PAnsiChar;
function Base64Decode(src:PAnsiChar;var dst):integer;

{******************************************************************************}
{******************************************************************************}
implementation

type
  PByte = ^Byte;

const
  base64chars{:array [0..63] of AnsiChar}:PAnsiChar =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function Base64Encode(src:pointer;len:integer):PAnsiChar;
var
  dst:PAnsiChar;
  lsrc:PByte absolute src;
begin
  if (src=nil) or (len<=0) then
  begin
    result:=nil;
    exit;
  end;
  GetMem(result,((len*4+11) div (12*4))+1);
  dst:=result;

  while len>0 do
  begin
    dst^:=base64chars[lsrc^ shr 2]; inc(dst);
    if len=1 then
    begin
      dst^:=base64chars[(lsrc^ and 3) shl 4]; inc(dst);
      dst^:='='; inc(dst);
      dst^:='='; inc(dst);
      break;
    end;
    dst^:=base64chars[((lsrc^ and 3) shl 4) or (pbyte(PAnsiChar(lsrc)+1)^ shr 4)]; inc(dst); inc(lsrc);
    if len=2 then
    begin
      dst^:=base64chars[(lsrc^ and $F) shl 2]; inc(dst);
      dst^:='='; inc(dst);
      break;
    end;
    dst^:=base64chars[((lsrc^ and $F) shl 2) or (pbyte(PAnsiChar(lsrc)+1)^ shr 6)]; inc(dst); inc(lsrc);
    dst^:=base64chars[lsrc^ and $3F]; inc(dst); inc(lsrc);
    dec(len,3);
  end;
  dst^:=#0;
end;

function Base64CharToInt(c:AnsiChar):byte;
begin
  case c of
    'A'..'Z': result:=ord(c)-ord('A');
    'a'..'z': result:=ord(c)-ord('a')+26;
    '0'..'9': result:=ord(c)-ord('0')+52;
    '+': result:=62;
    '/': result:=63;
    '=': result:=64;
  else
    result:=255;
  end;
end;

function Base64Decode(src:PAnsiChar;var dst):integer;
var
  slen:integer;
  ptr:PByte;
  b1,b2,b3,b4:byte;
begin
  if (src=nil) or (src^=#0) then
  begin
    result:=0;
    PByte(dst):=nil;
    exit;
  end;
  ptr:=pByte(src);
  while ptr^<>0 do inc(ptr);
  slen:=PAnsiChar(ptr)-src;
  GetMem(ptr,(slen*3) div 4);
  PByte(dst):=ptr;
  result:=0;
  while slen>0 do
  begin
    b1:=Base64CharToInt(src^); inc(src);
    b2:=Base64CharToInt(src^); inc(src);
    b3:=Base64CharToInt(src^); inc(src);
    b4:=Base64CharToInt(src^); inc(src);
    dec(slen,4);
    if (b1=255) or (b1=64) or (b2=255) or (b2=64) or (b3=255) or (b4=255) then
      break;
    ptr^:=(b1 shl 2) or (b2 shr 4); inc(ptr); inc(result);
    if b3=64 then
      break;
    ptr^:=(b2 shl 4) or (b3 shr 2); inc(ptr); inc(result);
    if b4=64 then
      break;
    ptr^:=b4 or (b3 shl 6); inc(ptr); inc(result);
  end;
end;

end.
