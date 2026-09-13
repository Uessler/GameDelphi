

unit Engine.Platform.Window;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils,
{$IFDEF FPC}
  Math,
{$ELSE}
  System.Math,
{$ENDIF}
  Engine.Core.Log,
  Engine.Platform.SDL2,
  Engine.Platform.Input;

type
  EPlatformError = class(Exception);

  TWindowConfig = record
    Title: string;
    Width: Integer;
    Height: Integer;
    Resizable: Boolean;
    Visible: Boolean;

    VSync: Boolean;
    GLMajor: Integer;
    GLMinor: Integer;

    MSAASamples: Integer;
    DepthBits: Integer;
    StencilBits: Integer;

    DebugContext: Boolean;

    class function Default: TWindowConfig; static;
  end;

  TWindow = class
  private
    FForeign: Boolean;
    FHandle: TSDL_Window;
    FContext: TSDL_GLContext;
    FWidth: Integer;
    FHeight: Integer;
    FShouldClose: Boolean;
    FFocused: Boolean;
    FMinimized: Boolean;
    FResizedThisFrame: Boolean;
    FVSyncRequested: Boolean;
    FSwapInterval: Integer;
    FVSyncSettled: Boolean;
    FMSAAFellBack: Boolean;
    procedure ApplyGLAttributes(const Cfg: TWindowConfig);

    function ApplyVSync(const Enabled: Boolean): Integer;
    function GetVSync: Boolean;
  public
    constructor Create(const Cfg: TWindowConfig);

    constructor CreateFromHandle(const NativeHandle: Pointer;
      const Cfg: TWindowConfig);
    destructor Destroy; override;

    procedure MakeCurrent;

    procedure NotifyResize(const NewWidth, NewHeight: Integer);

    procedure PumpEvents(var Input: TInput);

    procedure Present;
    procedure SetTitle(const S: string);

    procedure SetVSync(const Enabled: Boolean);

    procedure RequestClose;

    function GetGLProcAddress(const Name: PAnsiChar): Pointer;

    property Handle: TSDL_Window read FHandle;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;

    property ShouldClose: Boolean read FShouldClose;
    property Focused: Boolean read FFocused;
    property Minimized: Boolean read FMinimized;

    property ResizedThisFrame: Boolean read FResizedThisFrame;

    property VSync: Boolean read GetVSync;

    property VSyncRequested: Boolean read FVSyncRequested;

    property SwapInterval: Integer read FSwapInterval;

    property MSAAFellBack: Boolean read FMSAAFellBack;

    property IsForeign: Boolean read FForeign;
  end;

implementation

var
  GWindowCount: Integer = 0;

function SDLError: string;
begin
  Result := string(AnsiString(SDL_GetError));
end;

class function TWindowConfig.Default: TWindowConfig;
begin
  Result.Title := 'Jojos Engine';
  Result.Width := 1280;
  Result.Height := 720;
  Result.Resizable := True;
  Result.Visible := True;
  Result.VSync := True;
  Result.GLMajor := 3;
  Result.GLMinor := 3;
  Result.MSAASamples := 4;
  Result.DepthBits := 24;
  Result.StencilBits := 8;
{$IFDEF DEBUG}
  Result.DebugContext := True;
{$ELSE}
  Result.DebugContext := False;
{$ENDIF}
end;

procedure TWindow.ApplyGLAttributes(const Cfg: TWindowConfig);
begin

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, Cfg.GLMajor);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, Cfg.GLMinor);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

  if Cfg.DebugContext then
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG);

  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, Cfg.DepthBits);
  SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, Cfg.StencilBits);

  if Cfg.MSAASamples > 0 then
  begin
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, Cfg.MSAASamples);
  end;
end;

constructor TWindow.Create(const Cfg: TWindowConfig);
var
  Flags: Cardinal;
  TitleUtf8: UTF8String;
  FallbackCfg: TWindowConfig;
