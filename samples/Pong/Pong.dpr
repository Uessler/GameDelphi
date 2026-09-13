

program Pong;

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  SysUtils,
  Engine.Core.Math in '..\..\src\Core\Engine.Core.Math.pas',
  Engine.Core.Loop in '..\..\src\Core\Engine.Core.Loop.pas',
  Engine.Core.Log in '..\..\src\Core\Engine.Core.Log.pas',
  Engine.Core.Memory in '..\..\src\Core\Engine.Core.Memory.pas',
  Engine.Platform.SDL2 in '..\..\src\Platform\Engine.Platform.SDL2.pas',
  Engine.Platform.Time in '..\..\src\Platform\Engine.Platform.Time.pas',
  Engine.Platform.Input in '..\..\src\Platform\Engine.Platform.Input.pas',
  Engine.Platform.Window in '..\..\src\Platform\Engine.Platform.Window.pas',
  Engine.RHI.Types in '..\..\src\RHI\Engine.RHI.Types.pas',
  Engine.RHI.GL.Loader in '..\..\src\RHI\Engine.RHI.GL.Loader.pas',
  Engine.RHI.GL.Device in '..\..\src\RHI\Engine.RHI.GL.Device.pas',
  Engine.Renderer.Camera2D in '..\..\src\Renderer\Engine.Renderer.Camera2D.pas',
  Engine.Renderer.SpriteBatch in '..\..\src\Renderer\Engine.Renderer.SpriteBatch.pas';

const
  LOG_GAME = 'pong';

  WORLD_W = 1280.0;
  WORLD_H = 720.0;

  PADDLE_W = 18.0;
  PADDLE_H = 130.0;
  PADDLE_MARGIN = 60.0;
  PADDLE_SPEED = 620.0;

  BALL_SIZE = 18.0;
  BALL_SPEED_INICIAL = 460.0;
  BALL_SPEED_MAX = 1400.0;
  BALL_SPEED_GANHO = 1.045;

  IA_VELOCIDADE = 560.0;

  IA_ERRO = 26.0;

type
  TPaddle = record
    Y, PrevY: Single;
    CenterX: Single;
    procedure Init(const AX, AY: Single);
    function Box: TRect2;
  end;

  TBall = record
    Pos, PrevPos: TVec2;
    Vel: TVec2;
    Speed: Single;
    Parada: Boolean;
    procedure Reset(const ParaDireita: Boolean);
  end;

procedure TPaddle.Init(const AX, AY: Single);
begin
  CenterX := AX;
  Y := AY;
  PrevY := AY;
end;

function TPaddle.Box: TRect2;
begin
  Result := TRect2.FromCenter(Vec2(CenterX, Y),
    Vec2(PADDLE_W * 0.5, PADDLE_H * 0.5));
end;

procedure TBall.Reset(const ParaDireita: Boolean);
var
  Ang: Single;
begin
  Pos := Vec2(WORLD_W * 0.5, WORLD_H * 0.5);
  PrevPos := Pos;
  Speed := BALL_SPEED_INICIAL;
  Parada := True;

  Ang := (Random - 0.5) * Deg2RadF(70.0);
  Vel.X := Cos(Ang);
  Vel.Y := Sin(Ang);
  if not ParaDireita then
    Vel.X := -Vel.X;
  Vel := Vel.Normalized;
end;

const
  SEGMENTOS: array [0 .. 9] of Byte = (
    $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F);

var
  Window: TWindow;
  Cfg: TWindowConfig;
  Device: TRHIDevice;
  Batch: TSpriteBatch;
  Camera: TCamera2D;
  Vp: TViewport;
  Input: TInput;
  Clock: TClock;
  Step: TFixedStep;
  Frames: TFrameCounter;

  Esquerda, Direita: TPaddle;
  Bola: TBall;
  PontosE, PontosD: Integer;
  UsaIA: Boolean;
  ServeParaDireita: Boolean;
  Rebatidas: Integer;
  FlashE, FlashD: Single;

  Dt: Single;
  N, I: Integer;
  AlphaR, EsqR, DirR, Y: Single;
  BolaPosR: TVec2;
  CorCampo, CorObj, CorRede: TVec4;

procedure DrawDigito(const D: Integer; const CX, CY, Altura: Single;
  const Cor: TVec4);
var
  Segs: Byte;
  E, Meio, Larg: Single;
