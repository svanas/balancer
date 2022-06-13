unit main;

interface

uses
  // Delphi
  System.Classes,
  // FireMonkey
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Edit,
  FMX.EditBox,
  FMX.Forms,
  FMX.ListBox,
  FMX.NumberBox,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
  // web3
  web3,
  web3.eth.balancer.v2,
  web3.eth.tokenlists,
  web3.eth.types,
  // Project
  delay;

type
  TComboBox = class(FMX.ListBox.TComboBox)
  private
    FLastIndex: Integer;
  public
    property LastIndex: Integer read FLastIndex write FLastIndex;
  end;

  TAsset = (AssetIn, AssetOut);

  TAssetGroup = record
  strict private
    cbo: TComboBox;
    lbl: TLabel;
    edt: TNumberBox;
    function  GetAmount: Double;
    procedure SetAmount(Value: Double);
    procedure SetBalance(Value: Double);
    function  GetItemIndex: Integer;
    procedure SetItemIndex(Value: Integer);
  public
    constructor Create(cbo: TComboBox; lbl: TLabel; edt: TNumberBox);
    property Amount: Double read GetAmount write SetAmount;
    property Balance: Double write SetBalance;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    procedure Switch(other: TAssetGroup);
  end;

  TfrmMain = class(TForm)
    btnTrade: TButton;
    cboChain: TComboBox;
    rctAssetIn: TRectangle;
    cboAssetIn: TComboBox;
    lblAssetIn: TLabel;
    rctAssetOut: TRectangle;
    cboAssetOut: TComboBox;
    lblAssetOut: TLabel;
    edtAssetIn: TNumberBox;
    btnSwitch: TCornerButton;
    edtAssetOut: TNumberBox;
    Ethereum: TListBoxItem;
    Kovan: TListBoxItem;
    btnAssetIn: TEditButton;
    edtAddress: TEdit;
    Polygon: TListBoxItem;
    Arbitrum: TListBoxItem;
    SB: TStatusBar;
    lblStatus: TLabel;
    cboSlippage: TComboBox;
    lblSlippage: TLabel;
    halfPercent: TListBoxItem;
    onePercent: TListBoxItem;
    twoPercent: TListBoxItem;
    {----------------------------- event handlers -----------------------------}
    procedure btnTradeClick(Sender: TObject);
    procedure cboChainChange(Sender: TObject);
    procedure cboAssetChange(Sender: TObject);
    procedure btnMaxClick(Sender: TObject);
    procedure edtAssetChange(Sender: TObject);
    procedure edtAddressChange(Sender: TObject);
    procedure btnSwitchClick(Sender: TObject);
  private
    FDelay  : IDelay;
    FKind   : TSwapKind;
    FLockCnt: Integer;
    FTokens : TTokens;
    {------------------------------ Lock/UnLock -------------------------------}
    procedure Lock;
    procedure Unlock;
    function  Locked: Boolean;
    {------------------------------- AssetGroup -------------------------------}
    function  AssetGroup: TAssetGroup; overload;
    function  AssetGroup(Asset: TAsset): TAssetGroup; overload;
    function  AssetGroup(aControl: TControl): TAssetGroup; overload;
    {--------------------------------- Token ----------------------------------}
    function  Token: IToken; overload;
    function  Token(Asset: TAsset): IToken; overload;
    function  Token(aControl: TControl): IToken; overload;
    {-------------------------------- getters ---------------------------------}
    function  GetChain: TChain;
    function  GetClient: IWeb3;
    function  GetEndpoint: string;
    function  GetLimit: BigInteger;
    function  GetMultiplier: Double;
    {-------------------------------- setters ---------------------------------}
    procedure SetKind(Value: TSwapKind);
    procedure SetTokens(Value: TTokens);
    {-------------------------------- updaters --------------------------------}
    procedure UpdateAssets;
    procedure UpdateBalance(Sender: TControl);
    procedure UpdateOtherAmount;
    procedure UpdateStatus;
    {---------------------------------- misc ----------------------------------}
    procedure Address(callback: TAsyncAddress);
    procedure Switch;
  public
    constructor Create(aOwner: TComponent); override;
    property Chain: TChain read GetChain;
    property Client: IWeb3 read GetClient;
    property Endpoint: string read GetEndpoint;
    property Kind: TSwapKind read FKind write SetKind;
    property Tokens: TTokens read FTokens write SetTokens;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  // Delphi
  System.Math,
  System.SysUtils,
  // web3
  web3.eth,
  web3.eth.infura,
  web3.eth.tx,
  web3.utils,
  // Project
  error,
  open,
  prompt,
  thread;