begin
  inherited Create;

  SetExceptionMask(GetExceptionMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER) <> 0 then
    raise EPlatformError.CreateFmt('SDL_Init falhou: %s', [SDLError]);

  ApplyGLAttributes(Cfg);

  Flags := SDL_WINDOW_OPENGL or SDL_WINDOW_ALLOW_HIGHDPI;
  if Cfg.Visible then
    Flags := Flags or SDL_WINDOW_SHOWN
  else
    Flags := Flags or SDL_WINDOW_HIDDEN;
  if Cfg.Resizable then
    Flags := Flags or SDL_WINDOW_RESIZABLE;

  TitleUtf8 := UTF8String(Cfg.Title);
  FHandle := SDL_CreateWindow(PAnsiChar(TitleUtf8), SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED, Cfg.Width, Cfg.Height, Flags);

  if FHandle <> nil then
    FContext := SDL_GL_CreateContext(FHandle)
  else
    FContext := nil;

  if ((FHandle = nil) or (FContext = nil)) and (Cfg.MSAASamples > 0) then
  begin
    FallbackCfg := Cfg;
    FallbackCfg.MSAASamples := 0;

    if FHandle <> nil then
    begin
      SDL_DestroyWindow(FHandle);
      FHandle := nil;
    end;

    ApplyGLAttributes(FallbackCfg);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);

    FHandle := SDL_CreateWindow(PAnsiChar(TitleUtf8), SDL_WINDOWPOS_CENTERED,
      SDL_WINDOWPOS_CENTERED, Cfg.Width, Cfg.Height, Flags);
    if FHandle <> nil then
    begin
      FContext := SDL_GL_CreateContext(FHandle);
      FMSAAFellBack := FContext <> nil;
    end;
  end;

  if FHandle = nil then
  begin
    SDL_Quit;
    raise EPlatformError.CreateFmt('SDL_CreateWindow falhou: %s', [SDLError]);
  end;

  if FContext = nil then
  begin
    SDL_DestroyWindow(FHandle);
    FHandle := nil;
    SDL_Quit;
    raise EPlatformError.CreateFmt(
      'Contexto OpenGL %d.%d core nao pode ser criado: %s',
      [Cfg.GLMajor, Cfg.GLMinor, SDLError]);
  end;

  SDL_GL_MakeCurrent(FHandle, FContext);
  FVSyncSettled := False;
  FVSyncRequested := Cfg.VSync;
  ApplyVSync(Cfg.VSync);

  if FMSAAFellBack then
    LogWarn('platform', 'MSAA %dx recusado pelo driver; janela criada sem ' +
      'anti-aliasing', [Cfg.MSAASamples]);

  SDL_GetWindowSize(FHandle, FWidth, FHeight);

  FShouldClose := False;
  FFocused := True;
  FMinimized := False;
  FResizedThisFrame := True;
  FForeign := False;
  Inc(GWindowCount);
end;

constructor TWindow.CreateFromHandle(const NativeHandle: Pointer;
  const Cfg: TWindowConfig);
var
  Etapa: string;
begin
  inherited Create;

  Etapa := 'inicio';
  try

    Etapa := 'mascarar excecoes de FPU';
    SetExceptionMask(GetExceptionMask + [exInvalidOp, exDenormalized,
      exZeroDivide, exOverflow, exUnderflow, exPrecision]);

    if NativeHandle = nil then
      raise EPlatformError.Create('CreateFromHandle: handle nulo');

    Etapa := 'SDL_Init';
    if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER) <> 0 then
      raise EPlatformError.CreateFmt('SDL_Init falhou: %s', [SDLError]);

    Etapa := 'SDL_GL_LoadLibrary';
    if SDL_GL_LoadLibrary(nil) <> 0 then
      raise EPlatformError.CreateFmt('SDL_GL_LoadLibrary falhou: %s', [SDLError]);

    Etapa := 'SDL_SetHint';
    SDL_SetHint(SDL_HINT_VIDEO_FOREIGN_WINDOW_OPENGL, '1');

    Etapa := 'atributos de GL';
    ApplyGLAttributes(Cfg);

    Etapa := 'SDL_CreateWindowFrom';
    FHandle := SDL_CreateWindowFrom(NativeHandle);
    if FHandle = nil then
      raise EPlatformError.CreateFmt('SDL_CreateWindowFrom falhou: %s', [SDLError]);

    Etapa := 'SDL_GL_CreateContext';
    FContext := SDL_GL_CreateContext(FHandle);
    if (FContext = nil) and (Cfg.MSAASamples > 0) then
  begin

    SDL_DestroyWindow(FHandle);
    ApplyGLAttributes(Cfg);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
    FHandle := SDL_CreateWindowFrom(NativeHandle);
    if FHandle <> nil then
    begin
      FContext := SDL_GL_CreateContext(FHandle);
      FMSAAFellBack := FContext <> nil;
    end;
  end;

  if FContext = nil then
  begin
    if FHandle <> nil then
      SDL_DestroyWindow(FHandle);
    FHandle := nil;
    raise EPlatformError.CreateFmt(
      'Contexto OpenGL %d.%d core na janela do host falhou: %s',
      [Cfg.GLMajor, Cfg.GLMinor, SDLError]);
  end;

    Etapa := 'MakeCurrent / VSync';
    SDL_GL_MakeCurrent(FHandle, FContext);
    FVSyncSettled := False;
    FVSyncRequested := Cfg.VSync;
    ApplyVSync(Cfg.VSync);

    SDL_GetWindowSize(FHandle, FWidth, FHeight);
  if FWidth <= 0 then FWidth := Cfg.Width;
  if FHeight <= 0 then FHeight := Cfg.Height;

    FShouldClose := False;
    FFocused := True;
    FMinimized := False;
    FResizedThisFrame := True;
    FForeign := True;
    Inc(GWindowCount);

    LogInfo('platform', 'viewport embutido criado (%dx%d) na janela do host',
      [FWidth, FHeight]);
  except
    on E: Exception do
    begin
      LogError('platform', 'CreateFromHandle falhou na etapa "%s": %s',
        [Etapa, E.Message]);
      raise EPlatformError.CreateFmt('[etapa: %s] %s', [Etapa, E.Message]);
    end;
  end;