begin
  if (D < 0) or (D > 9) then
    Exit;
  Segs := SEGMENTOS[D];
  E := Altura * 0.12;
  Meio := Altura * 0.5;
  Larg := Altura * 0.58;

  if Segs and $01 <> 0 then Batch.DrawRect(Vec2(CX, CY + Meio), Vec2(Larg, E), Cor);
  if Segs and $02 <> 0 then Batch.DrawRect(Vec2(CX + Larg*0.5, CY + Meio*0.5), Vec2(E, Meio), Cor);
  if Segs and $04 <> 0 then Batch.DrawRect(Vec2(CX + Larg*0.5, CY - Meio*0.5), Vec2(E, Meio), Cor);
  if Segs and $08 <> 0 then Batch.DrawRect(Vec2(CX, CY - Meio), Vec2(Larg, E), Cor);
  if Segs and $10 <> 0 then Batch.DrawRect(Vec2(CX - Larg*0.5, CY - Meio*0.5), Vec2(E, Meio), Cor);
  if Segs and $20 <> 0 then Batch.DrawRect(Vec2(CX - Larg*0.5, CY + Meio*0.5), Vec2(E, Meio), Cor);
  if Segs and $40 <> 0 then Batch.DrawRect(Vec2(CX, CY), Vec2(Larg, E), Cor);
end;

procedure DrawNumero(const Valor: Integer; const CX, CY, Altura: Single;
  const Cor: TVec4);
var
  S: string;
  I: Integer;
  Passo, X0: Single;
begin
  S := IntToStr(Valor);
  Passo := Altura * 0.78;
  X0 := CX - (Length(S) - 1) * Passo * 0.5;
  for I := 1 to Length(S) do
    DrawDigito(Ord(S[I]) - Ord('0'), X0 + (I - 1) * Passo, CY, Altura, Cor);
end;

function ColideVarrida(const P0, P1: TVec2; const Paddle: TPaddle;
  const VindoDaEsquerda: Boolean; out TempoHit: Single): Boolean;
var
  PlanoX, Denom, T, YNoHit: Single;
  Caixa: TRect2;
begin
  Result := False;
  TempoHit := 0.0;
  Caixa := Paddle.Box;

  if VindoDaEsquerda then
    PlanoX := Caixa.X + Caixa.W + BALL_SIZE * 0.5
  else
    PlanoX := Caixa.X - BALL_SIZE * 0.5;

  Denom := P1.X - P0.X;
  if NearlyZero(Denom) then
    Exit;

  T := (PlanoX - P0.X) / Denom;
  if (T < 0.0) or (T > 1.0) then
    Exit;

  YNoHit := Lerp(P0.Y, P1.Y, T);
  if (YNoHit + BALL_SIZE * 0.5 < Caixa.Y) or
     (YNoHit - BALL_SIZE * 0.5 > Caixa.Y + Caixa.H) then
    Exit;

  TempoHit := T;
  Result := True;
end;

procedure Rebate(const Paddle: TPaddle; const ParaDireita: Boolean);
var
  Offset, Ang: Single;
  Caixa: TRect2;
begin
  Caixa := Paddle.Box;

  Offset := Clamp((Bola.Pos.Y - Paddle.Y) / (PADDLE_H * 0.5), -1.0, 1.0);
  Ang := Offset * Deg2RadF(55.0);

  Bola.Vel.X := Cos(Ang);
  Bola.Vel.Y := Sin(Ang);
  if not ParaDireita then
    Bola.Vel.X := -Bola.Vel.X;
  Bola.Vel := Bola.Vel.Normalized;

  Bola.Speed := Clamp(Bola.Speed * BALL_SPEED_GANHO, 0.0, BALL_SPEED_MAX);
  Inc(Rebatidas);

  if ParaDireita then
    Bola.Pos.X := Caixa.X + Caixa.W + BALL_SIZE * 0.5 + 0.5
  else
    Bola.Pos.X := Caixa.X - BALL_SIZE * 0.5 - 0.5;
end;

procedure FixedUpdate(const Dt: Single);
var
  P0, P1: TVec2;
  T: Single;
  Alvo, Dir: Single;
