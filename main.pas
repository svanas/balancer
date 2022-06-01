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
    procedure Switch(other: TAssetGroup);
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
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
    btnSwap: TCornerButton;
    edtAssetOut: TNumberBox;
    Ethereum: TListBoxItem;
    Kovan: TListBoxItem;
    btnAssetIn: TEditButton;
    edtAddress: TEdit;
    Polygon: TListBoxItem;
    Arbitrum: TListBoxItem;
    procedure btnTradeClick(Sender: TObject);
    procedure cboChainChange(Sender: TObject);
    procedure cboAssetChange(Sender: TObject);
    procedure btnMaxClick(Sender: TObject);
    procedure edtAssetChange(Sender: TObject);
    procedure edtAddressChange(Sender: TObject);
    procedure btnSwapClick(Sender: TObject);
  private
    FDelay  : IDelay;
    FKind   : TSwapKind;
    FLockCnt: Integer;
    FTokens : TTokens;
    procedure Lock;
    procedure Unlock;
    function  Locked: Boolean;
    procedure UpdateAssets;
    procedure UpdateOtherAmount;
    procedure Address(callback: TAsyncAddress);
    function  AssetGroup: TAssetGroup; overload;
    function  AssetGroup(Asset: TAsset): TAssetGroup; overload;
    function  AssetGroup(aControl: TControl): TAssetGroup; overload;
    function  GetChain: TChain;
    function  GetEndpoint: string;
    function  GetClient: IWeb3;
    procedure SetTokens(Value: TTokens);
    function  Token: IToken; overload;
    function  Token(Asset: TAsset): IToken; overload;
    function  Token(aControl: TControl): IToken; overload;
    procedure Switch;
  public
    constructor Create(aOwner: TComponent); override;
    property Chain: TChain read GetChain;
    property Endpoint: string read GetEndpoint;
    property Client: IWeb3 read GetClient;
    property Tokens: TTokens read FTokens write SetTokens;
    property Kind: TSwapKind read FKind write FKind;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  // Delphi
  System.Math,
  System.SysUtils,
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
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

{ TfrmMain }

constructor TfrmMain.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FDelay := delay.Create;

  edtAssetIn.Max  := web3.Infinite.AsDouble;
  edtAssetOut.Max := web3.Infinite.AsDouble;

  cboChainChange(cboChain);
end;

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

procedure TfrmMain.edtAddressChange(Sender: TObject);
begin
  UpdateAssets;
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
end;

procedure TfrmMain.Address(callback: TAsyncAddress);
begin
  if edtAddress.Text.Length = 0 then
    callback(EMPTY_ADDRESS, nil)
  else
    TAddress.New(Self.Client, edtAddress.Text, callback);
end;

function TfrmMain.AssetGroup: TAssetGroup;
begin
  if Self.Kind = GivenIn then
    Result := Self.AssetGroup(AssetIn)
  else
    Result := Self.AssetGroup(AssetOut);
end;

function TfrmMain.AssetGroup(Asset: TAsset): TAssetGroup;
begin
  if Asset = AssetIn then
    Result := TAssetGroup.Create(cboAssetIn, lblAssetIn, edtAssetIn)
  else if Asset = AssetOut then
    Result := TAssetGroup.Create(cboAssetOut, lblAssetOut, edtAssetOut);
end;

function TfrmMain.AssetGroup(aControl: TControl): TAssetGroup;
begin
  Result := AssetGroup(TAsset(aControl.Tag));
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

  Self.Address(procedure(addr: TAddress; err: IError)
  begin
    if Assigned(err) then
    begin
      error.show(Self.Chain, err);
      EXIT;
    end;
    Token(cbo).Balance(Self.Client, addr, procedure(qty: BigInteger; err: IError)
    begin
      if Assigned(err) then
        error.Show(Self.Chain, err)
      else
        thread.synchronize(procedure
        begin
          AssetGroup(cbo).Balance := qty.AsDouble / Power(10, Token(cbo).Decimals);
        end);
    end);
  end);

  UpdateOtherAmount;
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

procedure TfrmMain.SetTokens(Value: TTokens);
begin
  if Value <> FTokens then
  begin
    FTokens := Value;
    UpdateAssets;
  end;
end;

function TfrmMain.Token: IToken;
begin
  if Self.Kind = GivenIn then
    Result := Self.Token(AssetIn)
  else
    Result := Self.Token(AssetOut);
end;

function TfrmMain.Token(Asset: TAsset): IToken;
begin
  Result := nil;
  const I = AssetGroup(Asset).ItemIndex;
  if I > -1 then
    Result := Self.Tokens[I];
end;

function TfrmMain.Token(aControl: TControl): IToken;
begin
  Result := nil;
  const I = AssetGroup(aControl).ItemIndex;
  if I > -1 then
    Result := Self.Tokens[I];
end;

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

function TfrmMain.GetEndpoint: string;
begin
  Result := web3.eth.infura.endpoint(Self.Chain, INFURA_PROJECT_ID);
end;

function TfrmMain.GetClient: IWeb3;
begin
  Result := TWeb3.Create(Self.Chain, Self.Endpoint);
end;

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
            AssetGroup(btn).Amount := qty.AsDouble / Power(10, Token(btn).Decimals);
          end);
      end);
  end);
end;

procedure TfrmMain.btnSwapClick(Sender: TObject);
begin
  Switch;
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
        BigInteger.Create(Self.AssetGroup.Amount * Power(10, Self.Token.Decimals)),
        web3.Infinite,
        procedure(rcpt: ITxReceipt; err: IError)
        begin
          if Assigned(err) then
            error.show(Self.Chain, err)
          else
            // show the status of your transaction in a web browser
            open.transaction(self.Chain, rcpt.txHash);
        end);
    end;
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
        BigInteger.Create(amount * Power(10, Self.Token.Decimals)),
        procedure(deltas: TArray<BigInteger>; err: IError)
        begin
          setOtherAmount((function: Double
          begin
            if Assigned(err) then
              Result := 0
            else
              if Self.Kind = GivenOut then
                Result := deltas[0].Abs.AsDouble / Power(10, Self.Token(AssetIn).Decimals)
              else
                Result := deltas[High(deltas)].Abs.AsDouble / Power(10, Self.Token(AssetOut).Decimals);
          end)());
        end
      );
  end);
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

end.
