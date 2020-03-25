{
  Basic text functions
}
{$IFDEF Interface}

function StrDup (out dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
function StrDupW(out dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
function StrEmpty:pointer;

function StrDelete (aStr:PAnsiChar;apos,len:cardinal):PAnsiChar;
function StrDeleteW(aStr:PWideChar;apos,len:cardinal):PWideChar;
function StrInsert (SubStr,src:PAnsiChar;apos:cardinal):PAnsiChar;
function StrInsertW(SubStr,src:PWideChar;apos:cardinal):PWideChar;

function StrReplace (src,SubStr,NewStr:PAnsiChar):PAnsiChar;
function StrReplaceW(src,SubStr,NewStr:PWideChar):PWideChar;
function CharReplace (dst:PAnsiChar; old,new:AnsiChar):PAnsiChar;
function CharReplaceW(dst:PWideChar; old,new:WideChar):PWideChar;

function StrEnd (const a:PAnsiChar):PAnsiChar;
function StrEndW(const a:PWideChar):PWideChar;

function StrLen (aStr: PAnsiChar): Cardinal;
function StrLenW(aStr: PWideChar): Cardinal;

function StrCat  (Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
function StrCatW (Dest: PWideChar; const Source: PWideChar): PWideChar;
function StrCatE (Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
function StrCatEW(Dest: PWideChar; const Source: PWideChar): PWideChar;

function StrCopyE (dst:PAnsiChar; src:PAnsiChar; len:cardinal=0):PAnsiChar;
function StrCopyEW(dst:PWideChar; src:PWideChar; len:cardinal=0):PWideChar;
function StrCopy  (dst:PAnsiChar; src:PAnsiChar; len:cardinal=0):PAnsiChar;
function StrCopyW (dst:PWideChar; src:PWideChar; len:cardinal=0):PWideChar;

function StrCmp   (a,b:PAnsiChar; n:integer=0):integer;
function StrCmpW  (a,b:PWideChar; n:integer=0):integer;
function StrCmpI  (a,b:PAnsiChar; n:integer=0):integer;
function StrCmpIW (a,b:PWideChar; n:integer=0):integer;
function StrScan  (src:PAnsiChar; c:AnsiChar):PAnsiChar;
function StrScanW (src:PWideChar; c:WideChar):PWideChar;
function StrRScan (src:PAnsiChar; c:AnsiChar):PAnsiChar;
function StrRScanW(src:PWideChar; c:WideChar):PWideChar;

function StrPos   (const aStr, aSubStr: PAnsiChar; apos:cardinal=0): PAnsiChar;
function StrPosW  (const aStr, aSubStr: PWideChar; apos:cardinal=0): PWideChar;
function StrIndex (const aStr, aSubStr: PAnsiChar):integer;
function StrIndexW(const aStr, aSubStr: PWideChar):integer;

function GetPairChar(ch:AnsiChar):AnsiChar; overload;
function GetPairChar(ch:WideChar):WideChar; overload;

function IsLatin(aStr:PAnsiChar):boolean; overload;
function IsLatin(aStr:PWideChar):boolean; overload;

function IsCaps(aStr:PAnsiChar):boolean;

{$ELSE}

function StrDup(out dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;
var
  p:PAnsiChar;
  l:cardinal;
begin
  if (src=nil) or (src^=#0) then
    dst:=nil
  else
  begin
    if len=0 then
      len:=high(cardinal);
    p:=src;
    l:=len;
    while (p^<>#0) and (l>0) do
    begin
      inc(p); dec(l);
    end;
    l:=p-src;

    mGetMem(dst,l+1);
    move(src^, dst^,l);
    dst[l]:=#0;
  end;
  result:=dst;
end;

function StrDupW(out dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;
var
  p:PWideChar;
  l:cardinal;
begin
  if (src=nil) or (src^=#0) then
    dst:=nil
  else
  begin
    if len=0 then
      len:=high(cardinal);
    p:=src;
    l:=len;
    while (p^<>#0) and (l>0) do
    begin
      inc(p); dec(l);
    end;
    l:=p-src;
    mGetMem(dst,(l+1)*SizeOf(WideChar));
    move(src^, dst^,l*SizeOf(WideChar));
    dst[l]:=#0;
  end;
  result:=dst;
end;

function StrEmpty:pointer;
begin
  mGetMem(result,SizeOf(WideChar));
  pword(result)^:=0;
end;

function StrCopyInt(dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):cardinal;
var
  p:PAnsiChar;
  l:cardinal;
begin
  l:=0;
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l);
      dst[l]:=#0;
    end;
  end;
  result:=l;
end;

function StrCopyIntW(dst:PWideChar;src:PWideChar;len:cardinal=0):cardinal;
var
  p:PWideChar;
  l:cardinal;
begin
  l:=0;
  if dst<>nil then
  begin
    if (src=nil) or (src^=#0) then
      dst^:=#0
    else
    begin
      if len=0 then
        len:=high(cardinal);
      p:=src;
      l:=len;
      while (p^<>#0) and (l>0) do
      begin
        inc(p); dec(l);
      end;
      l:=p-src;
      move(src^, dst^,l*SizeOf(WideChar));
      dst[l]:=#0;
    end;
  end;
  result:=l;
end;

function StrCopyE(dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=dst+StrCopyInt(dst,src,len);
end;

function StrCopyEW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=dst+StrCopyIntW(dst,src,len);
end;

function StrCopy(dst:PAnsiChar;src:PAnsiChar;len:cardinal=0):PAnsiChar;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  StrCopyInt(dst,src,len);
  result:=dst;
end;

function StrCopyW(dst:PWideChar;src:PWideChar;len:cardinal=0):PWideChar;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  StrCopyIntW(dst,src,len);
  result:=dst;
end;

function StrDelete(aStr:PAnsiChar;apos,len:cardinal):PAnsiChar;
var
  i:cardinal;
begin
  if len>0 then
  begin
    i:=StrLen(aStr);
    if apos<i then
    begin
      if (apos+len)>i then
        len:=i-apos;
      StrCopy(aStr+apos,aStr+apos+len);
    end;
  end;
  result:=aStr;
end;

function StrDeleteW(aStr:PWideChar;apos,len:cardinal):PWideChar;
var
  i:cardinal;
begin
  if len>0 then
  begin
    i:=StrLenW(aStr);
    if apos<i then
    begin
      if (apos+len)>i then
        len:=i-apos;
      StrCopyW(aStr+apos,aStr+apos+len);
    end;
  end;
  result:=aStr;
end;

function StrInsert(SubStr,src:PAnsiChar;apos:cardinal):PAnsiChar;
var
  p:PAnsiChar;
  i:cardinal;
begin
  i:=StrLen(SubStr);
  if i<>0 then
  begin
    p:=src+apos;
    move(p^,(p+i)^,StrLen(src)-apos+1);
    move(SubStr^,p^,i);
  end;
  result:=src;
end;

function StrInsertW(SubStr,src:PWideChar;apos:cardinal):PWideChar;
var
  p:PWideChar;
  i:cardinal;
begin
  i:=StrLenW(SubStr);
  if i<>0 then
  begin
    p:=src+apos;
    move(p^,(p+i)^,(StrLenW(src)-apos+1)*SizeOf(PWideChar));
    move(SubStr^,p^,i*SizeOf(WideChar));
  end;
  result:=src;
end;

function StrReplace(src,SubStr,NewStr:PAnsiChar):PAnsiChar;
var
  p:PAnsiChar;
  i,j,l:integer;
  k:integer;
begin
  result:=src;
  p:=StrPos(src,SubStr);
  if p=nil then exit;
  i:=StrLen(SubStr);
  j:=StrLen(NewStr);
  l:=i-j;
  repeat
    if j=0 then
      StrCopy(p,p+i)
    else
    begin
      k:=StrLen(p)+1;
      if l>0 then
        move((p+l)^,p^,k-l)
      else if l<>0 then
        move(p^,(p-l)^,k);
      move(NewStr^,p^,j); {new characters}
      inc(p,j);
    end;
    p:=StrPos(p,SubStr);
    if p=nil then break;
  until false;
end;

function StrReplaceW(src,SubStr,NewStr:PWideChar):PWideChar;
var
  p:PWideChar;
  i,j,l:integer;
  k:integer;
begin
  result:=src;
  p:=StrPosW(src,SubStr);
  if p=nil then exit;
  i:=StrLenW(SubStr);
  j:=StrLenW(NewStr);
  l:=i-j;
  repeat
    if j=0 then
      StrCopyW(p,p+i)
    else
    begin
      k:=(StrLenW(p)+1)*SizeOf(WideChar);
      if l>0 then
        move((p+l)^,p^,k-l*SizeOf(WideChar))
      else if l<>0 then
        move(p^,(p-l)^,k);
      move(NewStr^,p^,j*SizeOf(WideChar)); {new characters}
      inc(p,j);
    end;
    p:=StrPosW(p,SubStr);
    if p=nil then break;
  until false;
end;

function CharReplace(dst:PAnsiChar;old,new:AnsiChar):PAnsiChar;
begin
  result:=dst;
  if dst<>nil then
  begin
    while dst^<>#0 do
    begin
      if dst^=old then dst^:=new;
      inc(dst);
    end;
  end;
end;

function CharReplaceW(dst:PWideChar;old,new:WideChar):PWideChar;
begin
  result:=dst;
  if dst<>nil then
  begin
    while dst^<>#0 do
    begin
      if dst^=old then dst^:=new;
      inc(dst);
    end;
  end;
end;

function StrCmp(a,b:PAnsiChar;n:integer=0):integer; // CompareString
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if ((a=nil) and (b^=#0)) or
     ((b=nil) and (a^=#0)) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  repeat
    result:=ord(a^)-ord(b^);
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  until n=0;
end;

function StrCmpW(a,b:PWideChar;n:integer=0):integer;
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if ((a=nil) and (b^=#0)) or
     ((b=nil) and (a^=#0)) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  repeat
    result:=ord(a^)-ord(b^);
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  until n=0;
end;

function StrCmpI(a,b:PAnsiChar;n:integer=0):integer; // CompareString
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if ((a=nil) and (b^=#0)) or
     ((b=nil) and (a^=#0)) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  repeat
    result:=ord(system.LowerCase(a^))-ord(system.LowerCase(b^));
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  until n=0;
end;

function StrCmpIW(a,b:PWideChar;n:integer=0):integer;
begin
  result:=0;
  if (a=nil) and (b=nil) then
    exit;
  if ((a=nil) and (b^=#0)) or
     ((b=nil) and (a^=#0)) then
    exit;
  if (a=nil) or (b=nil) then
  begin
    result:=-1;
    exit;
  end;
  repeat
    result:=ord(system.LowerCase(AnsiChar(a^)))-ord(system.LowerCase(AnsiChar(b^)));
    if (result<>0) or (a^=#0) then
      break;
    inc(a);
    inc(b);
    dec(n);
  until n=0;
end;

function StrEnd(const a:PAnsiChar):PAnsiChar;
begin
  result:=a;
  if result<>nil then
    while result^<>#0 do inc(result);
end;

function StrEndW(const a:PWideChar):PWideChar;
begin
  result:=a;
  if result<>nil then
    while result^<>#0 do inc(result);
end;

function StrScan(src:PAnsiChar;c:AnsiChar):PAnsiChar;
begin
  if src<>nil then
  begin
    while (src^<>#0) and (src^<>c) do inc(src);
    if src^<>#0 then
    begin
      result:=src;
      exit;
    end;
  end;
  result:=nil;
end;

function StrRScan(src:PAnsiChar;c:AnsiChar):PAnsiChar;
begin
  if src<>nil then
  begin
    result:=StrEnd(src);
    while (result>=src) and (result^<>c) do dec(result);
    if result<src then
      result:=nil;
  end
  else
    result:=nil;
end;

function StrScanW(src:PWideChar;c:WideChar):PWideChar;
begin
  if src<>nil then
  begin
    while (src^<>#0) and (src^<>c) do inc(src);
    if src^<>#0 then
    begin
      result:=src;
      exit;
    end;
  end;
  result:=nil;
end;

function StrRScanW(src:PWideChar;c:WideChar):PWideChar;
begin
  if src<>nil then
  begin
    result:=StrEndW(src);
    while (result>=src) and (result^<>c) do dec(result);
    if result<src then
      result:=nil;
  end
  else
    result:=nil;
end;

function StrLen(aStr: PAnsiChar): Cardinal;
var
  p:PAnsiChar;
begin
  p:=aStr;
  if p<>nil then
    while (p^<>#0) do Inc(p);
  Result:=(p-aStr);
end;

function StrLenW(aStr: PWideChar): Cardinal;
var
  p:PWideChar;
begin
  p:=aStr;
  if p<>nil then
    while (p^<>#0) do Inc(p);
  Result:=(p-aStr);
end;

function StrCat(Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
begin
  if Dest<>nil then
    StrCopy(StrEnd(Dest), Source);
  Result := Dest;
end;

function StrCatW(Dest: PWideChar; const Source: PWideChar): PWideChar;
begin
  if Dest<>nil then
    StrCopyW(StrEndW(Dest), Source);
  Result := Dest;
end;

function StrCatE(Dest: PAnsiChar; const Source: PAnsiChar): PAnsiChar;
begin
  if Dest<>nil then
    result:=StrCopyE(StrEnd(Dest), Source)
  else
    result:=nil;
end;

function StrCatEW(Dest: PWideChar; const Source: PWideChar): PWideChar;
begin
  if Dest<>nil then
    result:=StrCopyEW(StrEndW(Dest), Source)
  else
    result:=nil;
end;

function StrPos(const aStr, aSubStr: PAnsiChar; apos:cardinal=0): PAnsiChar;
var
  lStr, lSubStr: PAnsiChar;
  ch: AnsiChar;
begin
  if (aStr = nil) or (aStr^ = #0) or (aSubStr = nil) or (aSubStr^ = #0) then
  begin
    Result := nil;
    Exit;
  end;
  Result := aStr;
  if (apos>0) and (apos<StrLen(aStr)) then
    inc(Result,apos);
  ch := aSubStr^;
  repeat
    if Result^ = ch then
    begin
      lStr := Result;
      lSubStr := aSubStr;
      repeat
        Inc(lStr);
        Inc(lSubStr);
        if lSubStr^ = #0 then exit;
        if lStr^ = #0 then
        begin
          Result := nil;
          exit;
        end;
        if lStr^ <> lSubStr^ then break;
      until false;
    end;
    Inc(Result);
  until (Result^ = #0);
  Result := nil;
end;

function StrIndex(const aStr, aSubStr: PAnsiChar):integer;
var
  p:PAnsiChar;
begin
  p:=StrPos(aStr,aSubStr);
  if p=nil then
    result:=0
  else
    result:=p-aStr+1;
end;

function StrPosW(const aStr, aSubStr: PWideChar; apos:cardinal=0): PWideChar;
var
  lStr, lSubStr: PWideChar;
  ch: WideChar;
begin
  if (aStr = nil) or (aStr^ = #0) or (aSubStr = nil) or (aSubStr^ = #0) then
  begin
    Result := nil;
    Exit;
  end;
  Result := aStr;
  if (apos>0) and (apos<StrLenW(aStr)) then
    inc(Result,apos);
  ch := aSubStr^;
  repeat
    if Result^ = ch then
    begin
      lStr := Result;
      lSubStr := aSubStr;
      repeat
        Inc(lStr);
        Inc(lSubStr);
        if lSubStr^ = #0 then exit;
        if lStr^ = #0 then
        begin
          Result := nil;
          exit;
        end;
        if lStr^ <> lSubStr^ then break;
      until false;
    end;
    Inc(Result);
  until (Result^ = #0);
  Result := nil;
end;

function StrIndexW(const aStr, aSubStr: PWideChar):integer;
var
  p:PWideChar;
begin
  p:=StrPosW(aStr,aSubStr);
  if p=nil then
    result:=0
  else
    result:=(p-aStr)+1; //!!!!
end;

function GetPairChar(ch:AnsiChar):AnsiChar;
begin
  case ch of
    '[': result:=']';
    '<': result:='>';
    '(': result:=')';
    '{': result:='}';
  else // ' and " too
    result:=ch;
  end;
end;

function GetPairChar(ch:WideChar):WideChar;
begin
  case ch of
    '[': result:=']';
    '<': result:='>';
    '(': result:=')';
    '{': result:='}';
  else // ' and " too
    result:=ch;
  end;
end;

function IsLatin(aStr:PAnsiChar):boolean;
begin
  if aStr<>nil then
  begin
    while ORD(aStr^)<>0 do
    begin
      if ORD(aStr^)>127 then
      begin
        result:=false;
        exit
      end;
      inc(aStr);
    end;
  end;
  result:=true;
end;

function IsLatin(aStr:PWideChar):boolean;
begin
  if aStr<>nil then
  begin
    while ORD(aStr^)<>0 do
    begin
      if ORD(aStr^)>127 then
      begin
        result:=false;
        exit
      end;
      inc(aStr);
    end;
  end;
  result:=true;
end;

function IsCaps(aStr:PAnsiChar):boolean;
begin
  if aStr<>nil then
  begin
    while ORD(aStr^)<>0 do
    begin
      if aStr^ in ['a'..'z'] then
      begin
        result:=false;
        exit
      end;
      inc(aStr);
    end;
  end;
  result:=true;
end;

{$ENDIF}