begin
  Esquerda.PrevY := Esquerda.Y;
  Direita.PrevY := Direita.Y;
  Bola.PrevPos := Bola.Pos;

  if FlashE > 0 then FlashE := FlashE - Dt;
  if FlashD > 0 then FlashD := FlashD - Dt;

  Esquerda.Y := Esquerda.Y +
    Input.Axis(SDL_SCANCODE_S, SDL_SCANCODE_W) * PADDLE_SPEED * Dt;

  if UsaIA then
  begin

    if Bola.Vel.X > 0 then
      Alvo := Bola.Pos.Y + IA_ERRO * SignF(Bola.Vel.Y)
    else
      Alvo := WORLD_H * 0.5;
    Dir := Alvo - Direita.Y;
    if Abs(Dir) > 4.0 then
      Direita.Y := Direita.Y + SignF(Dir) * IA_VELOCIDADE * Dt;
  end
  else
    Direita.Y := Direita.Y +
      Input.Axis(SDL_SCANCODE_DOWN, SDL_SCANCODE_UP) * PADDLE_SPEED * Dt;

  Esquerda.Y := Clamp(Esquerda.Y, PADDLE_H * 0.5, WORLD_H - PADDLE_H * 0.5);
  Direita.Y := Clamp(Direita.Y, PADDLE_H * 0.5, WORLD_H - PADDLE_H * 0.5);

  if Bola.Parada then
    Exit;

  P0 := Bola.Pos;
  P1 := P0 + Bola.Vel * (Bola.Speed * Dt);

  if P1.Y - BALL_SIZE * 0.5 < 0.0 then
  begin
    P1.Y := BALL_SIZE * 0.5;
    Bola.Vel.Y := Abs(Bola.Vel.Y);
  end
  else if P1.Y + BALL_SIZE * 0.5 > WORLD_H then
  begin
    P1.Y := WORLD_H - BALL_SIZE * 0.5;
    Bola.Vel.Y := -Abs(Bola.Vel.Y);
  end;

  Bola.Pos := P1;

  if (Bola.Vel.X < 0) and ColideVarrida(P0, P1, Esquerda, False, T) then
    Rebate(Esquerda, True)
  else if (Bola.Vel.X > 0) and ColideVarrida(P0, P1, Direita, True, T) then
    Rebate(Direita, False);

  if Bola.Pos.X < -BALL_SIZE then
  begin
    Inc(PontosD);
    FlashD := 0.6;
    LogInfo(LOG_GAME, 'ponto da direita (%d x %d) apos %d rebatidas',
      [PontosE, PontosD, Rebatidas]);
    Rebatidas := 0;
    ServeParaDireita := False;
    Bola.Reset(ServeParaDireita);
  end
  else if Bola.Pos.X > WORLD_W + BALL_SIZE then
  begin
    Inc(PontosE);
    FlashE := 0.6;
    LogInfo(LOG_GAME, 'ponto da esquerda (%d x %d) apos %d rebatidas',
      [PontosE, PontosD, Rebatidas]);
    Rebatidas := 0;
    ServeParaDireita := True;
    Bola.Reset(ServeParaDireita);
  end;
end;

