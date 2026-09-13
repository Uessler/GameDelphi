

unit Engine.RHI.GL.Device;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils,
  Engine.Core.Math,
  Engine.Core.Memory,
  Engine.Core.Log,
  Engine.RHI.Types,
  Engine.RHI.GL.Loader;

const
  LOG_RHI = 'rhi';
  MAX_TEXTURE_SLOTS = 16;
  MAX_UNIFORM_CACHE = 32;

type
  ERHIError = class(Exception);

  TGLBuffer = record
    Id: GLuint;
    Kind: TBufferKind;
    Usage: TBufferUsage;
    Size: Integer;
  end;

  TUniformCacheEntry = record
    Name: string;
    Location: GLint;
  end;

  TGLShader = record
    Id: GLuint;
    Cache: array [0 .. MAX_UNIFORM_CACHE - 1] of TUniformCacheEntry;
    CacheCount: Integer;
  end;

  TGLTexture = record
    Id: GLuint;
    Width, Height: Integer;
    Format: TTextureFormat;
  end;

  TGLMesh = record
    Vao: GLuint;
    VertexBuffer: TBufferHandle;
    IndexBuffer: TBufferHandle;
    IndexFormat: TIndexFormat;
    VertexCount: Integer;
    IndexCount: Integer;
  end;

  TGLRenderTarget = record
    FramebufferId: GLuint;
    ColorTexture: TTextureHandle;
    Width, Height: Integer;
  end;

  TRHIDevice = class
  private
    FBuffers: TResourcePool<TGLBuffer>;
    FShaders: TResourcePool<TGLShader>;
    FTextures: TResourcePool<TGLTexture>;
    FMeshes: TResourcePool<TGLMesh>;
    FRenderTargets: TResourcePool<TGLRenderTarget>;

    FCurShader: TShaderHandle;
    FCurShaderId: GLuint;
    FCurMesh: TMeshHandle;
    FCurVao: GLuint;
    FCurTextures: array [0 .. MAX_TEXTURE_SLOTS - 1] of GLuint;
    FCurBlend: TBlendMode;
    FCurDepth: TDepthTest;
    FCurCull: TCullMode;
    FCurRenderTarget: TRenderTargetHandle;
    FCurFramebufferId: GLuint;
    FViewportW, FViewportH: Integer;

    FStats: TRHIStats;
    FDebugEnabled: Boolean;

    function CompileStage(const Source: string; const Stage: GLenum;
      out Error: string): GLuint;
    function UniformLocation(const H: TShaderHandle; const Name: string): GLint;
    procedure ApplyVertexLayout(const Layout: TVertexLayout);
    procedure BindMeshInternal(const Mesh: TMeshHandle);
  public

    constructor Create(const GetProc: TGLGetProcAddress;
      const EnableDebugOutput: Boolean = False);
    destructor Destroy; override;

    function VendorString: string;
    function RendererString: string;
    function VersionString: string;
    function GLSLVersionString: string;
    function MaxTextureSize: Integer;

    function CheckError(const Where: string): Boolean;

    procedure SetViewport(const X, Y, W, H: Integer);
    procedure Clear(const Flags: TClearFlags; const Color: TVec4);

    procedure BeginFrame;
    function Stats: TRHIStats;

    function CreateRenderTarget(const Width, Height: Integer): TRenderTargetHandle;
    function ResizeRenderTarget(const H: TRenderTargetHandle;
      const Width, Height: Integer): Boolean;
    procedure DestroyRenderTarget(const H: TRenderTargetHandle);
    procedure SetRenderTarget(const H: TRenderTargetHandle);
    function RenderTargetTexture(const H: TRenderTargetHandle): TTextureHandle;
    function ReadRenderTargetPixels(const H: TRenderTargetHandle;
      const Dest: Pointer; const DestBytes: NativeInt): Boolean;

    function CreateBuffer(const Kind: TBufferKind; const Usage: TBufferUsage;
      const SizeBytes: Integer; const Data: Pointer = nil): TBufferHandle;
    procedure UpdateBuffer(const H: TBufferHandle; const OffsetBytes,
      SizeBytes: Integer; const Data: Pointer);

    procedure UpdateBufferOrphaned(const H: TBufferHandle;
      const SizeBytes: Integer; const Data: Pointer);
    procedure DestroyBuffer(const H: TBufferHandle);

    function CreateShader(const VertexSource, FragmentSource: string;
      out Error: string): TShaderHandle;
    procedure DestroyShader(const H: TShaderHandle);
    procedure SetShader(const H: TShaderHandle);

    procedure SetUniformInt(const Name: string; const V: Integer);
    procedure SetUniformFloat(const Name: string; const V: Single);
    procedure SetUniformVec2(const Name: string; const V: TVec2);
    procedure SetUniformVec3(const Name: string; const V: TVec3);
    procedure SetUniformVec4(const Name: string; const V: TVec4);

    procedure SetUniformMat4(const Name: string; const M: TMat4);

    function CreateTexture(const Desc: TTextureDesc): TTextureHandle;

    function CreateWhiteTexture: TTextureHandle;
    procedure DestroyTexture(const H: TTextureHandle);
    procedure SetTexture(const Slot: Integer; const H: TTextureHandle);

    function CreateMesh(const VertexBuffer: TBufferHandle;
      const Layout: TVertexLayout; const VertexCount: Integer;
      const IndexBuffer: TBufferHandle; const IndexCount: Integer = 0;
      const IndexFormat: TIndexFormat = ifUInt16): TMeshHandle;
    procedure DestroyMesh(const H: TMeshHandle);

    procedure Draw(const Mesh: TMeshHandle; const Prim: TPrimitive;
      const First, Count: Integer);
    procedure DrawIndexed(const Mesh: TMeshHandle; const Prim: TPrimitive;
      const IndexCount: Integer; const FirstIndex: Integer = 0);

    procedure SetBlend(const Mode: TBlendMode);
    procedure SetDepthTest(const Test: TDepthTest);
    procedure SetCull(const Mode: TCullMode);

    property ViewportWidth: Integer read FViewportW;
    property ViewportHeight: Integer read FViewportH;
  end;