{$I infura.api.key}

{$R *.fmx}

constructor TAssetGroup.Create(cbo: TComboBox; lbl: TLabel; edt: TNumberBox);
begin
  Self.lbl := lbl;
  Self.cbo := cbo;
  Self.edt := edt;
end;

function TAssetGroup.GetAmount: Double;
begin
  Result := edt.Model.ConvertTextToValue(edt.Text);
end;

procedure TAssetGroup.SetAmount(Value: Double);
begin
  edt.Value := Value;
end;

procedure TAssetGroup.SetBalance(Value: Double);
begin
  Self.lbl.Text := Format('Balance: %f', [Value]);
end;

function TAssetGroup.GetItemIndex: Integer;
begin
  Result := Self.cbo.ItemIndex;
end;

procedure TAssetGroup.SetItemIndex(Value: Integer);
begin
  Self.cbo.ItemIndex := Value;
end;

procedure TAssetGroup.Switch(other: TAssetGroup);
begin
  const II = other.ItemIndex;
  other.ItemIndex := Self.ItemIndex;
  Self.ItemIndex := II;
  const LI = other.cbo.LastIndex;
  other.cbo.LastIndex := Self.cbo.LastIndex;
  Self.cbo.LastIndex := LI;
  const V = other.Amount;
  other.Amount := Self.Amount;
  Self.Amount := V;
  const S = other.lbl.Text;
  other.lbl.Text := Self.lbl.Text;
  Self.lbl.Text := S;
end;

{--------------------------------- TfrmMain -----------------------------------}

constructor TfrmMain.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FDelay := delay.Create;

  edtAssetIn.Max  := web3.Infinite.AsDouble;
  edtAssetOut.Max := web3.Infinite.AsDouble;

  cboChainChange(cboChain);
end;

procedure TfrmMain.Address(callback: TAsyncAddress);
begin
  if edtAddress.Text.Length = 0 then
    callback(EMPTY_ADDRESS, nil)
  else
    TAddress.New(Self.Client, edtAddress.Text, callback);
end;

procedure TfrmMain.Switch;
begin
  Self.Lock;
  try
    AssetGroup(AssetIn).Switch(AssetGroup(AssetOut));
    if Self.Kind = GivenIn then
      Self.Kind := GivenOut
    else
      Self.Kind := GivenIn;
  finally
    Self.Unlock;
  end;
end;

{-------------------------------- Lock/Unlock ---------------------------------}

procedure TfrmMain.Lock;
begin
  Inc(FLockCnt);
end;

procedure TfrmMain.Unlock;
begin
  if Self.Locked then Dec(FLockCnt);
end;

function TfrmMain.Locked: Boolean;
begin
  Result := FLockCnt > 0;
end;

{--------------------------------- AssetGroup ---------------------------------}

// returns the AssetGroup having (input) focus
function TfrmMain.AssetGroup: TAssetGroup;
begin
  if Self.Kind = GivenIn then
    Result := Self.AssetGroup(AssetIn)
  else
    Result := Self.AssetGroup(AssetOut);
end;

// returns the AssetGroup for 'AssetIn' or 'AssetOut'
function TfrmMain.AssetGroup(Asset: TAsset): TAssetGroup;
begin
  if Asset = AssetIn then
    Result := TAssetGroup.Create(cboAssetIn, lblAssetIn, edtAssetIn)
  else if Asset = AssetOut then
    Result := TAssetGroup.Create(cboAssetOut, lblAssetOut, edtAssetOut);
end;

// returns the AssetGroup associated with the GUI control
function TfrmMain.AssetGroup(aControl: TControl): TAssetGroup;
begin
  Result := AssetGroup(TAsset(aControl.Tag));
end;

{----------------------------------- Token ------------------------------------}

// returns the Token having (input) focus
function TfrmMain.Token: IToken;
begin
  if Self.Kind = GivenIn then
    Result := Self.Token(AssetIn)
  else
    Result := Self.Token(AssetOut);
end;

// returns the token for 'AssetIn' or 'AssetOut'
function TfrmMain.Token(Asset: TAsset): IToken;
begin
  Result := nil;
  const I = AssetGroup(Asset).ItemIndex;
  if I > -1 then
    Result := Self.Tokens[I];
end;

// returns the token associated with the GUI control
function TfrmMain.Token(aControl: TControl): IToken;
begin
  Result := nil;
  const I = AssetGroup(aControl).ItemIndex;
  if I > -1 then
    Result := Self.Tokens[I];
