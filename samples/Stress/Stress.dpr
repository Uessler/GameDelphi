

program Stress;

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
  LOG_APP = 'stress';
  WORLD_W = 1920.0;
  WORLD_H = 1080.0;
  MAX_SPRITES = 200000;
  TEX_SIZE = 32;

type
  TBicho = record
    Pos, PrevPos: TVec2;
    Vel: TVec2;
    Ang, PrevAng, VelAng: Single;
    Tam: Single;
    Cor: TVec4;
  end;

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

  TexA, TexB: TTextureHandle;
  Pixels: array [0 .. TEX_SIZE * TEX_SIZE * 4 - 1] of Byte;
  TexDesc: TTextureDesc;

  Bichos: array of TBicho;
  Quantos: Integer;
  Batched: Boolean;
  ComCulling: Boolean;
  DuasTexturas: Boolean;

  Dt, A: Single;
  N, I: Integer;
  P: TVec2;
  Ang: Single;
  Tex: TTextureHandle;
  S: TRHIStats;
  PiorFrame, MelhorFPS: Single;

procedure GeraTextura(const Claro: Boolean);
var
  X, Y, Idx: Integer;
  D, R: Single;
  Base: Byte;
begin

  R := TEX_SIZE * 0.5;
  if Claro then Base := 255 else Base := 120;
  for Y := 0 to TEX_SIZE - 1 do
    for X := 0 to TEX_SIZE - 1 do
    begin
      Idx := (Y * TEX_SIZE + X) * 4;
      D := Sqrt(Sqr(X + 0.5 - R) + Sqr(Y + 0.5 - R)) / R;
      Pixels[Idx] := Base;
      Pixels[Idx + 1] := Base;
      Pixels[Idx + 2] := Base;
      Pixels[Idx + 3] := Byte(Round(Saturate(1.0 - D) * 255.0));
    end;
end;

procedure Reinicia;
var
  I: Integer;
begin
  SetLength(Bichos, MAX_SPRITES);
  for I := 0 to MAX_SPRITES - 1 do
  begin
    Bichos[I].Pos := Vec2(Random * WORLD_W, Random * WORLD_H);
    Bichos[I].PrevPos := Bichos[I].Pos;
    Bichos[I].Vel := Vec2((Random - 0.5) * 260.0, (Random - 0.5) * 260.0);
    Bichos[I].Ang := Random * TAU_F;
    Bichos[I].PrevAng := Bichos[I].Ang;
    Bichos[I].VelAng := (Random - 0.5) * 5.0;
    Bichos[I].Tam := 14.0 + Random * 26.0;
    Bichos[I].Cor := Vec4(0.35 + Random * 0.65, 0.35 + Random * 0.65,
      0.45 + Random * 0.55, 0.85);
  end;
end;

procedure FixedUpdate(const Dt: Single);
var
  I: Integer;
begin
  for I := 0 to Quantos - 1 do
  begin
    Bichos[I].PrevPos := Bichos[I].Pos;
    Bichos[I].PrevAng := Bichos[I].Ang;

    Bichos[I].Pos := Bichos[I].Pos + Bichos[I].Vel * Dt;
    Bichos[I].Ang := Bichos[I].Ang + Bichos[I].VelAng * Dt;

    if (Bichos[I].Pos.X < 0) and (Bichos[I].Vel.X < 0) then
      Bichos[I].Vel.X := -Bichos[I].Vel.X;
    if (Bichos[I].Pos.X > WORLD_W) and (Bichos[I].Vel.X > 0) then
      Bichos[I].Vel.X := -Bichos[I].Vel.X;
    if (Bichos[I].Pos.Y < 0) and (Bichos[I].Vel.Y < 0) then
      Bichos[I].Vel.Y := -Bichos[I].Vel.Y;
    if (Bichos[I].Pos.Y > WORLD_H) and (Bichos[I].Vel.Y > 0) then
      Bichos[I].Vel.Y := -Bichos[I].Vel.Y;
  end;
end;

function ModoStr: string;
begin
  if Batched then Result := 'BATCHED' else Result := 'SEM BATCH';
end;

procedure Relatorio;
begin
  S := Device.Stats;
  WriteLn('-------------------------------------------------------------');
  WriteLn('modo          : ' + ModoStr);
  WriteLn(Format('sprites pedidos: %d', [Quantos]));
  WriteLn(Format('sprites aceitos: %d   descartados pelo culling: %d',
    [Batch.SpriteCount, Batch.CulledCount]));
  WriteLn(Format('draw calls     : %d', [Batch.FlushCount]));
  WriteLn(Format('uploads        : %d   (%.2f MB)',
    [S.BufferUploads, S.BufferBytesUploaded / (1024 * 1024)]));
  WriteLn(Format('trocas de estado: %d', [S.StateChanges]));
  WriteLn(Format('fps            : %.1f   (%.2f ms por frame)',
    [Frames.FPS, Frames.FrameMS]));
  WriteLn(Format('culling        : %s   texturas: %d',
    [BoolToStr(ComCulling, True), 1 + Ord(DuasTexturas)]));
  WriteLn('-------------------------------------------------------------');