implementation

function GLBufferTarget(const K: TBufferKind): GLenum;
begin
  case K of
    bkIndex: Result := GL_ELEMENT_ARRAY_BUFFER;
    bkUniform: Result := GL_UNIFORM_BUFFER;
  else
    Result := GL_ARRAY_BUFFER;
  end;
end;

function GLBufferUsage(const U: TBufferUsage): GLenum;
begin
  case U of
    buDynamic: Result := GL_DYNAMIC_DRAW;
    buStream: Result := GL_STREAM_DRAW;
  else
    Result := GL_STATIC_DRAW;
  end;
end;

function GLPrimitive(const P: TPrimitive): GLenum;
begin
  case P of
    ptTriangleStrip: Result := GL_TRIANGLE_STRIP;
    ptTriangleFan: Result := GL_TRIANGLE_FAN;
    ptLines: Result := GL_LINES;
    ptLineStrip: Result := GL_LINE_STRIP;
    ptPoints: Result := GL_POINTS;
  else
    Result := GL_TRIANGLES;
  end;
end;

function GLAttribType(const F: TVertexFormat): GLenum;
begin
  case F of
    vfUByte4, vfUByte4N: Result := GL_UNSIGNED_BYTE;
    vfShort2, vfShort2N, vfShort4, vfShort4N: Result := GL_SHORT;
  else
    Result := GL_FLOAT;
  end;
end;

procedure GLTextureFormat(const F: TTextureFormat;
  out Internal: GLint; out Fmt, Typ: GLenum);
begin
  case F of
    tfR8:
      begin Internal := GL_R8; Fmt := GL_RED; end;
    tfRGB8:
      begin Internal := GL_RGB8; Fmt := GL_RGB; end;
    tfSRGBA8:
      begin Internal := GL_SRGB8_ALPHA8; Fmt := GL_RGBA; end;
  else
    begin Internal := GL_RGBA8; Fmt := GL_RGBA; end;
  end;
  Typ := GL_UNSIGNED_BYTE;
end;

function GLMinFilter(const F: TTextureFilter): GLint;
begin
  case F of
    tflNearest: Result := GL_NEAREST;
    tflLinearMipmap: Result := GL_LINEAR_MIPMAP_LINEAR;
  else
    Result := GL_LINEAR;
  end;
end;

function GLMagFilter(const F: TTextureFilter): GLint;
begin
  if F = tflNearest then
    Result := GL_NEAREST
  else
    Result := GL_LINEAR;
end;

function GLWrap(const W: TTextureWrap): GLint;
begin
  case W of
    twClamp: Result := GL_CLAMP_TO_EDGE;
    twMirror: Result := GL_MIRRORED_REPEAT;
  else
    Result := GL_REPEAT;
  end;
end;

function GLIndexType(const F: TIndexFormat): GLenum;
begin
  if F = ifUInt16 then
    Result := GL_UNSIGNED_SHORT
  else
    Result := GL_UNSIGNED_INT;
end;

procedure GLDebugCallback(source, atype: GLenum; id: GLuint; severity: GLenum;
  length: GLsizei; const message_: PAnsiChar;
  const userParam: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
var
  Msg: string;
begin
  Msg := string(AnsiString(message_));
  case severity of
    GL_DEBUG_SEVERITY_HIGH:
      LogError(LOG_RHI, 'driver: %s', [Msg]);
    GL_DEBUG_SEVERITY_MEDIUM:
      LogWarn(LOG_RHI, 'driver: %s', [Msg]);
    GL_DEBUG_SEVERITY_LOW:
      LogInfo(LOG_RHI, 'driver: %s', [Msg]);
  else
    LogTrace(LOG_RHI, 'driver: %s', [Msg]);
  end;
end;

constructor TRHIDevice.Create(const GetProc: TGLGetProcAddress;
  const EnableDebugOutput: Boolean);
var
  I: Integer;
begin
  inherited Create;

  LoadGL(GetProc);

  FBuffers.Init(64);
  FShaders.Init(16);
  FTextures.Init(64);
  FMeshes.Init(64);
  FRenderTargets.Init(8);

  FCurShader := THandle.Null;
  FCurShaderId := 0;
  FCurMesh := THandle.Null;
  FCurVao := 0;
  FCurRenderTarget := THandle.Null;
  FCurFramebufferId := 0;
  for I := 0 to MAX_TEXTURE_SLOTS - 1 do
    FCurTextures[I] := 0;
  FStats.Reset;

  LogInfo(LOG_RHI, 'GL_VENDOR   : %s', [VendorString]);
  LogInfo(LOG_RHI, 'GL_RENDERER : %s', [RendererString]);
  LogInfo(LOG_RHI, 'GL_VERSION  : %s', [VersionString]);
  LogInfo(LOG_RHI, 'GLSL        : %s', [GLSLVersionString]);

  FDebugEnabled := False;
  if EnableDebugOutput then
  begin
    if GLHasDebugOutput then
    begin
      glEnable(GL_DEBUG_OUTPUT);

      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
      glDebugMessageCallback(GLDebugCallback, nil);
      glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, nil,
        GL_TRUE);
      FDebugEnabled := True;
      LogInfo(LOG_RHI, 'debug output do driver ligado', []);
    end
    else
      LogWarn(LOG_RHI, 'driver nao expoe KHR_debug; sem mensagens do driver', []);
  end;

  SetBlend(bmNone);
  SetDepthTest(dtOff);
  SetCull(cmNone);

  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
