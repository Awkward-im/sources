{
}
{$IFDEF Interface}

type
  pCfgBase = ^tCfgBase;
  tCFGBase = object
  private
    FComment:PAnsiChar;
    FNSList :PAnsiChar;

    arNamespaces:array of tNamespace;
    numnamespace:cardinal;
    CurNamespace:integer;

    FOptions:tCfgOptions;

    FOnChange:tCfgEvent;

    procedure Release;

    //--- Options ---

    procedure SetOptions(const opt:tCfgOptions);

    //--- Comment ---

    procedure SetComment(acomment:PAnsiChar);

    //--- Namespace ---

    function AddNamespace (aname:PAnsiChar):pNamespace;
    function FindNamespace(aname:PAnsiChar):pNamespace;
    function GetNamespace (aname:PAnsiChar):pNamespace;

    function GetNamespaceCount():integer;
    function GetNamespaceList ():PAnsiChar;

    function FirstNamespace():pNamespace;
    function NextNamespace ():pNamespace;

    //--- Section ---

    function FindSection(ans,asection:PAnsiChar):pSection; overload;
//    function FindSection(    asection:PAnsiChar):pSection; overload;
    function GetSection (ans,asection:PAnsiChar):pSection; overload;
    function GetSection (    asection:PAnsiChar):pSection; overload;

    function GetSectionCount(ans:PAnsiChar):integer;
    function GetSectionList (ans:PAnsiChar):PAnsiChar;

    //--- Parameter ---

    function FindParameter(ans,asection,aname:PAnsiChar):pParameter;
    function GetParameter (ans,asection,aname:PAnsiChar):pParameter;

    function GetParameterCount(ans,asection:PAnsiChar):integer;
    function GetParameterList (ans,asection:PAnsiChar):PAnsiChar;

    //--- Value ---

    function ReadStrBufInt(apar:pParameter; abuf:PAnsiChar; abufsize:integer):integer;
    function GetParameterType(ans,asection,akey:PAnsiChar):AnsiChar;

    procedure SetAsText(             akey:PAnsiChar; avalue:PAnsiChar); overload;
    procedure SetAsText(    asection,akey:PAnsiChar; avalue:PAnsiChar); overload;
    procedure SetAsText(ans,asection,akey:PAnsiChar; avalue:PAnsiChar); overload;

    function  GetAsText(             akey:PAnsiChar):PAnsiChar; overload;
    function  GetAsText(    asection,akey:PAnsiChar):PAnsiChar; overload;
    function  GetAsText(ans,asection,akey:PAnsiChar):PAnsiChar; overload;

  public
    property Namespace[ans:PAnsiChar]:pNamespace read GetNamespace;
    property Section  [ans:PAnsiChar; asection:PAnsiChar]:pSection read GetSection;
    property Parameter[ans:PAnsiChar; asection:PAnsiChar;
                    aname: PAnsiChar]:pParameter read GetParameter;

  public
    procedure Clear;
    procedure Free;

    //--- Namespace ---

    function  IsNamespace    (aname:PAnsiChar):boolean;
    procedure DeleteNamespace(aname:PAnsiChar);
    procedure RenameNamespace(aname,anew:PAnsiChar);
    procedure CopyNamespace  (aname,anew:PAnsiChar);

    //--- Section ---

