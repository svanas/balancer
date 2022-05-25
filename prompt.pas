unit prompt;

interface

uses
  // web3
  web3;

function privateKey(&public: TAddress): TPrivateKey;

implementation

uses
  // Delphi
  System.SysUtils,
  // FireMonkey
  FMX.Dialogs,
  // web3
  web3.eth.types,
  web3.utils,
  // Project
  error,
  thread;

function privateKey(&public: TAddress): TPrivateKey;
resourcestring
  RS_PRIVATE_KEY_IS_INVALID = 'Private key is invalid.';
begin
  Result := '';

  var &private: TPrivateKey;
  thread.synchronize(procedure
  begin
    &private := TPrivateKey(Trim(InputBox(string(&public), 'Please paste your private key', '')));
  end);

  if &private = '' then
    EXIT;
  if (
    (not web3.utils.isHex('', string(&private)))
  or
    (Length(&private) <> SizeOf(TPrivateKey) - 1)) then
  begin
    error.show(RS_PRIVATE_KEY_IS_INVALID);
    EXIT;
  end;

  &private.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
    begin
      error.show(err.Message);
      &private := '';
    end;
    if string(addr).ToUpper <> string(&public).ToUpper then
    begin
      error.show(RS_PRIVATE_KEY_IS_INVALID);
      &private := '';
    end;
  end);

  Result := &private;
end;

end.
