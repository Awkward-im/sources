{
  section manipulation
}
{$IFDEF Interface}

type
  pSection = ^tSection;
  tSection = object // record
  private
    FName:PAnsiChar;
    paramlist:PAnsiChar;

    arParameters:array of tParameter;
    numparam:integer;

    function AddParameter(akey:PAnsiChar):pParameter;

    procedure Delete();
    procedure CopyTo(dst:pSection; opt:TCfgOptions);
    procedure Rename(newname:PAnsiChar);

  public //!! used in tCfgBase
    function FindParameter(akey:PAnsiChar; acase:boolean):pParameter;
    function GetParameter (akey:PAnsiChar; acase:boolean):pParameter;

    function GetParameterList (withempty:boolean):PAnsiChar;
    function GetParameterCount(withempty:boolean):integer;

  public
    procedure Init(aname:PAnsiChar);

    function NotUsed():boolean;

    property Name:PAnsiChar read FName write Rename;
  end;

{$ELSE}

//----- Section processing -----

procedure tSection.Init(aname:PAnsiChar);
begin
  StrDup(FName,aname);

  numparam:=0;
  paramlist:=nil;
  arParameters:=nil;
end;

function tSection.NotUsed():boolean; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=numparam<0;
end;

procedure tSection.Delete;
var
  i:integer;
begin
  for i:=0 to numparam-1 do
    arParameters[i].Free;

  SetLength(arParameters,0);
  mFreeMem(paramlist);
  mFreeMem(FName);
  numparam:=-1;
end;

procedure tSection.CopyTo(dst:pSection; opt:TCfgOptions);
var
  lpar:pParameter;
  i:integer;
begin
  if dst<>@self then
  begin
    for i:=0 to numparam-1 do
    begin
      lpar:=@arParameters[i];
      if (CFG_KEEPEMPTY in opt) or (not lpar^.IsEmpty) then
      begin
        lpar^.CopyTo(dst^.GetParameter(lpar^.Name,(CFG_CASESENSITIVE in opt))^);
      end;
    end;
  end;
end;

procedure tSection.Rename(newname:PAnsiChar);
begin
  mFreeMem(FName);
  StrDup(FName,newname);
end;

//----- Parameters processing -----

function tSection.FindParameter(akey:PAnsiChar; acase:boolean):pParameter;
var
  i:integer;
  b:boolean;
begin
  for i:=0 to numparam-1 do
  begin
    if acase then
      b:=StrCmp (arParameters[i].name,akey)=0
    else
      b:=StrCmpI(arParameters[i].name,akey)=0;
    if b then
    begin
      result:=@arParameters[i];
      exit;
    end;
  end;

  result:=nil;
end;

function tSection.AddParameter(akey:PAnsiChar):pParameter;
begin
  if numparam>High(arParameters) then
    SetLength(arParameters,Length(arParameters)+increment);

  result:=@arParameters[numparam];
  inc(numparam);

  result^.Init(akey);
end;

function tSection.GetParameter(akey:PAnsiChar; acase:boolean):pParameter;
begin
  result:=FindParameter(akey,acase);
  if result=nil then
    result:=AddParameter(akey);
end;

function tSection.GetParameterCount(withempty:boolean):integer;
var
  i:integer;
begin
  result:=0;

  for i:=0 to numparam-1 do
  begin
    if (arParameters[i].name^>#31) and
       (withempty or (not arParameters[i].IsEmpty)) then
      inc(result);
  end;
end;

function tSection.GetParameterList(withempty:boolean):PAnsiChar;
var
  pc:PAnsiChar;
  i:integer;
  lsize:cardinal;
begin
  mFreeMem(paramlist);

  lsize:=0;
  for i:=0 to numparam-1 do
  begin
    if (arParameters[i].name^>#31) and
       (withempty or (not arParameters[i].IsEmpty)) then
      inc(lsize,StrLen(arParameters[i].name)+1);
  end;

  mGetMem(pc,lsize+1);
  paramlist:=pc;
  if lsize>0 then
  begin
    for i:=0 to numparam-1 do
    begin
      if (arParameters[i].name^>#31) and
        (withempty or (not arParameters[i].IsEmpty)) then
      begin
        pc:=StrCopyE(pc,arParameters[i].name);
        inc(pc);
      end;
    end;
  end;
  pc^:=#0;

  result:=paramlist;
end;

{$ENDIF}
