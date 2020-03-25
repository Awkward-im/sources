uses
  sysutils,
  common,
  wat_api,
  wat_basic,
  wat_template,
  wat_Stat
  ;

var
  buf:array [0..31] of AnsiChar;
  si:UIntPtr;
begin
  if ParamCount()>0 then
  begin
    si:=WATGetFileInfo(ParamStr(1));
    if si=WAT_RES_ERROR then exit;
  end
  else
  begin
    StatName:='log';
    MakeReport('wTrack.tmpl','repo');

    si:=WATCreate();
    if WATGetMusicInfo(si,0)=WAT_RES_NOTFOUND then exit;
  end;
  begin
    writeln(WATReplace(si,'Playing %file% (%artist% - %title% <%album%> [%length%])'));
    writeln('file   : ',WATGetString(si,siFile),' ',WATGet(si,siSize));
    writeln('date   : ',datetimetostr(filedatetodatetime(WATGet(si,siDate))));
    writeln('length : ',WATGet(si,siLength),' [',IntToTime(buf,WATGet(si,siLength)),']');
    writeln('artist : ',WATGetString(si,siArtist),' - ',WATGetString(si,siTitle));
    writeln('bitrate: ',WATGet(si,siBitrate),' / ',WATGet(si,siSamplerate));
    WATFree(si);
  end;
    readln;
end.
