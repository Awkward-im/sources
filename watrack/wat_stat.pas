{Statistic}
unit wat_stat;

interface

const
  smDirect  = 1;
  smReverse = 2;

const
  stArtist   = $0001;
  stCount    = $0002;
  stPath     = $0004;
  stDate     = $0008;
  stLength   = $0010;
  stAltCount = $0020;
  stAlbum    = $0040;

{$include default.tmpl}

procedure LoadStatOpt;
procedure SaveStatOpt;
procedure FreeStatOpt;

function  MakeReport(alog:PAnsiChar; areport:PAnsiChar; atmpl:PAnsiChar=nil):integer;
function  AddToLog  (alog:PAnsiChar; Info:UIntPtr):integer;
function  PackLog   (alog:PAnsiChar; inthread:boolean=false):integer;

var
  SortMode   :cardinal;
  ReportMask :cardinal;
  ReportItems:cardinal;
  Direction  :cardinal;
  DoRunReport:cardinal;
  DoAddExt   :cardinal;
  AutoSort   :cardinal;

const
  StatName  :PAnsiChar=nil;
  ReportName:PAnsiChar=nil;
  TmplName  :PAnsiChar=nil;


implementation

uses
  SysUtils,
  common,
  cmemini,
  wat_api;

//===== Options =====

const
  opt_StatName  :PAnsiChar = 'statname';
  opt_RepName   :PAnsiChar = 'repname';
  opt_TmplName  :PAnsiChar = 'tmplname';
  opt_SortMode  :PAnsiChar = 'sortmode';
  opt_ReportMask:PAnsiChar = 'reportmask';
  opt_ReportItem:PAnsiChar = 'reportitems';
  opt_Direction :PAnsiChar = 'direction';
  opt_RunReport :PAnsiChar = 'runreport';
  opt_AddExt    :PAnsiChar = 'addext';
  opt_AutoSort  :PAnsiChar = 'autosort';

  WATStats:PAnsiChar = 'statistic';

procedure LoadStatOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATStats];

  StrDup(ReportName,sect^.Key[opt_RepName]);
  StrDup(StatName  ,sect^.Key[opt_StatName]);
  StrDup(TmplName  ,sect^.Key[opt_TmplName]);

  DoAddExt   :=sect^.ReadInt(opt_AddExt    ,1);
  DoRunReport:=sect^.ReadInt(opt_RunReport ,0);
  Direction  :=sect^.ReadInt(opt_Direction ,smDirect);
  SortMode   :=sect^.ReadInt(opt_SortMode  ,stArtist);
  ReportItems:=sect^.ReadInt(opt_ReportItem,10);
  ReportMask :=sect^.ReadInt(opt_ReportMask,$FFFF);
  AutoSort   :=sect^.ReadInt(opt_AutoSort  ,1);
end;

procedure SaveStatOpt;
var
  sect:pINISection;
begin
  sect:=watini.Section[WATStats];

  sect^.Key[opt_RepName ]:=ReportName;
  sect^.Key[opt_StatName]:=StatName;
  sect^.Key[opt_TmplName]:=TmplName;
  sect^.WriteInt(opt_AddExt     ,DoAddExt);
  sect^.WriteInt(opt_RunReport  ,DoRunReport);
  sect^.WriteInt(opt_Direction  ,Direction);
  sect^.WriteInt(opt_SortMode   ,SortMode);
  sect^.WriteInt(opt_ReportItem ,ReportItems);
  sect^.WriteInt(opt_ReportMask ,ReportMask);
  sect^.WriteInt(opt_AutoSort   ,AutoSort);
end;

procedure FreeStatOpt;
begin
  mFreeMem(ReportName);
  mFreeMem(StatName);
  mFreeMem(TmplName);
end;

//===== Support =====

type
  pStatCell = ^tStatCell;
  tStatCell = record
    Count    :integer;
    AltCount :integer;
    LastTime :dword;
    Length   :integer;
    Artist   :PAnsiChar;
    Title    :PAnsiChar;
    MFile    :PAnsiChar;
    Album    :PAnsiChar;
    Next     :pStatCell; // only for fill
  end;

