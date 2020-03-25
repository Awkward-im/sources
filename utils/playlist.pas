{Playlist process}
{$Include mydefs.inc}
unit playlist;

interface

type
  pPlaylist = ^tPlaylist;
  tPlaylist = object
  private
    fShuffle  :boolean;
    plSize    :cardinal;  // playlist entries
    plCapacity:cardinal;
    base      :PWideChar;
    name      :PWideChar;
    descr     :PWideChar;
    plStrings :array of PWideChar;
    CurElement:cardinal;
    PlOrder   :array of cardinal;
    CurOrder  :cardinal;

    procedure SetShuffle(value:boolean);
    function  GetShuffle:boolean;
    procedure DoShuffle;

    function GetTrackNumber:integer;
    procedure SetTrackNumber(value:integer);

    procedure AddLine(aname,adescr:PWideChar;new:boolean=true);
    function ProcessElement(num:integer=-1):PWideChar;

    procedure Init;
    procedure Free;

  public
    procedure SetBasePath(path:PWideChar);

    function GetSong(number:integer=-1):PWideChar;
    function GetCount:integer;

    function Next    :PWideChar;
    function Previous:PWideChar;

    property Track  :integer read GetTrackNumber write SetTrackNumber;
    property Shuffle:boolean read GetShuffle     write SetShuffle;
  end;

function isPlaylist(fname:PWideChar):integer;
function CreatePlaylist(fname:PWideChar):pPlaylist; overload;
function CreatePlaylist(buf:pointer;format:integer):pPlaylist; overload;
procedure FreePlaylist(var playlist:pPlaylist);

implementation

uses
  common,
  cmemini;

const
  plSizeStart = 2048;
  plSizeStep  = 256;

procedure tPlaylist.Init;
begin
  CurElement:=0;
  base:=nil;
  name:=nil;
  descr:=nil;
  Shuffle:=false;
  plSize:=0;
end;

procedure tPlaylist.Free;
var
  i:integer;
begin
  PlOrder:=nil;

  mFreeMem(base);
  mFreeMem(name);
  mFreeMem(descr);

  for i:=0 to plSize-1 do
  begin
    mFreeMem(plStrings[i*2]);
    mFreeMem(plStrings[i*2+1]);
  end;
  plStrings:=nil;
end;

procedure tPlaylist.AddLine(aname,adescr:PWideChar;new:boolean=true);
begin
  if plCapacity=0 then
  begin
    plCapacity:=plSizeStart;
    SetLength(plStrings,plSizeStart*2);
    FillChar(plStrings[0],plSizeStart*2*SizeOf(PWideChar),0);
  end
  else if plSize=plCapacity then
  begin
    inc(plCapacity,plSizeStep);
    SetLength(plStrings,plCapacity*2);
    FillChar(plStrings[plSize],plSizeStep*2*SizeOf(PWideChar),0);
  end;
  if new then
  begin
    StrDupW(plStrings[plSize*2  ],aname);
    StrDupW(plStrings[plSize*2+1],adescr);
  end
  else
  begin
    plStrings[plSize*2  ]:=aname;
    plStrings[plSize*2+1]:=adescr;
  end;
  inc(plSize);
end;

procedure tPlaylist.SetBasePath(path:PWideChar);
var
  buf:array [0..255] of WideChar;
  p,pp:PWideChar;