end;

begin
  Randomize;
  LogInit(llInfo);

  Cfg := TWindowConfig.Default;
  Cfg.Title := 'Jojos Engine - Stress';

  Cfg.VSync := False;

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
      Device := TRHIDevice.Create(Window.GetGLProcAddress, False);
      Batch := TSpriteBatch.Create(Device);
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
      GeraTextura(True);
      TexDesc := TTextureDesc.Default2D(TEX_SIZE, TEX_SIZE);
      TexDesc.Pixels := @Pixels[0];
      TexA := Device.CreateTexture(TexDesc);

      GeraTextura(False);
      TexDesc.Pixels := @Pixels[0];
      TexB := Device.CreateTexture(TexDesc);

      Camera.Init(WORLD_W, WORLD_H);
      Input.Init;
      Clock.Start;
      Step.Init(1.0 / 60.0);
      Frames.Init(0.5);

      Quantos := 10000;
      Batched := True;
      ComCulling := False;
      DuasTexturas := False;
      PiorFrame := 0;
      MelhorFPS := 0;
      Reinicia;

      WriteLn;
      WriteLn('setas = quantidade | F3 = batch on/off | F4 = culling |');
      WriteLn('F5 = 1 ou 2 texturas | Q/E = zoom | espaco = relatorio | ESC = sai');
      WriteLn;
      WriteLn('DICA: aperte espaco no modo BATCHED, depois F3 e espaco de novo.');
      WriteLn('A diferenca de fps entre os dois e o custo de draw call.');
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
        if Input.WasPressedThisFrame(SDL_SCANCODE_F3) then
        begin
          Batched := not Batched;
          MelhorFPS := 0;
          Relatorio;
        end;
        if Input.WasPressedThisFrame(SDL_SCANCODE_F4) then
          ComCulling := not ComCulling;
        if Input.WasPressedThisFrame(SDL_SCANCODE_F5) then
          DuasTexturas := not DuasTexturas;
        if Input.WasPressedThisFrame(SDL_SCANCODE_SPACE) then
          Relatorio;
        if Input.WasPressedThisFrame(SDL_SCANCODE_R) then
          Reinicia;

        if Input.WasPressedThisFrame(SDL_SCANCODE_UP) then
          Quantos := Clampi(Quantos + 1000, 0, MAX_SPRITES);
        if Input.WasPressedThisFrame(SDL_SCANCODE_DOWN) then
          Quantos := Clampi(Quantos - 1000, 0, MAX_SPRITES);
        if Input.WasPressedThisFrame(SDL_SCANCODE_RIGHT) then
          Quantos := Clampi(Quantos + 100, 0, MAX_SPRITES);
        if Input.WasPressedThisFrame(SDL_SCANCODE_LEFT) then
          Quantos := Clampi(Quantos - 100, 0, MAX_SPRITES);

        if Input.IsDown(SDL_SCANCODE_Q) then
          Camera.Zoom := Clamp(Camera.Zoom * (1.0 - 1.2 * Dt), 0.1, 4.0);
        if Input.IsDown(SDL_SCANCODE_E) then
          Camera.Zoom := Clamp(Camera.Zoom * (1.0 + 1.2 * Dt), 0.1, 4.0);

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
        Device.Clear([cfColor], Vec4(0.05, 0.06, 0.09, 1.0));

        Batch.BeginFrame(Camera);
        if ComCulling then
          Batch.EnableCulling(Camera.VisibleBounds)
        else
          Batch.DisableCulling;

        A := Step.Alpha;
        for I := 0 to Quantos - 1 do
        begin
          P := Lerp2(Bichos[I].PrevPos, Bichos[I].Pos, A);
          Ang := LerpAngle(Bichos[I].PrevAng, Bichos[I].Ang, A);

          if DuasTexturas and (I and 1 = 1) then
            Tex := TexB
          else
            Tex := TexA;

          Batch.DrawSprite(Tex, P, Vec2(Bichos[I].Tam, Bichos[I].Tam),
            TRect2.Create(0, 0, 1, 1), Bichos[I].Cor, Ang, Vec2(0.5, 0.5));

          if not Batched then
            Batch.Flush;
        end;
        Batch.EndFrame;

        Window.Present;

        if Frames.Tick(Dt) then
        begin
          if Frames.FPS > MelhorFPS then
            MelhorFPS := Frames.FPS;
          if Frames.FrameMS > PiorFrame then
            PiorFrame := Frames.FrameMS;
          Window.SetTitle(Format(
            'Stress  |  %d sprites  |  %.0f fps (%.2f ms)  |  %d draw call(s)  ' +
            '|  %s  |  culling %s  |  zoom %.2f',
            [Quantos, Frames.FPS, Frames.FrameMS, Batch.FlushCount,
             ModoStr, BoolToStr(ComCulling, True),
             Camera.Zoom]));
        end;
      end;

      WriteLn;
      Relatorio;
    finally
      Batch.Free;
      Device.Free;
    end;
  finally
    Window.Free;
    LogShutdown;
  end;
end.