end;

destructor TRHIDevice.Destroy;
var
  Slot: Integer;
  B: ^TGLBuffer;
  S: ^TGLShader;
  T: ^TGLTexture;
  M: ^TGLMesh;
  R: ^TGLRenderTarget;
begin
  if GLLoaded then
  begin
    Slot := FRenderTargets.FirstAlive;
    while Slot >= 0 do
    begin
      R := FRenderTargets.PtrAt(Slot);
      if (R <> nil) and (R.FramebufferId <> 0) then
        glDeleteFramebuffers(1, @R.FramebufferId);
      Slot := FRenderTargets.NextAlive(Slot);
    end;

    Slot := FMeshes.FirstAlive;
    while Slot >= 0 do
    begin
      M := FMeshes.PtrAt(Slot);
      if (M <> nil) and (M.Vao <> 0) then
        glDeleteVertexArrays(1, @M.Vao);
      Slot := FMeshes.NextAlive(Slot);
    end;

    Slot := FBuffers.FirstAlive;
    while Slot >= 0 do
    begin
      B := FBuffers.PtrAt(Slot);
      if (B <> nil) and (B.Id <> 0) then
        glDeleteBuffers(1, @B.Id);
      Slot := FBuffers.NextAlive(Slot);
    end;

    Slot := FTextures.FirstAlive;
    while Slot >= 0 do
    begin
      T := FTextures.PtrAt(Slot);
      if (T <> nil) and (T.Id <> 0) then
        glDeleteTextures(1, @T.Id);
      Slot := FTextures.NextAlive(Slot);
    end;

    Slot := FShaders.FirstAlive;
    while Slot >= 0 do
    begin
      S := FShaders.PtrAt(Slot);
      if (S <> nil) and (S.Id <> 0) then
        glDeleteProgram(S.Id);
      Slot := FShaders.NextAlive(Slot);
    end;
  end;

  FMeshes.Clear;
  FBuffers.Clear;
  FRenderTargets.Clear;
  FTextures.Clear;
  FShaders.Clear;
  inherited;
end;

function TRHIDevice.VendorString: string;
begin
  Result := string(AnsiString(glGetString(GL_VENDOR)));
end;

function TRHIDevice.RendererString: string;
begin
  Result := string(AnsiString(glGetString(GL_RENDERER)));
end;

function TRHIDevice.VersionString: string;
begin
  Result := string(AnsiString(glGetString(GL_VERSION)));
end;

function TRHIDevice.GLSLVersionString: string;
begin
  Result := string(AnsiString(glGetString(GL_SHADING_LANGUAGE_VERSION)));
end;

function TRHIDevice.MaxTextureSize: Integer;
var
  V: GLint;
begin
  V := 0;
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @V);
  Result := V;
end;

function TRHIDevice.CheckError(const Where: string): Boolean;
var
  E: GLenum;
begin
  Result := False;

  E := glGetError;
  while E <> GL_NO_ERROR do
  begin
    Result := True;
    LogError(LOG_RHI, '%s: %s', [Where, GLErrorName(E)]);
    E := glGetError;
  end;
end;

procedure TRHIDevice.BeginFrame;
begin
  FStats.Reset;
end;

function TRHIDevice.Stats: TRHIStats;
begin
  Result := FStats;
end;

function TRHIDevice.CreateRenderTarget(const Width,
  Height: Integer): TRenderTargetHandle;
var
  R: TGLRenderTarget;
  Desc: TTextureDesc;
  Texture: ^TGLTexture;
  PreviousFramebuffer: GLuint;
  Status: GLenum;
