{
  INIFile namespace object
}
{$IFDEF Interface}

  tININamespace = object
  private
    FSections    :pINISection;
    SelSectionPtr:pINISection;

    parent:pINIFile;
    next  :pININamespace;

    FName    :PAnsiChar;
    FSectList:PAnsiChar;
    flags    :cardinal;


    function FindSection(aname:PAnsiChar):pINISection;
    function AddSection (aname:PAnsiChar):pINISection;
    function GetSection (aname:PAnsiChar):pINISection;

    function GetSectionList ():PAnsiChar;
    function GetSectionCount():integer;

    function FirstSection():pINISection;
    function NextSection ():pINISection;

  public
    procedure CopyTo(var dst:tININamespace); overload;
    procedure CopyTo(dst:PAnsiChar        ); overload;
    procedure Delete();
    procedure Rename(newname:PAnsiChar);

    property Name:PAnsiChar read FName write Rename;

    property SectionList :PAnsiChar read GetSectionList;
    property SectionCount:integer   read GetSectionCount;

    property Section[aname:PAnsiChar]:pINISection read GetSection; default;
  end;

{$ELSE}

//----- Section navigation -----

function tININamespace.FirstSection():pINISection;
var
  lsn:pINISection;
begin
  SelSectionPtr:=FSections;

  // Skip and delete unused section objects
  while (SelSectionPtr<>nil) and ((SelSectionPtr^.flags and F_USED)=0) do
  begin
    lsn:=SelSectionPtr;
    SelSectionPtr:=lsn^.next;
    Dispose(lsn);
  end;

  FSections:=SelSectionPtr;
  result   :=SelSectionPtr;
end;

function tININamespace.NextSection():pINISection;
var
  sn,lsn:pINISection;
begin
  sn:=SelSectionPtr;
  if sn<>nil then
  begin
    SelSectionPtr:=sn^.next;

    // Skip and delete unused section objects
    while (SelSectionPtr<>nil) and ((SelSectionPtr^.flags and F_USED)=0) do
    begin
      lsn:=SelSectionPtr;
      SelSectionPtr:=lsn^.next;
      Dispose(lsn);
    end;

    sn^.next:=SelSectionPtr;
  end;
  result:=SelSectionPtr;
end;

//----- Namespace manipulation -----

procedure tININamespace.Delete();
var
  sn,psn:pINISection;
begin
  sn:=FirstSection;
  while sn<>nil do
  begin
    psn:=sn;
    sn:=NextSection;
    psn^.Delete;
  end;
  FirstSection; // Free memory for sections

  mFreeMem(FSectList);
  if (flags and F_NAME)<>0 then
    mFreeMem(FName);

  flags:=0;

  parent^.flags:=parent^.flags or F_CHANGED;
end;

procedure tININamespace.CopyTo(var dst:tININamespace);
var
  sn:pINISection;
begin
  if (@dst<>@self) then
  begin
    sn:=FirstSection;
    while sn<>nil do
    begin
      sn^.CopyTo(dst.Section[sn^.Name]^);
      sn:=NextSection;
    end;
  end;
end;

procedure tININamespace.CopyTo(dst:PAnsiChar);
begin
  CopyTo(parent^.GetNamespace(dst)^);
end;

procedure tININamespace.Rename(newname:PAnsiChar);
var
  ns:pININamespace;
begin
  ns:=parent^.FindNamespace(newname);
  if ns<>nil then
  begin
    CopyTo(ns^);
//    Delete;
  end
  else
  begin
    if (flags and F_NAME)<>0 then
      mFreeMem(FName);

    StrDup(FName,newname);
    flags:=flags or F_NAME;

    parent^.flags:=parent^.flags or F_CHANGED;
  end;
end;

//----- Section manipulation -----

function tININamespace.FindSection(aname:PAnsiChar):pINISection;
var
  sn:pINISection;
{$IFDEF UseHash}
  lhash:cardinal;
{$ELSE}
  b:boolean;
{$ENDIF}
begin
  sn:=FirstSection;
{$IFDEF UseHash}
  lhash:=HashOf(aname,(flags and F_CASE)<>0);
  while (sn<>nil) and (sn^.hash<>lhash) do
  begin
    sn:=NextSection;
  end;
{$ELSE}
  while (sn<>nil) do
  begin
    if (flags and F_CASE)<>0 then
      b:=StrCmp (sn^.Name,aname)=0
    else
      b:=StrCmpI(sn^.Name,aname)=0;
    if b then break;

    sn:=NextSection;
  end;
{$ENDIF}

  result:=sn;
end;

function tININamespace.AddSection(aname:PAnsiChar):pINISection;
var
  sn,last:pINISection;
begin
  New(sn);
  FillChar(sn^,SizeOf(tINISection),0);

  if FSections<>nil then
  begin
    last:=FSections;
    while last^.next<>nil do
      last:=last^.next;
    last^.next:=sn;
  end
  else
    FSections:=sn;

  sn^.parent:=@self;
  sn^.flags :=F_USED;

  if (parent^.flags and F_BUFFER)<>0 then
  begin
    sn^.FName:=aname;
  end
  else
  begin
    sn^.flags:=sn^.flags or F_NAME;
    StrDup(sn^.FName,aname);
  end;
{$IFDEF UseHash}
  sn^.hash:=HashOf(sn^.FName,(flags and F_CASE)<>0);
{$ENDIF}

  flags:=flags or F_CHANGED;

  sn^.flags:=sn^.flags or F_KEEPEMPTY;

  result:=sn;
end;

function tININamespace.GetSection(aname:PAnsiChar):pINISection;
begin
  result:=FindSection(aname);
  if result=nil then
    result:=AddSection(aname)
end;

function tININamespace.GetSectionCount():integer;
var
  sn:pINISection;
begin
  result:=0;

  sn:=FirstSection;
  while (sn<>nil) do
  begin
    inc(result);
    sn:=NextSection;
  end;
end;

function tININamespace.GetSectionList():PAnsiChar;
var
  sn:pINISection;
  pc:PAnsiChar;
  lsize:cardinal;
begin
  if (flags and F_CHANGED)<>0 then
  begin
    mFreeMem(FSectList);
    
    lsize:=0;
    sn:=FirstSection;
    while sn<>nil do
    begin
      inc(lsize,StrLen(sn^.Name)+1);
      sn:=NextSection;
    end;

    mGetMem(pc,lsize+1);
    FSectList:=pc;
    if lsize>0 then
    begin
      sn:=FirstSection;
      while sn<>nil do
      begin
        pc:=StrCopyE(pc,sn^.Name);
        inc(pc);
        sn:=NextSection;
      end;
    end;
    pc^:=#0;
    flags:=flags and not F_CHANGED;
  end;
  result:=FSectList;
end;

{$ENDIF}
