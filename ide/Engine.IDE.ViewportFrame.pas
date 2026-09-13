unit Engine.IDE.ViewportFrame;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Graphics,
  Engine.Core.Math,
  Engine.Core.Loop,
  Engine.Core.Log,
  Engine.Core.Memory,
  Engine.Platform.SDL2,
  Engine.Platform.Time,
  Engine.Platform.Input,
  Engine.Platform.Window,
  Engine.RHI.Types,
  Engine.RHI.GL.Loader,
  Engine.RHI.GL.Device,
  Engine.Renderer.Camera2D,
  Engine.Renderer.SpriteBatch;

type
  TJojosViewportSurface = class(TCustomControl)
  private
    FBitmap: TBitmap;
    procedure SetBitmap(const Value: TBitmap);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
  published
    property Align;
    property Anchors;
    property Constraints;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TDemoSprite = record
    Pos, PrevPos, Vel: TVec2;
    Ang, PrevAng, VelAng: Single;
    Tam: Single;
    Cor: TVec4;
  end;

  TJojosViewportFrame = class(TFrame)
    PanelTop: TPanel;
    BtnPlay: TButton;
    BtnReset: TButton;
    LblStats: TLabel;
    PanelHost: TJojosViewportSurface;
    Ticker: TTimer;
    procedure TickerTimer(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnResetClick(Sender: TObject);
    procedure PanelHostMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure PanelHostMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PanelHostMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FWindow: TWindow;
    FDevice: TRHIDevice;
    FRenderTarget: TRenderTargetHandle;
    FBitmap: TBitmap;
    FRenderWidth: Integer;
    FRenderHeight: Integer;
    FBatch: TSpriteBatch;
    FCamera: TCamera2D;
    FInput: TInput;
    FClock: TClock;
    FStep: TFixedStep;
    FFrames: TFrameCounter;

    FIniciado: Boolean;
    FFalhou: Boolean;
    FRodando: Boolean;
    FNoTick: Boolean;
    FPiorTickMs: Double;
    FTicksLentos: Integer;
    FMotivoParado: string;
    FSprites: array of TDemoSprite;

    procedure IniciaEngine;
    procedure EncerraEngine;
    procedure ReiniciaCena;
    procedure PassoFixo(const Dt: Single);
    procedure Desenha;
    procedure GaranteSuperficie;
    procedure AtualizaBarra(const Fps: Single);
    procedure MostraErro(const Msg: string);
    function PodeDesenhar: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

var
  GUltimoAviso: string = '';

procedure SinkDoViewport(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);
begin
  if Level >= llWarn then
    GUltimoAviso := Formatted;
end;

const
  MUNDO_W = 960.0;
  MUNDO_H = 540.0;
  QUANTOS = 400;

constructor TJojosViewportSurface.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color := clBlack;
  ParentDoubleBuffered := False;
  DoubleBuffered := True;
  ControlStyle := (ControlStyle + [csOpaque]) - [csParentBackground];
end;

procedure TJojosViewportSurface.SetBitmap(const Value: TBitmap);
begin
  if FBitmap = Value then
    Exit;
  FBitmap := Value;
  Invalidate;
end;

procedure TJojosViewportSurface.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TJojosViewportSurface.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  if (FBitmap <> nil) and (FBitmap.Width > 0) and (FBitmap.Height > 0) then
  begin
    if (FBitmap.Width = ClientWidth) and (FBitmap.Height = ClientHeight) then
      Canvas.Draw(0, 0, FBitmap)
    else
      Canvas.StretchDraw(R, FBitmap);
  end
  else
  begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(R);
  end;
end;

constructor TJojosViewportFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIniciado := False;
  FFalhou := False;
  FRodando := True;
  FNoTick := False;
  FRenderTarget := THandle.Null;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf32bit;
  PanelHost.Bitmap := FBitmap;
  FRenderWidth := 0;
  FRenderHeight := 0;
  FPiorTickMs := 0;
  FTicksLentos := 0;
  FMotivoParado := '';
  Ticker.Interval := 33;
  Ticker.Enabled := True;
end;

destructor TJojosViewportFrame.Destroy;
begin
  Ticker.Enabled := False;
  EncerraEngine;
  PanelHost.Bitmap := nil;
  FreeAndNil(FBitmap);
  inherited;
end;

function TJojosViewportFrame.PodeDesenhar: Boolean;
begin
  FMotivoParado := '';
  if not FIniciado then FMotivoParado := 'nao iniciado'
  else if FFalhou then FMotivoParado := 'falhou'
  else if not Self.Showing then FMotivoParado := 'nao visivel'
  else if PanelHost.ClientWidth <= 0 then FMotivoParado := 'largura 0'
  else if PanelHost.ClientHeight <= 0 then FMotivoParado := 'altura 0'
  else if FWindow = nil then FMotivoParado := 'sem janela'
  else if FRenderTarget.IsNull then FMotivoParado := 'sem render target';
  Result := FMotivoParado = '';
end;

procedure TJojosViewportFrame.AtualizaBarra(const Fps: Single);
var
  Diag: string;
begin
  Diag := Format('offscreen=%dx%d  area=%dx%d',
    [FRenderWidth, FRenderHeight,
     PanelHost.ClientWidth, PanelHost.ClientHeight]);

  if FMotivoParado <> '' then
    Diag := Diag + '  PARADO: ' + FMotivoParado;

  if FIniciado and (FBatch <> nil) then
    LblStats.Caption := Format('%.0f fps | %d spr / %d dc | %.1f ms | %s',
      [Fps, FBatch.SpriteCount, FBatch.FlushCount, FPiorTickMs, Diag])
  else
    LblStats.Caption := Diag;

  if GUltimoAviso <> '' then
    LblStats.Caption := LblStats.Caption + '  >> ' + GUltimoAviso;
end;

procedure TJojosViewportFrame.MostraErro(const Msg: string);
begin
  FFalhou := True;
  Ticker.Enabled := False;
  LblStats.Font.Color := clRed;
  LblStats.Caption := Msg;
  PanelHost.Repaint;
end;

procedure TJojosViewportFrame.IniciaEngine;
var
  Cfg: TWindowConfig;
begin
  if FIniciado or FFalhou then
    Exit;
  if (PanelHost.ClientWidth <= 0) or (PanelHost.ClientHeight <= 0) then
    Exit;

  try
    LogInit(llInfo);
    LogClearSinks;
    LogAddSink(SinkDoViewport);

    Cfg := TWindowConfig.Default;
    Cfg.Width := PanelHost.ClientWidth;
    Cfg.Height := PanelHost.ClientHeight;
    Cfg.Visible := False;
    Cfg.Resizable := False;
    Cfg.VSync := False;
    Cfg.MSAASamples := 0;
    Cfg.DebugContext := False;

    FWindow := TWindow.Create(Cfg);
    FDevice := TRHIDevice.Create(FWindow.GetGLProcAddress, False);
    FRenderTarget := FDevice.CreateRenderTarget(Cfg.Width, Cfg.Height);
    FRenderWidth := Cfg.Width;
    FRenderHeight := Cfg.Height;
    FBitmap.SetSize(FRenderWidth, FRenderHeight);
    FBatch := TSpriteBatch.Create(FDevice, 2048);

    FCamera.Init(MUNDO_W, MUNDO_H);
    FInput.Init;
    FClock.Start;
    FStep.Init(1.0 / 60.0);
    FFrames.Init(0.5);
    ReiniciaCena;

    FIniciado := True;
    LogInfo('ide', 'viewport off-screen iniciado: %s',
      [FDevice.RendererString]);
  except
    on E: Exception do
    begin
      EncerraEngine;
      MostraErro('Falha ao iniciar o viewport: ' + E.Message);
    end;
  end;
end;

procedure TJojosViewportFrame.EncerraEngine;
begin
  if (FWindow = nil) and (FDevice = nil) and (FBatch = nil) then
  begin
    FIniciado := False;
    Exit;
  end;
  FIniciado := False;
  try
    if FWindow <> nil then
      FWindow.MakeCurrent;
  except
  end;
  FreeAndNil(FBatch);
  if (FDevice <> nil) and not FRenderTarget.IsNull then
    FDevice.DestroyRenderTarget(FRenderTarget);
  FRenderTarget := THandle.Null;
  FreeAndNil(FDevice);
  FreeAndNil(FWindow);
  FRenderWidth := 0;
  FRenderHeight := 0;
end;

procedure TJojosViewportFrame.GaranteSuperficie;
var
  W, H: Integer;
begin
  W := PanelHost.ClientWidth;
  H := PanelHost.ClientHeight;
  if (W <= 0) or (H <= 0) then
    Exit;
  if (W = FRenderWidth) and (H = FRenderHeight) then
    Exit;

  if not FDevice.ResizeRenderTarget(FRenderTarget, W, H) then
    raise ERHIError.CreateFmt('Falha ao redimensionar viewport para %dx%d',
      [W, H]);
  FRenderWidth := W;
  FRenderHeight := H;
  FBitmap.SetSize(W, H);
  FWindow.NotifyResize(W, H);
end;

procedure TJojosViewportFrame.ReiniciaCena;
var
  I: Integer;
begin
  Randomize;
  SetLength(FSprites, QUANTOS);
  for I := 0 to QUANTOS - 1 do
  begin
    FSprites[I].Pos := Vec2(Random * MUNDO_W, Random * MUNDO_H);
    FSprites[I].PrevPos := FSprites[I].Pos;
    FSprites[I].Vel := Vec2((Random - 0.5) * 220.0, (Random - 0.5) * 220.0);
    FSprites[I].Ang := Random * TAU_F;
    FSprites[I].PrevAng := FSprites[I].Ang;
    FSprites[I].VelAng := (Random - 0.5) * 4.0;
    FSprites[I].Tam := 12.0 + Random * 22.0;
    FSprites[I].Cor := Vec4(0.4 + Random * 0.6, 0.4 + Random * 0.6,
      0.5 + Random * 0.5, 0.9);
  end;
end;

procedure TJojosViewportFrame.PassoFixo(const Dt: Single);
var
  I: Integer;
begin
  for I := 0 to High(FSprites) do
  begin
    FSprites[I].PrevPos := FSprites[I].Pos;
    FSprites[I].PrevAng := FSprites[I].Ang;
    FSprites[I].Pos := FSprites[I].Pos + FSprites[I].Vel * Dt;
    FSprites[I].Ang := FSprites[I].Ang + FSprites[I].VelAng * Dt;

    if (FSprites[I].Pos.X < 0) and (FSprites[I].Vel.X < 0) then
      FSprites[I].Vel.X := -FSprites[I].Vel.X;
    if (FSprites[I].Pos.X > MUNDO_W) and (FSprites[I].Vel.X > 0) then
      FSprites[I].Vel.X := -FSprites[I].Vel.X;
    if (FSprites[I].Pos.Y < 0) and (FSprites[I].Vel.Y < 0) then
      FSprites[I].Vel.Y := -FSprites[I].Vel.Y;
    if (FSprites[I].Pos.Y > MUNDO_H) and (FSprites[I].Vel.Y > 0) then
      FSprites[I].Vel.Y := -FSprites[I].Vel.Y;
  end;
end;

procedure TJojosViewportFrame.Desenha;
var
  Vp: TViewport;
  A: Single;
  I: Integer;
  P: TVec2;
  Ang: Single;
  Mundo: TVec2;
begin
  GaranteSuperficie;
  FDevice.SetRenderTarget(FRenderTarget);
  Vp := FCamera.ComputeViewport(FRenderWidth, FRenderHeight);
  FDevice.SetViewport(Vp.X, Vp.Y, Vp.W, Vp.H);
  FDevice.BeginFrame;
  FDevice.Clear([cfColor], Vec4(0.10, 0.11, 0.14, 1.0));

  FBatch.BeginFrame(FCamera);

  A := 0;
  while A <= MUNDO_W do
  begin
    FBatch.DrawRect(Vec2(A, MUNDO_H * 0.5), Vec2(1.0, MUNDO_H),
      Vec4(1, 1, 1, 0.05));
    A := A + 60.0;
  end;
  A := 0;
  while A <= MUNDO_H do
  begin
    FBatch.DrawRect(Vec2(MUNDO_W * 0.5, A), Vec2(MUNDO_W, 1.0),
      Vec4(1, 1, 1, 0.05));
    A := A + 60.0;
  end;

  A := FStep.Alpha;
  for I := 0 to High(FSprites) do
  begin
    P := Lerp2(FSprites[I].PrevPos, FSprites[I].Pos, A);
    Ang := LerpAngle(FSprites[I].PrevAng, FSprites[I].Ang, A);
    FBatch.DrawRectRotated(P, Vec2(FSprites[I].Tam, FSprites[I].Tam), Ang,
      FSprites[I].Cor);
  end;

  if (FInput.MouseX >= 0) and (FInput.MouseY >= 0) then
  begin
    Mundo := FCamera.ScreenToWorld(FInput.MouseX, FInput.MouseY, Vp);
    FBatch.DrawRectOutline(TRect2.FromCenter(Mundo, Vec2(14, 14)), 2.0,
      Vec4(1.0, 0.85, 0.2, 0.9));
  end;

  FBatch.EndFrame;
  if not FDevice.ReadRenderTargetPixels(FRenderTarget,
    FBitmap.ScanLine[FBitmap.Height - 1],
    NativeInt(FBitmap.Width) * NativeInt(FBitmap.Height) * 4) then
    raise ERHIError.Create('Falha ao ler o framebuffer do viewport');
  FDevice.SetRenderTarget(THandle.Null);
  PanelHost.Repaint;
end;

procedure TJojosViewportFrame.TickerTimer(Sender: TObject);
var
  Dt: Single;
  N, I: Integer;
  Cronometro: TStopwatch;
  Ms: Double;
begin
  if FFalhou then
    Exit;

  if FNoTick then
    Exit;
  FNoTick := True;
  try
    try
    if not FIniciado then
    begin
      IniciaEngine;
      if not FIniciado then
        Exit;
    end;

    if not PodeDesenhar then
    begin
      FClock.Tick;
      FStep.Reset;
      AtualizaBarra(0);
      Exit;
    end;

    Cronometro.Start;

    FWindow.MakeCurrent;

    Dt := FClock.Tick;
    FInput.BeginFrame;

    if FRodando then
    begin
      N := FStep.Advance(Dt);
      for I := 1 to N do
        PassoFixo(FStep.FixedDelta);
    end;

    Desenha;

    Ms := Cronometro.ElapsedMS;
    if Ms > FPiorTickMs then
      FPiorTickMs := Ms;

    if Ms > 150.0 then
    begin
      Inc(FTicksLentos);
      if (FTicksLentos > 10) and (Ticker.Interval < 250) then
      begin
        Ticker.Interval := 250;
        LogWarn('ide', 'frames lentos (%.0f ms); viewport caiu para 4 fps ' +
          'para nao travar a IDE', [Ms]);
      end;
      if FTicksLentos > 40 then
      begin
        MostraErro(Format('Viewport desligado: frames de %.0f ms estavam ' +
          'travando a IDE. Renderer: %s', [Ms, FDevice.RendererString]));
        Exit;
      end;
    end
    else if FTicksLentos > 0 then
      Dec(FTicksLentos);

    if FFrames.Tick(Dt) then
      AtualizaBarra(FFrames.FPS);
    except
      on E: Exception do
        MostraErro('Erro no viewport: ' + E.Message);
    end;
  finally
    FNoTick := False;
  end;
end;

procedure TJojosViewportFrame.BtnPlayClick(Sender: TObject);
begin
  FRodando := not FRodando;
  if FRodando then
    BtnPlay.Caption := 'Pausar'
  else
    BtnPlay.Caption := 'Rodar';
  FStep.Reset;
  FClock.Tick;
end;

procedure TJojosViewportFrame.BtnResetClick(Sender: TObject);
begin
  if FIniciado then
    ReiniciaCena;
end;

procedure TJojosViewportFrame.PanelHostMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  FInput.SetMousePosition(X, Y, 0, 0);
end;

procedure TJojosViewportFrame.PanelHostMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FInput.SetMousePosition(X, Y, 0, 0);
  case Button of
    mbLeft: FInput.SetMouseButton(SDL_BUTTON_LEFT, True);
    mbRight: FInput.SetMouseButton(SDL_BUTTON_RIGHT, True);
    mbMiddle: FInput.SetMouseButton(SDL_BUTTON_MIDDLE, True);
  end;
end;

procedure TJojosViewportFrame.PanelHostMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  case Button of
    mbLeft: FInput.SetMouseButton(SDL_BUTTON_LEFT, False);
    mbRight: FInput.SetMouseButton(SDL_BUTTON_RIGHT, False);
    mbMiddle: FInput.SetMouseButton(SDL_BUTTON_MIDDLE, False);
  end;
end;

initialization
  RegisterClass(TJojosViewportSurface);

finalization
  UnRegisterClass(TJojosViewportSurface);

end.