begin
  Result := THandle.Null;
  if (Width <= 0) or (Height <= 0) then
    raise ERHIError.CreateFmt('Render target com tamanho invalido: %dx%d',
      [Width, Height]);

  Desc := TTextureDesc.Default2D(Width, Height);
  R.ColorTexture := CreateTexture(Desc);
  if R.ColorTexture.IsNull then
    raise ERHIError.Create('Nao foi possivel criar a textura do render target');

  Texture := FTextures.GetPtr(R.ColorTexture);
  R.FramebufferId := 0;
  R.Width := Width;
  R.Height := Height;
  glGenFramebuffers(1, @R.FramebufferId);
  if R.FramebufferId = 0 then
  begin
    DestroyTexture(R.ColorTexture);
    raise ERHIError.Create('glGenFramebuffers falhou');
  end;

  PreviousFramebuffer := FCurFramebufferId;
  glBindFramebuffer(GL_FRAMEBUFFER, R.FramebufferId);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
    Texture.Id, 0);
  Status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
  glBindFramebuffer(GL_FRAMEBUFFER, PreviousFramebuffer);

  if Status <> GL_FRAMEBUFFER_COMPLETE then
  begin
    glDeleteFramebuffers(1, @R.FramebufferId);
    DestroyTexture(R.ColorTexture);
    raise ERHIError.CreateFmt('Framebuffer incompleto: 0x%x', [Status]);
  end;

  Result := FRenderTargets.Add(R);
end;

function TRHIDevice.ResizeRenderTarget(const H: TRenderTargetHandle;
  const Width, Height: Integer): Boolean;
var
  R: ^TGLRenderTarget;
  Desc: TTextureDesc;
  NewTexture, OldTexture: TTextureHandle;
  Texture: ^TGLTexture;
  PreviousFramebuffer: GLuint;
  Status: GLenum;
begin
  Result := False;
  R := FRenderTargets.GetPtr(H);
  if R = nil then
  begin
    LogError(LOG_RHI, 'ResizeRenderTarget: handle invalido', []);
    Exit;
  end;
  if (Width <= 0) or (Height <= 0) then
    Exit;
  if (R.Width = Width) and (R.Height = Height) then
    Exit(True);

  Desc := TTextureDesc.Default2D(Width, Height);
  NewTexture := CreateTexture(Desc);
  if NewTexture.IsNull then
    Exit;
  Texture := FTextures.GetPtr(NewTexture);
  OldTexture := R.ColorTexture;

  PreviousFramebuffer := FCurFramebufferId;
  glBindFramebuffer(GL_FRAMEBUFFER, R.FramebufferId);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
    Texture.Id, 0);
  Status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if Status <> GL_FRAMEBUFFER_COMPLETE then
  begin
    Texture := FTextures.GetPtr(OldTexture);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
      Texture.Id, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, PreviousFramebuffer);
    DestroyTexture(NewTexture);
    LogError(LOG_RHI, 'ResizeRenderTarget: framebuffer incompleto (0x%x)',
      [Status]);
    Exit;
  end;
  glBindFramebuffer(GL_FRAMEBUFFER, PreviousFramebuffer);

  R.ColorTexture := NewTexture;
  R.Width := Width;
  R.Height := Height;
  DestroyTexture(OldTexture);
  Result := True;
end;

procedure TRHIDevice.DestroyRenderTarget(const H: TRenderTargetHandle);
var
  R: ^TGLRenderTarget;
  Color: TTextureHandle;
begin
  R := FRenderTargets.GetPtr(H);
  if R = nil then
    Exit;
  if FCurRenderTarget = H then
    SetRenderTarget(THandle.Null);
  Color := R.ColorTexture;
  if R.FramebufferId <> 0 then
    glDeleteFramebuffers(1, @R.FramebufferId);
  FRenderTargets.Remove(H);
  DestroyTexture(Color);
end;

procedure TRHIDevice.SetRenderTarget(const H: TRenderTargetHandle);
var
  R: ^TGLRenderTarget;
  Id: GLuint;
begin
  if H.IsNull then
    Id := 0
  else
  begin
    R := FRenderTargets.GetPtr(H);
    if R = nil then
    begin
      LogError(LOG_RHI, 'SetRenderTarget: handle invalido', []);
      Exit;
    end;
    Id := R.FramebufferId;
  end;

  if FCurFramebufferId <> Id then
    glBindFramebuffer(GL_FRAMEBUFFER, Id);
  FCurFramebufferId := Id;
  FCurRenderTarget := H;
end;

function TRHIDevice.RenderTargetTexture(
  const H: TRenderTargetHandle): TTextureHandle;
var
  R: ^TGLRenderTarget;
begin
  R := FRenderTargets.GetPtr(H);
  if R = nil then
    Result := THandle.Null
  else
    Result := R.ColorTexture;
end;

function TRHIDevice.ReadRenderTargetPixels(const H: TRenderTargetHandle;
  const Dest: Pointer; const DestBytes: NativeInt): Boolean;
var
  R: ^TGLRenderTarget;
  Required: Int64;
  PreviousFramebuffer: GLuint;
begin
  Result := False;
  R := FRenderTargets.GetPtr(H);
  if (R = nil) or (Dest = nil) then
    Exit;
  Required := Int64(R.Width) * Int64(R.Height) * 4;
  if DestBytes < Required then
  begin
    LogError(LOG_RHI, 'ReadRenderTargetPixels: buffer de %d bytes, precisa %d',
      [DestBytes, Required]);
    Exit;
  end;

  PreviousFramebuffer := FCurFramebufferId;
  if PreviousFramebuffer <> R.FramebufferId then
    glBindFramebuffer(GL_FRAMEBUFFER, R.FramebufferId);
  glPixelStorei(GL_PACK_ALIGNMENT, 4);
  glReadPixels(0, 0, R.Width, R.Height, GL_BGRA, GL_UNSIGNED_BYTE, Dest);
  if PreviousFramebuffer <> R.FramebufferId then
    glBindFramebuffer(GL_FRAMEBUFFER, PreviousFramebuffer);
  Result := not CheckError('ReadRenderTargetPixels');
