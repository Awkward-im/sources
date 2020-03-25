{
  namespace object
}
{$IFDEF Interface}

type
  pNamespace = ^tNamespace;
  tNamespace = object
  private
    FName    :PAnsiChar;
    FSectList:PAnsiChar;

    FLastSectName:PAnsiChar;
    FLastSect:pSection;

    arSections:array of tSection;
    numsection:integer;
    CurSection:integer;

    function AddSection(aname:PAnsiChar):pSection;

    function FirstSection():pSection;
    function NextSection ():pSection;

    procedure Delete();
    procedure CopyTo(dst:pNamespace; opt:TCfgOptions);
    procedure Rename(newname:PAnsiChar);

  public //!! used in tCfgBase
    function FindSection(aname:PAnsiChar; acase:boolean):pSection;
    function GetSection (aname:PAnsiChar; acase:boolean):pSection;

    function GetSectionList ():PAnsiChar;
    function GetSectionCount():integer;

    function DeleteSection(aname     :PAnsiChar; acase:boolean):boolean;
    function RenameSection(aname,anew:PAnsiChar; acase:boolean):boolean;
    function CopySection  (aname,anew:PAnsiChar; opt:tCfgOptions):boolean;

  public
    procedure Init(aname:PAnsiChar);

    function NotUsed():boolean;

    property Name:PAnsiChar read FName write Rename;
  end;

{$ELSE}

//----- Section navigation -----

function tNamespace.FirstSection():pSection;
begin
  CurSection:=-1;

  result:=NextSection();
end;

function tNamespace.NextSection():pSection;
begin
  inc(CurSection);

  while (CurSection<numsection) and (arSections[CurSection].NotUsed) do
    inc(CurSection);

  if CurSection>=numsection then
    result:=nil
  else
  begin
    result:=@arSections[CurSection];
  end;
end;

//----- Namespace manipulation -----

procedure tNamespace.Init(aname:PAnsiChar);
begin
  StrDup(FName,aname);

  numsection:=0;
  FSectList:=nil;
  arSections:=nil;
  FLastSectName:=nil;
end;

function tNamespace.NotUsed():boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=(numsection<0);
end;

procedure tNamespace.Delete();
var
  i:integer;
begin
  for i:=0 to numsection-1 do
    if not arSections[i].NotUsed then arSections[i].Delete;
  SetLength(arSections,0);

  mFreeMem(FLastSectName);
  mFreeMem(FSectList);
  mFreeMem(FName);
  numsection:=-1;
end;

procedure tNamespace.CopyTo(dst:pNamespace; opt:TCfgOptions);
var
  lsn:pSection;
begin
  if (dst<>@self) then
  begin
    lsn:=FirstSection();
    while lsn<>nil do
    begin
      lsn^.CopyTo(dst^.GetSection(lsn^.Name,(CFG_CASESENSITIVE in opt)),opt);
      lsn:=NextSection();
    end;
  end;
end;

procedure tNamespace.Rename(newname:PAnsiChar);
begin
  mFreeMem(FName);
  StrDup(FName,newname);
end;

//----- Section manipulation -----

function tNamespace.FindSection(aname:PAnsiChar; acase:boolean):pSection;
var
  lsn:pSection;
  b:boolean;
begin
  if (FLastSectName<>nil) then
  begin
    if acase then
      b:=StrCmp (FLastSectName,aname)=0
    else
      b:=StrCmpI(FLastSectName,aname)=0;
    if b then
    begin
      result:=FLastSect;
      exit;
    end;
  end;

  lsn:=FirstSection;

  while (lsn<>nil) do
  begin
    if acase then
      b:=StrCmp (lsn^.Name,aname)=0
    else
      b:=StrCmpI(lsn^.Name,aname)=0;
    if b then break;

    lsn:=NextSection;
  end;

  result:=lsn;

  mFreeMem(FLastSectName);
  if lsn<>nil then
  begin
    StrDup(FLastSectName,aname);
    FLastSect:=lsn;
  end;
end;

function tNamespace.AddSection(aname:PAnsiChar):pSection;
var
  i:integer;
begin
  result:=nil;

  for i:=0 to numsection-1 do
  begin
    if arSections[i].NotUsed then
    begin
      result:=@arSections[i];
      break;
    end;
  end;

  if result=nil then
  begin
    if numsection>High(arSections) then
      SetLength(arSections,Length(arSections)+increment);
    result:=@arSections[numsection];
    inc(numsection);
  end;
  result^.Init(aname);
end;

function tNamespace.GetSection(aname:PAnsiChar; acase:boolean):pSection;
begin
  result:=FindSection(aname,acase);
  if result=nil then
    result:=AddSection(aname)
end;

function tNamespace.DeleteSection(aname:PAnsiChar; acase:boolean):boolean;
var
  lsn:pSection;
begin
  lsn:=FindSection(aname,acase);
  if lsn<>nil then
    lsn^.Delete;

  result:=lsn<>nil;
  mFreeMem(FLastSectName);
end;

function tNamespace.RenameSection(aname,anew:PAnsiChar; acase:boolean):boolean;
var
  lsn,lsnnew:pSection;
begin
  result:=false;
  lsn:=FindSection(aname,acase);
  if lsn<>nil then
  begin
    lsnnew:=FindSection(anew,acase);
    if lsnnew=nil then
    begin
      result:=true;
      lsn^.Rename(anew);
    end;
  end;
  mFreeMem(FLastSectName);
end;

function tNamespace.CopySection(aname,anew:PAnsiChar; opt:TCfgOptions):boolean;
var
  lsn,lsnnew:pSection;
begin
  lsn:=FindSection(aname, (CFG_CASESENSITIVE in opt));
  if lsn<>nil then
  begin
    lsnnew:=GetSection(anew, (CFG_CASESENSITIVE in opt));
    lsn^.CopyTo(lsnnew,opt);
  end;

  result:=lsn<>nil;
end;

function tNamespace.GetSectionCount():integer;
var
  lsn:pSection;
begin
  result:=0;

  lsn:=FirstSection();
  while (lsn<>nil) do
  begin
    if (lsn^.Name<>nil) and (lsn^.Name^>#31) then
      inc(result);
    lsn:=NextSection();
  end;
end;

function tNamespace.GetSectionList():PAnsiChar;
var
  lsn:pSection;
  pc:PAnsiChar;
  lsize:cardinal;
begin
  mFreeMem(FSectList);
  
  lsize:=0;
  lsn:=FirstSection;
  while lsn<>nil do
  begin
    if (lsn^.Name<>nil) and (lsn^.Name^>#31) then
      inc(lsize,StrLen(lsn^.Name)+1);
    lsn:=NextSection;
  end;

  mGetMem(pc,lsize+1);
  FSectList:=pc;
  if lsize>0 then
  begin
    lsn:=FirstSection;
    while lsn<>nil do
    begin
    if (lsn^.Name<>nil) and (lsn^.Name^>#31) then
      begin
        pc:=StrCopyE(pc,lsn^.Name);
        inc(pc);
      end;
      lsn:=NextSection;
    end;
  end;
  pc^:=#0;

  result:=FSectList;
end;

{$ENDIF}
