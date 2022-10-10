program balancer;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'main.pas' {frmMain},
  delay in 'delay.pas',
  error in 'error.pas',
  open in 'open.pas',
  prompt in 'prompt.pas',
  thread in 'thread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
