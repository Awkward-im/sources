{}
const
  SIGN_UNICODE    = $FEFF;
  SIGN_REVERSEBOM = $FFFE;
  SIGN_UTF8       = $BFBBEF;
const
  CP_ACP        = 0;
  CP_UTF8       = 65001;
  CP_UTF16      = 1200;  // utf-16
  CP_UTF16BE    = 1201;  // unicodeFFFE
  CP_NONE       = $FFFF; // rawbytestring encoding

{$IFDEF UseWinAPI}
const
  IS_TEXT_UNICODE_ASCII16            = $1;
  IS_TEXT_UNICODE_REVERSE_ASCII16    = $10;
  IS_TEXT_UNICODE_STATISTICS         = $2;
  IS_TEXT_UNICODE_REVERSE_STATISTICS = $20;
  IS_TEXT_UNICODE_CONTROLS           = $4;
  IS_TEXT_UNICODE_REVERSE_CONTROLS   = $40;
  IS_TEXT_UNICODE_SIGNATURE          = $8;
  IS_TEXT_UNICODE_REVERSE_SIGNATURE  = $80;
  IS_TEXT_UNICODE_ILLEGAL_CHARS      = $100;
  IS_TEXT_UNICODE_ODD_LENGTH         = $200;
  IS_TEXT_UNICODE_DBCS_LEADBYTE      = $400;
  IS_TEXT_UNICODE_NULL_BYTES         = $1000;
  IS_TEXT_UNICODE_UNICODE_MASK       = $F;
  IS_TEXT_UNICODE_REVERSE_MASK       = $F0;
  IS_TEXT_UNICODE_NOT_UNICODE_MASK   = $F00;
  IS_TEXT_UNICODE_NOT_ASCII_MASK     = $F000;

function IsTextUTF8(Buffer:pbyte;Length:integer):boolean;
var
  Ascii:boolean;
  Octets:cardinal;
  c:byte;
begin
	Ascii:=true;
	Octets:=0;

	if Length=0 then
	  Length:=-1;
	repeat
	  if (Length=0) or (Buffer^=0) then
	    break;
	  dec(Length);
		c:=Buffer^;
		if (c and $80)<>0 then
			Ascii:=false;
		if Octets<>0 then
		begin
			if (c and $C0)<>$80 then
			begin
				result:=false;
				exit;
			end;
			dec(Octets);
		end
		else
		begin
			if (c and $80)<>0 then
			begin
				while (c and $80)<>0 do
				begin
					c:=c shl 1;
					inc(Octets);
				end;
				dec(Octets);
				if Octets=0 then
				begin
					result:=false;
					exit;
				end;
			end
		end;
		inc(Buffer);
	until false;
	result:= not ((Octets>0) or Ascii);
end;

function GetTextFormat(Buffer:PByte;sz:cardinal):integer;
var
  test:integer;
begin
	result:=CP_NONE;

	if sz>=2 then
	begin
  	if       pword (Buffer)^               =SIGN_UNICODE    then result := CP_UTF16
	  else if  pword (Buffer)^               =SIGN_REVERSEBOM then result := CP_UTF16BE
  	else if  (sz>=4) and 
           ((pdword(Buffer)^ and $00FFFFFF)=SIGN_UTF8)      then result := CP_UTF8;
  end;

	if result=CP_NONE then
	begin
		test:=
			IS_TEXT_UNICODE_STATISTICS         or
			IS_TEXT_UNICODE_REVERSE_STATISTICS or
			IS_TEXT_UNICODE_CONTROLS           or
			IS_TEXT_UNICODE_REVERSE_CONTROLS   or
			IS_TEXT_UNICODE_ILLEGAL_CHARS      or
			IS_TEXT_UNICODE_ODD_LENGTH         or
			IS_TEXT_UNICODE_NULL_BYTES;

		if not odd(sz) and IsTextUnicode(Buffer,sz,@test) then
		begin
			if (test and (IS_TEXT_UNICODE_ODD_LENGTH or IS_TEXT_UNICODE_ILLEGAL_CHARS))=0 then
			begin
				if (test and (IS_TEXT_UNICODE_NULL_BYTES or
				              IS_TEXT_UNICODE_CONTROLS   or
				              IS_TEXT_UNICODE_REVERSE_CONTROLS))<>0 then
				begin
					if (test and (IS_TEXT_UNICODE_CONTROLS or
					              IS_TEXT_UNICODE_STATISTICS))<>0 then
						result:=CP_UTF16
					else if (test and (IS_TEXT_UNICODE_REVERSE_CONTROLS or
					                   IS_TEXT_UNICODE_REVERSE_STATISTICS))<>0 then
						result:=CP_UTF16BE;
				end
			end
		end
		else if IsTextUTF8(Buffer,sz) then
			result:=CP_UTF8
		else
		  result:=CP_ACP;
	end;
end;
{$ENDIF}


{$IFDEF UseWinAPI}
procedure ShowDump(ptr:pointer;len:integer);
var
  buf: array of Ansichar;
  i:integer;
  p:PAnsiChar;
  p1:PByte;
  cnt:integer;
begin
  SetLength(buf,len*4+1);
  p:=@buf[0];
  p1:=ptr;
  cnt:=0;
  for i:=0 to len-1 do
  begin
    IntToHex(p,p1^,2);
    inc(p,2);
    inc(p1);
    inc(cnt);
    if cnt=4 then
    begin
      cnt:=0;
      p^:='.';
      inc(p);
    end;
  end;
  p^:=#0;
  messageboxa(0,@buf[0],'',0);
end;
{$ENDIF}
