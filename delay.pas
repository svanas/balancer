unit delay;

interface

uses
  // FireMonkey
  FMX.Types;

type
  IDelay = interface
    procedure &Set(proc: TTimerProc; interval: Cardinal);
  end;

function Create: IDelay;

implementation

uses
  // FireMonkey
  FMX.Platform;

type
  TDelay = class(TInterfacedObject, IDelay)
  private
    FHandle: TFmxHandle;
    FProc: TTimerProc;
    FTimer: IFMXTimerService;
    procedure Timer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure &Set(proc: TTimerProc; interval: Cardinal);
    procedure Clear;
  end;

constructor TDelay.Create;
begin
  inherited Create;
  FHandle := cIdNoTimer;
  FTimer := TPlatformServices.Current.GetPlatformService(IFMXTimerService) as IFMXTimerService;
end;

destructor TDelay.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TDelay.Timer;
begin
  Clear;
  if Assigned(FProc) then FProc;
end;

procedure TDelay.&Set(proc: TTimerProc; interval: Cardinal);
begin
  Clear;
  FProc := Proc;
  FHandle := FTimer.CreateTimer(interval, Timer);
end;

procedure TDelay.Clear;
begin
  if FHandle <> cIdNoTimer then
  begin
    FTimer.DestroyTimer(FHandle);
    FHandle := cIdNoTimer;
  end;
end;

function Create: IDelay;
begin
  Result := TDelay.Create;
end;

end.