type
  pCells = ^tCells;
  tCells = record
    Count:integer;
    Cells:array [0..1] of pStatCell
  end;

const
  DelimChar = '|';
const
  buflen = 2048;

const
  Lock:boolean=false;

procedure err(str:PWideChar);
begin
//  MessageBoxW(0,{TranslateW}(str),{TranslateW}('Music Statistic'),MB_OK);
end;

function OnlyPath(dst,src:PAnsiChar):PAnsiChar;
var
  i:integer;
begin
  i:=StrLen(src)-1;
  while (i>0) and (src[i]<>'\') do dec(i);
  StrCopy(dst,src,i);
  result:=dst;
end;

//----- Date/time processing -----

function PackTime(const aTime:TSystemTime):dword;
begin
  with aTime do
    result:=
       Second+
      (Minute shl 06)+
      (Hour   shl 12)+
      (Day    shl 17)+
      (Month  shl 22)+
      (((Year-2000) and $3F) shl 26);
end;

procedure UnPackTime(aTime:dword; var MyTime:TSystemTime);
begin
  with MyTime do
  begin
    Year  :=(aTime shr 26)+2000;
    Month :=(aTime shr 22) and $0F;
    Day   :=(aTime shr 17) and $1F;
    Hour  :=(aTime shr 12) and $1F;
    Minute:=(aTime shr 6 ) and $3F;
    Second:= aTime and $3F;
  end;
end;

function ShowTime(buf:PAnsiChar; aTime:dword):PAnsiChar;
var
  MyTime:TSystemTime;
begin
  UnPackTime(aTime,MyTime);
  with MyTime do
  begin
    IntToStr(buf   ,Day   ,2);
    IntToStr(buf+3 ,Month ,2);
    IntToStr(buf+6 ,Year  ,2);
    IntToStr(buf+9 ,Hour  ,2);
    IntToStr(buf+12,Minute,2);
    IntToStr(buf+15,Second,2);
  end;
  buf[2] :='.'; buf[5] :='.'; buf[8] :=' ';
  buf[11]:=':'; buf[14]:=':'; buf[17]:=#0;
  result:=buf;
end;

//----- String handling -----

function CompareStr(aStr1,aStr2:PAnsiChar):integer;{$IFDEF AllowInline}inline;{$ENDIF}
begin
//  result:=lstrcmpia(aStr1,aStr2);
  result:=AnsiCompareText(aStr1,aStr2);
end;

function AppendStr(src:PAnsiChar;var dst:PAnsiChar):PAnsiChar; overload;
begin
  dst^:=DelimChar; inc(dst);
  while src^<>#0 do
  begin
    dst^:=src^;
    inc(dst);
    inc(src);
  end;
  result:=dst;
end;

function AppendStr(src:PWideChar;var dst:PAnsiChar):PAnsiChar; overload;
var
  p,lp:PAnsiChar;
begin
  dst^:=DelimChar; inc(dst);
  lp:=WideToUTF8(src,p);
  while lp^<>#0 do
  begin
    dst^:=lp^;
    inc(dst);
    inc(lp);
  end;
  mFreeMem(p);
  result:=dst;
end;

//===== Processing =====

procedure AppendStat(afname:PAnsiChar; Info:UIntPtr);
var
  f:Text;
  MyTime:TSystemTime;
  buf:array [0..buflen-1] of AnsiChar;
  lp:PAnsiChar;
begin
  if Lock then
    exit;
  if WATIsEmpty(Info,siArtist) and
     WATIsEmpty(Info,siTitle ) and
     WATIsEmpty(Info,siAlbum ) and
     WATIsEmpty(Info,siFile  ) then
    exit;

  AssignFile(f,afname);
  Append(f);

//  if IOResult<>0 then Rewrite(f);
  if IOResult<>0 then exit;

  FillChar(buf,SizeOf(buf),0);
  lp:=@buf;
  buf[0]:='1'; buf[1]:=DelimChar; inc(lp,2); // Count

  //GetLocalTime(MyTime);
  DateTimeToSystemTime(Now(),MyTime);
  IntToStr(lp,PackTime(MyTime),9);

  inc(lp,9);
  lp^:=DelimChar;
  inc(lp);
  IntToStr(lp,WATGet(Info,siLength)); while lp^<>#0 do inc(lp);

  AppendStr(WATGetStr(Info,siArtist),lp);
  AppendStr(WATGetStr(Info,siTitle ),lp);
  AppendStr(WATGetStr(Info,siFile  ),lp);
  AppendStr(WATGetStr(Info,siAlbum ),lp);

  lp^:=#$0D; inc(lp); lp^:=#$0A;
  Writeln(f,PAnsiChar(@buf));

  CloseFile(f);
end;

// rewrite log file line-by-line
procedure OutputStat(afname:PAnsiChar; aCells:pCells);
var
  f:file of byte;
  buf:array [0..2047] of AnsiChar;
  lp:PAnsiChar;
  i:integer;
begin
  AssignFile(f,afname);
  Rewrite(f);
  if IOResult<>0 then
    exit;

  for i:=0 to aCells^.Count-1 do
  begin
    lp:=@buf;
    with aCells^.Cells[i]^ do
    begin
      IntToStr(buf,Count);     while lp^<>#0 do inc(lp); lp^:=DelimChar; inc(lp);
      IntToStr(lp,LastTime,9); inc(lp,9);                lp^:=DelimChar; inc(lp);
      IntToStr(lp,Length);     while lp^<>#0 do inc(lp);
      AppendStr(Artist,lp);
      AppendStr(Title ,lp);
      AppendStr(MFile ,lp);
      AppendStr(Album ,lp);

      lp^:=#$0D; inc(lp); lp^:=#$0A;
      BlockWrite(f,buf,lp-PAnsiChar(@buf)+1);
    end;
  end;

  CloseFile(f);
end;

function CutStr(var src:PAnsiChar):PAnsiChar;
begin
  result:=src;
  while not (src^ in [DelimChar,#$0D,#$0A,#0]) do inc(src);
  src^:=#0;
  inc(src);
end;

procedure ClearStatCells(aCells:pCells);
begin
  with aCells^ do
    while Count>0 do
    begin
      dec(Count);
      mFreeMem(Cells[Count]);
    end;
  mFreeMem(aCells);
end;

function FillCell(asrc:PAnsiChar):pStatCell;
var
  Cell:pStatCell;
begin
  mGetMem (Cell ,SizeOf(tStatCell));
  FillChar(Cell^,SizeOf(tStatCell),0);

  Cell^.Count   :=StrToInt(asrc); while asrc^<>DelimChar do inc(asrc); inc(asrc);
  Cell^.LastTime:=StrToInt(asrc); while asrc^<>DelimChar do inc(asrc); inc(asrc);
  Cell^.Length  :=StrToInt(asrc); while asrc^<>DelimChar do inc(asrc); inc(asrc);
  Cell^.Artist  :=CutStr(asrc);
  Cell^.Title   :=CutStr(asrc);
  Cell^.MFile   :=CutStr(asrc);
  Cell^.Album   :=CutStr(asrc);

  result:=Cell;
end;

function Compare(C1,C2:pStatCell; SortType:integer):integer;
var
  ls,ls1:array [0..511] of AnsiChar;
begin
  case SortType of
    stArtist: begin
                       result:=CompareStr(C1^.Artist,C2^.Artist);
      if result=0 then result:=CompareStr(C1^.Title ,C2^.Title);
      if result=0 then result:=CompareStr(C1^.Album ,C2^.Album);
    end;
    stAlbum   : result:=CompareStr(C1^.Album,C2^.Album);
    stPath    : result:=CompareStr(OnlyPath(@ls,C1^.MFile),OnlyPath(@ls1,C2^.MFile));
    stDate    : result:=C2^.LastTime-C1^.LastTime;
    stCount   : result:=C2^.Count   -C1^.Count;
    stLength  : result:=C2^.Length  -C1^.Length;
    stAltCount: result:=C2^.AltCount-C1^.AltCount;
  else
    result:=0;
  end;
end;

function SwapProc(var Root:pCells; aFirst,aSecond:integer):integer;
var
  p:pStatCell;
begin
  p:=Root^.Cells[aFirst];
  Root^.Cells[aFirst]:=Root^.Cells[aSecond];
  Root^.Cells[aSecond]:=p;
  result:=0;
end;

procedure Resort(var Root:pCells;Sort:integer;aDirection:integer=smDirect);

  function CompareProc(First,Second:integer):integer;
  begin
    result:=Compare(Root^.Cells[First],Root^.Cells[Second],Sort);
    if aDirection=smReverse then
      result:=-result;
  end;

var
  i,j,gap:longint;
begin
  gap:=Root^.Count shr 1;
  while gap>0 do
  begin
    for i:=gap to Root^.Count-1 do
    begin
      j:=i-gap;
      while (j>=0) and (CompareProc(j,UIntPtr(j+gap))>0) do
      begin
        SwapProc(Root,j,UIntPtr(j+gap));
        dec(j,gap);
      end;
    end;
    gap:=gap shr 1;
  end;
// now pack doubles
end;

function BuildTree(afname:PAnsiChar;var buffer:PAnsiChar):pCells;
var
  f:file of byte;
  i,cnt:integer;
  FirstCell,CurCell,Cell:pStatCell;
  p,p1,p2:PAnsiChar;
  ls,buf:PAnsiChar;
  arr:pCells;
begin
  result:=nil;
  buffer:=nil;

  //---
  AssignFile(f,afname);
  Reset(f);
  if IOResult<>0 then
    exit;

  i:=FileSize(f);
  if i<22 then
  begin
    CloseFile(f);
    Exit;
  end;

  mGetMem(buffer,i+1);
  p:=buffer;
  BlockRead(f,p^,i);
  CloseFile(f);

  //---

  p1:=p;
  p2:=p+i;
  FirstCell:=nil;
  CurCell  :=nil;
  mGetMem(buf,buflen);
  buf^:=#0;
  cnt:=0;
  // fill cell list
  // skip same line right after original
  while p<p2 do
  begin
    while p^<>#$0D do inc(p);
    i:=p-p1;
    p^:=#0;
    if i>=20 then //min log template + min fname [d:\.e]
    begin
      ls:=p1;
// skip duplicates one-by-one
      while ls^<>DelimChar do inc(ls); inc(ls); // Count
      while ls^<>DelimChar do inc(ls); inc(ls); // time
      while ls^<>DelimChar do inc(ls); inc(ls); // length
      if StrCmp(buf,ls)<>0 then
      begin
        inc(cnt);
        StrCopy(buf,ls);
        Cell:=FillCell(p1);

        if FirstCell=nil then
        begin
          FirstCell:=Cell;
          CurCell  :=FirstCell;
        end
        else
        begin
          CurCell^.Next:=Cell;
          CurCell:=Cell;
        end;
      end;
    end;
    inc(p,2); p1:=p;
  end;
  mFreeMem(buf);

  // Fill array
  if cnt>0 then
  begin
    mGetMem(arr,SizeOf(integer)+cnt*SizeOf(pStatCell));
    arr^.Count:=cnt;
    CurCell:=FirstCell;
    i:=0;
    while CurCell<>nil do
    begin
      arr^.Cells[i]:=CurCell;
      CurCell:=CurCell^.Next;
      inc(i);
    end;
    result:=arr;
    // sort & pack
    Resort(arr,stArtist);

    i:=1;
    Cell:=arr^.Cells[0];
    while i<arr^.Count do
    begin
      with arr^.Cells[i]^ do
        if (CompareStr(Cell^.Artist,Artist)=0) and
           (CompareStr(Cell^.Title ,Title )=0) and
           (CompareStr(Cell^.Album ,Album )=0) then
        begin
          if Cell^.LastTime<LastTime then
            Cell^.LastTime:=LastTime;
          inc(Cell^.Count,Count);
          dec(arr^.Count);
          if i<arr^.Count then
            move(arr^.Cells[i+1],arr^.Cells[i],SizeOf(pStatCell)*(arr^.Count-i));
          continue;
        end
        else
          Cell:=arr^.Cells[i];
      inc(i);
    end;

  end;
end;

procedure SortLog(alog:PAnsiChar; amode:integer; aDirection:integer);
var
  Root:pCells;
  buf:PAnsiChar;
  buf1:array [0..511] of AnsiChar;
begin
  Lock:=true;

  StrCopy(buf1,alog);
//!!  ConvertFileName(alog,@buf1);
//  CallService(MS_UTILS_PATHTOABSOLUTE,twparam(alog),tlparam(@buf1));
  Root:=BuildTree(buf1,buf);
  if Root<>nil then
  begin
    if (amode<>stArtist) or (aDirection<>smDirect) then
      Resort(Root, amode, aDirection);
    OutputStat(buf1,Root);
    ClearStatCells(Root);
  end;
  mFreeMem(buf);

  Lock:=false;
end;

//===== Report =====

function ReadTemplate(fname:PAnsiChar;var buf:PAnsiChar):integer;
var
  f:file of byte;
  size:integer;
begin
  if (fname=nil) or (fname^=#0) then
  begin
    StrDup(buf,IntTmpl);
    result:=StrLen(IntTmpl);
  end
  else
  begin
    AssignFile(f,fname);
    Reset(f);
    if IOResult=0 then
    begin
      size:=FileSize(f);
      mGetMem(buf,size+1);
      BlockRead(f,buf^,size);
      buf[size]:=#0;
      CloseFile(f);
      result:=size;
    end
    else
      result:=0;
  end;
end;

function StatOut(report,log,template:PAnsiChar):boolean;

const
  bufsize = 16384;
var
  fout:file of byte;
  tt,tf:array [0..15] of AnsiChar;
  timebuf:array [0..17] of AnsiChar; // for current date / time
  outbuf:PAnsiChar;
  outpos:PAnsiChar;

  // fout, outpos, outbuf + bufsize
  procedure OutChar(var pc:PAnsiChar);
  begin
    outpos^:=pc^;
    inc(pc);
    inc(outpos);
    if (outpos-outbuf)=bufsize then
    begin
      BlockWrite(fout,outbuf^,bufsize);
      outpos:=outbuf;
    end;
  end;

  // "OutChar"
  procedure OutStr(pc:PAnsiChar);
  begin
    while pc^<>#0 do
      OutChar(pc);
  end;

  procedure OutputBlock(var start:PAnsiChar; var Root:pCells; asortmode:integer);
  const
    blocksize = 8192;
  var
    i,max,cnt,len:integer;
    items:cardinal;
    Cell:pStatCell;
    ls,ls1:array [0..511] of AnsiChar;
    block:array [0..blocksize-1] of AnsiChar;
  begin
    len:=StrIndex(start,'%end%');
    if len=0 then
      len:=StrLen(start)
    else
      dec(len);
    if len>6143 then
      err('Template block too large');

    Resort(Root,asortmode);

    case asortmode of
      stArtist,stAlbum,stPath: begin

        Cell:=Root^.Cells[0];
        max:=Cell^.Count;
        if asortmode=stPath then OnlyPath(@ls,Cell^.MFile) // speed optimization
        else
          ls[0]:=#0;

        for i:=0 to Root^.Count-1 do
        begin
          with Root^.Cells[i]^ do
          begin
            AltCount:=0;
            if      asortmode=stArtist then cnt:=CompareStr(Cell^.Artist,Artist)
            else if asortmode=stAlbum  then cnt:=CompareStr(Cell^.Album,Album)
            else                            cnt:=CompareStr(@ls,OnlyPath(@ls1,MFile));
            if cnt=0 then
              inc(max,Count)
            else
            begin
              Cell^.AltCount:=max;
              Cell:=Root^.Cells[i];
              if asortmode=stPath then OnlyPath(@ls,Cell^.MFile); // speed optimization
              max:=Count;
            end;
          end;
        end;
        Cell^.AltCount:=max;

        Resort(Root,stAltCount);
        if (asortmode=stAlbum) and (Root^.Cells[0]^.Album^=#0) then
        begin
          if Root^.Count>1 then
            max:=Root^.Cells[1]^.AltCount
          else
            max:=0;
        end
        else
          max:=Root^.Cells[0]^.AltCount;
      end;

      stCount: begin
        max:=Root^.Cells[0]^.Count;
      end;

      stLength: begin
        max:=Root^.Cells[0]^.Length;
      end;
    else
      max:=1;
    end;
    
    items:=1;
    if ReportItems>0 then
      for i:=0 to Root^.Count-1 do
      begin
        with Root^.Cells[i]^ do
        begin
          if (asortmode=stAlbum) and (Album^=#0) then continue;
          case asortmode of
            stArtist,
            stAlbum,
            stPath  : cnt:=AltCount;
            stCount : cnt:=Count;
            stLength: cnt:=Length;
          else
            cnt:=1;
          end;
          if cnt=0 then break;
          move(start^,block,len);
          block[len]:=#0;
          StrReplace(block,'%date%'       ,ShowTime(@ls,LastTime));
          StrReplace(block,'%length%'     ,IntToTime(PAnsiChar(@ls),Length));
          StrReplace(block,'%artist%'     ,Artist);
          StrReplace(block,'%title%'      ,Title);
          StrReplace(block,'%album%'      ,Album);
          StrReplace(block,'%file%'       ,MFile);
          StrReplace(block,'%path%'       ,OnlyPath(@ls,MFile));
          StrReplace(block,'%num%'        ,IntToStr(PAnsiChar(@ls),items));
          StrReplace(block,'%currenttime%',timebuf);
          StrReplace(block,'%totaltime%'  ,tt);
          StrReplace(block,'%totalfiles%' ,tf);
          StrReplace(block,'%percent%'    ,IntToStr(PAnsiChar(@ls),round(cnt*100/max)));
          StrReplace(block,'%count%'      ,IntToStr(PAnsiChar(@ls),cnt));
          OutStr(block);
        end;
        if items=ReportItems then break;
        inc(items);
      end;
    inc(start,len+5);
  end;

var
  TmplBuf:PAnsiChar;
  ptr:PAnsiChar;
  i,j,k:integer;
  size:integer;
  lsortmode:integer;
  MyTime:TSystemTime;
  Root:pCells;
  b1,tmp:PAnsiChar;
begin
  result:=false;
  //GetLocalTime(MyTime);
  DateTimeToSystemTime(Now(),MyTime);
  ShowTime(@timebuf,PackTime(MyTime));

  Lock:=true;

  Root:=BuildTree(log,b1);

  if Root<>nil then
  begin
    Resort(Root,stArtist);
    Lock:=false;

    size:=ReadTemplate(template,TmplBuf);
    ptr:=TmplBuf;

    AssignFile(fout,report);
    Rewrite(fout);
    if IOResult<>0 then
      exit;
    mGetMem(outbuf,bufsize);
    outpos:=outbuf;

    i:=0;
    k:=0;
    for j:=0 to Root^.Count-1 do
    begin
      inc(k);
      with Root^.Cells[j]^ do
        inc(i,Length*Count);
    end;
    IntToTime(PAnsiChar(@tt),i); // total time
    IntToStr (PAnsiChar(@tf),k); // total files
    
    lsortmode:=stDate;
    while (ptr-TmplBuf)<size do
    begin
      while (ptr^<>'%') and (ptr^<>#0) do
        OutChar(ptr);
      if ptr^=#0 then break;
      if StrCmp(ptr,'%block_',7)=0 then
      begin
        if ptr>@TmplBuf then
        begin
          if (ptr-1)^<' ' then
            k:=-1;
        end;
        inc(ptr,7);
        if StrCmp(ptr,'end%',4)=0 then
        begin
          i:=4;
        end
        else if StrCmp(ptr,'freqartist%',11)=0 then
        begin
          lsortmode:=stArtist;
          i:=11;
        end
        else if StrCmp(ptr,'freqsongs%',10)=0 then
        begin
          lsortmode:=stCount;
          i:=10;
        end
        else if StrCmp(ptr,'freqalbum%',10)=0 then
        begin
          lsortmode:=stAlbum;
          i:=10;
        end
        else if StrCmp(ptr,'lastsongs%',10)=0 then
        begin
          lsortmode:=stDate;
          i:=10;
        end
        else if StrCmp(ptr,'songtime%',9)=0 then
        begin
          lsortmode:=stLength;
          i:=9;
        end
        else if StrCmp(ptr,'freqpath%',9)=0 then
        begin
          lsortmode:=stPath;
          i:=9;
        end
        else
        begin
          OutChar(ptr);
          continue;
        end;
        inc(ptr,i);
        if k<0 then
        begin
          while (ptr^<' ') and (ptr^<>#0) do inc(ptr);
          k:=0;
        end;
        if (ReportMask and lsortmode)=0 then
        begin
          tmp:=StrPos(ptr,'%block_end%');
          if tmp<>nil then
            ptr:=tmp+11
          else
            break;
        end;
      end
      else if StrCmp(ptr,'%start%',7)=0 then
      begin
        if ptr>@TmplBuf then
        begin
          if (ptr-1)^<' ' then
            k:=-1;
        end;
        inc(ptr,7);
        if k<0 then
        begin
          while (ptr^<' ') and (ptr^<>#0) do inc(ptr);
          k:=0;
        end;
        OutputBlock(ptr,Root,lsortmode);
      end
      else if StrCmp(ptr,'%currenttime%',13)=0 then
      begin
        inc(ptr,13);
        OutStr(timebuf);
      end
      else if StrCmp(ptr,'%totalfiles%',12)=0 then
      begin
        inc(ptr,12);
        OutStr(tf);
      end
      else if StrCmp(ptr,'%totaltime%',11)=0 then
      begin
        inc(ptr,11);
        OutStr(tt);
      end
      else
        OutChar(ptr);
    end;
    BlockWrite(fout,outbuf^,outpos-outbuf);
    CloseFile(fout);
    mFreeMem(outbuf);
    mFreeMem(TmplBuf);
    ClearStatCells(Root);
    result:=true;
  end;
  mFreeMem(b1);
end;

// --------------- service functions -----------------

function AddToLog(alog:PAnsiChar; Info:UIntPtr):integer;
var
  log:array [0..511] of AnsiChar;
begin
  result:=0;
  if (StatName=nil) or (StatName[0]=#0) then
    exit;
  if alog=nil then
    alog:=StatName;

  StrCopy(log,alog);
//!!  ConvertFileName(fname,@log);
//  CallService(MS_UTILS_PATHTOABSOLUTE,twparam(fname),tlparam(@log));
  AppendStat(log,Info);
end;

//---

function ThPackLog(param:pointer):ptrint;
begin
  SortLog(PAnsiChar(param),SortMode,Direction);
  result:=0;
end;

function PackLog(alog:PAnsiChar; inthread:boolean=false):integer;
begin
  if inthread then
    result:=BeginThread(@ThPackLog, alog)
  else
    result:=ThPackLog(alog);
end;

//---

function MakeReport(alog:PAnsiChar; areport:PAnsiChar; atmpl:PAnsiChar=nil):integer;
var
  report,log,template:array [0..511] of AnsiChar;
//  l,r:PAnsiChar;
begin
  result:=0;

//??  if atmpl  =nil then atmpl  :=TmplName;
//??  if areport=nil then areport:=ReportName;
//??  if alog   =nil then alog   :=StatName;

  if      (areport=nil) or (areport^=#0) then err('Report file name not defined')
  else if (alog   =nil) or (alog   ^=#0) then err('Log file name not defined')
  else
  begin
//!!    ConvertFileName(r,@report);
//!!    ConvertFileName(l,@template);
//!!    ConvertFileName(StatName,@log);
StrCopy(report,areport);
StrCopy(template,atmpl);
StrCopy(log,StatName);
//    CallService(MS_UTILS_PATHTOABSOLUTE,twparam(r),tlparam(@report));
//    CallService(MS_UTILS_PATHTOABSOLUTE,twparam(l),tlparam(@template));
//    CallService(MS_UTILS_PATHTOABSOLUTE,twparam(StatName),tlparam(@log));
    if DoAddExt<>0 then
      ChangeExt(report,'htm');

    if StatOut(report,log,template) then
    begin
      if DoRunReport<>0 then
      begin
//!!!!        ShellExecuteA(0,nil{'open'},report,nil,nil,SW_SHOWNORMAL);
      end;
      result:=1;
    end
    else
      err('Oops, something wrong!');
  end;
end;


end.