end;

{---------------------------------- getters -----------------------------------}

function TfrmMain.GetChain: TChain;
begin
  const I = cboChain.ItemIndex;
  if (I > -1) and (I < cboChain.Count) then
    for var C := System.Low(TChain) to System.High(TChain) do
      if C.Id = cboChain.ListItems[I].Tag then
      begin
        Result := C;
        EXIT;
      end;
  Result := web3.Ethereum;
end;

function TfrmMain.GetClient: IWeb3;
begin
  Result := TWeb3.Create(Self.Chain, Self.Endpoint);
end;

function TfrmMain.GetEndpoint: string;
begin
  Result := web3.eth.infura.endpoint(Self.Chain, INFURA_PROJECT_ID);
end;

// returns the minimum or maximum amount of each token the vault is allowed to transfer
function TfrmMain.GetLimit: BigInteger;
begin
  if kind = GivenIn then
    // minimum amount of tokens to receive
    Result := web3.utils.scale(
      Self.AssetGroup(AssetOut).Amount * Self.GetMultiplier,
      Self.Token(AssetOut).Decimals
    )
  else
    // maximum number of tokens to send
    Result := web3.utils.scale(
      Self.AssetGroup(AssetIn).Amount * Self.GetMultiplier,
      Self.Token(AssetIn).Decimals
    );
end;

function TfrmMain.GetMultiplier: Double;
begin
  case cboSlippage.ItemIndex of
    0: // 0.5%
    if kind = GivenIn then
      Result := 0.995
    else
      Result := 1.005;
    2: // 2.0%
    if kind = GivenIn then
      Result := 0.98
    else
      Result := 1.02;
  else // 1.0%
    if kind = GivenIn then
      Result := 0.99
    else
      Result := 1.01;
  end;
end;

{---------------------------------- setters -----------------------------------}

procedure TfrmMain.SetKind(Value: TSwapKind);
begin
  if Value <> FKind then
  begin
    FKind := Value;
    UpdateStatus;
  end;
end;

procedure TfrmMain.SetTokens(Value: TTokens);
begin
  if Value <> FTokens then
  begin
    FTokens := Value;
    UpdateAssets;
  end;
end;

{---------------------------------- updaters ----------------------------------}

procedure TfrmMain.UpdateAssets;
begin
  const updateAsset = procedure(cbo: TComboBox; ItemIndex: Integer)
  begin
    cbo.BeginUpdate;
    try
      cbo.Clear;
      for var token in Self.Tokens do
        cbo.Items.Add(token.Symbol);
      if cbo.Count > 0 then
        cbo.ItemIndex := Min(ItemIndex, cbo.Count - 1);
    finally
      cbo.EndUpdate;
    end;
  end;

  thread.synchronize(procedure
  begin
    updateAsset(cboAssetIn, 0);
    updateAsset(cboAssetOut, 1);
  end);
end;

procedure TfrmMain.UpdateBalance(Sender: TControl);
begin
  Self.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
      error.show(Self.Chain, err)
    else
      Token(Sender).Balance(Self.Client, addr, procedure(qty: BigInteger; err: IError)
      begin
        if Assigned(err) then
          error.Show(Self.Chain, err)
        else
          thread.synchronize(procedure
          begin
            AssetGroup(Sender).Balance := web3.utils.unscale(qty, Token(Sender).Decimals);
          end);
      end);
  end);
end;

procedure TfrmMain.UpdateOtherAmount;
begin
  const setOtherAmount = procedure(value: Double)
  begin
    thread.synchronize(procedure
    begin
      Self.Lock;
      try
        if Self.Kind = GivenOut then
          AssetGroup(AssetIn).Amount  := value
        else
          AssetGroup(AssetOut).Amount := value;
      finally
        Self.Unlock;
      end;
      btnTrade.Enabled := (AssetGroup(AssetIn).Amount > 0) and (AssetGroup(AssetOut).Amount > 0);
    end);
  end;

  const amount = Self.AssetGroup.Amount;
  if amount = 0 then
  begin
    setOtherAmount(0);
    EXIT;
  end;

  const tokenIn = Self.Token(AssetIn);
  if not Assigned(tokenIn) then
    EXIT;
  const tokenOut = Self.Token(AssetOut);
  if not Assigned(tokenOut) then
    EXIT;

  Self.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
      error.show(Self.Chain, err)
    else
      web3.eth.balancer.v2.simulate(
        Self.Client,
        addr,
        Self.Kind,
        tokenIn.Address.ToChecksum,
        tokenOut.Address.ToChecksum,
        web3.utils.scale(amount, Self.Token.Decimals),
        procedure(deltas: TArray<BigInteger>; err: IError)
        begin
          setOtherAmount((function: Double
          begin
            if Assigned(err) then
              Result := 0
            else
              if Self.Kind = GivenOut then
                Result := web3.utils.unscale(deltas[0].Abs, Self.Token(AssetIn).Decimals)
              else
                Result := web3.utils.unscale(deltas[High(deltas)].Abs, Self.Token(AssetOut).Decimals);
          end)());
        end
      );
  end);
