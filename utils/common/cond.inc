{
  Conditions
}

{$IFDEF Interface}

procedure SetFlag  (var flag:cardinal; mask:cardinal);
procedure ClearFlag(var flag:cardinal; mask:cardinal);

function IIF(cond:boolean;ret1,ret2:integer  ):integer;   overload;
function IIF(cond:boolean;ret1,ret2:PAnsiChar):PAnsiChar; overload;
function IIF(cond:boolean;ret1,ret2:PWideChar):PWideChar; overload;
function IIF(cond:boolean;ret1,ret2:Extended ):Extended;  overload;
function IIF(cond:boolean;ret1,ret2:tDateTime):tDateTime; overload;
function IIF(cond:boolean;ret1,ret2:pointer  ):pointer;   overload;
function IIF(cond:boolean;const ret1,ret2:string):string; overload;
{$IFNDEF DELPHI_7_UP}
function IIF(cond:boolean;ret1,ret2:variant  ):variant;   overload;
{$ENDIF}
function Min(a,b:integer):integer;
function Max(a,b:integer):integer;

{$ELSE}

procedure SetFlag(var flag:cardinal; mask:cardinal);{$IFDEF AllowInline}inline;{$ENDIF}
begin
  flag:=flag or mask;
end;

procedure ClearFlag(var flag:cardinal; mask:cardinal);{$IFDEF AllowInline}inline;{$ENDIF}
begin
  flag:=flag and not mask;
end;

function IIF(cond:boolean;ret1,ret2:integer):integer; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;ret1,ret2:PAnsiChar):PAnsiChar; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;ret1,ret2:PWideChar):PWideChar; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;ret1,ret2:Extended):Extended; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;ret1,ret2:tDateTime):tDateTime; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;ret1,ret2:pointer):pointer; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
function IIF(cond:boolean;const ret1,ret2:string):string; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
{$IFNDEF DELPHI_7_UP}
function IIF(cond:boolean;ret1,ret2:variant):variant; overload;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if cond then result:=ret1 else result:=ret2;
end;
{$ENDIF}

function Min(a,b:integer):integer;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if a>b then
    result:=b
  else
    result:=a;
end;

function Max(a,b:integer):integer;{$IFDEF AllowInline}inline;{$ENDIF}
begin
  if a<b then
    result:=b
  else
    result:=a;
end;

{$ENDIF}
