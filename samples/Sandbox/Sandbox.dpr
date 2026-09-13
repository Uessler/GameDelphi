

program Sandbox;

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  SysUtils,
  Engine.Core.Math in '..\..\src\Core\Engine.Core.Math.pas',
  Engine.Core.Loop in '..\..\src\Core\Engine.Core.Loop.pas',
  Engine.Core.Log in '..\..\src\Core\Engine.Core.Log.pas',
  Engine.Platform.SDL2 in '..\..\src\Platform\Engine.Platform.SDL2.pas',
  Engine.Platform.Time in '..\..\src\Platform\Engine.Platform.Time.pas',
  Engine.Platform.Input in '..\..\src\Platform\Engine.Platform.Input.pas',
  Engine.Platform.Window in '..\..\src\Platform\Engine.Platform.Window.pas';

const
{$IFDEF MSWINDOWS}
  GL_LIB = 'opengl32.dll';
{$ELSE}
  GL_LIB = 'libGL.so.1';
{$ENDIF}
  GL_COLOR_BUFFER_BIT = $00004000;
  GL_DEPTH_BUFFER_BIT = $00000100;
  GL_VERSION_STR      = $1F02;
  GL_RENDERER_STR     = $1F01;

{$IFDEF MSWINDOWS}
procedure glClearColor(R, G, B, A: Single); stdcall; external GL_LIB;
procedure glClear(Mask: Cardinal); stdcall; external GL_LIB;
procedure glViewport(X, Y, W, H: Integer); stdcall; external GL_LIB;
function glGetString(Name: Cardinal): PAnsiChar; stdcall; external GL_LIB;
{$ELSE}
procedure glClearColor(R, G, B, A: Single); cdecl; external GL_LIB;
procedure glClear(Mask: Cardinal); cdecl; external GL_LIB;
procedure glViewport(X, Y, W, H: Integer); cdecl; external GL_LIB;
function glGetString(Name: Cardinal): PAnsiChar; cdecl; external GL_LIB;
{$ENDIF}

type

  TPlayer = record
    Position: TVec2;
    PrevPosition: TVec2;
    Velocity: TVec2;
    procedure Init;
    procedure FixedUpdate(const Dt: Single; var Input: TInput);

    function RenderPosition(const Alpha: Single): TVec2;
  end;

procedure TPlayer.Init;
begin
  Position := TVec2.Zero;
  PrevPosition := TVec2.Zero;
  Velocity := TVec2.Zero;
end;

procedure TPlayer.FixedUpdate(const Dt: Single; var Input: TInput);
const
  SPEED = 2.0;
  RUN_MULTIPLIER = 3.0;
  DRAG = 6.0;
var
  Dir: TVec2;
  Accel: Single;
begin

  PrevPosition := Position;

  Dir.X := Input.Axis(SDL_SCANCODE_A, SDL_SCANCODE_D) +
           Input.Axis(SDL_SCANCODE_LEFT, SDL_SCANCODE_RIGHT);
  Dir.Y := Input.Axis(SDL_SCANCODE_S, SDL_SCANCODE_W) +
           Input.Axis(SDL_SCANCODE_DOWN, SDL_SCANCODE_UP);

  if not Dir.IsZero then
    Dir := Dir.Normalized;

  Accel := SPEED;
  if Input.IsDown(SDL_SCANCODE_LSHIFT) or Input.IsDown(SDL_SCANCODE_RSHIFT) then
    Accel := Accel * RUN_MULTIPLIER;

  Velocity := Velocity + Dir * (Accel * Dt);

  Velocity := Velocity * (1.0 - Clamp(DRAG * Dt, 0.0, 1.0));

  Position := Position + Velocity * Dt;

  Position.X := Clamp(Position.X, -1.0, 1.0);
  Position.Y := Clamp(Position.Y, -1.0, 1.0);
end;

function TPlayer.RenderPosition(const Alpha: Single): TVec2;
begin
  Result := Lerp2(PrevPosition, Position, Alpha);
end;

var
  Window: TWindow;
  Cfg: TWindowConfig;
  Input: TInput;
  Clock: TClock;
  Step: TFixedStep;
  Frames: TFrameCounter;
  Player: TPlayer;
  Dt: Single;
  N, I: Integer;
  Draw: TVec2;
  SlowMode, Fast, ArtificialLoad: Boolean;
  Busy: Double;
  J: Integer;

