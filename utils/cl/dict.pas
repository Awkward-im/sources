unit Dict;

interface

uses
  Classes;

//procedure LoadDict       (const dict, aKey:AnsiString);
function  GetDict        (const dict:AnsiString):TStringList;
function  FindDictValue  (const dict:AnsiString; anId:integer):integer;
function  GetDictValue   (const dict:AnsiString; anId:integer):AnsiString;
function  AddDictValue   (const dict:AnsiString; anId:integer; const aValue:AnsiString):boolean;
procedure DeleteDictValue(const dict:AnsiString; anId:integer);


implementation

var
  DictCatalog:TStringList = nil;

{
procedure LoadDict(const dict, aKey:AnsiString);
var
  sl:TStringList;
begin
  sl:=GetDict(dict);

  SQLQuery.SQL.Text := 'SELECT * FROM ' + dict;
  SQLQuery.Open;
  while not SQLQuery.EOF do
  begin
    sl.AddObject(
              SQLQuery.FieldByName('name').AsString,
      TObject(SQLQuery.FieldByName(aKey).AsInteger)
    );
    SQLQuery.Next;
  end;
  SQLQuery.Close
end;
}
function GetDict(const dict:AnsiString):TStringList;
var
  sl:TStringList;
  idx:integer;
begin
  idx := DictCatalog.IndexOf(dict);
  if idx<0 then
  begin
    sl := TStringList.Create;
//    sl.Sorted := true;
    idx := DictCatalog.AddObject(dict,sl);
  end;

  result := TStringList(DictCatalog.Objects[idx]);
end;

function FindDictValue(const dict:AnsiString; anId:integer):integer;
var
  sl:TStringList;
begin
  sl := GetDict(dict);
  if sl<>nil then
    result := sl.IndexOfObject(TObject(UIntPtr(anId)))
  else
    result := -1;
end;

function GetDictValue(const dict:AnsiString; anId:integer):AnsiString;
var
  sl:TStringList;
  idx:integer;
begin
  result := '';
  sl := GetDict(dict);
  if sl<>nil then
  begin
    idx := sl.IndexOfObject(TObject(UIntPtr(anId)));
    if idx >= 0 then
      result := sl[idx];
  end;
end;

function AddDictValue(const dict:AnsiString; anId:integer; const aValue:AnsiString):boolean;
var
  sl:TStringList;
  idx:integer;
begin
  result := false;

  sl:=GetDict(dict);
  if sl<>nil then
  begin
    idx := sl.IndexOfObject(TObject(UIntPtr(anId)));
    if idx >= 0 then
      exit;
    sl.AddObject(aValue, TObject(UIntPtr(anId)));
  end;
end;

procedure DeleteDictValue(const dict:AnsiString; anId:integer);
var
  sl:TStringList;
  idx:integer;
begin
  sl := GetDict(dict);
  if sl<>nil then
  begin
    idx := sl.IndexOfObject(TObject(UIntPtr(anId)));
    if idx >=0 then
      sl.Delete(idx);
  end;
end;


procedure InitDicts;
begin
  DictCatalog := TStringList.Create;
end;

procedure FreeDicts;
var
  i:integer;
begin
  for i:=0 to DictCatalog.Count-1 do
    DictCatalog.Objects[i].Free;

  DictCatalog.Free;
end;

initialization

  InitDicts;

finalization

  FreeDicts;

end.
