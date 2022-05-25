unit error;

interface

uses
  // web3
  web3;

procedure show(const msg: string); overload;
procedure show(chain: TChain; const err: IError); overload;

implementation

uses
  // Delphi
  System.SysUtils,
  System.UITypes,
  // FireMonkey
  FMX.Dialogs,
  // web3
  web3.eth.tx,
  // Project
  open,
  thread;

procedure show(const msg: string);
begin
  thread.synchronize(procedure
  begin
    MessageDlg(msg, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
  end);
end;

procedure show(chain: TChain; const err: IError);
begin
  if Supports(err, ISignatureDenied) then
    EXIT;
  thread.synchronize(procedure
  var
    txError: ITxError;
  begin
    if Supports(err, ITxError, txError) then
    begin
      if MessageDlg(
        Format(
          '%s. Would you like to view this transaction on etherscan?',
          [err.Message]
        ),
        TMsgDlgType.mtError, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0
      ) = mrYes then
        open.transaction(chain, txError.Hash);
      EXIT;
    end;
    MessageDlg(err.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
  end);
end;

end.