begin
  Cfg := TWindowConfig.Default;
  Cfg.Title := 'Jojos Engine - Sandbox';
  Cfg.Width := 1280;
  Cfg.Height := 720;

  try
    Window := TWindow.Create(Cfg);
  except
    on E: Exception do
    begin
      WriteLn('ERRO: ', E.Message);
      WriteLn;
      WriteLn('Checklist:');
      WriteLn('  - SDL2.dll esta ao lado do .exe? (x64 se o alvo for Win64)');
      WriteLn('  - O driver de video suporta OpenGL 3.3 core?');
      WriteLn('  - Rodando em RDP ou VM sem aceleracao? Isso costuma falhar.');
      WriteLn('(enter para sair)');
      ReadLn;
      Halt(1);
    end;
  end;

  try
    WriteLn('GL_VERSION : ', string(AnsiString(glGetString(GL_VERSION_STR))));
    WriteLn('GL_RENDERER: ', string(AnsiString(glGetString(GL_RENDERER_STR))));
    WriteLn('janela     : ', Window.Width, 'x', Window.Height);
    WriteLn('vsync      : ', Window.VSync);
    WriteLn;
    WriteLn('WASD move | Shift corre | F1 vsync | F2 60/120Hz | F3 60/5Hz |');
    WriteLn('F4 carga artificial | Espaco snapshot | ESC sai');
    WriteLn;

    Input.Init;
    Player.Init;
    Clock.Start;
    Step.Init(1.0 / 60.0);
    Frames.Init(0.25);
    SlowMode := False;
    Fast := False;
    ArtificialLoad := False;

    while not Window.ShouldClose do
    begin
      Dt := Clock.Tick;

      Input.BeginFrame;
      Window.PumpEvents(Input);

      if Input.WasPressedThisFrame(SDL_SCANCODE_ESCAPE) then
        Window.RequestClose;

      if Input.WasPressedThisFrame(SDL_SCANCODE_F1) then
      begin
        Window.SetVSync(not Window.VSync);
        WriteLn('vsync = ', Window.VSync);
      end;

      if Input.WasPressedThisFrame(SDL_SCANCODE_F2) then
      begin
        Fast := not Fast;
        SlowMode := False;
        if Fast then
          Step.Init(1.0 / 120.0)
        else
          Step.Init(1.0 / 60.0);
        WriteLn('simulacao = ', Step.StepsPerSecond: 0: 0, ' Hz');
      end;

      if Input.WasPressedThisFrame(SDL_SCANCODE_F3) then
      begin
        SlowMode := not SlowMode;
        Fast := False;
        if SlowMode then
          Step.Init(1.0 / 5.0)
        else
          Step.Init(1.0 / 60.0);
        WriteLn('simulacao = ', Step.StepsPerSecond: 0: 0, ' Hz');
      end;

      if Input.WasPressedThisFrame(SDL_SCANCODE_F4) then
      begin
        ArtificialLoad := not ArtificialLoad;
        WriteLn('carga artificial = ', ArtificialLoad);
      end;

      if Input.WasPressedThisFrame(SDL_SCANCODE_SPACE) then
      begin
        WriteLn(Format('pos=(%.3f, %.3f)  vel=(%.3f, %.3f)  alpha=%.3f  ' +
          'passos=%d  simtime=%.2fs  realtime=%.2fs',
          [Player.Position.X, Player.Position.Y, Player.Velocity.X,
           Player.Velocity.Y, Step.Alpha, Step.TotalSteps, Step.SimTime,
           Clock.Elapsed]));
      end;

      N := Step.Advance(Dt);
      for I := 1 to N do
        Player.FixedUpdate(Step.FixedDelta, Input);

      if Step.Starved then
        WriteLn('AVISO: simulacao nao acompanhou o tempo real neste frame');

      if ArtificialLoad then
      begin
        Busy := 0;
        for J := 1 to 8000000 do
          Busy := Busy + J * 0.5;
        if Busy < 0 then
          WriteLn('impossivel');
      end;

      if Window.ResizedThisFrame then
        glViewport(0, 0, Window.Width, Window.Height);

      if not Window.Minimized then
      begin
        Draw := Player.RenderPosition(Step.Alpha);

        glClearColor(Draw.X * 0.5 + 0.5, Draw.Y * 0.5 + 0.5, 0.35, 1.0);
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        Window.Present;
      end
      else
        SleepMS(10);

      if Frames.Tick(Dt) then
        Window.SetTitle(Format('Jojos Engine - Sandbox  |  %.0f fps  ' +
          '(%.2f ms)  |  sim %.0f Hz  |  vsync %s',
          [Frames.FPS, Frames.FrameMS, Step.StepsPerSecond,
           BoolToStr(Window.VSync, True)]));
    end;

    WriteLn;
    WriteLn(Format('encerrado. %d frames, %d passos de simulacao em %.1fs',
      [Step.TotalFrames, Step.TotalSteps, Clock.Elapsed]));
  finally
    Window.Free;
  end;
end.
