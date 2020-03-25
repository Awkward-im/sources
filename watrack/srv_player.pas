{player service}
{$include compilers.inc}
unit srv_player;

interface

//----- Dynamic player info -----
(*
type
  pPlayerInfo = ^tPlayerInfo;
  tPlayerInfo = record
    WindowTitle  :array [0..1023] of AnsiChar;
    VersionString:array [0..  63] of AnsiChar;
    PlayerWindow :THANDLE;
{$IFDEF Windows}
    WinampWindow :THANDLE;
{$ENDIF}
    VersionNumber:cardinal;
    Volume       :cardinal;
    TrackPosition:cardinal;
    PlayerStatus :integer;
  end;
*)
//----- Static player info -----

type
  tCheckProc   = function (wnd:THANDLE; aflags:cardinal):THANDLE;
  tInitProc    = function (doInit:longbool):UIntPtr;
  tStatusProc  = function (wnd:THANDLE):integer;
  tNameProc    = procedure(Info:UIntPtr; aflags:cardinal);
  tInfoProc    = function (Info:UIntPtr; aflags:cardinal):integer;
  tCommandProc = function (wnd:THANDLE; command:integer; value:IntPtr):IntPtr;

  pPlayerCell = ^tPlayerCell;
  tPlayerCell = record
    Check    :pointer;    // tCheckProc;   check player
    Init     :pointer;    // tInitProc;    can be NIL. initialize/finalize any player things
    GetStatus:pointer;    // tStatusProc;  can be NIL. get player status
    GetName  :pointer;    // tNameProc;    can be NIL. get media filename
    GetInfo  :pointer;    // tInfoProc;    can be NIL. get track info from player
    Command  :pointer;    // tCommandProc; can be NIL. send command to player
    Desc     :PAnsiChar;  // Short player name
    URL      :PAnsiChar;  // only if WAT_OPT_HASURL flag present
    Notes    :PAnsiChar;  // any tips, notes etc for this player
    Group    :integer;    // player cathegory (namespace)
    Flags    :cardinal;
  end;

// miranda-style function for new player registering
function ServicePlayer(code:cardinal;data:pointer):IntPtr;

type
  TMusEnumProc = function(param:PAnsiChar;alParam:pointer):boolean;stdcall;

function EnumPlayers(param:TMusEnumProc;alParam:pointer;filtered:boolean=false):longbool;
function GetActivePlayer:pPlayerCell;

function SendCommand(awParam:UIntPtr;alParam:UIntPtr;flags:cardinal):integer;

//----- additional functions -----

{
  Delete templates only (for template file change?)
}
procedure DeleteTemplates;

function LoadFromFile(fname:PAnsiChar; const ns:PAnsiChar=nil):integer;

function GetPlayerNote(const name:PAnsiChar):PAnsiChar;

//----- Player Groups -----

function  GetPlayerGroup(const name:PAnsiChar):PAnsiChar;
function  GetGroupStatus(idx:integer; var agroup:PAnsiChar; var astatus:integer):boolean;
procedure SetGroupStatus(agroup:PAnsiChar; astatus:integer);
procedure ResortGroups;

//----- Handle related -----
{
  Returns player window handle ('winamp' window if found)
}
function CheckAllPlayers(aflags:cardinal; out status:integer; out PlayerChanged:boolean):THANDLE;

function GetPlayerWindowText(pl:pPlayerCell; wnd:THANDLE):AnsiString;

//----- init/free procedures -----

procedure ClearPlayers;

type
  pwPlayer = ^twPlayer;
  twPlayer = record
    This:pPlayerCell;
    Next:pwPlayer;
  end;

const
  PlayerLink:pwPlayer=nil;
  
function ProcessPlayerLink:integer;


//=================== implementation =====================

implementation

uses
{$IFDEF Windows}
  windows,
  appcmdapi,
  syswin,
  wrapper,
  winampapi,
{$ENDIF}
  wat_api,
  common,
  simplelist,
  cmemini;

