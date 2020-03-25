{
  Text processing
}
{$IFDEF Interface}

function FormatStrW   (fmt:PWideChar; const arr:array of PWideChar):PWideChar;
function FormatStr    (fmt:PAnsiChar; const arr:array of PAnsiChar):PAnsiChar;
function FormatSimpleW(fmt:PWideChar; const arr:array of const):PWideChar;
function FormatSimple (fmt:PAnsiChar; const arr:array of const):PAnsiChar;

function AdjustLineBreaks(s:PWideChar):PWideChar;

{
  filesize to string conversion
  value   - filelength
  divider - 1=byte; 1024=kbyte; 1024*1024 - Mbyte
  prec    - numbers after point (1-3)
  post    - 0=none
            1=(small)' bytes','kb','mb'
            2=(mix)  ' Bytes','Kb','Mb'
            3=(caps) ''      ,'KB','MB'
  postfix calculated from 'divider' value
}
function IntToK(dst:PWideChar; value,divider,prec,post:integer):PWideChar; overload;
function IntToK(dst:PAnsiChar; value,divider,prec,post:integer):PAnsiChar; overload;

{$ELSE}

function FormatStrW(fmt:PWideChar; const arr:array of PWideChar):PWideChar;
var
  i:integer;
  len:cardinal;
  pc:PWideChar;
  number:integer;
