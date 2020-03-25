{
  Text encoding
}

{$IFDEF Interface}

function WideToCombo(src:PWideChar;out dst;cp:integer=CP_ACP):integer;

function ChangeUnicode(aStr:PWideChar):PWideChar;
function UTF8Len    (src:PAnsiChar):integer;
function CalcUTF8Len(src:PWideChar):integer;
function WideToAnsi(src:PWideChar;out dst:PAnsiChar;cp:cardinal=CP_ACP):PAnsiChar;
function AnsiToWide(src:PAnsiChar;out dst:PWideChar;cp:cardinal=CP_ACP):PWideChar;
function AnsiToUTF8(src:PAnsiChar;out dst:PAnsiChar;cp:cardinal=CP_ACP):PAnsiChar;
function UTF8ToAnsi(src:PAnsiChar;out dst:PAnsiChar;cp:cardinal=CP_ACP):PAnsiChar;
function UTF8ToWide(src:PAnsiChar;out dst:PWideChar;len:cardinal=cardinal(-1)):PWideChar;
function WideToUTF8(src:PWideChar;out dst:PAnsiChar):PAnsiChar;

function CharWideToUTF8(src:WideChar;var dst:PAnsiChar):integer;
function CharUTF8ToWide(src:PAnsiChar;pin:pointer=nil):WideChar;
function CharUTF8Len(src:PAnsiChar):integer;

function FastWideToAnsiBuf(src:PWideChar;dst:PAnsiChar;len:cardinal=cardinal(-1)):PAnsiChar;
function FastAnsiToWideBuf(src:PAnsiChar;dst:PWideChar;len:cardinal=cardinal(-1)):PWideChar;
function FastWideToAnsi   (src:PWideChar;out dst:PAnsiChar):PAnsiChar;
function FastAnsiToWide   (src:PAnsiChar;out dst:PWideChar):PWideChar;

function IsTextUTF8(Buffer:pointer):boolean;

{$ELSE}

