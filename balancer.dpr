program balancer;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  main in 'main.pas' {frmMain},
  delay in 'delay.pas',
  thread in 'thread.pas';

{$R *.res}

begin
  GlobalUseMetal := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
