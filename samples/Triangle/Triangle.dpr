

program Triangle;

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
  Engine.RHI.GL.Device in '..\..\src\RHI\Engine.RHI.GL.Device.pas';

const
  LOG_APP = 'sample';

  VS_SOURCE =
    '#version 330 core' + sLineBreak +
    'layout(location = 0) in vec2 aPos;' + sLineBreak +
    'layout(location = 1) in vec4 aColor;' + sLineBreak +
    'layout(location = 2) in vec2 aUV;' + sLineBreak +
    'uniform mat4 uMVP;' + sLineBreak +
    'out vec4 vColor;' + sLineBreak +
    'out vec2 vUV;' + sLineBreak +
    'void main()' + sLineBreak +
    '{' + sLineBreak +
    '    vColor = aColor;' + sLineBreak +
    '    vUV = aUV;' + sLineBreak +
    '    gl_Position = uMVP * vec4(aPos, 0.0, 1.0);' + sLineBreak +
    '}';

  FS_SOURCE =
    '#version 330 core' + sLineBreak +
    'in vec4 vColor;' + sLineBreak +
    'in vec2 vUV;' + sLineBreak +
    'uniform sampler2D uTexture;' + sLineBreak +
    'uniform vec4 uTint;' + sLineBreak +
    'out vec4 FragColor;' + sLineBreak +
    'void main()' + sLineBreak +
    '{' + sLineBreak +
    '    FragColor = vColor * uTint * texture(uTexture, vUV);' + sLineBreak +
    '}';

type

  TVertex2D = packed record
    X, Y: Single;
    R, G, B, A: Byte;
    U, V: Single;
  end;

function V2(const AX, AY: Single; const AR, AG, AB, AA: Byte;
  const AU, AV: Single): TVertex2D;
begin
  Result.X := AX; Result.Y := AY;
  Result.R := AR; Result.G := AG; Result.B := AB; Result.A := AA;
  Result.U := AU; Result.V := AV;
end;

procedure MakeCheckerboard(var Pixels: array of Byte; const Size, Cell: Integer);
var
  X, Y, I: Integer;
  Claro: Boolean;
begin
  for Y := 0 to Size - 1 do
    for X := 0 to Size - 1 do
    begin
      Claro := ((X div Cell) + (Y div Cell)) mod 2 = 0;
      I := (Y * Size + X) * 4;
      if Claro then
      begin
        Pixels[I] := 240; Pixels[I + 1] := 240; Pixels[I + 2] := 245;
      end
      else
      begin
        Pixels[I] := 60; Pixels[I + 1] := 70; Pixels[I + 2] := 90;
      end;
      Pixels[I + 3] := 255;
    end;
end;

var
  Window: TWindow;
  Cfg: TWindowConfig;
  Device: TRHIDevice;
  Input: TInput;
  Clock: TClock;
  Step: TFixedStep;
  Frames: TFrameCounter;

  Shader: TShaderHandle;
  WhiteTex, CheckerTex: TTextureHandle;
  TriMesh, QuadMesh: TMeshHandle;
  TriVB, QuadVB, QuadIB: TBufferHandle;

  Layout: TVertexLayout;
  TriVerts: array [0 .. 2] of TVertex2D;
  QuadVerts: array [0 .. 3] of TVertex2D;
  QuadIndices: array [0 .. 5] of Word;
  CheckerPixels: array [0 .. 64 * 64 * 4 - 1] of Byte;
  TexDesc: TTextureDesc;

  Proj, Model, MVP: TMat4;
  CamPos: TVec2;
  CamZoom: Single;
  Angulo, AnguloAnterior: Single;
  Girando: Boolean;
  Erro: string;
  Dt, Alpha, AngRender: Single;
  N, I: Integer;
  S: TRHIStats;