function WideToAnsi(src:PWideChar;out dst:PAnsiChar; cp:cardinal=0):PAnsiChar;
{$IFDEF UseWinAPI}
var
  l,len:integer;
{$ENDIF}
begin
  if (src=nil) or (src^=#0) then
  begin
    mGetMem(dst,SizeOf(AnsiChar));
    dst^:=#0;
  end
  else
  begin
{$IFDEF UseWinAPI}
    l:=StrLenW(src);
    len:=WideCharToMultiByte(cp,0,src,l,NIL,0,NIL,NIL)+1;
    mGetMem (dst ,len);
    FillChar(dst^,len,0);
    WideCharToMultiByte(cp,0,src,l,dst,len,NIL,NIL);
{$ELSE}
    StrDup(dst,PAnsiChar(AnsiString(WideCharToString(src))));
//    StrDup(result,PAnsiChar(AnsiString(UnicodeString   (src))));
{$ENDIF}
  end;
  result:=dst;
end;

function AnsiToWide(src:PAnsiChar;out dst:PWideChar; cp:cardinal=0):PWideChar;
var
  l:integer;
{$IFDEF UseWinAPI}
  len:integer;
{$ENDIF}
begin
  if (src=nil) or (src^=#0) then
  begin
    mGetMem(dst,SizeOf(WideChar));
    dst^:=#0;
  end
  else
  begin
    if IsLatin(src) then
      FastAnsiToWide(src,dst)
    else
    begin
{$IFDEF UseWinAPI}
      l:=StrLen(src);
      len:=MultiByteToWideChar(cp,0,src,l,NIL,0)+1;
      mGetMem (dst ,len*SizeOf(WideChar));
      FillChar(dst^,len*SizeOf(WideChar),0);
      MultiByteToWideChar(cp,0,src,l,dst,len);
{$ELSE}
      l:=StrLen(src)+1;
      mGetMem (dst ,l*SizeOf(WideChar));
      FillChar(dst^,l*SizeOf(WideChar),0);
      StringToWideChar(src,dst,l);
//    StrDupW(result,PWideChar(WideString(AnsiString(src))));
{$ENDIF}
    end
  end;
  result:=dst;
end;

function WideToCombo(src:PWideChar;out dst;cp:integer=CP_ACP):integer;
var
  pc:PAnsiChar;
  i,j:Cardinal;
begin
  WideToAnsi(src,pc,cp);
  j:=StrLen(pc)+1;
  i:=j+(StrLenW(src)+1)*SizeOf(WideChar);
  mGetMem(PAnsiChar(dst),i);
  StrCopy(PAnsiChar(dst),pc);
  mFreeMem(pc);
  StrCopyW(PWideChar(PAnsiChar(dst)+j),src);
  result:=i;
end;

function ChangeUnicode(aStr:PWideChar):PWideChar;
var
  i,len:integer;
begin
  result:=aStr;
  if (aStr=nil) or (aStr^=#0) then
    exit;
  if (word(aStr^)=SIGN_REVERSEBOM) or (word(aStr^)=SIGN_UNICODE) then
  begin
    len:=StrLenW(aStr);
    if word(aStr^)=SIGN_REVERSEBOM then
    begin
      i:=len-1;
      while i>0 do // aStr^<>#0
      begin
        pword(aStr)^:=swap(pword(aStr)^);
        inc(aStr);
        dec(i);
      end;
    end;
    move((result+1)^,result^,len*SizeOf(WideChar));
  end;
end;


function AnsiToUTF8(src:PAnsiChar;out dst:PAnsiChar;cp:cardinal=CP_ACP):PAnsiChar;
var
  tmp:PWideChar;
begin
  if IsLatin(src) then
    StrDup(dst,src)
  else
  begin
    AnsiToWide(src,tmp,cp);
    WideToUTF8(tmp,dst);
    mFreeMem(tmp);
  end;
  result:=dst;
end;

function UTF8ToAnsi(src:PAnsiChar;out dst:PAnsiChar;cp:cardinal=CP_ACP):PAnsiChar;
var
  tmp:PWideChar;
begin
  if IsLatin(src) then
    StrDup(dst,src)
  else
  begin
    UTF8ToWide(src,tmp);
    WideToAnsi(tmp,dst,cp);
    mFreeMem(tmp);
  end;
  result:=dst;
end;

function UTF8Len(src:PAnsiChar):integer; // w/o zero
begin
  result:=0;
  if src<>nil then
  begin
    if (pcardinal(src)^ and $00FFFFFF)=SIGN_UTF8 then
      inc(src,3);
    while src^<>#0 do
    begin
      if      (ord(src^) and $80)=0 then
      else if (ord(src^) and $E0)=$E0 then
        inc(src,2)
      else
        inc(src);
      inc(result);
      inc(src);
    end;
  end;
end;

function CalcUTF8Len(src:PWideChar):integer;
begin
  result:=0;
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      if      src^<#$0080 then
      else if src^<#$0800 then
        inc(result)
      else
        inc(result,2);
      inc(src);
      inc(result);
    end;
  end;
end;

function CharWideToUTF8(src:WideChar;var dst:PAnsiChar):integer;
begin
  if src<#$0080 then
  begin
    dst^:=AnsiChar(src);
    result:=1;
  end
  else if src<#$0800 then
  begin
    dst^:=AnsiChar($C0 or (ord(src) shr 6));
    inc(dst);
    dst^:=AnsiChar($80 or (ord(src) and $3F));
    result:=2;
  end
  else
  begin
    dst^:=AnsiChar($E0 or (ord(src) shr 12));
    inc(dst);
    dst^:=AnsiChar($80 or ((ord(src) shr 6) and $3F));
    inc(dst);
    dst^:=AnsiChar($80 or (ord(src) and $3F));
    result:=3;
  end;
  inc(dst); dst^:=#0;
end;

function CharUTF8ToWide(src:PAnsiChar;pin:pointer=nil):WideChar;
var
  cnt:integer;
  w:word;
begin
  if ord(src^)<$80 then
  begin
    w:=ord(src^);
    cnt:=1;
  end
  else if (ord(src^) and $E0)=$E0 then
  begin
    w:=(ord(src^) and $1F) shl 12;
    inc(src);
    w:=w or (((ord(src^))and $3F) shl 6);
    inc(src);
    w:=w or (ord(src^) and $3F);
    cnt:=3;
  end
  else
  begin
    w:=(ord(src^) and $3F) shl 6;
    inc(src);
    w:=w or (ord(src^) and $3F);
    cnt:=2;
  end;
  if pin<>nil then
    pcardinal(pin)^:=cnt;
  result:=WideChar(w);
end;

function CharUTF8Len(src:PAnsiChar):integer;
begin
{!!}
  if (ord(src^) and $80)=0 then
    result:=1
  else if (ord(src^) and $E0)=$E0 then
    result:=3
  else
    result:=2;
{}
end;

function UTF8ToWide(src:PAnsiChar; out dst:PWideChar; len:cardinal=cardinal(-1)):PWideChar;
var
  w:word;
  p:PWideChar;
begin
  mGetMem(dst,(UTF8Len(src)+1)*SizeOf(WideChar));
  p:=dst;
  if src<>nil then
  begin
    if (pcardinal(src)^ and $00FFFFFF)=SIGN_UTF8 then
      inc(src,3);
    while (src^<>#0) and (len>0) do
    begin
      if ord(src^)<$80 then
        w:=ord(src^)
      else if (ord(src^) and $E0)=$E0 then
      begin
        w:=(ord(src^) and $1F) shl 12;
        inc(src); dec(len);
        w:=w or (((ord(src^))and $3F) shl 6);
        inc(src); dec(len);
        w:=w or (ord(src^) and $3F);
      end
      else
      begin
        w:=(ord(src^) and $3F) shl 6;
        inc(src); dec(len);
        w:=w or (ord(src^) and $3F);
      end;
      p^:=WideChar(w);
      inc(p);
      inc(src); dec(len);
    end;
  end;
  p^:=#0;
  result:=dst;
end;

function WidetoUTF8(src:PWideChar;out dst:PAnsiChar):PAnsiChar;
var
  p:PAnsiChar;
begin
  mGetMem(dst,CalcUTF8Len(src)+1);
  p:=dst;
  if src<>nil then
  begin
    while src^<>#0 do
    begin
      if src^<#$0080 then
        p^:=AnsiChar(src^)
      else if src^<#$0800 then
      begin
        p^:=AnsiChar($C0 or (ord(src^) shr 6));
        inc(p);
        p^:=AnsiChar($80 or (ord(src^) and $3F));
      end
      else
      begin
        p^:=AnsiChar($E0 or (ord(src^) shr 12));
        inc(p);
        p^:=AnsiChar($80 or ((ord(src^) shr 6) and $3F));
        inc(p);
        p^:=AnsiChar($80 or (ord(src^) and $3F));
      end;
      inc(p);
      inc(src);
    end;
  end;
  p^:=#0;
  result:=dst;
end;

function FastWideToAnsiBuf(src:PWideChar;dst:PAnsiChar;len:cardinal=cardinal(-1)):PAnsiChar;
begin
  result:=dst;
  if src<>nil then
  begin
    repeat
      dst^:=AnsiChar(src^);
      if src^=#0 then
        break;
      dec(len);
      if len=0 then
      begin
        (dst+1)^:=#0;
        break;
      end;
      inc(src);
      inc(dst);
    until false;
  end
  else
    dst^:=#0;
end;

function FastWideToAnsi(src:PWideChar;out dst:PAnsiChar):PAnsiChar;
begin
  if src=nil then
    dst:=nil
  else
  begin
    mGetMem(dst,StrLenW(src)+1);
    FastWideToAnsiBuf(src,dst);
  end;
  result:=dst;
end;

function FastAnsiToWideBuf(src:PAnsiChar;dst:PWideChar;len:cardinal=cardinal(-1)):PWideChar;
begin
  result:=dst;
  if src<>nil then
  begin
    repeat
      dst^:=WideChar(src^);
      if src^=#0 then
        break;
      dec(len);
      if len=0 then
      begin
        (dst+1)^:=#0;
        break;
      end;
      inc(src);
      inc(dst);
    until false;
  end
  else
    dst^:=#0;
end;

function FastAnsiToWide(src:PAnsiChar;out dst:PWideChar):PWideChar;
begin
  if src=nil then
    dst:=nil
  else
  begin
    mGetMem(dst,(StrLen(src)+1)*SizeOf(WideChar));
    FastAnsiToWideBuf(src,dst);
  end;
  result:=dst;
end;


function IsTextUTF8(Buffer:pointer):boolean;
var
  Ascii:boolean;
  Octets:cardinal;
  c:byte;
begin
  if (PAnsiChar(Buffer   )^=#$EF) and
    ((PAnsiChar(Buffer)+1)^=#$BB) and
    ((PAnsiChar(Buffer)+2)^=#$BF) then
  begin
    result:=true;
    exit;
  end;

	Ascii:=true;
	Octets:=0;

	repeat
	  if PByte(Buffer)^=0 then
	    break;

		c:=PByte(Buffer)^;
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

		inc(PByte(Buffer));
	until false;

	result:= not ((Octets>0) or Ascii);
end;

{$ENDIF}