end;

procedure TRHIDevice.SetViewport(const X, Y, W, H: Integer);
begin
  FViewportW := W;
  FViewportH := H;
  glViewport(X, Y, W, H);
end;

procedure TRHIDevice.Clear(const Flags: TClearFlags; const Color: TVec4);
var
  Mask: GLbitfield;
begin
  Mask := 0;
  if cfColor in Flags then
  begin
    glClearColor(Color.X, Color.Y, Color.Z, Color.W);
    Mask := Mask or GL_COLOR_BUFFER_BIT;
  end;
  if cfDepth in Flags then
  begin

    glDepthMask(GL_TRUE);
    Mask := Mask or GL_DEPTH_BUFFER_BIT;
  end;
  if cfStencil in Flags then
    Mask := Mask or GL_STENCIL_BUFFER_BIT;
  if Mask <> 0 then
    glClear(Mask);
end;

function TRHIDevice.CreateBuffer(const Kind: TBufferKind;
  const Usage: TBufferUsage; const SizeBytes: Integer;
  const Data: Pointer): TBufferHandle;
var
  B: TGLBuffer;
  Target: GLenum;
begin
  B.Id := 0;
  B.Kind := Kind;
  B.Usage := Usage;
  B.Size := SizeBytes;
  Target := GLBufferTarget(Kind);

  glGenBuffers(1, @B.Id);
  if B.Id = 0 then
  begin
    LogError(LOG_RHI, 'glGenBuffers falhou', []);
    Exit(THandle.Null);
  end;

  glBindBuffer(Target, B.Id);
  glBufferData(Target, SizeBytes, Data, GLBufferUsage(Usage));
  glBindBuffer(Target, 0);

  if Data <> nil then
  begin
    Inc(FStats.BufferUploads);
    Inc(FStats.BufferBytesUploaded, SizeBytes);
  end;

  Result := FBuffers.Add(B);
end;

procedure TRHIDevice.UpdateBuffer(const H: TBufferHandle;
  const OffsetBytes, SizeBytes: Integer; const Data: Pointer);
var
  B: ^TGLBuffer;
  Target: GLenum;
begin
  B := FBuffers.GetPtr(H);
  if B = nil then
  begin
    LogError(LOG_RHI, 'UpdateBuffer: handle invalido', []);
    Exit;
  end;
  if OffsetBytes + SizeBytes > B.Size then
  begin
    LogError(LOG_RHI, 'UpdateBuffer: %d bytes no offset %d estouram o buffer de %d',
      [SizeBytes, OffsetBytes, B.Size]);
    Exit;
  end;

  Target := GLBufferTarget(B.Kind);
  glBindBuffer(Target, B.Id);
  glBufferSubData(Target, OffsetBytes, SizeBytes, Data);
  glBindBuffer(Target, 0);

  Inc(FStats.BufferUploads);
  Inc(FStats.BufferBytesUploaded, SizeBytes);
end;

procedure TRHIDevice.UpdateBufferOrphaned(const H: TBufferHandle;
  const SizeBytes: Integer; const Data: Pointer);
var
  B: ^TGLBuffer;
  Target: GLenum;
begin
  B := FBuffers.GetPtr(H);
  if B = nil then
  begin
    LogError(LOG_RHI, 'UpdateBufferOrphaned: handle invalido', []);
    Exit;
  end;
  if SizeBytes > B.Size then
  begin
    LogError(LOG_RHI, 'UpdateBufferOrphaned: %d bytes estouram o buffer de %d',
      [SizeBytes, B.Size]);
    Exit;
  end;

  Target := GLBufferTarget(B.Kind);
  glBindBuffer(Target, B.Id);

  glBufferData(Target, B.Size, nil, GLBufferUsage(B.Usage));

  if (SizeBytes > 0) and (Data <> nil) then
    glBufferSubData(Target, 0, SizeBytes, Data);
  glBindBuffer(Target, 0);

  Inc(FStats.BufferUploads);
  Inc(FStats.BufferBytesUploaded, SizeBytes);
end;

procedure TRHIDevice.DestroyBuffer(const H: TBufferHandle);
var
  B: ^TGLBuffer;
begin
  B := FBuffers.GetPtr(H);
  if B = nil then
    Exit;
  if B.Id <> 0 then
    glDeleteBuffers(1, @B.Id);
  FBuffers.Remove(H);
end;

function TRHIDevice.CompileStage(const Source: string; const Stage: GLenum;
  out Error: string): GLuint;
var
  Src: AnsiString;
  PSrc: PAnsiChar;
  Status, LogLen: GLint;
  LogBuf: AnsiString;