end;

procedure TWindow.MakeCurrent;
begin
  if (FHandle <> nil) and (FContext <> nil) then
    SDL_GL_MakeCurrent(FHandle, FContext);
end;

procedure TWindow.NotifyResize(const NewWidth, NewHeight: Integer);
begin
  if (NewWidth = FWidth) and (NewHeight = FHeight) then
    Exit;
  FWidth := NewWidth;
  FHeight := NewHeight;
  FResizedThisFrame := True;
end;

destructor TWindow.Destroy;
begin
  if FContext <> nil then
  begin
    SDL_GL_DeleteContext(FContext);
    FContext := nil;
  end;
  if FHandle <> nil then
  begin
    SDL_DestroyWindow(FHandle);
    FHandle := nil;
  end;

  Dec(GWindowCount);
  if GWindowCount <= 0 then
  begin
    GWindowCount := 0;
    SDL_Quit;
  end;
  inherited;
end;

procedure TWindow.PumpEvents(var Input: TInput);
var
  Ev: TSDL_Event;
begin

  if FForeign then
    Exit;

  FResizedThisFrame := False;

  while SDL_PollEvent(Ev) <> 0 do
  begin
    case Ev.Kind of
      SDL_EV_QUIT:
        FShouldClose := True;

      SDL_EV_KEYDOWN:

        if Ev.Key.Repeated = 0 then
          Input.SetKey(Ev.Key.Keysym.Scancode, True);

      SDL_EV_KEYUP:
        Input.SetKey(Ev.Key.Keysym.Scancode, False);

      SDL_EV_MOUSEMOTION:
        Input.SetMousePosition(Ev.Motion.X, Ev.Motion.Y, Ev.Motion.XRel,
          Ev.Motion.YRel);

      SDL_EV_MOUSEBUTTONDOWN:
        Input.SetMouseButton(Ev.Button.Button, True);

      SDL_EV_MOUSEBUTTONUP:
        Input.SetMouseButton(Ev.Button.Button, False);

      SDL_EV_MOUSEWHEEL:
        Input.AddWheel(Ev.Wheel.X, Ev.Wheel.Y);

      SDL_EV_WINDOWEVENT:
        case Ev.Window.Event of
          SDL_WINDOWEVENT_CLOSE:
            FShouldClose := True;

          SDL_WINDOWEVENT_SIZE_CHANGED, SDL_WINDOWEVENT_RESIZED:
            begin
              FWidth := Ev.Window.Data1;
              FHeight := Ev.Window.Data2;
              FResizedThisFrame := True;
            end;

          SDL_WINDOWEVENT_FOCUS_GAINED:
            FFocused := True;

          SDL_WINDOWEVENT_FOCUS_LOST:
            begin
              FFocused := False;

              Input.ReleaseAll;
            end;

          SDL_WINDOWEVENT_MINIMIZED:
            FMinimized := True;

          SDL_WINDOWEVENT_RESTORED:
            FMinimized := False;
        end;
    end;
  end;
end;

procedure TWindow.Present;
begin
  SDL_GL_SwapWindow(FHandle);

  if not FVSyncSettled then
  begin
    FVSyncSettled := True;
    if FVSyncRequested and (FSwapInterval = 0) then
    begin
      ApplyVSync(True);
      if FSwapInterval <> 0 then
        LogInfo('platform', 'VSync so pegou depois do primeiro frame ' +
          '(intervalo %d)', [FSwapInterval])
      else
        LogWarn('platform', 'VSync pedido mas o driver nao aplicou; ' +
          'provavelmente forcado como desligado no painel de controle', []);
    end;
  end;
end;

procedure TWindow.SetTitle(const S: string);
var
  U: UTF8String;
begin
  U := UTF8String(S);
  SDL_SetWindowTitle(FHandle, PAnsiChar(U));
end;

function TWindow.ApplyVSync(const Enabled: Boolean): Integer;
begin
  if Enabled then
  begin

    if SDL_GL_SetSwapInterval(-1) <> 0 then
      SDL_GL_SetSwapInterval(1);
  end
  else
    SDL_GL_SetSwapInterval(0);

  Result := SDL_GL_GetSwapInterval;
  FSwapInterval := Result;
end;

function TWindow.GetVSync: Boolean;
begin
  Result := FSwapInterval <> 0;
end;

procedure TWindow.SetVSync(const Enabled: Boolean);
begin
  FVSyncRequested := Enabled;
  ApplyVSync(Enabled);
  if GetVSync <> Enabled then
    LogWarn('platform', 'VSync %s foi pedido mas o driver esta com ' +
      'intervalo %d; provavelmente esta forcado no painel de controle',
      [BoolToStr(Enabled, True), FSwapInterval]);
end;

procedure TWindow.RequestClose;
begin
  FShouldClose := True;
end;

function TWindow.GetGLProcAddress(const Name: PAnsiChar): Pointer;
begin
  Result := SDL_GL_GetProcAddress(Name);
end;

end.
