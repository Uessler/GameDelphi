program AssetLab;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
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
  Engine.Assets.Image.WIC in '..\..\src\Assets\Engine.Assets.Image.WIC.pas',
  Engine.Assets in '..\..\src\Assets\Engine.Assets.pas';

type
  TVertex = packed record
    X, Y: Single;
    U, V: Single;
  end;

function Vertex(const X, Y, U, V: Single): TVertex;
begin
  Result.X := X;
  Result.Y := Y;
  Result.U := U;
  Result.V := V;
end;

function AssetFile(const Name: string): string;
var
  Base: string;
begin
  Base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '..\..\samples\AssetLab\assets\';
  Result := ExpandFileName(Base + Name);
  if not FileExists(Result) then
    Result := ExpandFileName(IncludeTrailingPathDelimiter(GetCurrentDir) +
      'assets\' + Name);
end;

var
  Window: TWindow;
  Device: TRHIDevice;
  Assets: TAssetManager;
  Input: TInput;
  Clock: TClock;
  Cfg: TWindowConfig;
  Layout: TVertexLayout;
  Vertices: array [0 .. 3] of TVertex;
  Indices: array [0 .. 5] of Word;
  VertexBuffer, IndexBuffer: TBufferHandle;
  Mesh: TMeshHandle;
  TextureAsset, ShaderAsset: TAssetHandle;
  TextureHandle: TTextureHandle;
  ShaderHandle: TShaderHandle;
  Delta: Single;
  Error, PreviousError: string;
begin
  Window := nil;
  Device := nil;
  Assets := nil;
  VertexBuffer := THandle.Null;
  IndexBuffer := THandle.Null;
  Mesh := THandle.Null;
  LogInit(llInfo);

  try
    Cfg := TWindowConfig.Default;
    Cfg.Title := 'Jojos Engine - AssetLab';
    Cfg.Width := 960;
    Cfg.Height := 540;
    Window := TWindow.Create(Cfg);
    Device := TRHIDevice.Create(Window.GetGLProcAddress, Cfg.DebugContext);
    Assets := TAssetManager.Create(Device);

    Vertices[0] := Vertex(-0.7, -0.7, 0, 0);
    Vertices[1] := Vertex( 0.7, -0.7, 1, 0);
    Vertices[2] := Vertex( 0.7,  0.7, 1, 1);
    Vertices[3] := Vertex(-0.7,  0.7, 0, 1);
    Indices[0] := 0;
    Indices[1] := 1;
    Indices[2] := 2;
    Indices[3] := 2;
    Indices[4] := 3;
    Indices[5] := 0;

    Layout.Init(SizeOf(TVertex));
    Layout.Add(0, vfFloat2, 0);
    Layout.Add(1, vfFloat2, 8);
    VertexBuffer := Device.CreateBuffer(bkVertex, buStatic,
      SizeOf(Vertices), @Vertices[0]);
    IndexBuffer := Device.CreateBuffer(bkIndex, buStatic,
      SizeOf(Indices), @Indices[0]);
    Mesh := Device.CreateMesh(VertexBuffer, Layout, Length(Vertices),
      IndexBuffer, Length(Indices), ifUInt16);

    TextureAsset := Assets.LoadTexture(AssetFile('sample.png'));
    ShaderAsset := Assets.LoadShader(AssetFile('asset.vert'),
      AssetFile('asset.frag'));
    PreviousError := '';
    Input.Init;
    Clock.Start;

    WriteLn('Edite sample.png, asset.vert ou asset.frag durante a execucao.');
    WriteLn('R recarrega agora. ESC encerra.');

    while not Window.ShouldClose do
    begin
      Delta := Clock.Tick;
      Input.BeginFrame;
      Window.PumpEvents(Input);
      if Input.WasPressedThisFrame(SDL_SCANCODE_ESCAPE) then
        Window.RequestClose;
      if Input.WasPressedThisFrame(SDL_SCANCODE_R) then
      begin
        Assets.Reload(TextureAsset);
        Assets.Reload(ShaderAsset);
      end;

      Assets.Update(Delta);
      Error := Assets.LastError(TextureAsset);
      if Error = '' then
        Error := Assets.LastError(ShaderAsset);
      if Error <> PreviousError then
      begin
        if Error <> '' then
          WriteLn('Asset: ', Error)
        else if PreviousError <> '' then
          WriteLn('Assets recarregados.');
        PreviousError := Error;
      end;

      Device.BeginFrame;
      Device.SetViewport(0, 0, Window.Width, Window.Height);
      Device.Clear([cfColor], Vec4(0.08, 0.09, 0.12, 1));
      TextureHandle := Assets.Texture(TextureAsset);
      ShaderHandle := Assets.Shader(ShaderAsset);
      if not TextureHandle.IsNull and not ShaderHandle.IsNull then
      begin
        Device.SetShader(ShaderHandle);
        Device.SetTexture(0, TextureHandle);
        Device.SetUniformInt('uTexture', 0);
        Device.DrawIndexed(Mesh, ptTriangles, Length(Indices));
      end;
      Window.Present;
    end;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      WriteLn('Pressione enter para sair.');
      ReadLn;
    end;
  end;

  Assets.Free;
  if Device <> nil then
  begin
    if not Mesh.IsNull then
      Device.DestroyMesh(Mesh);
    if not IndexBuffer.IsNull then
      Device.DestroyBuffer(IndexBuffer);
    if not VertexBuffer.IsNull then
      Device.DestroyBuffer(VertexBuffer);
  end;
  Device.Free;
  Window.Free;
end.