begin
  Error := '';
  Result := glCreateShader(Stage);
  if Result = 0 then
  begin
    Error := 'glCreateShader falhou';
    Exit;
  end;

  Src := AnsiString(Source);
  PSrc := PAnsiChar(Src);
  glShaderSource(Result, 1, @PSrc, nil);
  glCompileShader(Result);

  Status := GL_FALSE;
  glGetShaderiv(Result, GL_COMPILE_STATUS, @Status);
  if Status = GL_TRUE then
    Exit;

  LogLen := 0;
  glGetShaderiv(Result, GL_INFO_LOG_LENGTH, @LogLen);
  if LogLen > 0 then
  begin
    SetLength(LogBuf, LogLen);
    glGetShaderInfoLog(Result, LogLen, nil, PAnsiChar(LogBuf));
    Error := Trim(string(LogBuf));
  end
  else
    Error := 'falha de compilacao sem log do driver';

  glDeleteShader(Result);
  Result := 0;
end;

function TRHIDevice.CreateShader(const VertexSource, FragmentSource: string;
  out Error: string): TShaderHandle;
var
  S: TGLShader;
  Vs, Fs: GLuint;
  Status, LogLen: GLint;
  LogBuf: AnsiString;
begin
  Result := THandle.Null;
  Error := '';

  Vs := CompileStage(VertexSource, GL_VERTEX_SHADER, Error);
  if Vs = 0 then
  begin
    Error := 'vertex shader: ' + Error;
    LogError(LOG_RHI, '%s', [Error]);
    Exit;
  end;

  Fs := CompileStage(FragmentSource, GL_FRAGMENT_SHADER, Error);
  if Fs = 0 then
  begin
    glDeleteShader(Vs);
    Error := 'fragment shader: ' + Error;
    LogError(LOG_RHI, '%s', [Error]);
    Exit;
  end;

  S.Id := glCreateProgram;
  glAttachShader(S.Id, Vs);
  glAttachShader(S.Id, Fs);
  glLinkProgram(S.Id);

  Status := GL_FALSE;
  glGetProgramiv(S.Id, GL_LINK_STATUS, @Status);

  glDetachShader(S.Id, Vs);
  glDetachShader(S.Id, Fs);
  glDeleteShader(Vs);
  glDeleteShader(Fs);

  if Status <> GL_TRUE then
  begin
    LogLen := 0;
    glGetProgramiv(S.Id, GL_INFO_LOG_LENGTH, @LogLen);
    if LogLen > 0 then
    begin
      SetLength(LogBuf, LogLen);
      glGetProgramInfoLog(S.Id, LogLen, nil, PAnsiChar(LogBuf));
      Error := 'link: ' + Trim(string(LogBuf));
    end
    else
      Error := 'link falhou sem log do driver';
    glDeleteProgram(S.Id);
    LogError(LOG_RHI, '%s', [Error]);
    Exit;
  end;

  S.CacheCount := 0;
  Result := FShaders.Add(S);
  LogDebug(LOG_RHI, 'shader criado (programa GL %d)', [S.Id]);
end;

procedure TRHIDevice.DestroyShader(const H: TShaderHandle);
var
  S: ^TGLShader;
begin
  S := FShaders.GetPtr(H);
  if S = nil then
    Exit;
  if FCurShaderId = S.Id then
  begin
    glUseProgram(0);
    FCurShaderId := 0;
    FCurShader := THandle.Null;
  end;
  glDeleteProgram(S.Id);
  FShaders.Remove(H);
end;

procedure TRHIDevice.SetShader(const H: TShaderHandle);
var
  S: ^TGLShader;
begin
  S := FShaders.GetPtr(H);
  if S = nil then
  begin
    LogError(LOG_RHI, 'SetShader: handle invalido', []);
    Exit;
  end;
  if S.Id = FCurShaderId then
    Exit;
  glUseProgram(S.Id);
  FCurShaderId := S.Id;
  FCurShader := H;
  Inc(FStats.StateChanges);
end;

function TRHIDevice.UniformLocation(const H: TShaderHandle;
  const Name: string): GLint;
var
  S: ^TGLShader;
  I: Integer;
  A: AnsiString;
begin
  Result := -1;
  S := FShaders.GetPtr(H);
  if S = nil then
    Exit;

  for I := 0 to S.CacheCount - 1 do
    if S.Cache[I].Name = Name then
      Exit(S.Cache[I].Location);

  A := AnsiString(Name);
  Result := glGetUniformLocation(S.Id, PAnsiChar(A));

  if S.CacheCount < MAX_UNIFORM_CACHE then
  begin
    S.Cache[S.CacheCount].Name := Name;
    S.Cache[S.CacheCount].Location := Result;
    Inc(S.CacheCount);
  end;

  if Result < 0 then
    LogTrace(LOG_RHI, 'uniform "%s" nao existe no shader corrente', [Name]);
end;

procedure TRHIDevice.SetUniformInt(const Name: string; const V: Integer);
var
  L: GLint;
begin
  L := UniformLocation(FCurShader, Name);
  if L >= 0 then
    glUniform1i(L, V);
end;

procedure TRHIDevice.SetUniformFloat(const Name: string; const V: Single);
var
  L: GLint;
begin
  L := UniformLocation(FCurShader, Name);
  if L >= 0 then
    glUniform1f(L, V);
end;

procedure TRHIDevice.SetUniformVec2(const Name: string; const V: TVec2);
var
  L: GLint;
begin
  L := UniformLocation(FCurShader, Name);
  if L >= 0 then
    glUniform2f(L, V.X, V.Y);
end;

procedure TRHIDevice.SetUniformVec3(const Name: string; const V: TVec3);
var
  L: GLint;
