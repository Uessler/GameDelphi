

unit Engine.Platform.Time;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Engine.Platform.SDL2;

type
  TClock = record
  private
    FFrequency: UInt64;
    FLastCounter: UInt64;
    FStartCounter: UInt64;
  public

    Delta: Single;

    Elapsed: Double;

    procedure Start;

    function Tick: Single;

    function Now: Double;
  end;

  TStopwatch = record
  private
    FFrequency: UInt64;
    FStart: UInt64;
  public
    procedure Start;
    function ElapsedSeconds: Double;
    function ElapsedMS: Double;
  end;

procedure SleepMS(const MS: Cardinal);

implementation

procedure TClock.Start;
begin
  FFrequency := SDL_GetPerformanceFrequency;
  if FFrequency = 0 then
    FFrequency := 1;
  FStartCounter := SDL_GetPerformanceCounter;
  FLastCounter := FStartCounter;
  Delta := 0.0;
  Elapsed := 0.0;
end;

function TClock.Tick: Single;
var
  Current: UInt64;
begin
  Current := SDL_GetPerformanceCounter;
  Delta := (Current - FLastCounter) / FFrequency;
  FLastCounter := Current;
  Elapsed := (Current - FStartCounter) / FFrequency;
  Result := Delta;
end;

function TClock.Now: Double;
begin
  Result := (SDL_GetPerformanceCounter - FStartCounter) / FFrequency;
end;

procedure TStopwatch.Start;
begin
  FFrequency := SDL_GetPerformanceFrequency;
  if FFrequency = 0 then
    FFrequency := 1;
  FStart := SDL_GetPerformanceCounter;
end;

function TStopwatch.ElapsedSeconds: Double;
begin
  Result := (SDL_GetPerformanceCounter - FStart) / FFrequency;
end;

function TStopwatch.ElapsedMS: Double;
begin
  Result := ElapsedSeconds * 1000.0;
end;

procedure SleepMS(const MS: Cardinal);
begin
  SDL_Delay(MS);
end;

end.
