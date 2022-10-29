program balancer;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'main.pas' {frmMain},
  delay in 'delay.pas',
  thread in 'thread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
