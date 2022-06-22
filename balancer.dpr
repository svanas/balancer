program balancer;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'main.pas' {frmMain},
  thread in 'thread.pas',
  error in 'error.pas',
  open in 'open.pas',
  prompt in 'prompt.pas',
  delay in 'delay.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