begin
  Randomize;
  LogInit(llInfo);

  Cfg := TWindowConfig.Default;
  Cfg.Title := 'Jojos Engine - Pong';

  try
    Window := TWindow.Create(Cfg);
  except
    on E: Exception do
    begin
      WriteLn('ERRO ao criar a janela: ', E.Message);
      WriteLn('(enter para sair)');
      ReadLn;
      Halt(1);
    end;
  end;

  try
    try
      Device := TRHIDevice.Create(Window.GetGLProcAddress, True);

      Batch := TSpriteBatch.Create(Device, 256);
    except
      on E: Exception do
      begin
        WriteLn('ERRO ao iniciar o renderer: ', E.Message);
        WriteLn('(enter para sair)');
        ReadLn;
        Window.Free;
        Halt(1);
      end;
    end;

    try
      Camera.Init(WORLD_W, WORLD_H);
      Camera.FitMode := fmLetterbox;

      Input.Init;
      Clock.Start;
      Step.Init(1.0 / 60.0);
      Frames.Init(0.25);

      Esquerda.Init(PADDLE_MARGIN, WORLD_H * 0.5);
      Direita.Init(WORLD_W - PADDLE_MARGIN, WORLD_H * 0.5);
      PontosE := 0;
      PontosD := 0;
      Rebatidas := 0;
      UsaIA := True;
      ServeParaDireita := True;
      FlashE := 0;
      FlashD := 0;
      Bola.Reset(ServeParaDireita);

      CorCampo := Vec4(0.06, 0.07, 0.10, 1.0);
      CorObj   := Vec4(0.92, 0.94, 0.98, 1.0);
      CorRede  := Vec4(1.0, 1.0, 1.0, 0.12);

      WriteLn;
      WriteLn('W/S = esquerda | setas = direita | F1 = IA | espaco = saque');
      WriteLn('R = zera placar | F2 = vsync | ESC = sai');
      WriteLn;

      while not Window.ShouldClose do
      begin
        Dt := Clock.Tick;
        Input.BeginFrame;
        Window.PumpEvents(Input);

        if Input.WasPressedThisFrame(SDL_SCANCODE_ESCAPE) then
          Window.RequestClose;
        if Input.WasPressedThisFrame(SDL_SCANCODE_F2) then
          Window.SetVSync(not Window.VSync);
        if Input.WasPressedThisFrame(SDL_SCANCODE_F1) then
        begin
          UsaIA := not UsaIA;
          LogInfo(LOG_GAME, 'IA = %s', [BoolToStr(UsaIA, True)]);
        end;
        if Input.WasPressedThisFrame(SDL_SCANCODE_R) then
        begin
          PontosE := 0;
          PontosD := 0;
          Rebatidas := 0;
          Bola.Reset(ServeParaDireita);
        end;
        if Input.WasPressedThisFrame(SDL_SCANCODE_SPACE) then
          Bola.Parada := False;

        N := Step.Advance(Dt);
        for I := 1 to N do
          FixedUpdate(Step.FixedDelta);

        if Window.Minimized then
        begin
          SleepMS(10);
          Continue;
        end;

        Vp := Camera.ComputeViewport(Window.Width, Window.Height);
        Device.SetViewport(Vp.X, Vp.Y, Vp.W, Vp.H);

        Device.BeginFrame;
        Device.Clear([cfColor], CorCampo);

        AlphaR := Step.Alpha;
        EsqR := Lerp(Esquerda.PrevY, Esquerda.Y, AlphaR);
        DirR := Lerp(Direita.PrevY, Direita.Y, AlphaR);
        BolaPosR := Lerp2(Bola.PrevPos, Bola.Pos, AlphaR);

        Batch.BeginFrame(Camera);

        Y := 0;
        while Y < WORLD_H do
        begin
          Batch.DrawRect(Vec2(WORLD_W * 0.5, Y + 18.0), Vec2(4.0, 26.0), CorRede);
          Y := Y + 46.0;
        end;

        DrawNumero(PontosE, WORLD_W * 0.5 - 150.0, WORLD_H - 110.0, 96.0,
          Vec4(1, 1, 1, 0.25 + 0.5 * Saturate(FlashE / 0.6)));
        DrawNumero(PontosD, WORLD_W * 0.5 + 150.0, WORLD_H - 110.0, 96.0,
          Vec4(1, 1, 1, 0.25 + 0.5 * Saturate(FlashD / 0.6)));

        Batch.DrawRect(Vec2(Esquerda.CenterX, EsqR), Vec2(PADDLE_W, PADDLE_H), CorObj);
        Batch.DrawRect(Vec2(Direita.CenterX, DirR), Vec2(PADDLE_W, PADDLE_H), CorObj);
        Batch.DrawRect(BolaPosR, Vec2(BALL_SIZE, BALL_SIZE), CorObj);

        Batch.EndFrame;
        Window.Present;

        if Frames.Tick(Dt) then
          Window.SetTitle(Format(
            'Pong  |  %d x %d  |  %.0f fps  |  %d sprites em %d draw call(s)  ' +
            '|  bola %.0f u/s  |  IA %s  |  vsync %s (int %d)',
            [PontosE, PontosD, Frames.FPS, Batch.SpriteCount, Batch.FlushCount,
             Bola.Speed, BoolToStr(UsaIA, True), BoolToStr(Window.VSync, True),
             Window.SwapInterval]));
      end;

      Device.CheckError('fim do loop');
      WriteLn;
      WriteLn(Format('placar final: %d x %d em %.0fs',
        [PontosE, PontosD, Clock.Elapsed]));
    finally
      Batch.Free;
      Device.Free;
    end;
  finally
    Window.Free;
    LogShutdown;
  end;
end.
