

unit Engine.Platform.Input;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Engine.Platform.SDL2;

const
  MAX_MOUSE_BUTTONS = 8;

type
  TInput = record
  private
    FDown: array [0 .. SDL_NUM_SCANCODES - 1] of Boolean;
    FPrev: array [0 .. SDL_NUM_SCANCODES - 1] of Boolean;
    FMouseDown: array [0 .. MAX_MOUSE_BUTTONS - 1] of Boolean;
    FMousePrev: array [0 .. MAX_MOUSE_BUTTONS - 1] of Boolean;
  public

    MouseX, MouseY: Integer;

    MouseDX, MouseDY: Integer;

    WheelX, WheelY: Integer;

    Text: string;

    procedure Init;

    procedure BeginFrame;

    procedure SetKey(const Scancode: Integer; const Down: Boolean);
    procedure SetMouseButton(const Button: Integer; const Down: Boolean);
    procedure SetMousePosition(const X, Y, DX, DY: Integer);
    procedure AddWheel(const X, Y: Integer);
    procedure AddText(const S: string);

    procedure ReleaseAll;

    function IsDown(const Scancode: Integer): Boolean;
    function IsUp(const Scancode: Integer): Boolean;
    function WasPressedThisFrame(const Scancode: Integer): Boolean;
    function WasReleasedThisFrame(const Scancode: Integer): Boolean;

    function MouseIsDown(const Button: Integer): Boolean;
    function MouseWasPressedThisFrame(const Button: Integer): Boolean;
    function MouseWasReleasedThisFrame(const Button: Integer): Boolean;

    function Axis(const NegativeKey, PositiveKey: Integer): Single;

    function AnyKeyPressedThisFrame: Boolean;
  end;
  PInput = ^TInput;

implementation

procedure TInput.Init;
begin
  FillChar(FDown, SizeOf(FDown), 0);
  FillChar(FPrev, SizeOf(FPrev), 0);
  FillChar(FMouseDown, SizeOf(FMouseDown), 0);
  FillChar(FMousePrev, SizeOf(FMousePrev), 0);
  MouseX := 0;
  MouseY := 0;
  MouseDX := 0;
  MouseDY := 0;
  WheelX := 0;
  WheelY := 0;
  Text := '';
end;

procedure TInput.BeginFrame;
begin
  Move(FDown, FPrev, SizeOf(FDown));
  Move(FMouseDown, FMousePrev, SizeOf(FMouseDown));
  MouseDX := 0;
  MouseDY := 0;
  WheelX := 0;
  WheelY := 0;
  Text := '';
end;

procedure TInput.SetKey(const Scancode: Integer; const Down: Boolean);
begin
  if (Scancode >= 0) and (Scancode < SDL_NUM_SCANCODES) then
    FDown[Scancode] := Down;
end;

procedure TInput.SetMouseButton(const Button: Integer; const Down: Boolean);
begin
  if (Button >= 0) and (Button < MAX_MOUSE_BUTTONS) then
    FMouseDown[Button] := Down;
end;

procedure TInput.SetMousePosition(const X, Y, DX, DY: Integer);
begin
  MouseX := X;
  MouseY := Y;

  Inc(MouseDX, DX);
  Inc(MouseDY, DY);
end;

procedure TInput.AddWheel(const X, Y: Integer);
begin
  Inc(WheelX, X);
  Inc(WheelY, Y);
end;

procedure TInput.AddText(const S: string);
begin
  Text := Text + S;
end;

procedure TInput.ReleaseAll;
begin
  FillChar(FDown, SizeOf(FDown), 0);
  FillChar(FMouseDown, SizeOf(FMouseDown), 0);
end;

function TInput.IsDown(const Scancode: Integer): Boolean;
begin
  Result := (Scancode >= 0) and (Scancode < SDL_NUM_SCANCODES) and FDown[Scancode];
end;

function TInput.IsUp(const Scancode: Integer): Boolean;
begin
  Result := not IsDown(Scancode);
end;

function TInput.WasPressedThisFrame(const Scancode: Integer): Boolean;
begin
  Result := (Scancode >= 0) and (Scancode < SDL_NUM_SCANCODES) and
            FDown[Scancode] and (not FPrev[Scancode]);
end;

function TInput.WasReleasedThisFrame(const Scancode: Integer): Boolean;
begin
  Result := (Scancode >= 0) and (Scancode < SDL_NUM_SCANCODES) and
            (not FDown[Scancode]) and FPrev[Scancode];
end;

function TInput.MouseIsDown(const Button: Integer): Boolean;
begin
  Result := (Button >= 0) and (Button < MAX_MOUSE_BUTTONS) and FMouseDown[Button];
end;

function TInput.MouseWasPressedThisFrame(const Button: Integer): Boolean;
begin
  Result := (Button >= 0) and (Button < MAX_MOUSE_BUTTONS) and
            FMouseDown[Button] and (not FMousePrev[Button]);
end;

function TInput.MouseWasReleasedThisFrame(const Button: Integer): Boolean;
begin
  Result := (Button >= 0) and (Button < MAX_MOUSE_BUTTONS) and
            (not FMouseDown[Button]) and FMousePrev[Button];
end;

function TInput.Axis(const NegativeKey, PositiveKey: Integer): Single;
begin
  Result := 0.0;
  if IsDown(PositiveKey) then
    Result := Result + 1.0;
  if IsDown(NegativeKey) then
    Result := Result - 1.0;
end;

function TInput.AnyKeyPressedThisFrame: Boolean;
var
  I: Integer;
begin
  for I := 0 to SDL_NUM_SCANCODES - 1 do
    if FDown[I] and (not FPrev[I]) then
      Exit(True);
  Result := False;
end;

end.