begin
  LogInit(llDebug);

  Cfg := TWindowConfig.Default;
  Cfg.Title := 'Jojos Engine - Triangle';
  Cfg.Width := 1280;
  Cfg.Height := 720;
  Cfg.DebugContext := True;

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
    except
      on E: Exception do
      begin
        WriteLn('ERRO ao iniciar o OpenGL: ', E.Message);
        WriteLn('Seu driver suporta OpenGL 3.3 core?');
        WriteLn('(enter para sair)');
        ReadLn;
        Window.Free;
        Halt(1);
      end;
    end;

    try

      Shader := Device.CreateShader(VS_SOURCE, FS_SOURCE, Erro);
      if Shader.IsNull then
      begin
        WriteLn('Shader nao compilou:');
        WriteLn(Erro);
        WriteLn('(enter para sair)');
        ReadLn;
        Halt(1);
      end;

      Layout.Init(SizeOf(TVertex2D));
      Layout.Add(0, vfFloat2,  0);
      Layout.Add(1, vfUByte4N, 8);
      Layout.Add(2, vfFloat2,  12);
      if Layout.PackedSize <> SizeOf(TVertex2D) then
        LogWarn(LOG_APP, 'layout (%d bytes) nao bate com TVertex2D (%d)',
          [Layout.PackedSize, SizeOf(TVertex2D)]);

      TriVerts[0] := V2(   0.0,  120.0, 235,  80,  70, 255, 0.5, 1.0);
      TriVerts[1] := V2(-110.0, -90.0,   80, 210, 120, 255, 0.0, 0.0);
      TriVerts[2] := V2( 110.0, -90.0,   90, 150, 240, 255, 1.0, 0.0);

      TriVB := Device.CreateBuffer(bkVertex, buStatic, SizeOf(TriVerts),
        @TriVerts[0]);
      TriMesh := Device.CreateMesh(TriVB, Layout, 3, THandle.Null);

      QuadVerts[0] := V2(-60.0, -60.0, 255, 255, 255, 255, 0.0, 0.0);
      QuadVerts[1] := V2( 60.0, -60.0, 255, 255, 255, 255, 1.0, 0.0);
      QuadVerts[2] := V2( 60.0,  60.0, 255, 255, 255, 255, 1.0, 1.0);
      QuadVerts[3] := V2(-60.0,  60.0, 255, 255, 255, 255, 0.0, 1.0);

      QuadIndices[0] := 0; QuadIndices[1] := 1; QuadIndices[2] := 2;
      QuadIndices[3] := 2; QuadIndices[4] := 3; QuadIndices[5] := 0;

      QuadVB := Device.CreateBuffer(bkVertex, buStatic, SizeOf(QuadVerts),
        @QuadVerts[0]);
      QuadIB := Device.CreateBuffer(bkIndex, buStatic, SizeOf(QuadIndices),
        @QuadIndices[0]);
      QuadMesh := Device.CreateMesh(QuadVB, Layout, 4, QuadIB, 6, ifUInt16);

      WhiteTex := Device.CreateWhiteTexture;

      MakeCheckerboard(CheckerPixels, 64, 8);
      TexDesc := TTextureDesc.Default2D(64, 64);
      TexDesc.Filter := tflNearest;
      TexDesc.Wrap := twRepeat;
      TexDesc.Pixels := @CheckerPixels[0];
      CheckerTex := Device.CreateTexture(TexDesc);

      Device.CheckError('setup');

      WriteLn;
      WriteLn('tudo criado. WASD move a camera, Q/E zoom, espaco = stats, ESC sai.');
      WriteLn;

      Input.Init;
      Clock.Start;
      Step.Init(1.0 / 60.0);
      Frames.Init(0.25);
      CamPos := TVec2.Zero;
      CamZoom := 1.0;
      Angulo := 0.0;
      AnguloAnterior := 0.0;
      Girando := True;

      Device.SetBlend(bmAlpha);
      Device.SetDepthTest(dtOff);

      while not Window.ShouldClose do
      begin
        Dt := Clock.Tick;
        Input.BeginFrame;
        Window.PumpEvents(Input);

        if Input.WasPressedThisFrame(SDL_SCANCODE_ESCAPE) then
          Window.RequestClose;
        if Input.WasPressedThisFrame(SDL_SCANCODE_F1) then
          Window.SetVSync(not Window.VSync);
        if Input.WasPressedThisFrame(SDL_SCANCODE_F2) then
          Girando := not Girando;
        if Input.WasPressedThisFrame(SDL_SCANCODE_R) then
        begin
          CamPos := TVec2.Zero;
          CamZoom := 1.0;
        end;
        if Input.WasPressedThisFrame(SDL_SCANCODE_SPACE) then
        begin
          S := Device.Stats;
          WriteLn(Format('draw calls=%d  triangulos=%d  trocas de estado=%d  ' +
            'uploads=%d  fps=%.0f', [S.DrawCalls, S.Triangles, S.StateChanges,
            S.BufferUploads, Frames.FPS]));
        end;

        N := Step.Advance(Dt);
        for I := 1 to N do
        begin
          AnguloAnterior := Angulo;
          if Girando then
            Angulo := Angulo + 0.6 * Step.FixedDelta;

          CamPos.X := CamPos.X + (Input.Axis(SDL_SCANCODE_A, SDL_SCANCODE_D) +
            Input.Axis(SDL_SCANCODE_LEFT, SDL_SCANCODE_RIGHT)) * 400.0 *
            Step.FixedDelta;
          CamPos.Y := CamPos.Y + (Input.Axis(SDL_SCANCODE_S, SDL_SCANCODE_W) +
            Input.Axis(SDL_SCANCODE_DOWN, SDL_SCANCODE_UP)) * 400.0 *
            Step.FixedDelta;

          if Input.IsDown(SDL_SCANCODE_Q) then
            CamZoom := Clamp(CamZoom * (1.0 - 0.9 * Step.FixedDelta), 0.2, 5.0);
          if Input.IsDown(SDL_SCANCODE_E) then
            CamZoom := Clamp(CamZoom * (1.0 + 0.9 * Step.FixedDelta), 0.2, 5.0);
        end;

        if Window.Minimized then
        begin
          SleepMS(10);
          Continue;
        end;

        Alpha := Step.Alpha;
        AngRender := Lerp(AnguloAnterior, Angulo, Alpha);

        if Window.ResizedThisFrame or (Device.ViewportWidth <> Window.Width) then
          Device.SetViewport(0, 0, Window.Width, Window.Height);

        Device.BeginFrame;
        Device.Clear([cfColor], Vec4(0.09, 0.10, 0.13, 1.0));

        Proj := TMat4.Ortho(
          CamPos.X - Window.Width  * 0.5 / CamZoom,
          CamPos.X + Window.Width  * 0.5 / CamZoom,
          CamPos.Y - Window.Height * 0.5 / CamZoom,
          CamPos.Y + Window.Height * 0.5 / CamZoom,
          -1.0, 1.0);

        Device.SetShader(Shader);
        Device.SetUniformInt('uTexture', 0);

        Device.SetTexture(0, WhiteTex);
        Device.SetUniformVec4('uTint', Vec4(1, 1, 1, 1));
        Model := TMat4.TRS(TVec3.Zero,
          TQuat.FromAxisAngle(TVec3.UnitZ, AngRender), TVec3.One);
        MVP := Proj * Model;
        Device.SetUniformMat4('uMVP', MVP);
        Device.Draw(TriMesh, ptTriangles, 0, 3);

        Device.SetTexture(0, CheckerTex);
        Model := TMat4.TRS(
          Vec3(Cos(AngRender) * 280.0, Sin(AngRender) * 280.0, 0.0),
          TQuat.FromAxisAngle(TVec3.UnitZ, -AngRender * 2.0),
          TVec3.One);
        MVP := Proj * Model;
        Device.SetUniformMat4('uMVP', MVP);
        Device.DrawIndexed(QuadMesh, ptTriangles, 6);

        Device.SetUniformVec4('uTint', Vec4(1.0, 0.6, 0.3, 0.45));
        Model := TMat4.TRS(
          Vec3(Cos(AngRender + PI_F) * 280.0, Sin(AngRender + PI_F) * 280.0, 0.0),
          TQuat.FromAxisAngle(TVec3.UnitZ, AngRender * 2.0),
          Vec3(1.5, 1.5, 1.0));
        MVP := Proj * Model;
        Device.SetUniformMat4('uMVP', MVP);
        Device.DrawIndexed(QuadMesh, ptTriangles, 6);

        Window.Present;

        if Frames.Tick(Dt) then
        begin
          S := Device.Stats;
          Window.SetTitle(Format(
            'Jojos Engine - Triangle  |  %.0f fps (%.2f ms)  |  %d draws, ' +
            '%d tris  |  zoom %.2f  |  vsync %s',
            [Frames.FPS, Frames.FrameMS, S.DrawCalls, S.Triangles, CamZoom,
             BoolToStr(Window.VSync, True)]));
        end;
      end;

      Device.CheckError('fim do loop');
      WriteLn;
      WriteLn(Format('encerrado. %d frames, %d passos, %.1fs.',
        [Step.TotalFrames, Step.TotalSteps, Clock.Elapsed]));
      if LogErrorCount > 0 then
        WriteLn(Format('ATENCAO: %d erro(s) registrado(s) no log.',
          [LogErrorCount]));
    finally
      Device.Free;
    end;
  finally
    Window.Free;
    LogShutdown;
  end;
end.