//    function  IsSection    (    aname:PAnsiChar):boolean; overload;
    function  IsSection    (ans,aname:PAnsiChar):boolean; overload;
    procedure DeleteSection(ans,aname:PAnsiChar);
    procedure RenameSection(ans,aname,anew:PAnsiChar);
    procedure CopySection  (ans,aname,anew:PAnsiChar);

    //--- Read/write data ---

    procedure AssignComment(avalue:PAnsiChar);

    function  ReadBool     (ans,asection,akey:PAnsiChar; adefault:boolean=false):boolean; overload;
    function  ReadBool     (    asection,akey:PAnsiChar; adefault:boolean=false):boolean; overload;
    procedure WriteBool    (ans,asection,akey:PAnsiChar; avalue  :boolean); overload;
    procedure WriteBool    (    asection,akey:PAnsiChar; avalue  :boolean); overload;
    function  ReadInt      (ans,asection,akey:PAnsiChar; adefault:IntPtr=0):IntPtr; overload;
    function  ReadInt      (    asection,akey:PAnsiChar; adefault:IntPtr=0):IntPtr; overload;
    procedure WriteInt     (ans,asection,akey:PAnsiChar; avalue  :IntPtr); overload;
    procedure WriteInt     (    asection,akey:PAnsiChar; avalue  :IntPtr); overload;
    function  ReadFloat    (ans,asection,akey:PAnsiChar; adefault:Double=0):Double; overload;
    function  ReadFloat    (    asection,akey:PAnsiChar; adefault:Double=0):Double; overload;
    procedure WriteFloat   (ans,asection,akey:PAnsiChar; avalue  :Double); overload;
    procedure WriteFloat   (    asection,akey:PAnsiChar; avalue  :Double); overload;
    function  ReadDateTime (ans,asection,akey:PAnsiChar; adefault:TDateTime=0):TDateTime; overload;
    function  ReadDateTime (    asection,akey:PAnsiChar; adefault:TDateTime=0):TDateTime; overload;
    procedure WriteDateTime(ans,asection,akey:PAnsiChar; avalue  :TDateTime); overload;
    procedure WriteDateTime(    asection,akey:PAnsiChar; avalue  :TDateTime); overload;

    function  ReadWide     (ans,asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar; overload;
    function  ReadWide     (    asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar; overload;
    procedure WriteWide    (ans,asection,akey:PAnsiChar; avalue  :PWideChar); overload;
    procedure WriteWide    (    asection,akey:PAnsiChar; avalue  :PWideChar); overload;
    function  ReadStrBuf   (ans,asection,akey:PAnsiChar; abuf    :PAnsiChar; abufsize:integer):integer;
    function  ReadStr      (ans,asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar; overload;
    function  ReadStr      (    asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar; overload;
    procedure WriteStr     (ans,asection,akey:PAnsiChar; avalue  :PAnsiChar); overload;
    procedure WriteStr     (    asection,akey:PAnsiChar; avalue  :PAnsiChar); overload;
    procedure AssignStr    (ans,asection,akey:PAnsiChar; avalue  :PAnsiChar); overload;
    procedure AssignStr    (    asection,akey:PAnsiChar; avalue  :PAnsiChar); overload;
    function  ReadString   (ans,asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString; overload;
    function  ReadString   (    asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString; overload;
    procedure WriteString  (ans,asection,akey:PAnsiChar; const avalue  :AnsiString); overload;
    procedure WriteString  (    asection,akey:PAnsiChar; const avalue  :AnsiString); overload;

    function  ReadPointer  (ans,asection,akey:PAnsiChar):pointer; overload;
    function  ReadPointer  (    asection,akey:PAnsiChar):pointer; overload;
    procedure WritePointer (ans,asection,akey:PAnsiChar; avalue:pointer); overload;
    procedure WritePointer (    asection,akey:PAnsiChar; avalue:pointer); overload;

    function  ReadBinary   (ans,asection,akey:PAnsiChar; buf:pointer=nil):pointer; overload;
    function  ReadBinary   (    asection,akey:PAnsiChar; buf:pointer=nil):pointer; overload;
    procedure WriteBinary  (ans,asection,akey:PAnsiChar; avalue:pointer; asize:cardinal); overload;
    procedure WriteBinary  (    asection,akey:PAnsiChar; avalue:pointer; asize:cardinal); overload;

    //--- properties ---

    property Options:tCfgOptions read FOptions write SetOptions;

    property OnChange:tCfgEvent read FOnChange write FOnChange;

    property Comment:PAnsiChar read FComment write SetComment;

    property NamespaceList :PAnsiChar read GetNamespaceList;
    property NamespaceCount:integer   read GetNamespaceCount;

    property SectionList [ans:PAnsiChar]:PAnsiChar read GetSectionList;
    property SectionCount[ans:PAnsiChar]:integer   read GetSectionCount;

    property ParameterList [ans,asection:PAnsiChar]:PAnsiChar read GetParameterList;
    property ParameterCount[ans,asection:PAnsiChar]:integer   read GetParameterCount;

    property ParameterType[ans,asection,akey:PAnsiChar]: AnsiChar read GetParameterType;
    property Value        [ans,asection,akey:PAnsiChar]:PAnsiChar read GetAsText write SetAsText; default;
  end;

{$ELSE}

//----- Support -----

procedure TCfgBase.AssignComment(avalue:PAnsiChar);
begin
  mFreeMem(FComment);
  FComment:=avalue;

  if Assigned(OnChange) then
    OnChange(nil,nil,nil,cldComment+cldChange);
end;

procedure TCfgBase.SetComment(acomment:PAnsiChar);
begin
  mFreeMem(FComment);
  StrDup  (FComment,acomment);

  if Assigned(OnChange) then
    OnChange(nil,nil,nil,cldComment+cldChange);
end;

//----- Namespace navigation -----

function tCfgBase.FirstNamespace():pNamespace;
begin
  if numnamespace<=0 then
  begin
    result:=nil;
    exit;
  end;
  result:=@arNamespaces[0];
  CurNamespace:=0;
end;

function tCfgBase.NextNamespace():pNamespace;
begin
  inc(CurNamespace);

  while (CurNamespace<numnamespace) and (arNamespaces[CurNamespace].NotUsed) do
    inc(CurNamespace);

  if CurNamespace>=numnamespace then
    result:=nil
  else
    result:=@arNamespaces[CurNamespace];
end;

//----- Namespace -----

function TCfgBase.FindNamespace(aname:PAnsiChar):pNamespace;
var
  ns:pNamespace;
  b:boolean;
begin
  ns:=FirstNamespace;
  if (aname<>nil) and (aname^<>#0) then
  begin
    ns:=NextNamespace;

    while (ns<>nil) do
    begin
      if CFG_CASESENSITIVE in FOptions then
        b:=StrCmp (ns^.Name,aname)=0
      else
        b:=StrCmpI(ns^.Name,aname)=0;
      if b then break;

      ns:=NextNamespace;
    end;
  end;
  result:=ns;
end;

function TCfgBase.AddNamespace(aname:PAnsiChar):pNamespace;
var
  i:integer;
begin
  result:=nil;

  for i:=1 to numnamespace-1 do
  begin
    if arNamespaces[i].NotUsed then
    begin
      result:=@arNamespaces[i];
      break;
    end;
  end;

  if result=nil then
  begin
    if numnamespace>High(arNamespaces) then
      SetLength(arNamespaces,Length(arNamespaces)+increment);

    result:=@arNamespaces[numnamespace];
    inc(numnamespace);
  end;

  result^.Init(aname);
  if Assigned(OnChange) then
    OnChange(aname,nil,nil,cldNamespace+cldCreate);
end;

function TCfgBase.GetNamespace(aname:PAnsiChar):pNamespace;
begin
  result:=FindNamespace(aname);
  if result=nil then
    result:=AddNamespace(aname);
end;

function TCfgBase.IsNamespace(aname:PAnsiChar):boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=FindNamespace(aname)<>nil;
end;

procedure TCfgBase.DeleteNamespace(aname:PAnsiChar);
var
  lptr:pNamespace;
begin
  lptr:=FindNamespace(aname);
  if lptr<>nil then
  begin
    lptr^.Delete;
    if Assigned(OnChange) then
      OnChange(aname,nil,nil,cldNamespace+cldDelete);
  end;
end;

procedure TCfgBase.RenameNamespace(aname,anew:PAnsiChar);
var
  lptr,lptrnew:pNamespace;
begin
  lptr:=FindNamespace(aname);
  if lptr<>nil then
  begin
    lptrnew:=FindNamespace(anew);
    if lptrnew=nil then
    begin
      lptr^.Rename(anew);
      if Assigned(OnChange) then
        OnChange(aname,nil,nil,cldNamespace+cldRename);
    end;
  end;
end;

procedure TCfgBase.CopyNamespace(aname,anew:PAnsiChar);
var
  lptr,lptrnew:pNamespace;
begin
  lptr:=FindNamespace(aname);
  if lptr<>nil then
  begin
    lptrnew:=GetNamespace(anew);
    lptr^.CopyTo(lptrnew,FOptions);
  end;
end;

function TCfgBase.GetNamespaceCount():integer;
var
  lns:pNamespace;
begin
  result:=0;
  if CFG_USENAMESPACE in FOptions then
  begin
    lns:=FirstNamespace;
    while lns<>nil do
    begin
      if lns^.Name^>#31 then
        inc(result);
      lns:=NextNamespace;
    end;
  end;
end;

function TCfgBase.GetNamespaceList():PAnsiChar;
var
  pc:PAnsiChar;
  lns:pNamespace;
  lsize:cardinal;
begin
  if not (CFG_USENAMESPACE in FOptions) then
  begin
    result:=nil;
    exit;
  end;

  mFreeMem(FNSList);
  
  lsize:=0;
  FirstNamespace; // skip default
  lns:=NextNamespace;
  while lns<>nil do
  begin
    if lns^.Name>#31 then
      inc(lsize,StrLen(lns^.Name)+1);
    lns:=NextNamespace;
  end;

  mGetMem(pc,lsize+1);
  FNSList:=pc;
  if lsize>0 then
  begin
    FirstNamespace; // skip default
    lns:=NextNamespace;
    while lns<>nil do
    begin
      if lns^.Name>#31 then
      begin
        pc:=StrCopyE(pc,lns^.Name);
        inc(pc);
      end;
      lns:=NextNamespace;
    end;
  end;
  pc^:=#0;

  result:=FNSList;
end;

//----- Sections -----

function TCfgBase.GetSectionCount(ans:PAnsiChar):integer;
var
  lns:pNamespace;
begin
  result:=0;

  if (ans=nil) or (ans^=#0) then
  begin
    result:=arNamespaces[0].GetSectionCount()
  end
  else
  begin
    if CFG_USENAMESPACE in FOptions then
    begin
      lns:=FindNamespace(ans);
      if lns<>nil then
        result:=lns^.GetSectionCount();
    end;
  end;
end;

function TCfgBase.GetSectionList(ans:PAnsiChar):PAnsiChar;
var
  lns:pNamespace;
begin
  lns:=FindNamespace(ans);
  if lns<>nil then
    result:=lns^.GetSectionList()
  else
    result:=nil;
end;

function TCfgBase.FindSection(ans,asection:PAnsiChar):pSection;
var
  lns:pNamespace;
  p:PAnsiChar;
begin
  result:=nil;
{
  if (asection=nil) or (asection[0]=#0) then
    exit;
}
  if CFG_USENAMESPACE in FOptions then
    p:=ans
  else
    p:=nil;
  lns:=FindNamespace(p);
  if lns<>nil then
    result:=lns^.FindSection(asection,(CFG_CASESENSITIVE in FOptions));
end;
{
function TCfgBase.FindSection(asection:PAnsiChar):pSection;
var
  p:PAnsiChar;
  buf:array [0..63] of AnsiChar;
begin
  if (CFG_USENAMESPACE in FOptions) and
     (CFG_CHECKCOMBO   in FOptions) then
  begin
    p:=StrScan(asection,ns_separator);
    if p<>nil then
    begin
      StrCopy(@buf,asection,p-asection);
      result:=FindSection(@buf,p+1);
      exit;
    end;
  end;
  result:=FindSection(nil,asection);
end;
}
function TCfgBase.GetSection(ans,asection:PAnsiChar):pSection;
var
  lns:pNamespace;
  p:PAnsiChar;
begin

  if ((ans<>nil) and (ans^<>#0)) and
    ((asection=nil) or (asection[0]=#0)) then
    asection:=DefaultSectionName;

  if CFG_USENAMESPACE in FOptions then
    p:=ans
  else
    p:=nil;

  if Assigned(OnChange) then
    result:=FindSection(p,asection)
  else
    result:=nil;

  if result=nil then
  begin
    lns:=GetNamespace(p);
    result:=lns^.GetSection(asection,(CFG_CASESENSITIVE in FOptions));

    if Assigned(OnChange) then
      OnChange(p,asection,nil,cldSection+cldCreate);
  end;
end;

function TCfgBase.GetSection(asection:PAnsiChar):pSection;
var
  p:PAnsiChar;
  buf:array [0..63] of AnsiChar;
begin
  if (CFG_USENAMESPACE in FOptions) and
     (CFG_CHECKCOMBO   in FOptions) then
  begin
    p:=StrScan(asection,ns_separator);
    if p<>nil then
    begin
      StrCopy(@buf,asection,p-asection);
      result:=GetSection(@buf,p+1);
      exit;
    end;
  end;
  result:=GetSection(nil,asection);
end;

function TCfgBase.IsSection(ans,aname:PAnsiChar):boolean;
begin
  result:=FindSection(ans,aname)<>nil;
end;
{
function TCfgBase.IsSection(aname:PAnsiChar):boolean;
begin
  result:=FindSection(aname)<>nil;
end;
}
procedure TCfgBase.DeleteSection(ans,aname:PAnsiChar);
var
  lns:pNamespace;
begin
  lns:=FindNamespace(ans);
  if lns<>nil then
    if lns^.DeleteSection(aname,(CFG_CASESENSITIVE in FOptions)) then
    begin
      if Assigned(OnChange) then
        OnChange(ans,aname,nil,cldSection+cldDelete);
    end;
end;

procedure TCfgBase.RenameSection(ans,aname,anew:PAnsiChar);
var
  lns:pNamespace;
begin
  lns:=FindNamespace(ans);
  if lns<>nil then
    if lns^.RenameSection(aname,anew,(CFG_CASESENSITIVE in FOptions)) then
    begin
      if Assigned(OnChange) then
        OnChange(ans,aname,nil,cldSection+cldRename);
    end;
end;

procedure TCfgBase.CopySection(ans,aname,anew:PAnsiChar);
var
  lns:pNamespace;
begin
  lns:=FindNamespace(ans);
  if lns<>nil then
    lns^.CopySection(aname,anew,FOptions);
end;

//----- Parameters -----

function TCfgBase.FindParameter(ans,asection,aname:PAnsiChar):pParameter;
var
  lsn:pSection;
begin
  result:=nil;

  if //(asection=nil) or (asection[0]=#0) or
     (aname   =nil) or (aname   [0]=#0) then
    exit;

  lsn:=FindSection(ans,asection);
  if lsn<>nil then
  begin
    result:=lsn^.FindParameter(aname,(CFG_CASESENSITIVE in FOptions));
  end;
end;

function TCfgBase.GetParameter(ans,asection,aname:PAnsiChar):pParameter;
var
  lsn:pSection;
begin
  if (aname=nil) or (aname[0]=#0) then
    aname:=DefaultParamName;

  lsn:=GetSection(ans,asection);
  result:=lsn^.GetParameter(aname,(CFG_CASESENSITIVE in FOptions));
end;

function TCfgBase.GetParameterCount(ans,asection:PAnsiChar):integer;
var
  lsn:pSection;
begin
  lsn:=FindSection(ans,asection);
  if lsn<>nil then
    result:=lsn^.GetParameterCount(CFG_KEEPEMPTY in FOptions)
  else
    result:=0;
end;

function TCfgBase.GetParameterList(ans,asection:PAnsiChar):PAnsiChar;
var
  lsn:pSection;
begin
  lsn:=FindSection(ans,asection);
  if lsn<>nil then
    result:=lsn^.GetParameterList(CFG_KEEPEMPTY in FOptions)
  else
    result:=nil;
end;

function TCfgBase.GetParameterType(ans,asection,akey:PAnsiChar):AnsiChar;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if lpar=nil then
    result:='n'
  else
    result:=lpar^._Type;
end;

//===== Read/write parameters =====

//----- Set setting -----

procedure TCfgBase.SetAsText(ans,asection,akey:PAnsiChar; avalue:PAnsiChar);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsText:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtText);
end;

procedure TCfgBase.SetAsText(asection,akey:PAnsiChar; avalue:PAnsiChar);
{
var
  lsn:pSection;
begin
  lsn:=GetSection(asection);
  if lsn<>nil then
  begin
    lsn^.GetParameter(akey,(CFG_CASESENSITIVE in FOptions))^.AsText:=aval;

    if Assigned(OnChange) then
      OnChange(ans,asection,akey,cldParameter+cldtText);
  end;
}
begin
  SetAsText(nil,asection,akey, avalue);
end;

procedure TCfgBase.SetAsText(akey:PAnsiChar; avalue:PAnsiChar);
begin
  SetAsText(nil,akey, avalue);
end;

//----- Get setting -----

function TCfgBase.GetAsText(ans,asection,akey:PAnsiChar):PAnsiChar;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=nil
  else
    result:=lpar^.AsText;
end;

function TCfgBase.GetAsText(asection,akey:PAnsiChar):PAnsiChar;
{
var
  lsn:pSection;
begin
  lsn:=FindSection(asection);
  if lsn<>nil then
  begin
    result:=lsn^.GetParameter(akey,(CFG_CASESENSITIVE in FOptions))^.AsText;
  end
  else
    result:=nil;
}
begin
  result:=GetAsText(nil,asection,akey);
end;

function TCfgBase.GetAsText(akey:PAnsiChar):PAnsiChar;
begin
  result:=GetAsText(nil,akey);
end;


//----- Read/write data -----

function TCfgBase.ReadBool(ans,asection,akey:PAnsiChar; adefault:boolean=false):boolean;
var
  lpar:pParameter;
  p:PAnsiChar;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=adefault
  else
    case lpar^._Type of
      'a': begin
        p:=lpar^.AsText;
        result:=(StrCmpI(p,'true')=0) or (StrToInt(p)<>0);
      end;
      'b': result:=true; // (value.data<>nil) and (value.size>0);
      'd': result:=lpar^.AsDateTime<>0;
      'f': result:=lpar^.AsFloat<>0;
      'i': result:=lpar^.AsInteger<>0;
      'l': result:=lpar^.AsBoolean;
    else
      result:=adefault;
    end;
end;
function TCfgBase.ReadBool(asection,akey:PAnsiChar; adefault:boolean=false):boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadBool(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteBool(ans,asection,akey:PAnsiChar; avalue:boolean);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsBoolean:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtBoolean);
end;

procedure TCfgBase.WriteBool(asection,akey:PAnsiChar; avalue:boolean); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteBool(nil,asection,akey,avalue);
end;

function TCfgBase.ReadInt(ans,asection,akey:PAnsiChar; adefault:IntPtr=0):IntPtr;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=adefault
  else
    case lpar^._Type of
      'a': result:=NumToInt(lpar^.AsText);
      'b': result:=lpar^.AsInteger;
      'f': result:=Round(lpar^.AsFloat);
      'i': result:=lpar^.AsInteger;
      'l': if lpar^.AsBoolean then result:=1 else result:=0;
      'p': result:=IntPtr(lpar^.AsPointer);
    else
      result:=adefault;
    end;
end;

function TCfgBase.ReadInt(asection,akey:PAnsiChar; adefault:IntPtr=0):IntPtr; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadInt(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteInt(ans,asection,akey:PAnsiChar; avalue:IntPtr);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsInteger:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtInteger);
end;

procedure TCfgBase.WriteInt(asection,akey:PAnsiChar; avalue:IntPtr); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteInt(nil,asection,akey,avalue);
end;

function TCfgBase.ReadFloat(ans,asection,akey:PAnsiChar; adefault:Double=0):Double;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=adefault
  else
    case lpar^._Type of
      'a': {$IFNDEF UseSysUtils}result:=0;{$ELSE}TryStrToFloat(lpar^.AsText,result);{$ENDIF}
      'd': result:=lpar^.AsDateTime;
      'f': result:=lpar^.AsFloat;
      'i': result:=lpar^.AsInteger;
      'l': if lpar^.AsBoolean then result:=1 else result:=0;
    else
      result:=adefault;
    end;
end;

function TCfgBase.ReadFloat(asection,akey:PAnsiChar; adefault:Double=0):Double; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadFloat(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteFloat(ans,asection,akey:PAnsiChar; avalue:Double);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsFloat:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtFloat);
end;

procedure TCfgBase.WriteFloat(asection,akey:PAnsiChar; avalue:Double); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteFloat(nil,asection,akey,avalue);
end;

function TCfgBase.ReadDateTime(ans,asection,akey:PAnsiChar; adefault:TDateTime=0):TDateTime;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=adefault
  else
    case lpar^._Type of
      'a': {$IFNDEF UseSysUtils}result:=0;{$ELSE}TryStrToDateTime(lpar^.AsText,result);{$ENDIF}
      'd': result:=lpar^.AsDateTime;
      'f': result:=lpar^.AsFloat;
      'i': result:=lpar^.AsInteger;
    else
      result:=adefault;
    end;
end;

function TCfgBase.ReadDateTime(asection,akey:PAnsiChar; adefault:TDateTime=0):TDateTime; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadDateTime(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteDateTime(ans,asection,akey:PAnsiChar; avalue:TDateTime);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsDateTime:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtDateTime);
end;

procedure TCfgBase.WriteDateTime(asection,akey:PAnsiChar; avalue:TDateTime); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteDateTime(nil,asection,akey,avalue);
end;

//--- Text

// Separate function to avoid hidden code for AnsiStrings
function GetFloatWide(const avalue:Double):PWideChar;
var
  ls:AnsiString;
begin
  Str(avalue:0:decimals,ls);
  FastAnsiToWide(pointer(ls),result);
end;

// Same case, hidden AnsiString code
{$IFDEF UseSysUtils}
function GetDateTimeToWide(const avalue:TDateTime):PWideChar;
begin
  FastAnsiToWide(pointer(DateTimeToStr(avalue)),result);
end;
{$ENDIF}

function TCfgBase.ReadWide(ans,asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar;
var
  lpar:pParameter;
  buf:array [0..63] of WideChar;
  p:pAnsiChar;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=StrDupW(result,adefault)
  else
    case lpar^._Type of
      'a': UTF8ToWide(lpar^.AsText,result);
      'b': begin
        mGetMem(p,lpar^.AsInteger*2+1);
        BinaryEncode(p,lpar^.ReadBinary(nil),lpar^.AsInteger);
        FastAnsiToWide(p,result);
        mFreeMem(p);
      end;
{$IFDEF UseSysUtils}
      'd': result:=GetDateTimeToWide(lpar^.AsDateTime);
{$ENDIF}
      'f': result:=GetFloatWide(lpar^.AsFloat);
      'i': begin
        IntToStr(buf,lpar^.AsInteger);
        StrDupW(result,@buf);
      end;
      'l': begin
        if not (CFG_COMPLEXBOOL in FOptions) then
        begin
          if lpar^.AsBoolean then buf[0]:='1' else buf[0]:='0';
          buf[1]:=#0;
        end
        else
        begin
          if lpar^.AsBoolean then StrCopyW(buf,'true') else StrCopyW(buf,'false');
        end;
        StrDupW(result,@buf);
      end;
    else
      StrDupW(result,adefault);
    end;
end;

function TCfgBase.ReadWide(asection,akey:PAnsiChar; adefault:PWideChar=nil):PWideChar; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadWide(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteWide(ans,asection,akey:PAnsiChar; avalue:PWideChar);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.WriteWide(avalue);

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtUnicode{cldtText});
end;

procedure TCfgBase.WriteWide(asection,akey:PAnsiChar; avalue:PWideChar); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteWide(nil,asection,akey,avalue);
end;

// Separate function to avoid hidden code for AnsiStrings
function GetFloatStr(abuf:PAnsiChar; const avalue:Double):PAnsiChar;
var
  ls:AnsiString;
begin
  Str(avalue:0:decimals,ls);
  StrCopy(abuf,pointer(ls));
  result:=abuf;
end;

// Same case, hidden AnsiString code
{$IFDEF UseSysUtils}
function GetDateTimeToStr(abuf:PAnsiChar; const avalue:TDateTime):PAnsiChar;
begin
  StrCopy(abuf,pointer(DateTimeToStr(avalue)));
  result:=abuf;
end;
{$ENDIF}

function TCfgBase.ReadStrBufInt(apar:pParameter; abuf:PAnsiChar; abufsize:integer):integer;
begin
  if (apar<>nil) and not (apar^.IsEmpty) then
  begin
    case apar^._Type of
      'a': result:=StrLen(apar^.AsText)+1;
      'b': result:=apar^.AsInteger*2+1;
    else
      result:=32; // even much more than needs (no month names - 24 is enough)
    end;
    if abufsize<result then exit;

    case apar^._Type of
      'a': StrCopy(abuf,apar^.AsText);
      'b': BinaryEncode(abuf,apar^.ReadBinary(nil),apar^.AsInteger);
{$IFDEF UseSysUtils}
      'd': GetDateTimeToStr(abuf,apar^.AsDateTime);
{$ENDIF}
      'f': GetFloatStr(abuf,apar^.AsFloat);
      'i': IntToStr(abuf,apar^.AsInteger);
      'l': begin
        if not (CFG_COMPLEXBOOL in FOptions) then
        begin
          if apar^.AsBoolean then abuf[0]:='1' else abuf[0]:='0';
          abuf[1]:=#0;
        end
        else
        begin
          if apar^.AsBoolean then StrCopy(abuf,'true') else StrCopy(abuf,'false');
        end;
      end;
      'p': begin
        abuf[0]:='0'; abuf[1]:='x';
        IntToHex(@abuf[2],UIntPtr(apar^.AsPointer));
      end;
    else
    end;
  end;
  result:=0;
end;

function TCfgBase.ReadStrBuf(ans,asection,akey:PAnsiChar;
                             abuf:PAnsiChar; abufsize:integer):integer;
                             {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadStrBufInt(FindParameter(ans,asection,akey),abuf,abufsize);
end;

function TCfgBase.ReadStr(ans,asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar;
var
  lpar:pParameter;
  buf:array [0..511] of AnsiChar;
  llen:integer;
begin
  lpar:=FindParameter(ans,asection,akey);

  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=StrDup(result,adefault)
  else
  begin
    llen:=ReadStrBufInt(lpar,buf,Length(buf));
    if llen=0 then
      StrDup(result,buf)
    else
    begin
      mGetMem(result,llen);
      ReadStrBufInt(lpar,result,llen);
    end;
  end;
end;

function TCfgBase.ReadStr(asection,akey:PAnsiChar; adefault:PAnsiChar=nil):PAnsiChar; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadStr(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteStr(ans,asection,akey:PAnsiChar; avalue:PAnsiChar);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsText:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtText);
end;

procedure TCfgBase.WriteStr(asection,akey:PAnsiChar; avalue:PAnsiChar); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteStr(nil,asection,akey,avalue);
end;

procedure TCfgBase.AssignStr(ans,asection,akey:PAnsiChar; avalue:PAnsiChar);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AssignStr(avalue);

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtText);
end;

procedure TCfgBase.AssignStr(asection,akey:PAnsiChar; avalue:PAnsiChar); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  AssignStr(nil,asection,akey,avalue);
end;

function TCfgBase.ReadString(ans,asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString;
var
  lbuf:array [0..63] of AnsiChar;
  lpar:pParameter;
  p:PAnsiChar;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=adefault
  else
    case lpar^._Type of
      'a': result:=lpar^.AsString;
      'b': begin
        mGetMem(p,lpar^.AsInteger*2+1);
        result:=BinaryEncode(p,lpar^.ReadBinary(nil),lpar^.AsInteger);
        mFreeMem(p);
      end;
{$IFDEF UseSysUtils}
      'd': result:=DateTimeToStr(lpar^.AsDateTime);
{$ENDIF}
      'f': Str(lpar^.AsFloat:0:decimals,result);
      'i': Str(lpar^.AsInteger,result);
      'l': begin
        if not (CFG_COMPLEXBOOL in FOptions) then
        begin
          if lpar^.AsBoolean then result:='1' else result:='0';
        end
        else
        begin
          if lpar^.AsBoolean then result:='true' else result:='false';
        end;
      end;
      'p': begin
        lbuf[0]:='0'; lbuf[1]:='x';
        IntToHex(@lbuf[2],UIntPtr(lpar^.AsPointer));
        result:=PAnsiChar(@lbuf);
      end;
    else
      result:=adefault;
    end;
end;

function TCfgBase.ReadString(asection,akey:PAnsiChar; const adefault:AnsiString=''):AnsiString; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadString(nil,asection,akey,adefault);
end;

procedure TCfgBase.WriteString(ans,asection,akey:PAnsiChar; const avalue:AnsiString);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsString:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtText);
end;

procedure TCfgBase.WriteString(asection,akey:PAnsiChar; const avalue:AnsiString); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteString(nil,asection,akey,avalue);
end;

//--- Binary

function TCfgBase.ReadBinary(ans,asection,akey:PAnsiChar; buf:pointer=nil):pointer;
var
  lpar:pParameter;
begin
  lpar:=FindParameter(ans,asection,akey);
  if (lpar=nil) or (lpar^.IsEmpty) then
    result:=nil
  else
    case lpar^._Type of
      'a': begin
        if buf<>nil then
        begin
          BinaryDecode(buf,lpar^.AsText,false);
          result:=buf;
        end
        else
          result:=nil;
      end;
      'b': result:=lpar^.ReadBinary(buf); // nil - return internal, not - copy
    else
      result:=nil;
    end;
end;

function TCfgBase.ReadBinary(asection,akey:PAnsiChar; buf:pointer=nil):pointer; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadBinary(nil,asection,akey,buf);
end;

procedure TCfgBase.WriteBinary(ans,asection,akey:PAnsiChar; avalue:pointer; asize:cardinal);
var
  lpar:pParameter;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.WriteBinary(avalue,asize);

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtBinary);
end;

procedure TCfgBase.WriteBinary(asection,akey:PAnsiChar; avalue:pointer; asize:cardinal); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WriteBinary(nil,asection,akey,avalue,asize);
end;

//---  Pointer

function TCfgBase.ReadPointer(ans,asection,akey:PAnsiChar):pointer;
var
  lpar:pParameter;
begin
  result:=nil;

  lpar:=FindParameter(ans,asection,akey);
  if (lpar<>nil) and not (lpar^.IsEmpty) then
    case lpar^._Type of
      'a': result:=pointer(UIntPtr(NumToInt(lpar^.AsText)));
      'b': result:=ppointer(lpar^.ReadBinary(nil))^;
      'i': result:=pointer(lpar^.AsInteger);
      'p': result:=lpar^.AsPointer;
    end;
end;

function TCfgBase.ReadPointer(asection,akey:PAnsiChar):pointer; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=ReadPointer(nil,asection,akey);
end;

procedure TCfgBase.WritePointer(ans,asection,akey:PAnsiChar; avalue:pointer);
var
  lpar:pParameter;
//  buf:array [0..63] of AnsiChar;
begin
  lpar:=GetParameter(ans,asection,akey);
  lpar^.AsPointer:=avalue;

  if Assigned(OnChange) then
    OnChange(ans,asection,akey,cldParameter+cldtPointer);
end;

procedure TCfgBase.WritePointer(asection,akey:PAnsiChar; avalue:pointer); {$IFDEF AllowInline}inline;{$ENDIF}
begin
  WritePointer(nil,asection,akey,avalue);
end;

//----- Main methods -----

{
procedure TCfgBase.EnumSections();
var
  lns:pNamespace;
  lsect:pSection;
begin
  lns:=FirstNamespace;
  while lns<>nil do
  begin
    lsect:=lns^.FirstSection;
    while lsect<>nil do
    begin

      lsect:=lsect^.NextSection;
    end;
    lns:=NextNamespace;
  end;
end;
}
procedure TCfgBase.SetOptions(const opt:tCfgOptions);
begin
  FOptions:=opt;
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

procedure TCfgBase.Release;
var
  i:integer;
begin
  for i:=0 to numnamespace-1 do
    if not arNamespaces[i].NotUsed then arNamespaces[i].Delete;

  SetLength(arNamespaces,0);
  numnamespace:=0;

  mFreeMem(FNSList);

  mFreeMem(FComment);

  if Assigned(OnChange) then
    OnChange(nil,nil,nil,cldObject{cldNamespace+cldSection+cldParameter}+cldDelete);
end;

procedure TCfgBase.Clear;
begin
  Release;

  AddNamespace(nil);
  Section[nil,nil];
end;

procedure TCfgBase.Free;
begin
  Release;

  OnChange:=nil;
end;

{$ENDIF}