const
  TextOptions:array [0..5] of record
    name:PAnsiChar;
    flag:cardinal;
  end = (
    (name:'one'       ; flag:WAT_OPT_ONLYONE),
    (name:'winampapi' ; flag:WAT_OPT_WINAMPAPI),
    (name:'last'      ; flag:WAT_OPT_LAST),
    (name:'first'     ; flag:WAT_OPT_FIRST),
    (name:'singleinst'; flag:WAT_OPT_SINGLEINST),
    (name:'appcommand'; flag:WAT_OPT_APPCOMMAND)
  );
{
const
  DefaultNS = 'Player';
}
type
  pTmplCell = ^tTmplCell;
  tTmplCell = record
    p_class,
    p_text   :PAnsiChar;
    p_class1,
    p_text1  :PAnsiChar;
    p_file   :PAnsiChar;
    p_prefix :PAnsiChar;
    p_postfix:PAnsiChar;
  end;

var
  plyLink:TSimpleList;

const
  TmplFileCache:array of pINIFile = nil;

  PlayerGroups:array of record
    name  :PAnsiChar;
    status:integer;
  end = nil;

//----- Support functions -----

procedure PreProcess; // BASS to start
var
  i:integer;
begin
  i:=1;
  while i<plyLink.Count-1 do
  begin
    if (PPlayercell(plyLink.Items[i])^.flags and WAT_OPT_FIRST)<>0 then
    begin
      plyLink.ToTop(i);

      break;
    end;
    inc(i);
  end;

  if (PPlayerCell(plyLink.Items[0])^.flags and WAT_OPT_LAST)<>0 then
    plyLink.ToBottom(0);
end;

procedure PostProcess; // Winamp clone to the end
var
  i,j:integer;
begin
  i:=1;
  j:=plyLink.Count-1;
  while i<j do
  begin
    if (PPlayerCell(plyLink.Items[i])^.flags and WAT_OPT_LAST)<>0 then
    begin
      plyLink.ToBottom(i);
//??      i:=1;
      dec(j);
      continue;
    end;
    inc(i);
  end;
end;

function FindPlayer(desc:PAnsiChar):integer;
var
  i:cardinal;