begin
  mFreeMem(base);

  pp:=ExtractW(path,false);
  p:=StrCopyEW(@buf,pp);
  mFreeMem(pp);
  
  if ((p-1)^<>'\') and ((p-1)^<>'/') then
  begin
    if StrScanW(buf,'/')<>nil then
      p^:='/'
    else
      p^:='\';
    inc(p);
  end;
  p^:=#0;
  StrDupW(base,buf);
end;

function tPlaylist.GetCount:integer;
begin
  result:=plSize;
end;

function tPlaylist.GetTrackNumber:integer;
begin
  if fShuffle then
    result:=CurOrder
  else
    result:=CurElement;
end;

procedure tPlaylist.SetTrackNumber(value:integer);
begin
  if value<0 then
    value:=0
  else if value>=integer(plSize) then
    value:=plSize-1;

  if fShuffle then
    CurOrder:=value
  else
    CurElement:=value;
end;

function tPlaylist.ProcessElement(num:integer=-1):PWideChar;
begin
  if num<0 then
    num:=Track
  else if num>=integer(plSize) then
    num:=plSize-1;
  if fShuffle then
    num:=PlOrder[num];

  result:=plStrings[num*2];
end;

function tPlaylist.GetSong(number:integer=-1):PWideChar;
var
  buf:array [0..255] of WideChar;
begin
  result:=ProcessElement(number);

  if (result<>nil) and not isPathAbsolute(result) and (base<>nil) then
  begin
    StrCopyW(StrCopyEW(@buf,base),result);
    StrDupW(result,buf);
  end
  else
    StrDupW(result,result);
end;

procedure tPlaylist.SetShuffle(value:boolean);
begin
  if value then
  begin
//    if not fShuffle then // need to set Shuffle
      DoShuffle;
  end;

  fShuffle:=value;
end;

function tPlaylist.GetShuffle:boolean;
begin
  result:=fShuffle;
end;

procedure tPlaylist.DoShuffle;
var
  i,RandInx: cardinal;
  SwapItem: cardinal;
begin
  SetLength(PlOrder,plSize);
  Randomize;
  for i:=0 to plSize-1 do
    PlOrder[i]:=i;
  if plSize>1 then
  begin
    for i:=0 to plSize-2 do
    begin
      RandInx:=cardinal(Random(plSize-i));
      SwapItem:=PlOrder[i];
      PlOrder[i      ]:=PlOrder[RandInx];
      PlOrder[RandInx]:=SwapItem;
    end;
  end;
  CurOrder:=0;
end;

function tPlaylist.Next:PWideChar;
begin
  if plSize<>0 then
  begin
    if not Shuffle then
    begin
      inc(CurElement);
      if CurElement=plSize then
        CurElement:=0;
    end
    else // if mode=plShuffle then
    begin
      inc(CurOrder);
      if CurOrder=plSize then
      begin
        DoShuffle;
        CurOrder:=0;
      end;
    end;
    result:=GetSong;
  end
  else
    result:=nil;
end;

function tPlaylist.Previous:PWideChar;
begin
  if plSize<>0 then
  begin
    if not Shuffle then
    begin
      if CurElement=0 then
        CurElement:=plSize;
      Dec(CurElement);
    end
    else // if mode=plShuffle then
    begin
      if CurOrder=0 then
      begin
        DoShuffle;
        CurOrder:=plSize;
      end;
      dec(CurOrder);
    end;
    result:=GetSong;
  end
  else
    result:=nil;
end;

//----- Playlist format reading -----

function SkipLine(var p:PWideChar):boolean;
begin
  while p^>=' ' do inc(p);
  while p^<=' ' do // Skip spaces too
  begin
    if p^=#0 then
    begin
      result:=false;
      exit;
    end;
    p^:=#0;
    inc(p);
  end;
  result:=true;
end;

procedure ReadM3UPlaylist(playlist:pPlaylist;buf:pointer);
type
  pdword = ^longword;
var
  p:PAnsiChar;
  pp,pd:PWideChar;
  plBufW:PWideChar;
  lname,ldescr:PWideChar;
  finish:boolean;
  pltNew:boolean;
begin
  p:=buf;
  if (pdword(p)^ and $00FFFFFF)=SIGN_UTF8 then
  begin
    inc(p,3);
    UTF8ToWide(p,plBufW)
  end
  else
    AnsiToWide(p,plBufW);

  pp:=plBufW;
  pltNew:=StrCmpW(pp,'#EXTM3U',7)=0;
  if pltNew then SkipLine(pp);

  ldescr:=nil;
  finish:=false;
  repeat
    if pltNew then
    begin
      pd:=StrScanW(pp,',');
      if pd<>nil then
      begin
        ldescr:=pd+1;
        if not SkipLine(pp) then break;
      end;
    end;
    lname:=pp;
    finish:=SkipLine(pp);
    playlist^.AddLine(lname,ldescr);
  until not finish;

  mFreeMem(plBufW);
end;

procedure ReadPLSPlaylist(playlist:pPlaylist;buf:pointer);
var
  lname,ldescr:PWideChar;
  ini:pINIFile;
  lsection:PAnsiChar;
  ffile,ftitle:array [0..31] of AnsiChar;
  f,t:PAnsiChar;
  i,size:integer;
begin
  ini:=CreateIniFile();
  ini^.Text:=PAnsiChar(buf);

  lsection:=ini^.SectionList[nil];

  size:=StrToInt(ini^.Value[lsection,'NumberOfEntries']);
  f:=StrCopyE(@ffile ,'File');
  t:=StrCopyE(@ftitle,'Title');
  for i:=1 to size do
  begin
    IntToStr(f,i); AnsiToWide(ini^.Value[lsection,ffile ],lname);
    IntToStr(t,i); AnsiToWide(ini^.Value[lsection,ftitle],ldescr);

    playlist^.AddLine(lname,ldescr,false);
  end;

  FreeINIFile(ini);
end;

//----- Public functions -----

function isPlaylist(fname:PWideChar):integer;
var
  ext:array [0..7] of WideChar;
begin
  GetExt(fname,PWideChar(@ext),7);
  if      StrCmpW(ext,'M3U',3)=0 then result:=1
  else if StrCmpW(ext,'PLS'  )=0 then result:=2
  else result:=0;
end;

function CreatePlaylist(buf:pointer;format:integer):pPlaylist;
begin
  if format in [1,2] then
  begin
    New(result);
    result^.Init;
    case format of
      1: ReadM3UPlaylist(result,buf);
      2: ReadPLSPlaylist(result,buf);
    end;
  end
  else
    result:=nil;
end;

function CreatePlaylist(fname:PWideChar):pPlaylist;
var
  f:file of byte;
  buf:PAnsiChar;
  size:integer;
begin
  result:=nil;
  AssignFile(f,fname);
  Reset(f);
  if IOResult()=0 then
  begin
    size:=FileSize(f);
    if size>0 then
    begin
      mGetMem(buf,size+1);
      BlockRead(f,buf^,size);
      buf[size]:=#0;
      result:=CreatePlaylist(buf,isPlaylist(fname));
      if result<>nil then
        result^.SetBasePath(fname);
      mFreeMem(buf);
    end;
    CloseFile(f);
  end;
end;

procedure FreePlaylist(var playlist:pPlaylist);
begin
  playlist^.Free;
  Dispose(playlist);
  playlist:=nil;
end;

end.
