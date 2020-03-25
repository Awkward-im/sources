{
<space>.text.
  n_<modulename>_$$ or n_<module>_$_$<class>_$__$$
  _<procname>[$<argtype>][$$<resulttype>] or _<procname>[$<'crc'+8hex>]

<16 spaces><0xadr><? spaces><0xlength> (col=39)<objfile.o>

(interface part presents)
<16 spaces><0xadr><? spaces>(col=43)(caps)_<procname>[$<argtype>][$$<resulttype>]
=aliases

object file, module, class method/function[args] [+alias], start address, length
}

uses
  common,
  Classes;

var
  sl:TStringList;
  s:ansistring;
  addr,len,
  oldfile,objfile,modname:ansistring;
  buf:array [0..31] of AnsiChar;
  i,j,lpos,objsize:integer;
  cnt:integer;
begin
  sl:=TStringList.Create;
  try
    sl.Sorted:=false;
    sl.LoadFromFile(ParamStr(1));
    cnt:=ParamCount;

    i:=0;
    oldfile:='';
    objsize:=0;
    while i<sl.Count do
    begin
      s:=sl.strings[i];

      if Pos('.data',s)=1 then
        break;

      if Pos('.text.',s)=2 then
      begin
        // "header"
        modname:='';

        lpos:=1;

        // modulename
        while not (s[lpos]='$') and (lpos<=Length(s)) do inc(lpos);
        inc(lpos);

        modname:='';

        // '$_$' - class or overload
        if (s[lpos]='_') and (s[lpos+1]='$') then
        begin
          inc(lpos,2);
          repeat
            modname:=modname+s[lpos];
            inc(lpos);

            // '_$_' - end of class
            if (s[lpos]='_') and (s[lpos+1]='$') and (s[lpos+2]='_') then
            begin
              modname:=modname+'.';
              inc(lpos,3);
              if (s[lpos]='_') and (s[lpos+1]='$') then
              begin
                inc(lpos,2);
                break;
              end;
            end
            // overload
            else if s[lpos]='$' then
            begin
              break;
            end;
          until false;
        end;

        // '_$$_' - function name
        if (s[lpos]='$') and (s[lpos+1]='_') then
        begin
          inc(lpos,2);
          repeat
            modname:=modname+s[lpos];
            inc(lpos);
          until (lpos>Length(s)) or (s[lpos]='$');
        end;

        //-- 2nd line: address, length and object file

        inc(i);
        s:=sl.strings[i];

        lpos:=1;
        while s[lpos]<=#32 do inc(lpos);
        // lpos:=17;
        addr:='';
        while s[lpos]>#32 do
        begin
          addr:=addr+s[lpos];
          inc(lpos);
        end;

        // lpos:=28;
        while s[lpos]<=#32 do inc(lpos);
        len :='';
        while s[lpos]>#32 do
        begin
          len:=len+s[lpos];
          inc(lpos);
        end;

        while s[lpos]<=#32 do inc(lpos);
        // lpos:=39
        objfile:='';
        while (s[lpos]>#32) and (lpos<=Length(s)) do
        begin
          objfile:=objfile+s[lpos];
          inc(lpos);
        end;

        //-- 3+ line: public names
        j:=i+1;
        while j<sl.Count do
        begin
          s:=sl.strings[j];

          if s[2]<>' ' then
            break;

          inc(j);
        end;

        if objfile=oldfile then
        begin
          objsize:=objsize+NumToInt(PAnsiChar(len));
        end
        else
        begin
          if oldfile<>'' then
            writeln('size of ',oldfile,' = 0x',IntToHex(buf,objsize));

          oldfile:=objfile;
          objsize:=NumToInt(PAnsiChar(len));
        end;

        if cnt=1 then
          writeln(' ',addr,#9,len,#9,objfile,' ',modname);

        i:=j;
        continue;

      end;

      inc(i);
    end;
    writeln('size of ',oldfile,' = 0x',IntToHex(buf,objsize));

  finally
    sl.Free;
  end;
end.
