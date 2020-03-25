unit awkSQLite;

interface

uses
  sqldb;


procedure ExecSQLQuery(const aStr:AnsiString);
function CreateSQLQuery(const aStr:AnsiString=''): TSQLQuery;

function GetLastId(Q:TSQLQuery; const atable, anid:AnsiString):integer; overload;
function GetLastId(             const atable, anid:AnsiString):integer; overload;

function OpenDatabase(const name:AnsiString):boolean;
procedure CloseDatabase;


implementation

uses
  SysUtils,
  sqlite3conn;


var
  SQLConnection: TSQLite3Connection = nil;
  SQLTransaction: TSQLTransaction;
//  SQLQuery: TSQLQuery;


procedure ExecSQLQuery(const aStr:AnsiString);
var
  Q:TSQLQuery;
begin
{1}
(*
  Q:=CreateSQLQuery(aStr);
  Q.ExecSQL;
  Q.Free;
*)
{2}
  SQLConnection.ExecuteDirect(aStr);
end;

function CreateSQLQuery(const aStr:AnsiString=''): TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.Options     := [sqoAutoCommit];
  Result.Database    := SQLConnection;
  Result.Transaction := SQLTransaction;

  if aStr <> '' then
    Result.SQL.Text := aStr;
end;

function GetLastId(Q:TSQLQuery; const atable, anid:AnsiString):integer;
begin
  Q.SQL.Text:='SELECT '+anid+' FROM '+atable+' ORDER BY '+anid+' DESC LIMIT 1';
  Q.Open;
  if Q.RecordCount>0 then
    result:=Q.Fields[0].AsInteger
  else
    result:=-1;
  Q.Close;
end;

function GetLastId(const atable, anid:AnsiString):integer;
var
  Q:TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  Q.Database    := SQLConnection;
  Q.Transaction := SQLTransaction;

  result:=GetLastId(Q, atable, anid);

  Q.Free;
end;

function GetDataById(Q:TSQLQuery; const atable,akey:AnsiString; anid:integer):boolean;
begin
  Q.Close;
  Q.SQL.Text := 'SELECT * FROM ' + atable + ' WHERE ' + akey + ' = ' + IntToStr(anid);
  Q.Open;

  result:=Q.RecordCount>0;
end;


procedure CloseDatabase;
begin
  SQLConnection.Close;
end;

function OpenDatabase(const name:AnsiString):boolean;
var
  exists:boolean;
begin
  SQLConnection.Close;
  SQLConnection.DatabaseName := name;
  exists := FileExists(SQLConnection.DatabaseName);

  if exists then
    SQLConnection.Open;

  result := exists;
end;

procedure InitDatabase;
begin
  SQLConnection  := TSQLite3Connection.Create(nil);
  SQLTransaction := TSQLTransaction.Create(SQLConnection);

  SQLConnection.Transaction := SQLTransaction;
{
  SQLQuery := TSQLQuery.Create(nil);
  SQLQuery.Options     := [sqoAutoCommit];
  SQLQuery.Database    := SQLConnection;
  SQLQuery.Transaction := SQLTransaction;
}
end;

procedure FreeDatabase;
begin
  if SQLConnection<>nil then
  begin
//    SQLQuery.Close;
//    SQLQuery.Free;

    SQLTransaction.Active := False;
    SQLConnection.Connected := False;

    SQLTransaction.Free;
    SQLConnection.Free;
//    SQLConnection := nil;
  end;
end;

initialization

  InitDatabase;

finalization

  FreeDatabase;

end.
