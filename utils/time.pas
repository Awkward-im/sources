unit time;

interface

function DateTimeToMilliseconds(aDateTime: TDateTime): Int64;

implementation

type
   TTimeStamp = record
      Time: longint;   { Number of milliseconds since midnight }
      Date: longint;   { One plus number of days since 1/1/0001 }
   end ;

const
   HoursPerDay = 24;
   MinsPerHour = 60;
   SecsPerMin  = 60;
   MSecsPerSec = 1000;

   MinsPerDay  = HoursPerDay * MinsPerHour;
   SecsPerHour = SecsPerMin * MinsPerHour;
   SecsPerDay  = MinsPerDay * SecsPerMin;
   MSecsPerDay = SecsPerDay * MSecsPerSec;

   JulianEpoch = TDateTime(-2415018.5);
   UnixEpoch = JulianEpoch + TDateTime(2440587.5);

   DateDelta = 693594;        // Days between 1/1/0001 and 12/31/1899
   UnixDateDelta = Trunc(UnixEpoch); //25569

function DateTimeToTimeStamp(DateTime: TDateTime): TTimeStamp;

Var
  D : Double;
begin
  D:=DateTime * Single(MSecsPerDay);
  if D<0 then
    D:=D-0.5
  else
    D:=D+0.5;
  result.Time := Abs(Trunc(D)) Mod MSecsPerDay;
  result.Date := DateDelta + Trunc(D) div MSecsPerDay;
end;

function DateTimeToMilliseconds(aDateTime: TDateTime): Int64;
var
  TimeStamp: TTimeStamp;
begin
  {Call DateTimeToTimeStamp to convert DateTime to TimeStamp:}
  TimeStamp:= DateTimeToTimeStamp (aDateTime);
  {Multiply and add to complete the conversion:}
  Result:= TimeStamp.Time;
end;

end.
-------------------------------
procedure TMyClass.DoSomething;
var
  {$IFDEF VerboseProfiler}
  lTimeStart: TDateTime;
  {$ENDIF}
  ...
begin
  {$IFDEF VerboseProfiler}
  lTimeStart := Now();
  {$ENDIF}

  ReallyDoSomething;

  {$IFDEF VerboseProfiler}
  DebugLn(Format('[TMyClass.DoSomething] Duration: %d ms', [DateTimeToMilliseconds(Now() - lTimeStart)]));
  {$ENDIF}
end;
