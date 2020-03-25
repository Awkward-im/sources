{
  INI file processing
  todo: different comment prefixes like ';', '//' or '#'
}
{.$DEFINE UseStrings}

unit INIConfig;

interface

uses
  cfgbase;

function  WriteText     (acfg:PCfgBase):PAnsiChar;
procedure ReadText      (acfg:PCfgBase; txt:PAnsiChar);
function  GetSectionText(acfg:PCfgBase; ans,asection:PAnsiChar):PAnsiChar;


implementation

uses
  common;

const
  MaxLineLen = 60;
  UnbreakLen = 5;
const
  line_separator = '\';


//----- text creating -----

function GetValueLen(avalue:PAnsiChar):integer;
var
  p:PAnsiChar;
  l,llen:integer;
  quotes,crlfs,linebreaks:cardinal;
begin
  if avalue=nil then
  begin
    result:=0;
    exit;
  end;
  quotes    :=0;
  crlfs     :=0;
  linebreaks:=0;
  l:=0;
  p:=avalue;
  llen:=StrLen(avalue);
  inc(avalue,llen);
  while p^<>#0 do
  begin
    if p^ in [#9,' ','''',';',line_separator] then
      quotes:=1;

    if p^ in [#10,#13] then
    begin
      inc(crlfs);
      if ((p+1)^<>p^) and ((p+1)^ in [#10,#13]) then
        inc(p);
      inc(p);

      l:=0;
    end
    else
    begin
      inc(l);
      if l=MaxLineLen then
      begin
        if (avalue-p)>=UnbreakLen then
        begin
          inc(linebreaks);
          l:=0;
        end;
      end;
      inc(p);
    end;
  end;
  result:=llen +
      2*quotes*(crlfs+linebreaks) + // reserve - quotes for #9,#32 and '
      6*crlfs +                     // 2 quotes+space+sep+sep+1, if newline is one char
      6*linebreaks;                 // 2 quotes+space+sep+cr+lf

  if (quotes=0) and (crlfs=0) and (linebreaks=0) then
    result:=-result;
end;

procedure GetValueText(dst:PAnsiChar; avalue:PAnsiChar);
var
  p:PAnsiChar;
  l:integer;
  quotes:boolean;
begin
  if avalue=nil then
  begin
    dst^:=#0;
    exit;
  end;

  p:=avalue;
  l:=0;
  quotes:=false;
  while p^<>#0 do
  begin
    if p^ in [#9,' ','''',';',line_separator] then
    begin
      quotes:=true;
      break;
    end;
    inc(p);
  end;
  if quotes then
  begin
    dst^:=''''; inc(dst);
  end;

  p:=avalue;
  avalue:=StrEnd(avalue);
  while p^<>#0 do
  begin
    if p^ in [#10,#13] then
    begin
      if ((p+1)^<>p^) and ((p+1)^ in [#10,#13]) then
        inc(p);
      inc(p);
    end
    else
    begin
      dst^:=p^; inc(dst); inc(p);
      inc(l);

      if (l<MaxLineLen) or ((avalue-p)<UnbreakLen) then
        continue;
    end;

    if quotes then
    begin
      dst^:=''''; inc(dst);
    end;

    dst^:=' '; inc(dst);
    dst^:=line_separator; inc(dst);
    if (p-1)^ in [#10,#13] then
    begin
      dst^:=line_separator; inc(dst);
    end;

    dst^:=#13; inc(dst); dst^:=#10; inc(dst);
    if quotes then
    begin
      dst^:=''''; inc(dst);
    end;
    l:=0;
  end;
  if quotes then
  begin
    dst^:=''''; inc(dst);
  end;

  dst^:=#0;
end;

// don't calculate spaces of line positions, just pure length
function GetCommentLen(avalue:PAnsiChar):integer;
var
  crlfs:integer;
begin
  if avalue=nil then
  begin
    result:=0;
    exit;
  end;

  crlfs:=0;
  while avalue^<>#0 do
  begin
    if avalue^ in [#13,#10] then
    begin
      inc(crlfs);
      if ((avalue+1)^ in [#13,#10]) and
         ((avalue+1)^ <> avalue^  ) then
        inc(avalue);
      inc(avalue);
    end;
    inc(avalue);
  end;
  result:=StrLen(avalue)+crlfs*(1+StrLen(commentprefix)+1);
end;

function GetParamLen(acfg:PCfgBase; ans,asection,aparam:PAnsiChar):integer;
// var p:PAnsiChar;
begin
  case acfg^.ParameterType[ans,asection,aparam] of
    'a': result:=GetValueLen(acfg^.Value[ans,asection,aparam]);
    'b': begin
      result:=acfg^.ReadInt(ans,asection,aparam)*2;
      result:=result+(result div MaxLineLen)*6 // <quote><quote><space><separator><cr><lf>
    end;
    'n': result:=0;
  else
    result:=32; // even much more than needs (no month names - 24 is enough)
  end;
{
  p:=acfg^.ReadStr(ans,asection,aparam,nil);
  result:=GetValueLen(p);
  mFreeMem(p);
}
end;

function GetSectionText(acfg:PCfgBase; ans,asection:PAnsiChar):PAnsiChar;
var
  p,pl,pp:PAnsiChar;
  sum,ladd,llen:cardinal;
  ltype:AnsiChar;
begin
  result:=nil;

  pl:=acfg^.ParameterList[ans,asection];
  if pl<>nil then
  begin
    //--- calculate full size
    sum:=0;
    p:=pl;
    while p^<>#0 do
    begin
      ladd:=StrLen(p)+1;

      // no additional memory allocation
      llen:=GetParamLen(acfg,ans,asection,p);
      if (llen=0) and not (CFG_KEEPEMPTY in acfg^.Options) then
      begin
        inc(p,ladd);
        continue;
      end;

      inc(sum,ladd+2);    // parameter name including "=" and final crlf
      inc(sum,ABS(llen)); // parameter value with separators, quotes, crlf
    
      inc(p,ladd);
    end;
    mGetMem(result,sum+1);
    
    //--- fill buffer
    p:=result;

    while pl^<>#0 do
    begin
      ladd:=StrLen(pl)+1;

      ltype:=acfg^.ParameterType[ans,asection,p];

      if (ltype='n') and not (CFG_KEEPEMPTY in acfg^.Options) then
      begin
        inc(pl,ladd);
        continue;
      end;

      p:=StrCopyE(p,pl);
      p^:='='; inc(p);
      if ltype<>'n' then
      begin
        pp:=acfg^.ReadStr(ans,asection,pl,nil); //!! slowest place
        case ltype of
          'a','b': begin
            GetValueText(p,pp);
          end;
        else
          p:=StrCopyE(p,pp);
        end;
        mFreeMem(pp); //!!
      end;
      p^:=#13; inc(p);
      p^:=#10; inc(p);

      inc(pl,ladd);
    end;
    p^:=#0;
  end;
end;

function WriteText(acfg:PCfgBase):PAnsiChar;
var
  buf:array [0..1023] of AnsiChar;
  nl,sl,pl:PAnsiChar;
  p:PAnsiChar;
  buflen,llen:integer;
{$IFDEF UseStrings}
  s,ls:AnsiString;
{$ELSE}
  pc,pb:PAnsiChar;
  nslen:integer;
{$ENDIF}
begin
  p:=@buf;
  buflen:=High(buf);

{$IFDEF UseStrings}
  if acfg^.Comment<>nil then
    s:=AnsiString(acfg^.Comment)
  else
    s:='';

  nl:=nil;
  repeat
    sl:=acfg^.SectionList[nl];
    if sl<>nil then
    begin
      while sl^<>#0 do
      begin
        // section header
        s := s + '[' + IIF(nl<>nil,nl + ns_separator, '') + sl + ']'#13#10;
        pl:=acfg^.ParameterList[nl,sl];
        if pl<>nil then
        begin
          while pl^<>#0 do
          begin
            // parameter
            ls:=acfg^.ReadString(nl,sl,pl);
            llen:=GetValueLen(pointer(ls));
            if llen<=0 then
              s := s + pl + '=' + ls + #13#10
            else
            begin
              if llen>buflen then
              begin
                if p<>@buf then mFreeMem(p);
                mGetMem(p,llen+1);
                buflen:=llen;
              end;
              GetValueText(p,pointer(ls));
              s := s + pl + '=' + p + #13#10;
            end;

            pl:=StrEnd(pl)+1;
          end;
        end;
        s := s + #13#10;
        sl:=StrEnd(sl)+1;
      end;
    end;

    if nl=nil then
    begin
      nl:=acfg^.NamespaceList;
      if nl=nil then break;
    end
    else
      nl:=StrEnd(nl)+1;
  until nl^=#0;

  StrDup(result,pointer(s));

{$ELSE}
  // calculate length
  llen:=StrLen(aCfg^.Comment);
  nl:=nil;
  repeat
    nslen:=StrLen(nl);
    sl:=acfg^.SectionList[nl];
    if sl<>nil then
    begin
      while sl^<>#0 do
      begin
        if nl<>nil then inc(llen,nslen+1);
        inc(llen,1+StrLen(sl)+3);

        pl:=acfg^.ParameterList[nl,sl];
        if pl<>nil then
        begin
          while pl^<>#0 do
          begin
            // no difference, keep empty parameter or not
            inc(llen,StrLen(pl)+1+2);
            inc(llen,ABS(GetParamLen(acfg,nl,sl,pl)));

            pl:=StrEnd(pl)+1;
          end;
        end;

        inc(llen,2);
        sl:=StrEnd(sl)+1;
      end;
    end;

    if nl=nil then
    begin
      nl:=acfg^.NamespaceList;
      if nl=nil then break;
    end
    else
      nl:=StrEnd(nl)+1;

  until nl^=#0;

  mGetMem(result,llen+1);
  pb:=result;

  // fill data

  nl:=nil;
  repeat
    sl:=acfg^.SectionList[nl];
    if sl<>nil then
    begin
      while sl^<>#0 do
      begin
        pb^:='['; inc(pb);
        if nl<>nil then
        begin
          pb:=StrCopyE(pb,nl);
          pb^:=ns_separator; inc(pb);
        end;
        pb:=StrCopyE(pb,sl);
        pb^:=']'; inc(pb);
        pb^:=#13; inc(pb);
        pb^:=#10; inc(pb);

        pl:=acfg^.ParameterList[nl,sl];
        if pl<>nil then
        begin
          while pl^<>#0 do
          begin
{}
            pc:=acfg^.ReadStr(nl,sl,pl,nil);
            llen:=GetValueLen(pc);
            pb:=StrCopyE(pb,pl);
            pb^:='='; inc(pb);
            if llen<=0 then
              pb:=StrCopyE(pb,pc)
            else
            begin
              if llen>buflen then
              begin
                if p<>@buf then mFreeMem(p);
                mGetMem(p,llen+1);
                buflen:=llen;
              end;
              GetValueText(p,pc);
              pb:=StrCopyE(pb,p);
            end;
            pb^:=#13; inc(pb);
            pb^:=#10; inc(pb);
{}
            pl:=StrEnd(pl)+1;
          end;
        end;

        pb^:=#13; inc(pb);
        pb^:=#10; inc(pb);

        sl:=StrEnd(sl)+1;
      end;
    end;

    if nl=nil then
    begin
      nl:=acfg^.NamespaceList;
      if nl=nil then break;
    end
    else
      nl:=StrEnd(nl)+1;

  until nl^=#0;

  pb^:=#0;
{$ENDIF}

  if p<>@buf then
    mFreeMem(p);
end;

//----- Reading from buffer -----

// quotes, multiline etc
// result = pointer to non-parameter line
// pointers: start of value, start of current line, end of value in line, end of current line
{
  docopy=false - return decoded value len
  docopy=true  - return encoded value len including trailing crlfs
}
function ProcessParamValue(valstart,dst:PAnsiChar; docopy:boolean=false):integer;
var
  start,lineend,eol:PAnsiChar;
  llen:integer;
  multiline,crlf:boolean;
begin
  start:=valstart;
  llen:=0;
  repeat
    multiline:=false;
    crlf     :=false;

    //-- 1 - skip starting spaces

    while start^ in [#9,' '] do inc(start);

    //-- 2 - determine line end

    if start^ in [#0,#10,#13] then // empty value or end
    begin
      while start^ in [#10,#13] do inc(start);
      break;
    end;

    lineend:=start;
    while not (lineend^ in [#0,#10,#13]) do inc(lineend);
    eol:=lineend; // pointer AFTER last char
    dec(lineend);
    while lineend^ in [#9,' '] do dec(lineend);

    //-- 3 - check for multiline

    if lineend^=line_separator then // multiline or part of value
    begin
      if (lineend=start) or ((lineend-1)^ in [#9,' ']) then // multiline
      begin
        if lineend>start then dec(lineend);
        multiline:=true;
        while lineend^ in [#9,' '] do dec(lineend);
      end
      // double separator = multiline + crlf saving
      else if (lineend> start   ) and ((lineend-1)^=line_separator) and
             ((lineend=(start+1)) or  ((lineend-2)^ in [#9,' '])) then
      begin
        if lineend>(start+1) then dec(lineend,2);
        multiline:=true;
        crlf     :=true;
        while lineend^ in [#9,' '] do dec(lineend);
      end;
    end;
    // lineend points to last char
    // start   points to first char
    // eol     points to end of line

    //-- 4 - check for starting/trailing quotes

    if (start^ in ['''','"']) and (lineend^ = start^) and (lineend<>start) then
    begin
      inc(start);
      dec(lineend);
    end;

    //-- 5 - copy line content excluding quotes, border spaces and multiline separators

    if docopy then
    begin
      while start<=lineend do
      begin
        dst^:=start^;
        inc(dst);
        inc(start);
      end;
      if crlf then
      begin
        dst^:=#13; inc(dst);
        dst^:=#10; inc(dst);
        inc(llen,2);
      end;
    end
    else
    begin
      llen:=llen+(lineend-start)+1;
      if crlf then
        inc(llen,2);
    end;

    start:=eol;
    while start^ in [#10,#13] do inc(start);

  until not multiline;

  if docopy then
  begin
    dst^:=#0;
    llen:=start-valstart;
  end;

  result:=llen;
end;

procedure ReadText(acfg:PCfgBase; txt:PAnsiChar);
var
  pc1,pc,pend:PAnsiChar;
  lns,lsection,lparam:array [0..127] of AnsiChar;
  len:integer;
  createsection,hascomment:boolean;
begin
  aCfg^.Clear;

  if (txt=nil) or (txt^=#0) then
    exit;

  hascomment:=false;
  createsection:=true;
  pc:=txt; //!!

  lns     [0]:=#0;
  lsection[0]:=#0;

  while pc^<>#0 do
  begin
    while pc^ in [#9,#10,#13,' '] do inc(pc);

    //-- comment
    if pc^=';' then
    begin
      hascomment:=true;
      while not (pc^ in [#0,#10,#13])     do inc(pc); // skip to next line (or end)
      while     (pc^ in [#9,#10,#13,' ']) do inc(pc); // skip empty
    end

    //-- section
    else if pc^='[' then
    begin
      // top comment
      if (lsection[0]=#0) and (hascomment) then
      begin
        StrDup(pc1,txt,pc-txt);
        acfg^.AssignComment(pc1);
      end;

      //!! empty section
      if (lsection[0]<>#0) and
         (not createsection) and
         (CFG_KEEPEMPTY in aCfg^.Options) then
      begin
        acfg^.Section[lns,lsection];
      end;

      inc(pc);
      {}
      pc1:=pc;
      repeat
        if (pc^ = ']') or (pc^ = #0) then
          break;
        inc(pc);
      until false;
      if pc^=#0 then break;
      {}
      StrCopy(lsection,pc1,pc-pc1);

      if (CFG_USENAMESPACE in aCfg^.Options) then
      begin
        pc1:=StrScan(lsection,ns_separator);
        if pc1<>nil then
        begin
          StrCopy(lns,lsection,pc1-lsection);
          StrCopy(lsection,pc1+1);
        end
        else
        begin
          lns[0]:=#0;
        end;
      end;
       
      createsection:=false;
      inc(pc);
    end

    //-- parameter (skip before first section)
    else if (pc^ in sWord) and (lsection[0]<>#0) then
    begin
      pc1:=pc;
      // skip param name (can have spaces)
      while not (pc^ in [#0,#9,#10,#13,'=']) do inc(pc);
      if pc^<>#0 then
      begin
        pend:=pc;
        repeat
          dec(pend);
        until (pend^ in sWord);
        inc(pend);
        // skip spaces
        while pc^ in [#9,' '] do inc(pc);
        // no "=" means bad line, just skip it
        if pc^='=' then
        begin
          inc(pc); // must be "="
          // skip spaces
          while pc^ in [#9,' '] do inc(pc);

          StrCopy(lparam,pc1,pend-pc1);

          len:=ProcessParamValue(pc,nil,false);
          if len>0 then
          begin
            mGetMem(pc1,len+1);
            pc:=pc+ProcessParamValue(pc,pc1,true);
          end
          else
            pc1:=nil;
          if (CFG_KEEPEMPTY in aCfg^.Options) or (pc1<>nil) then
          begin
            aCfg^.AssignStr(lns,lsection,lparam,pc1);
            createsection:=true;
          end;
        end
        else
          while not (pc^ in [#0,#10,#13]) do inc(pc);
      end;
    end

    //-- wrong thing, skip line
    else
      while not (pc^ in [#0,#10,#13]) do inc(pc);
  end;

  //!! empty section at the end
  if (lsection[0]<>#0) and
     (not createsection) and
     (CFG_KEEPEMPTY in aCfg^.Options) then
  begin
    acfg^.Section[lns,lsection];
  end;

end;

begin
end.
