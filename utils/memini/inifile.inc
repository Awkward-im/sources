{
}
{$IFDEF Interface}

  tINIFile = object
  private
    ffilename:PAnsiChar;
    buffer   :PAnsiChar;
    outtext  :PAnsiChar;

    FNamespaces:pININamespace;

    FTopComment:PAnsiChar;
    FNSList    :PAnsiChar;

    flags   :cardinal;
    FOptions:tINIOptions;

    function FlushFile(var f):boolean;

    function  PrepareText  ():PAnsiChar;
    procedure TranslateText(txt:PAnsiChar);

    procedure SetINIOptions(const opt:tINIOptions);
    procedure Clear;

    //--- Comment ---

    procedure SetTopComment(acomment:PAnsiChar);

    //--- Namespace ---

    function  AddNamespace (aname:PAnsiChar):pININamespace;
    function  FindNamespace(aname:PAnsiChar):pININamespace;
    function  GetNamespace (aname:PAnsiChar):pININamespace;

    function  GetNamespaceCount():integer;
    function  GetNamespaceList ():PAnsiChar;

    //--- Section ---

    function  FindSection(ans,asection:PAnsiChar):pINISection;
    function  GetSection (ans,asection:PAnsiChar):pINISection; overload;
    function  GetSection (    asection:PAnsiChar):pINISection; overload;

    function  GetSectionCount(ans:PAnsiChar):integer;
    function  GetSectionList (ans:PAnsiChar):PAnsiChar;

    //--- Value ---

    procedure SetAsText(             akey:PAnsiChar; aval:PAnsiChar); overload;
    procedure SetAsText(    asection,akey:PAnsiChar; aval:PAnsiChar); overload;
    procedure SetAsText(ans,asection,akey:PAnsiChar; aval:PAnsiChar); overload;

    function  GetAsText(             akey:PAnsiChar):PAnsiChar; overload;
    function  GetAsText(    asection,akey:PAnsiChar):PAnsiChar; overload;
    function  GetAsText(ans,asection,akey:PAnsiChar):PAnsiChar; overload;

  public
    property Namespace[ans:PAnsiChar]:pININamespace read GetNamespace;
    property Section  [ans:PAnsiChar; asection:PAnsiChar]:pINISection read GetSection;

  public
    procedure Free;

    function Flush(const afname:AnsiString   ):boolean; overload; //??
    function Flush(const afname:PAnsiChar=nil):boolean; overload; //??
    function Flush(const afname:PWideChar    ):boolean; overload; //??

    function IsNamespace(aname:PAnsiChar):boolean;
    function IsSection  (aname:PAnsiChar):boolean;

    function  ReadBool   (ans,asection,akey:PAnsiChar; adefault:boolean=false):boolean;
    procedure WriteBool  (ans,asection,akey:PAnsiChar; avalue  :boolean);
    function  ReadInt    (ans,asection,akey:PAnsiChar; adefault:integer=0):integer;
    procedure WriteInt   (ans,asection,akey:PAnsiChar; avalue  :integer);
    function  ReadWide   (ans,asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar;
    procedure WriteWide  (ans,asection,akey:PAnsiChar; avalue  :PWideChar);
    function  ReadStr    (ans,asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar;
    procedure WriteStr   (ans,asection,akey:PAnsiChar; avalue  :PAnsiChar);
    function  ReadString (ans,asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString;
    procedure WriteString(ans,asection,akey:PAnsiChar; const avalue  :AnsiString);
    function  ReadStruct (ans,asection,akey:PAnsiChar; buf   :pointer=nil):pointer;
    procedure WriteStruct(ans,asection,akey:PAnsiChar; avalue:pointer; asize:cardinal);

    //--- properties ---

    property FileName  :PAnsiChar read ffilename;
    property Text      :PAnsiChar read PrepareText write TranslateText;
    property TopComment:PAnsiChar read FTopComment write SetTopComment;

    // namespacelist+namespace
    property NamespaceList :PAnsiChar read GetNamespaceList;
    property NamespaceCount:integer   read GetNamespaceCount;

    //sectionlist+sections
    property SectionList [ans:PAnsiChar]:PAnsiChar read GetSectionList;
    property SectionCount[ans:PAnsiChar]:integer   read GetSectionCount;

    property Options:tINIOptions read FOptions write SetINIOptions;

    property Value[ans:PAnsiChar; asection:PAnsiChar; akey:PAnsiChar]:PAnsiChar
             read GetAsText write SetAsText; default;
  end;

{$ELSE}

//----- Support -----

procedure tINIFile.SetTopComment(acomment:PAnsiChar);
begin
  mFreeMem(FTopComment);
  StrDup  (FTopComment,acomment);
end;

//----- Namespace -----

function tINIFile.GetNamespaceCount():integer;
var
  ns:pININamespace;
begin
  result:=0;
  if (flags and F_IGNORENS)=0 then
  begin
    ns:=FNamespaces;
    while ns<>nil do
    begin
      inc(result);
      ns:=ns^.next;
    end;
  end;
end;

function tINIFile.GetNamespaceList():PAnsiChar;
var
  pc:PAnsiChar;
  ns:pININamespace;
  lsize:cardinal;
begin
  if (flags and F_IGNORENS)<>0 then
  begin
    result:=nil;
    exit;
  end;

  if (flags and F_CHANGED)<>0 then
  begin
    mFreeMem(FNSList);
    
    lsize:=0;
    ns:=FNamespaces^.next;
    while ns<>nil do
    begin
      inc(lsize,StrLen(ns^.Name)+1);
      ns:=ns^.next;
    end;

    mGetMem(pc,lsize+1);
    FNSList:=pc;
    if lsize>0 then
    begin
      ns:=FNamespaces;
      while ns<>nil do
      begin
        if ns^.Name<>nil then
        begin
          pc:=StrCopyE(pc,ns^.Name);
          inc(pc);
        end;
        ns:=ns^.next;
      end;
    end;
    pc^:=#0;
    flags:=flags and not F_CHANGED;
  end;
  result:=FNSList;
end;

function tINIFile.AddNamespace(aname:PAnsiChar):pININamespace;
var
  ns,last:pININamespace;
begin
  New(ns);
  FillChar(ns^,SizeOf(tININamespace),0);

  if aname<>nil then
  begin
    last:=FNamespaces;
    while last^.next<>nil do
      last:=last^.next;
    last^.next:=ns;
  end
  else
    FNamespaces:=ns;

  ns^.parent:=@self;
  ns^.flags :=F_USED;

  if (flags and F_BUFFER)<>0 then
    ns^.FName:=aname
  else
  begin
    StrDup(ns^.FName,aname);
    ns^.flags:=ns^.flags or F_NAME;
  end;

  flags:=flags or F_CHANGED;
  result:=ns;
end;

function tINIFile.FindNamespace(aname:PAnsiChar):pININamespace;
var
  ns:pININamespace;
  b:boolean;
begin
  ns:=FNamespaces;
  if (aname<>nil) and (aname^<>#0) then
  begin
    ns:=ns^.next;

    while (ns<>nil) do
    begin
      if (flags and F_CASE)<>0 then
        b:=StrCmp (ns^.Name,aname)=0
      else
        b:=StrCmpI(ns^.Name,aname)=0;
      if b then break;

      ns:=ns^.next;
    end;
  end;
  result:=ns;
end;

function tINIFile.GetNamespace(aname:PAnsiChar):pININamespace;
begin
  result:=FindNamespace(aname);
  if result=nil then
    result:=AddNamespace(aname);
end;

function tINIFile.IsNamespace(aname:PAnsiChar):boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=FindNamespace(aname)<>nil;
end;

//----- Sections -----

function tINIFile.GetSectionCount(ans:PAnsiChar):integer;
var
  lns:pININamespace;
begin
  result:=0;
  // total
{
  if ans=nil then
  begin
    lns:=FNamespaces;
    while lns<>nil do
    begin
      inc(result);
      lns:=lns^.next;
    end;
  end
  // no namespace, use first (total if no namespaces)
  else }
  if (ans=nil) or (ans^=#0) then
  begin
    result:=FNamespaces^.SectionCount
  end
  // namespace
  else
  begin
    if (flags and F_IGNORENS)=0 then
    begin
      lns:=FindNamespace(ans);
      if lns<>nil then
        result:=lns^.SectionCount;
    end;
  end;
end;

function tINIFile.GetSectionList(ans:PAnsiChar):PAnsiChar;
var
  lns:pININamespace;
begin
  lns:=FindNamespace(ans);
  if lns<>nil then
    result:=lns^.GetSectionList()
  else
    result:=nil;
end;

function tINIFile.FindSection(ans,asection:PAnsiChar):pINISection;
var
  ns:pININamespace;
  p:PAnsiChar;
begin
  result:=nil;

  if (asection=nil) or (asection[0]=#0) then
    exit;

  if (flags and F_IGNORENS)=0 then
    p:=ans
  else
    p:=nil;
  ns:=FindNamespace(p);
  if ns<>nil then
    result:=ns^.FindSection(asection);
end;

function tINIFile.GetSection(ans,asection:PAnsiChar):pINISection;
var
  lns:pININamespace;
  p:PAnsiChar;
begin
  result:=nil;

  if (asection=nil) or (asection[0]=#0) then
    asection:=DefaultSectionName;

  if (flags and F_IGNORENS)=0 then
    p:=ans
  else
    p:=nil;
  lns:=GetNamespace(p);
  result:=lns^.GetSection(asection)
end;

function tINIFile.GetSection(asection:PAnsiChar):pINISection;
var
  p:PAnsiChar;
  buf:array [0..63] of AnsiChar;
begin
  if ((flags and F_IGNORENS)= 0) and
     ((flags and F_COMBOCHK)<>0) then
  begin
    p:=StrScan(asection,ns_separator);
    if p<>nil then
    begin
      // translate text buffer (ns must kept as is, not allocating)
      if (flags and F_BUFFER)<>0 then
      begin
        p^:=#0;
        result:=GetSection(asection,p+1);
      end
      else
      begin
        StrCopy(@buf,asection,p-asection);
        result:=GetSection(@buf,p+1);
      end;
      exit;
    end;
  end;
  result:=GetSection(nil,asection);
end;

function tINIFile.IsSection(aname:PAnsiChar):boolean;
begin
  result:=FindSection(nil,aname)<>nil;
end;

//===== Read/write parameters =====

function tINIFile.ReadBool(ans,asection,akey:PAnsiChar; adefault:boolean=false):boolean;
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    pc:=sn^.Key[akey];
    if pc<>nil then
    begin
      result:=(StrCmp(pc,'true')=0) or (StrToInt(pc)<>0);
      exit;
    end
  end;
  result:=adefault;
end;

procedure tINIFile.WriteBool(ans,asection,akey:PAnsiChar; avalue:boolean);
var
  sn:pINISection;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
  begin
    if (flags and F_SIMPLEBOOL)<>0 then
    begin
      if avalue then
        sn^.Key[akey]:='1'
      else
        sn^.Key[akey]:='0';
      exit;
    end;

    if avalue then
      sn^.Key[akey]:='true'
    else
      sn^.Key[akey]:='false';
  end;
end;

function tINIFile.ReadInt(ans,asection,akey:PAnsiChar; adefault:integer=0):integer;
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    pc:=sn^.Key[akey];
    if pc<>nil then
    begin
      result:=StrToInt(pc);
      exit;
    end
  end;
  result:=adefault;
end;

procedure tINIFile.WriteInt(ans,asection,akey:PAnsiChar; avalue:integer);
var
  sn:pINISection;
  buf:array [0..31] of AnsiChar;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
    sn^.Key[akey]:=IntToStr(buf,avalue);
end;

function tINIFile.ReadWide(ans,asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar;
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    pc:=sn^.Key[akey];
    if pc<>nil then
    begin
      UTF8ToWide(pc,result);
      exit;
    end
  end;
  StrDupW(result,adefault);
end;

procedure tINIFile.WriteWide(ans,asection,akey:PAnsiChar; avalue:PWideChar);
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
  begin
    WideToUTF8(avalue,pc);
    sn^.Key[akey]:=pc;
    mFreeMem(pc);
  end;
end;

function tINIFile.ReadStr(ans,asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar;
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    pc:=sn^.Key[akey];
    if pc<>nil then
    begin
      StrDup(result,pc); // or UTF8ToAnsi(pc,result)
      exit;
    end
  end;
  StrDup(result,adefault);
end;

procedure tINIFile.WriteStr(ans,asection,akey:PAnsiChar; avalue:PAnsiChar);
var
  sn:pINISection;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
    sn^.Key[akey]:=avalue;
end;

function tINIFile.ReadString(ans,asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString;
var
  sn:pINISection;
  pc:PAnsiChar;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    pc:=sn^.Key[akey];
    if pc<>nil then
    begin
      result:=pc; // or result:=system.UTF8ToAnsi(pc)
      exit;
    end
  end;
  result:=adefault
end;

procedure tINIFile.WriteString(ans,asection,akey:PAnsiChar; const avalue:AnsiString);
var
  sn:pINISection;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
    sn^.Key[akey]:=pointer(avalue);
end;

function tINIFile.ReadStruct(ans,asection,akey:PAnsiChar; buf:pointer=nil):pointer;
var
  sn:pINISection;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
  begin
    if buf=nil then
      StructDecode(result,sn^.Key[akey],true)
    else
    begin
      StructDecode(buf,sn^.Key[akey],false);
      result:=buf;
    end;
  end
  else
    result:=nil;
end;

procedure tINIFile.WriteStruct(ans,asection,akey:PAnsiChar; avalue:pointer; asize:cardinal);
var
  sn:pINISection;
  tmp:PAnsiChar;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
  begin
    StructEncode(tmp,avalue,asize);
    sn^.Key[akey]:=tmp;
    mFreeMem(tmp);
  end;
end;

//----- Set setting -----

procedure tINIFile.SetAsText(ans,asection,akey:PAnsiChar; aval:PAnsiChar);
var
  sn:pINISection;
begin
  sn:=GetSection(ans,asection);
  if sn<>nil then
    sn^.Key[akey]:=aval;
end;

procedure tINIFile.SetAsText(asection,akey:PAnsiChar; aval:PAnsiChar);
begin
  SetAsText(nil,asection,akey, aval);
end;

procedure tINIFile.SetAsText(akey:PAnsiChar; aval:PAnsiChar);
begin
  SetAsText(nil,nil,akey, aval);
end;

//----- Get setting -----

function tINIFile.GetAsText(ans,asection,akey:PAnsiChar):PAnsiChar;
var
  sn:pINISection;
begin
  sn:=FindSection(ans,asection);
  if sn<>nil then
    result:=sn^.Key[akey]
  else
    result:=nil;
end;

function tINIFile.GetAsText(asection,akey:PAnsiChar):PAnsiChar;
begin
  result:=GetAsText(nil,asection,akey);
end;

function tINIFile.GetAsText(akey:PAnsiChar):PAnsiChar;
begin
  result:=GetAsText(nil,nil,akey);
end;

//===== Text =====

//----- Reading from buffer -----

// quotes, multiline etc
// result = pointer to non-parameter line
// pointers: start of value, start of current line, end of value in line, end of current line
{
param= ;
param='' ;
param=text1\ ;
text2 ;
param=text1\\ ;
text2 ;
}
function ProcessParamValue(var start:PAnsiChar):PAnsiChar;
var
  lineend,eol,dst:PAnsiChar;
  multiline,crlf:boolean;
begin
  dst:=start;
  result:=start;

  repeat
    multiline:=false;
    crlf     :=false;
    // skip starting spaces
    while start^ in [#9,' '] do inc(start);

    if start^ in [#0,#10,#13] then // empty value or end
    begin
      while start^ in [#10,#13] do inc(start);
      break;
    end;

    lineend:=start;
    while not (lineend^ in [#0,#10,#13]) do inc(lineend);
    eol:=lineend;
    dec(lineend);
    while lineend^ in [#9,' '] do dec(lineend);

    // can't be first line of buffer, no need to check for buffer start
    if lineend^=line_separator then // multiline or part of value
    begin
      if (lineend-1)^ in [#9,' '] then // multiline
      begin
        dec(lineend);
        multiline:=true;
        while lineend^ in [#9,' '] do dec(lineend);
      end
      // double separator = multiline + crlf saving
      else if ((lineend-1)^=line_separator) and ((lineend-2)^ in [#9,' ']) then
      begin
        dec(lineend,2);
        multiline:=true;
        crlf     :=true;
        while lineend^ in [#9,' '] do dec(lineend);
      end;
    end;
    // lineend points to last char
    // start points to first char
    // eol points to end of line

    //!! now just starting/ending quotes
    if (start^ in ['''','"']) and (lineend^ = start^) then
    begin
      inc(start);
      dec(lineend);
    end;

    //!!
    while start<=lineend do
    begin
      dst^:=start^;
      inc(dst);
      inc(start);
    end;
    if crlf then
    begin
      dst^:=#13;
      inc(dst);
      dst^:=#10;
      inc(dst);
    end;
    start:=eol;
    while start^ in [#10,#13] do inc(start);

  until not multiline;
  dst^:=#0;
end;

procedure tINIFile.TranslateText(txt:PAnsiChar);
var
  pc1,pc,pend:PAnsiChar;
  lastsection:pINISection;
  len:integer;
  hascomment:boolean;
begin
  Clear;

  if (txt=nil) or (txt^=#0) then
    exit;

  flags:=flags or F_COMBOCHK;  //!!

  flags:=flags or F_BUFFER;
  StrDup(buffer,txt);

  hascomment:=false;

  pc:=buffer;
  lastsection:=nil;
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
      if (lastsection=nil) and (hascomment) then
      begin
        StrDup(FTopComment,buffer,pc-buffer);
      end;

      inc(pc);
      {}
      pc1:=pc;
      repeat
        len:=CharUTF8Len(pc);
        if (len=1) and (pc^ = ']') or (pc^ = #0) then
          break;
        inc(pc,len);
      until false;
      if pc^=#0 then break;
      {}
      pc^:=#0; //!!

      if lastsection<>nil then
        lastsection^.flags:=lastsection^.flags and not F_BUFFER;

      lastsection:=GetSection(pc1);
      if (flags and F_BUFFER)<>0 then
        lastsection^.flags:=lastsection^.flags or F_BUFFER;

      inc(pc);
    end

    //-- parameter (skip before first section)
    else if (pc^ in sWord) and (lastsection<>nil) then
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
          // parameter can be quoted
          // here need to cut spaces, comments but join next lines
          pend^:=#0;
          // can be replaced by section name using, not pinisection
          // but no reason coz needs to set/clear F_BUFFER flag
          lastsection^.Key[pc1]:=ProcessParamValue(pc);
        end
        else
          while not (pc^ in [#0,#10,#13]) do inc(pc);
      end;
    end

    //-- wrong thing, skip line
    else
      while not (pc^ in [#0,#10,#13]) do inc(pc);
  end;

  if lastsection<>nil then
    lastsection^.flags:=lastsection^.flags and not F_BUFFER;

  flags:=flags and not F_BUFFER;
end;

function tINIFile.PrepareText():PAnsiChar;
var
  ns:pININamespace;
  sn:pINISection;
{$IFDEF UseStrings}
  s:AnsiString;
{$ELSE}
  pp:PAnsiChar;
  sum:cardinal;
{$ENDIF}
begin
  ns:=FNamespaces;
  mFreeMem(outtext);
{$IFDEF UseStrings}
  if TopComment<>nil then
    s:=AnsiString(TopComment)
  else
    s:='';
  while ns<>nil do
  begin

    sn:=ns^.FirstSection;
    while (sn<>nil) do
    begin
      s := s + '[' + IIF(ns^.Name<>nil,ns^.Name + ns_separator, '') + sn^.Name + ']'#13#10;
      s := s + sn^.SectionText + #13#10;

      sn:=ns^.NextSection;
    end;
    
    ns:=ns^.Next;
  end;
  StrDup(outtext,pointer(s));
{$ELSE}
  sum:=StrLen(TopComment)+1;
  while ns<>nil do
  begin

    sn:=ns^.FirstSection;
    while (sn<>nil) do
    begin
      inc(sum,StrLen(ns^.Name)+1+StrLen(sn^.Name)+2+2+2);
      inc(sum,StrLen(sn^.SectionText)+2);

      sn:=ns^.NextSection;
    end;
    
    ns:=ns^.Next;
  end;
  mGetMem(outtext,sum);

  pp:=StrCopyE(outtext,TopComment);

  ns:=FNamespaces;
  while ns<>nil do
  begin

    sn:=ns^.FirstSection;
    while (sn<>nil) do
    begin
      // Section name
      if pp<>outtext then
      begin
        pp^:=#13; inc(pp); pp^:=#10; inc(pp);
      end;

      pp^:='['; inc(pp);
      if ns^.Name<>nil then
      begin
        pp:=StrCopyE(pp,ns^.Name);
        pp^:=ns_separator; inc(pp);
      end;
      pp:=StrCopyE(pp,sn^.Name);
      pp^:=']'; inc(pp);
      pp^:=#13; inc(pp); pp^:=#10; inc(pp);
      pp:=StrCopyE(pp,sn^.SectionText);

      sn:=ns^.NextSection;
    end;
    
    ns:=ns^.Next;
  end;
  pp^:=#0;
{$ENDIF}
  result:=outtext;
end;

//----- Main methods -----

{
procedure tINIFile.Combine;
begin
end;

procedure tINIFile.Split;
begin
end;

procedure tINIFile.QueueToArray;
begin
end;

procedure tINIFile.ArrayToQueue;
begin
end;
}
{
procedure tINIFile.EnumSections();
var
  lns:pININamespace;
  lsect:pINISection;
begin
  lns:=FNamespaces;
  while lns<>nil do
  begin
    lsect:=lns^.FSections;
    while lsect<>nil do
    begin

      lsect:=lsect^.next;
    end;
    lns:=lns^.next;
  end;
end;
}
procedure tINIFile.SetINIOptions(const opt:tINIOptions);
begin
{
  if [USENAMESPACE] in opt then
  begin
    if not [USENAMESPACE] in FOptions then
      Split;
  end
  else
  begin
    if [USENAMESPACE] in FOptions then
      Combine;
  end;

  if [LOTOFSECTIONS] in opt then
  begin
    if not [LOTOFSECTIONS] in FOptions then
      QueueToArray;
  end
  else
  begin
    if [LOTOFSECTIONS] in FOptions then
      ArrayToQueue;
  end;
}
{
  if [] in opt then
  begin
    if not [] in FOptions then
  end
  else
  begin
    if [] in FOptions then
  end;
}
end;

procedure tINIFile.Clear;
var
  pns,ns:pININamespace;
begin
  // cycle by sections
  ns:=FNamespaces;
  while ns<>nil do
  begin
    pns:=ns;
    ns:=ns^.next;
    pns^.Delete;
    Dispose(pns);
  end;
  Fnamespaces:=nil;

  mFreeMem(FNSList);

  mFreeMem(buffer);
  mFreeMem(outtext);

  mFreeMem(FTopComment);

  flags:=flags or F_CHANGED;
end;

procedure tINIFile.Free;
begin
  Clear;
  mFreeMem(ffilename);
end;

//----- File operations -----

type
  tmifile = file of byte;

function tINIFile.FlushFile(var f):boolean;
var
  p:PAnsiChar;
  llen:integer;
begin
  result:=false;
  p:=Text;
  llen:=StrLen(p);
  if llen>0 then
  begin
{$IFOPT I-}
    Rewrite(tmifile(f));
    if IOResult()=0 then
    begin
{$ELSE}
    try
      Rewrite(tmifile(f));
{$ENDIF}
      BlockWrite(tmifile(f),p^,llen);
      CloseFile(tmifile(f));
      result:=true;
{$IFOPT I-}
{$ELSE}
    except
{$ENDIF}
    end;
  end;
end;

function tINIFile.Flush(const afname:PAnsiChar=nil):boolean;
var
  f:tmifile;
begin
  if afname=nil then
  begin
    if ffilename=nil then
    begin
      result:=false;
      exit;
    end;
  end
  else
  begin
    if StrCmp(ffilename,afname)<>0 then
    begin
      mFreeMem(ffilename);
      StrDup(ffilename,afname);
      flags:=flags or F_FLUSH;
    end;
  end;

  AssignFile(f,ffilename);
  result:=FlushFile(f);
end;

function tINIFile.Flush(const afname:AnsiString):boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=Flush(PAnsiChar(pointer(afname)));
end;

function tINIFile.Flush(const afname:PWideChar):boolean;
var
  f:tmifile;
begin
  if afname=nil then
  begin
    if ffilename=nil then
    begin
      result:=false;
      exit;
    end;
  end;
  AssignFile(f,afname);
  result:=FlushFile(f);
end;

{$ENDIF}