begin
  L := UniformLocation(FCurShader, Name);
  if L >= 0 then
    glUniform3f(L, V.X, V.Y, V.Z);
end;

procedure TRHIDevice.SetUniformVec4(const Name: string; const V: TVec4);
var
  L: GLint;
begin
  L := UniformLocation(FCurShader, Name);
  if L >= 0 then
    glUniform4f(L, V.X, V.Y, V.Z, V.W);
end;

procedure TRHIDevice.SetUniformMat4(const Name: string; const M: TMat4);
var
  L: GLint;
  Tmp: TMat4;
begin
  L := UniformLocation(FCurShader, Name);
  if L < 0 then
    Exit;

  Tmp := M;
  glUniformMatrix4fv(L, 1, GL_FALSE, PGLfloat(Tmp.Ptr));
end;

function TRHIDevice.CreateTexture(const Desc: TTextureDesc): TTextureHandle;
var
  T: TGLTexture;
  Internal: GLint;
  Fmt, Typ: GLenum;
begin
  T.Id := 0;
  T.Width := Desc.Width;
  T.Height := Desc.Height;
  T.Format := Desc.Format;

  glGenTextures(1, @T.Id);
  if T.Id = 0 then
  begin
    LogError(LOG_RHI, 'glGenTextures falhou', []);
    Exit(THandle.Null);
  end;

  GLTextureFormat(Desc.Format, Internal, Fmt, Typ);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, T.Id);
  glTexImage2D(GL_TEXTURE_2D, 0, Internal, Desc.Width, Desc.Height, 0, Fmt,
    Typ, Desc.Pixels);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GLMinFilter(Desc.Filter));
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GLMagFilter(Desc.Filter));
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GLWrap(Desc.Wrap));
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GLWrap(Desc.Wrap));

  if Desc.GenerateMipmaps and (Desc.Pixels <> nil) then
    glGenerateMipmap(GL_TEXTURE_2D);

  glBindTexture(GL_TEXTURE_2D, 0);
  FCurTextures[0] := 0;

  Result := FTextures.Add(T);
end;

function TRHIDevice.CreateWhiteTexture: TTextureHandle;
var
  Desc: TTextureDesc;
  Pixel: array [0 .. 3] of Byte;
begin
  Pixel[0] := 255; Pixel[1] := 255; Pixel[2] := 255; Pixel[3] := 255;
  Desc := TTextureDesc.Default2D(1, 1);
  Desc.Filter := tflNearest;
  Desc.Wrap := twRepeat;
  Desc.Pixels := @Pixel[0];
  Result := CreateTexture(Desc);
end;

procedure TRHIDevice.DestroyTexture(const H: TTextureHandle);
var
  T: ^TGLTexture;
  I: Integer;
begin
  T := FTextures.GetPtr(H);
  if T = nil then
    Exit;
  for I := 0 to MAX_TEXTURE_SLOTS - 1 do
    if FCurTextures[I] = T.Id then
      FCurTextures[I] := 0;
  if T.Id <> 0 then
    glDeleteTextures(1, @T.Id);
  FTextures.Remove(H);
end;

procedure TRHIDevice.SetTexture(const Slot: Integer; const H: TTextureHandle);
var
  T: ^TGLTexture;
  Id: GLuint;
begin
  if (Slot < 0) or (Slot >= MAX_TEXTURE_SLOTS) then
    Exit;

  T := FTextures.GetPtr(H);
  if T = nil then
    Id := 0
  else
    Id := T.Id;

  if FCurTextures[Slot] = Id then
    Exit;

  glActiveTexture(GL_TEXTURE0 + GLenum(Slot));
  glBindTexture(GL_TEXTURE_2D, Id);
  FCurTextures[Slot] := Id;
  Inc(FStats.StateChanges);
end;

procedure TRHIDevice.ApplyVertexLayout(const Layout: TVertexLayout);
var
  I: Integer;
  A: TVertexAttrib;
  Norm: GLboolean;
begin
  for I := 0 to Layout.Count - 1 do
  begin
    A := Layout.Attrib(I);
    glEnableVertexAttribArray(GLuint(A.Location));
    if VertexFormatIsNormalized(A.Format) then
      Norm := GL_TRUE
    else
      Norm := GL_FALSE;
    glVertexAttribPointer(GLuint(A.Location), VertexFormatComponents(A.Format),
      GLAttribType(A.Format), Norm, Layout.Stride, Pointer(NativeUInt(A.Offset)));
  end;
end;

function TRHIDevice.CreateMesh(const VertexBuffer: TBufferHandle;
  const Layout: TVertexLayout; const VertexCount: Integer;
  const IndexBuffer: TBufferHandle; const IndexCount: Integer;
  const IndexFormat: TIndexFormat): TMeshHandle;
var
  M: TGLMesh;
  VB, IB: ^TGLBuffer;
