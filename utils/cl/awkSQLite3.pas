unit awkSQLite3;

interface


function IsTableExists (const aTable:AnsiString):boolean;
function IsColumnExists(const aTable,aColumn:AnsiString):boolean;

function ExecSQLQuery (const aSQL:AnsiString):boolean;
function ExecuteDirect(const aSQL:AnsiString):boolean;

function GetLastId  ():integer; overload;
function GetLastId  (const atable,anid:AnsiString):integer; overload;
//function GetDataById(const atable,akey:AnsiString; anid:integer):boolean;

function  OpenDatabase(const aname:AnsiString):boolean;
procedure CloseDatabase;


implementation

uses
//  SysUtils,
  sqlite3;


var
  db:PSQLite3;


function IsExistsInternal(const aSQL:AnsiString):boolean;
var
  vm:pointer;
  lresult:integer;
begin
  lresult := sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil);
  if lresult=SQLITE_OK then
  begin
    lresult:=sqlite3_step(vm);
    if lresult=SQLITE_ROW then
      lresult:=sqlite3_column_int(vm,0)
    else
      lresult:=0;
    sqlite3_finalize(vm);
    result:=lresult>0;
  end
  else
    result:=false;
end;

function IsTableExists(const aTable:AnsiString):boolean;
begin
  result:=IsExistsInternal(
    'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' AND name = '''+aTable+'''');
end;

function IsColumnExists(const aTable,aColumn:AnsiString):boolean;
begin
  result:=IsExistsInternal(
    'SELECT COUNT(*) FROM pragma_table_info('''+aTable+''') WHERE name='''+aColumn+'''');
end;

//----- Execute SQL -----

function ExecSQLQuery(const aSQL:AnsiString):boolean;
begin
  result:=sqlite3_exec(db,PChar(aSQL),nil,nil,nil)=SQLITE_OK;
end;

function ExecuteDirect(const aSQL:AnsiString):boolean;
var
  vm: Pointer;
  lresult:integer;
begin
  lresult := sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil);
  if lresult=SQLITE_OK then
  begin
    lresult:=sqlite3_step(vm);
    sqlite3_finalize(vm);
  end;
  result:=lresult=SQLITE_OK;
end;

//----- Retrieve Last ID -----

function CallbackInt(_para1:pointer; plArgc:longint; argv:PPchar; argcol:PPchar):longint; cdecl;
var
  ltmp:integer;
{
  i: Integer;
  PVal, PName: ^PChar;
}
begin
  Val(argv^,PInteger(_para1)^,ltmp);
{
  PVal :=argv;
  PName:=argcol;
  for i:=0 to plArgc-1 do
  begin
    inc(PVal);
    inc(PName);
  end;
}
  Result:=0;
end;

function GetLastId(const atable, anid:AnsiString):integer;
var
  lresult:integer;
begin
  if sqlite3_exec(db,
    PChar('SELECT '+anid+' FROM '+atable+' ORDER BY '+anid+' DESC LIMIT 1'),
    @CallbackInt,@lresult,nil)=SQLITE_OK then
  begin
    result:=lresult
  end
  else
    result:=-1;
end;

function GetLastId():integer;
begin
  result:=sqlite3_last_insert_rowid(db);
end;



function GetDataById(const atable,akey:AnsiString; anid:integer):boolean;
var
  ls:AnsiString;
begin
  Str(anid,ls);
  // check TSqlite3Dataset.QuickQuery
  result:=sqlite3_exec(db,
    PChar('SELECT * FROM '+atable+' WHERE '+akey+' = '+ls),
    nil,nil,nil)=SQLITE_OK;
end;


//----- Init/Free -----

procedure CloseDatabase;
begin
  sqlite3_close(db);
end;

function OpenDatabase(const aname:AnsiString):boolean;
begin
  result:=sqlite3_open(pointer(aname),@db)=SQLITE_OK;
end;


procedure InitDatabase;
begin
end;

procedure FreeDatabase;
begin
end;

initialization

  InitDatabase;

finalization

  FreeDatabase;

end.