begin
  if (desc<>nil) and (desc^<>#0) then
  begin
    i:=0;
    while i<plyLink.Count do
    begin
      if StrCmp{lstrcmpia}(PPlayerCell(plyLink.Items[i])^.Desc,desc)=0 then //!!
//      if AnsiCompareText(PPlayerCell(plyLink[i])^.Desc,desc)=0 then //??
      begin
        result:=i;
        exit;
      end;
      inc(i);
    end;
  end;
  result:=WAT_RES_NOTFOUND;
end;

//----- Group functions -----

function GetGroupIdxByOrder(anorder:integer):integer;
var
  i:integer;
begin
  for i:=0 to High(PlayerGroups) do
    if ABS(PlayerGroups[i].status)=anorder then
    begin
      result:=i;
      exit;
    end;
  result:=-1;
end;

function GetPlayerGroup(const name:PAnsiChar):PAnsiChar;
var
  i:integer;
begin
  i:=FindPlayer(name);
  if i>=0 then
    result:=PlayerGroups[PPlayerCell(plyLink.Items[i])^.Group].name
  else
    result:=nil;
end;

function CheckPlayerGroup(desc:PAnsiChar; grouponly:boolean=false):integer;
var
  lgroup:array [0..255] of AnsiChar;
  p:PAnsiChar;
  i:integer;
begin
  if not grouponly then
  begin
    p:=StrScan(desc,':');
    if p=nil then
    begin
      result:=0;
      exit;
    end;
    StrCopy(lgroup,desc,p-desc);
  end
  else
    StrCopy(lgroup,desc);

  for i:=0 to High(PlayerGroups) do
  begin
    if StrCmp(lgroup,PlayerGroups[i].name)=0 then
    begin
      result:=i;
      exit;
    end;
  end;
  result:=Length(PlayerGroups);
  SetLength(PlayerGroups,result+1);
  with PlayerGroups[result] do
  begin
    StrDup(name,lgroup);
    status:=255;
  end;
end;

function GetGroupStatus(idx:integer; var agroup:PAnsiChar; var astatus:integer):boolean;
begin
  if idx>=Length(PlayerGroups) then
  begin
    result:=false;
    exit;
  end;
  result:=true;
  with PlayerGroups[GetGroupIdxByOrder(idx+1)] do //!!
  begin
    agroup :=name;
    astatus:=status;
  end;
end;

procedure SetGroupStatus(agroup:PAnsiChar; astatus:integer);
var
  idx:integer;
begin
  idx:=CheckPlayerGroup(agroup,true);
  PlayerGroups[idx].status:=astatus;
end;

procedure ResortGroups;
var
  i,j,minval,curmin:integer;
begin
  for i:=0 to High(PlayerGroups) do
    PlayerGroups[i].status:=PlayerGroups[i].status*100;

  minval:=1;
  for j:=0 to High(PlayerGroups) do
  begin
    //search for minimal order
    curmin:=-1;
    for i:=0 to High(PlayerGroups) do
    begin
      if (ABS(PlayerGroups[i].status)>minval) then // not changed
      begin
        if (curmin<0) or
           (ABS(PlayerGroups[i].status)<ABS(PlayerGroups[curmin].status)) then
        begin
          curmin:=i;
        end;
      end;
    end;
    // keep sign
    if curmin>=0 then
    begin
      with PlayerGroups[curmin] do
      begin
        if status>0 then
          status:=minval
        else
          status:=-minval;
      end;
      inc(minval);
    end;
  end;
  PreProcess;
  PostProcess;
end;

//----- public functions -----

function GetActivePlayer:pPlayerCell; {$IFDEF AllowInline}inline;{$ENDIF}
begin
  result:=plyLink.Items[0];
end;

function EnumPlayers(param:TMusEnumProc;alParam:pointer;filtered:boolean=false):longbool;
var
  tmpa:TSimpleList;
  i:integer;
  gorder,lgroup:integer;
  b:boolean;
begin
  if (plyLink.Count>0) and (@param<>nil) then
  begin
    tmpa.Init(SizeOf(TPlayerCell));
    tmpa.AddList(plyLink);

    if filtered then
    begin
      b:=true;
      //?? or keep player order just by group, not group order?
      for gorder:=1 to Length(PlayerGroups) do
      begin
        lgroup:=GetGroupIdxByOrder(gorder);
        if PlayerGroups[lgroup].status>0 then
        begin
          for i:=0 to tmpa.Count-1 do
          begin
            if PPlayerCell(tmpa.Items[i])^.Group=lgroup then
              b:=param(PPlayerCell(tmpa.Items[i])^.Desc,alParam);
            if not b then break;
          end;
        end;
        if not b then break;
      end;
    end
    else
    begin
      for i:=0 to tmpa.Count-1 do
        if not param(PPlayerCell(tmpa.Items[i])^.Desc,alParam) then break;
    end;

    tmpa.Free;
    result:=true;
  end
  else
    result:=false;
end;

function GetPlayerNote(const name:PAnsiChar):PAnsiChar;
var
  i:integer;
begin
  i:=FindPlayer(name);
  if i>=0 then
    result:=PPlayerCell(plyLink.Items[i])^.Notes
  else
    result:=nil;
end;

//----- Templates -----

procedure ClearTemplate(var tmpl);
begin
  FreeMem(pTmplCell(tmpl));
end;

procedure DeleteTemplates;
var
  i:integer;
begin
  i:=plyLink.Count;
  while i>0 do
  begin
    dec(i);
    with PPlayerCell(plyLink.Items[i])^ do
    begin
      if (flags and WAT_OPT_TEMPLATE)<>0 then
        ServicePlayer(WAT_ACT_UNREGISTER,Desc);
    end;
  end;
end;

function TextToOption(astr:PAnsiChar):cardinal;
var
  i:integer;
begin
  result:=StrToInt(astr);
  for i:=0 to High(TextOptions) do
    if StrPos(astr,TextOptions[i].name)<>nil then
      result:=result or TextOptions[i].flag;
end;

function LoadFromFile(fname:PAnsiChar; const ns:PAnsiChar=nil):integer;
var
  ptr:PAnsiChar;
  NumPlayers:integer;
  pcell:pTmplCell;
  rec:TPlayerCell;
  lini:pINIFile;
  sec:pINISection;
  i:integer;
begin
  result:=0;
  lini:=nil;

  for i:=0 to High(TmplFileCache) do
  begin
    if StrCmp(TmplFileCache[i]^.FileName,fname)=0 then
    begin
      exit;
{ reload old
      lini:=TmplFileCache[i];
      break;
}
    end;
  end;

  if lini=nil then
  begin
    lini:=CreateIniFile(fname,ns<>nil);
    if lini=nil then exit;
    SetLength(TmplFileCache,Length(TmplFileCache)+1);
    TmplFileCache[High(TmplFileCache)]:=lini;
  end;

  ptr:=lini^.SectionList[ns];

  NumPlayers:=0;
  if ptr<>nil then
    while ptr^<>#0 do
    begin
      sec:=lini^.Section[ns,ptr];
      FillChar(rec,SizeOf(rec),0);

      GetMem  (pcell ,SizeOf(tTmplCell));
      FillChar(pcell^,SizeOf(tTmplCell),0);

      pcell^.p_class  :=sec^.Key['class' ];
      pcell^.p_text   :=sec^.Key['text'  ];
      pcell^.p_class1 :=sec^.Key['class1'];
      pcell^.p_text1  :=sec^.Key['text1' ];
      pcell^.p_file   :=sec^.Key['file'  ];
      pcell^.p_prefix :=sec^.Key['prefix' ];
      pcell^.p_postfix:=sec^.Key['postfix'];

//      rec.flags:=sec^.ReadInt('flags') or WAT_OPT_TEMPLATE;
      rec.flags:=TextToOption(sec^.Key['flags']) or WAT_OPT_TEMPLATE;
      rec.Check:=pointer(pcell);
      rec.Desc :=sec^.Name;
      rec.URL  :=sec^.Key['url'];
      rec.Notes:=sec^.Key['notes'];

      if ServicePlayer(WAT_ACT_REGISTER,@rec)=WAT_RES_ERROR then
      begin
        ClearTemplate(pcell);
      end
      else
        inc(NumPlayers);

      while ptr^<>#0 do inc(ptr);
      inc(ptr);
    end;

  result:=NumPlayers;
end;

{$IFDEF Windows}
{
const
  nCount = 1024;
const
  ProcessList:array of dword = nil;
  ProcNameLst:array of array [0..255] of AnsiChar = nil;

function CheckByName(afile:PAnsiChar):THANDLE;
var
  exename:array [0..127] of AnsiChar;
  pc:PAnsiChar;
  i,len:integer;
begin
  result:=INVALID_HANDLE_VALUE;

  // initialize (allocate and clear)
  if Length(ProcessList)=0 then
  begin
    SetLength(ProcessList,nCount);
    EnumProcesses(pointer(@Processes[0]),nCount*SizeOf(dword),nProcess);
    nProcess:=(nProcess div SizeOf(dword));
    SetLength(ProcNameLst,nProcess);
    FillChar(ProcNameLst[0],nProcess*256,0);
  end;

  // upcase source fname
  i:=0;
  len:=StrLen(afile);
  while i<len do
  begin
    exename[i]:=UpCase(afile[i]);
    inc(i);
  end;
  exename[i]:=#0;

  // skip Idle & System
  for i:=2 to nProcess-1 do
  begin
    pc:=@ProcNameLst[i][0];
    // read process file name for unreaded before (really, must be all)
    if pc^=#0 then
    begin
      hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessList[i]);
      if hProcess<>0 then
      begin
//        GetModuleFilenameEx(hProcess,0,@ProcNameLst[i],255);
        GetProcessImageFileNameA(hProcess,pc,255);
        CloseHandle(hProcess);

        // skip and remember system processes
        if pc^=#0 then
        begin
          pc^=#1;
          continue;
        end;

        // change to upcase
        len:=StrLen(pc)-1;
        while (len>=0) and not (pc[len] in ['\','/']) do
        begin
          pc[len]:=UpCase(pc[len]);
          dec(len);
        end;
        // keep file name only
        if len>0 then // always
          StrCopy(pc,pc+len);
      end;
    end;

    // check and get window handle
    if pc^>' ' then
    begin
      if StrCmp(pc,exename)=0 then
      begin
        result:=ProcessList[i] //??
        break;
      end;
    end;
  end;

  // finalize (must be outside this function, at the end of check)
  SetLength(ProcessList,0);
  SetLength(ProcessNameList,0);
end;
}
function CheckTmpl(lwnd:THANDLE; cell:pTmplCell; flags:cardinal):THANDLE;
var
  lEXEName:PAnsiChar;
  tmp:PAnsiChar;
  lclass,ltext:PAnsiChar;
  ltmp,lcycle:boolean;
begin
  lclass:=cell^.p_class;
  ltext :=cell^.p_text;
  lcycle:=false;
  repeat
    result:=lwnd;
    if (lclass<>nil) or (ltext<>nil) then
      repeat
        result:=FindWindowExA(0,result,lclass,ltext);
        if result=0 then
          break;
//  check filename
        if cell^.p_file<>nil then
        begin
          tmp:=Extract(GetEXEByWnd(result,lEXEName),true);
          mFreeMem(lEXEName);
          ltmp:=lstrcmpia(tmp,cell^.p_file)=0;
//          ltmp:=AnsiCompareFileName(tmp,cell^.p_file)=0;
          mFreeMem(tmp);
          if not ltmp then
            continue;
        end;
        exit;
      until false;
    // repeat for alternative window
    if lcycle then break;
    lclass:=cell^.p_class1;
    ltext :=cell^.p_text1;
    if (lclass=nil) and (ltext=nil) then break;
    lcycle:=not lcycle;
  until false;
end;
{$ELSE}
{$ENDIF}

//----- Init/Free procedures -----

function ServicePlayer(code:cardinal;data:pointer):IntPtr;
var
  p:integer;
  lpc:PPlayerCell;
begin
  result:=WAT_RES_ERROR;

  if Word(code)=WAT_ACT_REGISTER then
  begin
    if PPlayerCell(data)^.Check=nil then
      exit;

    p:=FindPlayer(PPlayerCell(data)^.Desc);
    if (p=WAT_RES_NOTFOUND) or ((code and WAT_ACT_REPLACE)<>0) then
    begin
      if (p<>WAT_RES_NOTFOUND) and
         ((PPlayerCell(plyLink.Items[p])^.flags and WAT_OPT_ONLYONE)<>0) then
        exit;

      if p=WAT_RES_NOTFOUND then
      begin
        result:=WAT_RES_OK;
        p:=plyLink.Add(data);
        
        with PPlayerCell(plyLink.Items[p])^ do
        begin
          Group:=CheckPlayerGroup(Desc,false);
          if (flags and (WAT_OPT_TEMPLATE or WAT_OPT_INTERNAL))=0 then
          begin
            StrDup(Notes,Notes);
            StrDup(Desc ,Desc);
            StrDup(URL  ,URL);
          end;
        end;
      end

      else // existing player
      begin
        lpc:=PPlayerCell(plyLink.Items[p]);

        if (lpc^.flags and WAT_OPT_TEMPLATE)=0 then
          result:=IntPtr(@lpc^.Check)
        else
        begin // remove any info from templates
          result:=WAT_RES_OK;
          ClearTemplate(lpc^.Check);
        end;

        plyLink.Items[p]:=data;
      end;

      // fill info
      with PPlayerCell(plyLink.Items[p])^ do
      begin
        if URL<>nil then
          flags:=flags or WAT_OPT_HASURL;
        if Init<>nil then
          tInitProc(Init)(true);
      end;

//        PreProcess;
      PostProcess;
    end;
  end
  else
  begin
    p:=FindPlayer(data);
    if p<>WAT_RES_NOTFOUND then
      case Word(code) of
        WAT_ACT_UNREGISTER: begin
          lpc:=PPlayerCell(plyLink.Items[p]);

          if lpc^.Init<>nil then
            tInitProc(lpc^.Init)(false);

          if (lpc^.flags and WAT_OPT_TEMPLATE)<>0 then
            ClearTemplate(lpc^.Check)
          else if (lpc^.flags and WAT_OPT_INTERNAL)=0 then
          begin
            mFreeMem(lpc^.Notes);
            mFreeMem(lpc^.Desc);
            mFreeMem(lpc^.URL);
          end;

          plyLink.Delete(p);

          result:=WAT_RES_OK;
        end;

        WAT_ACT_DISABLE: begin
          // SetFlag(PPlayerCell(plyLink[p])^.flags, WAT_OPT_DISABLED);
          PPlayerCell(plyLink.Items[p])^.flags:=PPlayerCell(plyLink.Items[p])^.flags or WAT_OPT_DISABLED;
          result:=WAT_RES_DISABLED;
        end;

        WAT_ACT_ENABLE: begin
          // ClearFlag(PPlayerCell(plyLink[p])^.flags, WAT_OPT_DISABLED);
          PPlayerCell(plyLink.Items[p])^.flags:=PPlayerCell(plyLink.Items[p])^.flags and not WAT_OPT_DISABLED;
          result:=WAT_RES_ENABLED;
        end;

        WAT_ACT_GETSTATUS: begin
          if (PPlayerCell(plyLink.Items[p])^.flags and WAT_OPT_DISABLED)<>0 then
            result:=WAT_RES_DISABLED
          else
            result:=WAT_RES_ENABLED;
        end;

        WAT_ACT_SETACTIVE: begin
          if p>0 then
            plyLink.ToTop(p);
    //      PreProcess;
    //      PostProcess;
        end;

      end;

  end;
end;

function ProcessPlayerLink:integer;
var
  lptr:pwPlayer;
begin
  result:=0;
  CheckPlayerGroup('built-in',true);
  plyLink.Init(SizeOf(TPlayerCell));
  lptr:=PlayerLink;
  while lptr<>nil do
  begin
    lptr^.This^.flags:=lptr^.This^.flags or WAT_OPT_INTERNAL;
    ServicePlayer(WAT_ACT_REGISTER,lptr^.This);
    lptr:=lptr^.Next;
    inc(result);
  end;
end;

procedure ClearPlayers;
var
  i:cardinal;
begin
  for i:=0 to plyLink.Count-1 do
  begin
    with PPlayerCell(plyLink.Items[i])^ do
    begin
      if Init<>nil then
        tInitProc(Init)(false);
      if (flags and (WAT_OPT_INTERNAL or WAT_OPT_TEMPLATE))=0 then
      begin
        mFreeMem(Desc);
        mFreeMem(URL);
        mFreeMem(Notes);
      end
      else if (flags and WAT_OPT_TEMPLATE)<>0 then
        ClearTemplate(Check);
    end;
  end;
  plyLink.Free;

  for i:=0 to High(TmplFileCache) do
    FreeIniFile(TmplFileCache[i]);
  SetLength(TmplFileCache,0);

  for i:=0 to High(PlayerGroups) do
    mFreeMem(PlayerGroups[i]);
  SetLength(PlayerGroups,0);
end;

//----- Active player search -----

// find active player
function CheckAllPlayers(aflags:cardinal;out status:integer; out PlayerChanged:boolean):THANDLE;
var
  wwnd,lwnd:THANDLE;
  stat,act,oldstat,j:integer;
  gorder,gidx:integer;
  i:cardinal;
begin
  result:=THANDLE(WAT_RES_NOTFOUND);

  PlayerChanged:=true;
  PreProcess;
  oldstat:=-1;
  act:=-1;
  // for case when no any player enabled/registered
  stat:=WAT_PLS_UNKNOWN;
  wwnd:=0;

  for gorder:=1 to Length(PlayerGroups) do
  begin
    gidx:=GetGroupIdxByOrder(gorder);
    if PlayerGroups[gidx].status<0 then continue;

    i:=0;
    //!! Read processes to buffer
    while i<plyLink.Count do
    begin
      if (PPlayerCell(plyLink.Items[i])^.Group=gidx) and
        ((PPlayerCell(plyLink.Items[i])^.flags and WAT_OPT_DISABLED)=0) then
      begin

        lwnd:=0;
        repeat
          wwnd:=0;
          stat:=WAT_PLS_UNKNOWN;

          with PPlayerCell(plyLink.Items[i])^ do
          begin
            if (flags and WAT_OPT_TEMPLATE)<>0 then // template player
  {$IFDEF Windows} //!!!!
              lwnd:=CheckTmpl(lwnd,Check,flags)
  {$ENDIF}
            else                                    // separate processing
              lwnd:=tCheckProc(Check)(lwnd,flags);
          end;

          // player window found
          if (lwnd<>THANDLE(WAT_RES_NOTFOUND)) and (lwnd<>0) then
          begin
            with PPlayerCell(plyLink.Items[i])^ do
            begin
              if ((flags and WAT_OPT_TEMPLATE)=0) and (GetStatus<>nil) then
              begin
                stat:=tStatusProc(GetStatus)(lwnd);
              end
              else
              begin
  {$IFDEF Windows}
                if (flags and WAT_OPT_WINAMPAPI)<>0 then
                begin
                  wwnd:=WinampFindWindow(lwnd);
                  if wwnd<>0 then
                    stat:=WinampGetStatus(wwnd);
                end;
  {$ENDIF}
              end;
            end;

            if (stat=WAT_PLS_PLAYING) or ((aflags and WAT_OPT_CHECKALL)=0) then
            begin
              act   :=i;
              result:=lwnd;
              break;
            end
            else
            begin
              case stat of
                WAT_PLS_STOPPED: j:=00;
                WAT_PLS_UNKNOWN: j:=10;
                WAT_PLS_PAUSED : j:=20;
              else
                j:=00;
              end;
              if oldstat<j then
              begin
                oldstat:=j;
                act    :=i;
                result :=lwnd;
              end;
            end;
          end
          else
            break;

          if (PPlayerCell(plyLink.Items[i])^.flags and WAT_OPT_SINGLEINST)<>0 then
            break;

        until false;

        if (result<>THANDLE(WAT_RES_NOTFOUND)) and (result<>0) and
           ((stat=WAT_PLS_PLAYING) or ((aflags and WAT_OPT_CHECKALL)=0)) then
          break;
      end;
      inc(i);
    end;
    //!! Free process buffer
  end;

  // hmm, we found player
  if act>=0 then
  begin
    if result=1 then result:=0 //!! for example, mradio
    else if wwnd<>0 then
      result:=wwnd;

    if act>0 then // to first position
      plyLink.ToTop(act)
    else
      PlayerChanged:=false;

    status:=stat;
  end
  else
  begin
    status:=WAT_PLS_NOTFOUND;
  end;

  PostProcess;
end;

function GetPlayerWindowText(pl:PPlayerCell; wnd:THANDLE):AnsiString;
var
{$IFDEF Windows}
  res:PAnsiChar;
{$ENDIF}
  i:integer;
begin
  if wnd<>0 then
  begin
{$IFDEF Windows}
// Wrapper
    res:=GetDlgText(wnd);
    result:=res;
    mFreeMem(res);
{$ELSE}
    result:='';
{$ENDIF}
    if result<>'' then
    begin
      if (pl^.flags and WAT_OPT_TEMPLATE)<>0 then
      begin
        with pTmplCell(pl^.Check)^ do
        begin

          if p_prefix<>nil then
          begin
            i:=Pos(p_prefix,result);
            if i=1 then
              Delete(result,1,Length(p_prefix));
          end;

          if p_postfix<>nil then
          begin
            i:=Pos(p_postfix,result);
            if i<>0 then
              SetLength(result,i-1);
          end;
        end;
      end;
    end;
{
    if result<>nil then
    begin
      if (pl^.flags and WAT_OPT_TEMPLATE)<>0 then
      begin
        with pTmplCell(pl^.Check)^ do
        begin
          if p_prefix<>nil then
          begin
            p:=StrPosW(result,p_prefix);
            if p=result then
              StrCopyW(result,result+StrLenW(p_prefix));
          end;
          if p_postfix<>nil then
          begin
            p:=StrPosW(result,p_postfix);
            if p<>nil then
              p^:=#0;
          end;
        end;
      end;
    end;
}
  end
  else
    result:='';
end;

//----- Send command to player -----

{$IFDEF Windows}
function TranslateToApp(code:integer):integer;
begin
  case code of
    WAT_CTRL_PREV : result:=APPCOMMAND_MEDIA_PREVIOUSTRACK;
    WAT_CTRL_PLAY : result:=APPCOMMAND_MEDIA_PLAY_PAUSE;
    WAT_CTRL_PAUSE: result:=APPCOMMAND_MEDIA_PLAY_PAUSE;
    WAT_CTRL_STOP : result:=APPCOMMAND_MEDIA_STOP;
    WAT_CTRL_NEXT : result:=APPCOMMAND_MEDIA_NEXTTRACK;
    WAT_CTRL_VOLDN: result:=APPCOMMAND_VOLUME_DOWN;
    WAT_CTRL_VOLUP: result:=APPCOMMAND_VOLUME_UP;
  else
    result:=-1;
  end;
end;
{$ENDIF}

function SendCommand(awParam:UIntPtr; alParam:UIntPtr; flags:cardinal):integer;
var
  dummy:boolean;
  wnd:THANDLE;
  lstat:integer;
  curpl:pPlayerCell;
begin
  result:=WAT_RES_ERROR;
  wnd:=CheckAllPlayers(flags,lstat,dummy);
  if wnd<>THANDLE(WAT_RES_NOTFOUND) then
  begin
    curpl:=GetActivePlayer;
    if curpl^.Command<>nil then
      result:=tCommandProc(curpl^.Command)(wnd,awParam,alParam)
{$IFDEF Windows}
    else if (curpl^.flags and WAT_OPT_WINAMPAPI)<>0 then
      result:=WinampCommand(wnd,UIntPtr(awParam)+(alParam shl 16))

    else if (flags and WAT_OPT_APPCOMMAND)<>0 then
    begin
      result:=TranslateToApp(awParam);
      if result>=0 then
        result:=SendMMCommand(wnd,result);
    end;
{$ENDIF}
  end;
end;

end.