begin
  VB := FBuffers.GetPtr(VertexBuffer);
  if VB = nil then
  begin
    LogError(LOG_RHI, 'CreateMesh: vertex buffer invalido', []);
    Exit(THandle.Null);
  end;
  if Layout.Stride <= 0 then
  begin
    LogError(LOG_RHI, 'CreateMesh: layout com stride zero', []);
    Exit(THandle.Null);
  end;

  M.Vao := 0;
  M.VertexBuffer := VertexBuffer;
  M.IndexBuffer := IndexBuffer;
  M.IndexFormat := IndexFormat;
  M.VertexCount := VertexCount;
  M.IndexCount := IndexCount;

  glGenVertexArrays(1, @M.Vao);
  glBindVertexArray(M.Vao);

  glBindBuffer(GL_ARRAY_BUFFER, VB.Id);
  ApplyVertexLayout(Layout);

  IB := FBuffers.GetPtr(IndexBuffer);
  if IB <> nil then
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IB.Id);

  glBindVertexArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  FCurVao := 0;
  FCurMesh := THandle.Null;

  Result := FMeshes.Add(M);
end;

procedure TRHIDevice.DestroyMesh(const H: TMeshHandle);
var
  M: ^TGLMesh;
begin
  M := FMeshes.GetPtr(H);
  if M = nil then
    Exit;
  if FCurVao = M.Vao then
  begin
    glBindVertexArray(0);
    FCurVao := 0;
    FCurMesh := THandle.Null;
  end;
  if M.Vao <> 0 then
    glDeleteVertexArrays(1, @M.Vao);
  FMeshes.Remove(H);
end;

procedure TRHIDevice.BindMeshInternal(const Mesh: TMeshHandle);
var
  M: ^TGLMesh;
begin
  M := FMeshes.GetPtr(Mesh);
  if M = nil then
  begin
    LogError(LOG_RHI, 'Draw: mesh invalida', []);
    Exit;
  end;
  if FCurVao = M.Vao then
    Exit;
  glBindVertexArray(M.Vao);
  FCurVao := M.Vao;
  FCurMesh := Mesh;
  Inc(FStats.StateChanges);
end;

procedure TRHIDevice.Draw(const Mesh: TMeshHandle; const Prim: TPrimitive;
  const First, Count: Integer);
begin
  if Count <= 0 then
    Exit;
  BindMeshInternal(Mesh);
  if FCurVao = 0 then
    Exit;

  glDrawArrays(GLPrimitive(Prim), First, Count);

  Inc(FStats.DrawCalls);
  if Prim = ptTriangles then
    Inc(FStats.Triangles, Count div 3)
  else if Prim in [ptTriangleStrip, ptTriangleFan] then
    Inc(FStats.Triangles, Count - 2);
end;

procedure TRHIDevice.DrawIndexed(const Mesh: TMeshHandle;
  const Prim: TPrimitive; const IndexCount, FirstIndex: Integer);
var
  M: ^TGLMesh;
  Offset: NativeUInt;
begin
  if IndexCount <= 0 then
    Exit;
  M := FMeshes.GetPtr(Mesh);
  if M = nil then
  begin
    LogError(LOG_RHI, 'DrawIndexed: mesh invalida', []);
    Exit;
  end;
  if M.IndexBuffer.IsNull then
  begin
    LogError(LOG_RHI, 'DrawIndexed: mesh nao tem index buffer', []);
    Exit;
  end;

  BindMeshInternal(Mesh);
  Offset := NativeUInt(FirstIndex) * NativeUInt(IndexFormatSize(M.IndexFormat));
  glDrawElements(GLPrimitive(Prim), IndexCount, GLIndexType(M.IndexFormat),
    Pointer(Offset));

  Inc(FStats.DrawCalls);
  if Prim = ptTriangles then
    Inc(FStats.Triangles, IndexCount div 3);
end;

procedure TRHIDevice.SetBlend(const Mode: TBlendMode);
begin
  if FCurBlend = Mode then
    Exit;
  case Mode of
    bmNone:
      glDisable(GL_BLEND);
    bmAlpha:
      begin
        glEnable(GL_BLEND);

        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,
          GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glBlendEquation(GL_FUNC_ADD);
      end;
    bmAdditive:
      begin
        glEnable(GL_BLEND);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE, GL_ONE, GL_ONE);
        glBlendEquation(GL_FUNC_ADD);
      end;
    bmPremultiplied:
      begin
        glEnable(GL_BLEND);
        glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA,
          GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glBlendEquation(GL_FUNC_ADD);
      end;
  end;
  FCurBlend := Mode;
  Inc(FStats.StateChanges);
end;

procedure TRHIDevice.SetDepthTest(const Test: TDepthTest);
begin
  if FCurDepth = Test then
    Exit;
  if Test = dtOff then
    glDisable(GL_DEPTH_TEST)
  else
  begin
    glEnable(GL_DEPTH_TEST);
    case Test of
      dtLess: glDepthFunc(GL_LESS);
      dtLessEqual: glDepthFunc(GL_LEQUAL);
      dtAlways: glDepthFunc(GL_ALWAYS);
    end;
  end;
  FCurDepth := Test;
  Inc(FStats.StateChanges);
end;

procedure TRHIDevice.SetCull(const Mode: TCullMode);
begin
  if FCurCull = Mode then
    Exit;
  if Mode = cmNone then
    glDisable(GL_CULL_FACE)
  else
  begin
    glEnable(GL_CULL_FACE);
    if Mode = cmBack then
      glCullFace(GL_BACK)
    else
      glCullFace(GL_FRONT);
    glFrontFace(GL_CCW);
  end;
  FCurCull := Mode;
  Inc(FStats.StateChanges);
end;

end.