end;

procedure TfrmMain.UpdateStatus;
begin
  if Self.AssetGroup.Amount = 0 then
    lblStatus.Text := ''
  else
    lblStatus.Text := Format('You are about to %s %f', [(function: string
      begin
        if Self.Kind = GivenIn then
          Result := Format('send %s', [Self.Token(AssetIn).Symbol])
        else
          Result := Format('receive %s', [Self.Token(AssetOut).Symbol]);
      end)(),
      Self.AssetGroup.Amount
    ]);
end;

{------------------------------- event handlers -------------------------------}

procedure TfrmMain.btnMaxClick(Sender: TObject);
begin
  if not(Sender is TCustomButton) then
    EXIT;
  const btn = TCustomComboBox(Sender);
  Self.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
      error.show(Self.Chain, err)
    else
      Token(btn).Balance(Self.Client, addr, procedure(qty: BigInteger; err: IError)
      begin
        if Assigned(err) then
          error.show(Self.Chain, err)
        else
          thread.synchronize(procedure
          begin
            AssetGroup(btn).Amount := web3.utils.unscale(qty, Token(btn).Decimals);
          end);
      end);
  end);
end;

procedure TfrmMain.btnSwitchClick(Sender: TObject);
begin
  Self.Switch;
end;

procedure TfrmMain.btnTradeClick(Sender: TObject);
begin
  Self.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
    begin
      error.show(Self.Chain, err);
      EXIT;
    end;
    const &private = prompt.privateKey(addr);
    if &private <> '' then
    begin
      web3.eth.balancer.v2.swap(
        Self.Client,
        &private,
        Self.Kind,
        Self.Token(AssetIn).Address.ToChecksum,
        Self.Token(AssetOut).Address.ToChecksum,
        web3.utils.scale(Self.AssetGroup.Amount, Self.Token.Decimals),
        Self.GetLimit,
        web3.Infinite,
        procedure(rcpt: ITxReceipt; err: IError)
        begin
          if Assigned(err) then
          begin
            error.show(Self.Chain, err);
            EXIT;
          end;
          // show the new balance in your wallet
          UpdateBalance(cboAssetIn);
          UpdateBalance(cboAssetOut);
          // show the status of your transaction in a web browser
          open.transaction(self.Chain, rcpt.txHash);
        end);
    end;
  end);
end;

procedure TfrmMain.cboAssetChange(Sender: TObject);
begin
  if Self.Locked then
    EXIT;

  if not(Sender is TComboBox) then
    EXIT;
  const cbo = TComboBox(Sender);

  if cboAssetIn.ItemIndex = cboAssetOut.ItemIndex then
  begin
    Self.Lock;
    try
      // restore the last ItemIndex value
      cbo.ItemIndex := cbo.LastIndex;
      Self.Switch;
    finally
      Self.Unlock;
    end;
    EXIT;
  end;

  // store the last ItemIndex value
  cbo.LastIndex := cbo.ItemIndex;

  UpdateBalance(cbo);
  UpdateOtherAmount;
  UpdateStatus;
end;

procedure TfrmMain.cboChainChange(Sender: TObject);
begin
  web3.eth.balancer.v2.tokens(Self.Chain, procedure(tokens: TTokens; err: IError)
  begin
    if Assigned(err) then
      error.show(Self.Chain, err)
    else
      Self.Tokens := tokens;
  end);
end;

procedure TfrmMain.edtAddressChange(Sender: TObject);
begin
  UpdateBalance(cboAssetIn);
  UpdateBalance(cboAssetOut);
end;

procedure TfrmMain.edtAssetChange(Sender: TObject);
begin
  if Self.Locked then
    EXIT;
  if not(Sender is TControl) then
    EXIT;
  if TAsset(TControl(Sender).Tag) = AssetIn then
    Self.Kind := GivenIn
  else
    Self.Kind := GivenOut;
  FDelay.&Set(UpdateOtherAmount, 500);
  UpdateStatus;
end;

end.