begin
  result:=nil;
  if (fmt=nil) or (fmt^=#0) then
    exit;

  // calculate length
  len:=StrLenW(fmt); // -2*Length(arr)
  for i:=0 to HIGH(arr) do
    inc(len,StrLenW(arr[i]));

  // format
  mGetMem(result,(len+1)*SizeOf(WideChar));
  pc:=result;
  number:=0;
  while fmt^<>#0 do
  begin
    if (fmt^='%') and ((fmt+1)^='s') then
    begin
      if number<=HIGH(arr) then
      begin
        pc:=StrCopyEW(pc,arr[number]);
        inc(number);
      end;
      inc(fmt,2);
    end
    else
    begin
      pc^:=fmt^;
      inc(pc);
      inc(fmt);
    end;
  end;
  pc^:=#0;
end;

function FormatStr(fmt:PAnsiChar; const arr:array of PAnsiChar):PAnsiChar;
var
  i:integer;
  len:cardinal;
  pc:PAnsiChar;
  number:integer;
begin
  result:=nil;
  if (fmt=nil) or (fmt^=#0) then
    exit;

  // calculate length
  len:=StrLen(fmt); // -2*Length(arr)
  for i:=0 to HIGH(arr) do
    inc(len,StrLen(arr[i]));

  // format
  mGetMem(result,len+1);
  pc:=result;
  number:=0;
  while fmt^<>#0 do
  begin
    if (fmt^='%') and ((fmt+1)^='s') then
    begin
      if number<=HIGH(arr) then
      begin
        pc:=StrCopyE(pc,arr[number]);
        inc(number);
      end;
      inc(fmt,2);
    end
    else
    begin
      pc^:=fmt^;
      inc(pc);
      inc(fmt);
    end;
  end;
  pc^:=#0;
end;

function FormatSimpleW(fmt:PWideChar; const arr:array of const):PWideChar;
var
  i:integer;
  len:cardinal;
  pc:PWideChar;
  number:integer;
begin
  result:=nil;
  if (fmt=nil) or (fmt^=#0) then
    exit;

  // calculate length
  len:=StrLenW(fmt); // -2*Length(arr)
  for i:=0 to HIGH(arr) do
  begin
    case arr[i].VType of
      vtInteger  : inc(len,10); // max len of VInteger text
      vtPWideChar: inc(len,StrLenW(arr[i].VPWideChar));
    end;
  end;

  // format
  mGetMem(result,(len+1)*SizeOf(WideChar));
  pc:=result;
  number:=0;
  while fmt^<>#0 do
  begin
    if (fmt^='%') then
    begin
      case (fmt+1)^ of
        's': begin
          if number<=HIGH(arr) then
          begin
            pc:=StrCopyEW(pc,arr[number].VPWideChar);
            inc(number);
          end;
          inc(fmt,2);
        end;
        'd','u': begin
          if number<=HIGH(arr) then
          begin
            pc:=StrEndW(IntToStr(pc,arr[number].VInteger));
            inc(number);
          end;
          inc(fmt,2);
        end;
        '%': begin
          pc^:='%';
          inc(pc);
          inc(fmt,2);
        end;
      else
        pc^:=fmt^;
        inc(pc);
        inc(fmt);
      end;
    end;
  end;
  pc^:=#0;
end;

function FormatSimple(fmt:PAnsiChar; const arr:array of const):PAnsiChar;
var
  i:integer;
  len:cardinal;
  pc:PAnsiChar;
  number:integer;
begin
  result:=nil;
  if (fmt=nil) or (fmt^=#0) then
    exit;

  // calculate length
  len:=StrLen(fmt); // -2*Length(arr)
  for i:=0 to HIGH(arr) do
  begin
    case arr[i].VType of
      vtInteger: inc(len,10); // max len of VInteger text
      vtPChar  : inc(len,StrLen(arr[i].VPChar));
    end;
  end;

  // format
  mGetMem(result,len+1);
  pc:=result;
  number:=0;
  while fmt^<>#0 do
  begin
    if (fmt^='%') then
    begin
      case (fmt+1)^ of
        's': begin
          if number<=HIGH(arr) then
          begin
            pc:=StrCopyE(pc,arr[number].VPChar);
            inc(number);
          end;
          inc(fmt,2);
        end;
        'd','u': begin
          if number<=HIGH(arr) then
          begin
            pc:=StrEnd(IntToStr(pc,arr[number].VInteger));
            inc(number);
          end;
          inc(fmt,2);
        end;
        '%': begin
          pc^:='%';
          inc(pc);
          inc(fmt,2);
        end;
      else
        pc^:=fmt^;
        inc(pc);
        inc(fmt);
      end;
    end;
  end;
  pc^:=#0;
end;

function AdjustLineBreaks(s:PWideChar):PWideChar;
var
  Source, Dest: PWideChar;
  Extra, len: Integer;
begin
  Result := nil;
  len := StrLenW(s);
  if len=0 then
    exit;

  Source := s;
  Extra := 0;
  while Source^ <> #0 do
  begin
    case Source^ of
      #10:
        Inc(Extra);
      #13:
        if Source[1] = #10 then
          Inc(Source)
        else
          Inc(Extra);
    end;
    Inc(Source);
  end;

  if Extra = 0 then
  begin
    StrDupW(Result, s);
  end
  else
  begin
    Source := s;
    mGetMem(Result, (len + Extra + 1) * SizeOf(WideChar));
    Dest := Result;
    while Source^ <> #0 do
    begin
      case Source^ of
        #10: begin
          Dest^ := #13;
          Inc(Dest);
          Dest^ := #10;
        end;
        #13: begin
          Dest^ := #13;
          Inc(Dest);
          Dest^ := #10;
          if Source[1] = #10 then
            Inc(Source);
        end;
      else
        Dest^ := Source^;
      end;
      Inc(Dest);
      Inc(Source);
    end;
    Dest^ := #0;
  end;
end;

const
  Posts:array [0..8] of PAnsiChar =
    (' bytes',' Bytes','',
     'kb'    ,'Kb'    ,'KB',
     'mb'    ,'Mb'    ,'MB');

function IntToK(dst:PWideChar; value,divider,prec,post:integer):PWideChar;
var
  p:PWideChar;
  pp:PAnsiChar;
  ls:array [0..7] of WideChar;
  tmp:integer;
begin
  result:=dst;
  if divider=0 then divider:=1;
  IntToStr(dst,value div divider);
  if divider=1 then prec:=0;
  while dst^<>#0 do inc(dst);
  if prec<>0 then
  begin
    if      prec=1 then prec:=10
    else if prec=2 then prec:=100
    else {if prec=3 then} prec:=1000;
    tmp:=round(frac(value*1.0/divider)*prec);
    dst^:='.'; inc(dst);
    IntToStr(PWideChar(@ls),tmp);
    p:=ls;
    while p^<>#0 do
    begin
      dst^:=p^; inc(dst); inc(p);
    end;
    dst^:=#0;
  end;
  if post<>0 then
  begin
    if      divider=1    then tmp:=0
    else if divider=1024 then tmp:=1
    else                      tmp:=2;
    pp:=Posts[tmp*3+post-1];
    while pp^<>#0 do
    begin
      dst^:=WideChar(pp^);
      inc(dst);
      inc(pp);
    end;
    dst^:=#0;
  end;
end;

function IntToK(dst:PAnsiChar; value,divider,prec,post:integer):PAnsiChar;
var
  p:PAnsiChar;
  ls:array [0..7] of AnsiChar;
  tmp:integer;
begin
  result:=dst;
  if divider=0 then divider:=1;
  IntToStr(dst,value div divider);
  if divider=1 then prec:=0;
  while dst^<>#0 do inc(dst);
  if prec<>0 then
  begin
    if      prec=1 then prec:=10
    else if prec=2 then prec:=100
    else {if prec=3 then} prec:=1000;
    tmp:=round(frac(value*1.0/divider)*prec);
    dst^:='.'; inc(dst);
    IntToStr(PAnsiChar(@ls),tmp);
    p:=ls;
    while p^<>#0 do
    begin
      dst^:=p^; inc(dst); inc(p);
    end;
    dst^:=#0;
  end;
  if post<>0 then
  begin
    if      divider=1    then tmp:=0
    else if divider=1024 then tmp:=1
    else                      tmp:=2;
    p:=Posts[tmp*3+post-1];
    while p^<>#0 do
    begin
      dst^:=p^;
      inc(dst);
      inc(p);
    end;
    dst^:=#0;
  end;
end;

{$ENDIF}
