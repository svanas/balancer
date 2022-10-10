unit prompt;

interface

uses
  // web3
  web3;

type
  ICancelled = interface(IError)
  ['{EB6305B0-A310-43ED-A868-8BCB3334B11F}']
  end;
  TCancelled = class(TError, ICancelled)
  public
    constructor Create;
  end;

function privateKey(&public: TAddress): IResult<TPrivateKey>;

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

constructor TCancelled.Create;
begin
  inherited Create('');
end;

function privateKey(&public: TAddress): IResult<TPrivateKey>;
begin
  var &private: TPrivateKey;
  thread.synchronize(procedure
  begin
    &private := TPrivateKey(Trim(InputBox(string(&public), 'Please paste your private key', '')));
  end);

  if &private = '' then
  begin
    Result := TResult<TPrivateKey>.Err('', TCancelled.Create);
    EXIT;
  end;

  if (
    (not web3.utils.isHex('', string(&private)))
  or
    (Length(&private) <> SizeOf(TPrivateKey) - 1)) then
  begin
    Result := TResult<TPrivateKey>.Err('', 'Private key is invalid');
    EXIT;
  end;

  const address = &private.GetAddress;
  if address.IsErr then
  begin
    Result := TResult<TPrivateKey>.Err('', address.Error);
    EXIT;
  end;
  if address.Value.ToChecksum <> &public.ToChecksum then
  begin
    Result := TResult<TPrivateKey>.Err('', 'Private key is invalid');
    EXIT;
  end;

  Result := TResult<TPrivateKey>.Ok(&private);
end;

end.
