unit open;

interface

uses
  // web3
  web3;

procedure transaction(chain: TChain; tx: TTxHash);

implementation

uses
{$IFDEF MSWINDOWS}
  WinAPI.ShellAPI,
  WinAPI.Windows
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Posix.Stdlib
{$ENDIF POSIX}
  ;

procedure URL(const URL: string);
begin
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  _system(PAnsiChar('open ' + AnsiString(URL)));
{$ENDIF POSIX}
end;

procedure transaction(chain: TChain; tx: TTxHash);
begin
  URL(chain.BlockExplorerURL + '/tx/' + string(tx));
end;

end.
