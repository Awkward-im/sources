unit INIList;

interface

uses
  Classes;

type
  TIniList = class(TStringList)
  private
    function GetKeyIndex(const asection,akey:string):integer;
    function GetKeyValue(const asection,akey:string):string;    
  public
    function ReadString (const asection,akey,adefault:string):string;
    function ReadInteger(const asection,akey:string; adefault:integer):integer;
    function ReadBool   (const asection,akey:string; adefault:boolean):boolean;
    procedure ReadSectionNames(const asection:string; alist:TStrings);
  end;


implementation

uses
  SysUtils;

{ TIniList }

function TIniList.GetKeyIndex(const asection, akey: string): integer;
var
  i,c:integer;
begin
  result:=-1;
  i:=self.IndexOf('['+asection+']');
  if i=-1 then exit;

  c:=self.Count;
  inc(i);
  while (i<c) and (pos('=',strings[i])<>0) do
  begin
    if CompareText(names[i],akey)=0 then
    begin
      result:=i;
      exit;
    end;
    inc(i);
  end;
end;

function TIniList.GetKeyValue(const asection, akey: string): string;
var
  i,p:integer;
begin
  result:='';
  i:=GetKeyIndex(asection,akey);
  if i=-1 then exit;

  p:=Pos('=',strings[i]);
  result:=Copy(strings[i],p+1,maxint);
end;

function TIniList.ReadBool(const asection, akey: string; adefault: boolean): boolean;
var
  keyvalue:string;
begin
  result:=adefault;
  keyvalue:=GetKeyValue(asection,akey);
  if keyvalue<>'' then
    result:=CompareText('true',keyvalue)=0;
end;

function TIniList.ReadInteger(const asection, akey: string; adefault: integer): integer;
var
  keyvalue:string;
begin
  keyvalue:=GetKeyValue(asection,akey);
  result:=StrToIntDef(keyvalue,adefault);
end;

function TIniList.ReadString(const asection, akey, adefault: string): string;
var
  keyvalue:string;
begin
  result:=adefault;
  keyvalue:=GetKeyValue(asection,akey);
  if keyvalue<>'' then result:=keyvalue;
end;

procedure TIniList.ReadSectionNames(const asection: string; alist: TStrings);
var
  i,c,p:integer;
  s:string;
begin
  alist.Clear;
  i:=self.IndexOf('['+asection+']');
  if i=-1 then exit;

  inc(i);
  c:=count;
  while (i<c) and (Pos('[',strings[i])=0) and (strings[i]<>'') do
  begin
    s:=strings[i];
    p:=pos('=',s);
    if p=0 then
      alist.Append(s)
    else
      alist.Append(Copy(s,1,p-1));
    inc(i);
  end;
end;

end.
