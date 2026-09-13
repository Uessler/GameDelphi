

unit Engine.Core.Loop;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

const

  DEFAULT_MAX_FRAME_DELTA = 0.25;

  DEFAULT_MAX_STEPS = 5;

type
  TFixedStep = record
  public

    FixedDelta: Single;

    MaxSteps: Integer;

    MaxFrameDelta: Single;

    Accumulator: Single;

    Alpha: Single;

    Starved: Boolean;

    Clamped: Boolean;

    TotalSteps: UInt64;
    TotalFrames: UInt64;

    SimTime: Double;

    procedure Init(const AFixedDelta: Single;
      const AMaxSteps: Integer = DEFAULT_MAX_STEPS;
      const AMaxFrameDelta: Single = DEFAULT_MAX_FRAME_DELTA);

    function Advance(const RealDelta: Single): Integer;

    procedure Reset;

    function StepsPerSecond: Single;
  end;

  TFrameCounter = record
  private
    FAccumTime: Single;
    FFrames: Integer;
  public

    FPS: Single;

    FrameMS: Single;

    Interval: Single;

    procedure Init(const AInterval: Single = 0.5);

    function Tick(const RealDelta: Single): Boolean;
  end;

implementation

procedure TFixedStep.Init(const AFixedDelta: Single; const AMaxSteps: Integer;
  const AMaxFrameDelta: Single);
begin
  if AFixedDelta > 0.0 then
    FixedDelta := AFixedDelta
  else
    FixedDelta := 1.0 / 60.0;

  if AMaxSteps > 0 then
    MaxSteps := AMaxSteps
  else
    MaxSteps := 1;

  MaxFrameDelta := AMaxFrameDelta;

  Accumulator := 0.0;
  Alpha := 0.0;
  Starved := False;
  Clamped := False;
  TotalSteps := 0;
  TotalFrames := 0;
  SimTime := 0.0;
end;

function TFixedStep.Advance(const RealDelta: Single): Integer;
var
  Delta: Single;
  StepSeconds: Double;
begin
  Inc(TotalFrames);
  Starved := False;
  Clamped := False;

  Delta := RealDelta;

  if Delta < 0.0 then
    Delta := 0.0;

  if Delta > MaxFrameDelta then
  begin
    Delta := MaxFrameDelta;
    Clamped := True;
  end;

  Accumulator := Accumulator + Delta;

  Result := 0;
  while (Accumulator >= FixedDelta) and (Result < MaxSteps) do
  begin
    Accumulator := Accumulator - FixedDelta;
    Inc(Result);
  end;

  if (Result >= MaxSteps) and (Accumulator >= FixedDelta) then
  begin
    Starved := True;
    Accumulator := 0.0;
  end;

  Inc(TotalSteps, UInt64(Result));
  StepSeconds := FixedDelta;
  SimTime := SimTime + Result * StepSeconds;

  Alpha := Accumulator / FixedDelta;
  if Alpha < 0.0 then
    Alpha := 0.0
  else if Alpha > 1.0 then
    Alpha := 1.0;
end;

procedure TFixedStep.Reset;
begin
  Accumulator := 0.0;
  Alpha := 0.0;
  Starved := False;
  Clamped := False;
end;

function TFixedStep.StepsPerSecond: Single;
begin
  Result := 1.0 / FixedDelta;
end;

procedure TFrameCounter.Init(const AInterval: Single);
begin
  FAccumTime := 0.0;
  FFrames := 0;
  FPS := 0.0;
  FrameMS := 0.0;
  if AInterval > 0.0 then
    Interval := AInterval
  else
    Interval := 0.5;
end;

function TFrameCounter.Tick(const RealDelta: Single): Boolean;
begin
  FAccumTime := FAccumTime + RealDelta;
  Inc(FFrames);

  Result := FAccumTime >= Interval;
  if Result then
  begin
    FPS := FFrames / FAccumTime;
    FrameMS := (FAccumTime / FFrames) * 1000.0;
    FAccumTime := 0.0;
    FFrames := 0;
  end;
end;

end.
