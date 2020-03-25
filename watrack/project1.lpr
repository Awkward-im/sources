program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  DefaultTranslator, lazcontrols,
  optMain,
  { you can add units after this }
  srv_format,srv_player,srv_getinfo,
  common,msninfo,syswin,wrapper
  ,wat_api
//  ,optLastFM   in 'lastfm\optlastfm.pas'
  ,optStat     in 'stat\optstat.pas'
  ,optMyShows  in 'myshows\optmyshows.pas'
  ,optTemplate in 'templates\opttemplate.pas'
  ,optBasic
  ;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMainOptForm, OptForm);
  Application.Run;
end.

