

unit Engine.Renderer.SpriteBatch;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$POINTERMATH ON}

interface

uses
  SysUtils,
{$IFDEF FPC}
  Math,
{$ELSE}
  System.Math,
{$ENDIF}
  Engine.Core.Math,
  Engine.Core.Memory,
  Engine.Core.Log,
  Engine.RHI.Types,
  Engine.RHI.GL.Device,
  Engine.Renderer.Camera2D;

const
  LOG_RENDER = 'render';

  MAX_SPRITES_POR_LOTE = 16384;
  DEFAULT_SPRITES_POR_LOTE = 8192;

type

  TSpriteVertex = packed record
    X, Y: Single;
    R, G, B, A: Byte;
    U, V: Single;
  end;
  PSpriteVertex = ^TSpriteVertex;

  TSpriteBatch = class
  private
    FDevice: TRHIDevice;
    FShader: TShaderHandle;
    FWhiteTex: TTextureHandle;
    FMesh: TMeshHandle;
    FVertexBuffer: TBufferHandle;
    FIndexBuffer: TBufferHandle;

    FArena: TArena;
    FMaxSprites: Integer;
    FVertexBytes: Integer;

    FAtivo: Boolean;
    FTexAtual: TTextureHandle;
    FBlendAtual: TBlendMode;
    FViewProj: TMat4;

    FCullAtivo: Boolean;
    FCullBounds: TRect2;

    FSprites: Integer;
    FFlushes: Integer;
    FDescartados: Integer;

    function SpritesNoLote: Integer;
    function ReservaVertices: PSpriteVertex;
    procedure TrocaTextura(const Tex: TTextureHandle);
  public

    constructor Create(const ADevice: TRHIDevice;
      const AMaxSprites: Integer = DEFAULT_SPRITES_POR_LOTE);
    destructor Destroy; override;

    procedure BeginFrame(const ViewProj: TMat4); overload;
    procedure BeginFrame(const Camera: TCamera2D); overload;

    procedure EndFrame;

    procedure Flush;

    procedure EnableCulling(const Bounds: TRect2);
    procedure DisableCulling;

    procedure SetBlend(const Mode: TBlendMode);

    procedure DrawRect(const Center, Size: TVec2; const Color: TVec4);

    procedure DrawRectRotated(const Center, Size: TVec2; const Radians: Single;
      const Color: TVec4);

    procedure DrawSprite(const Tex: TTextureHandle; const Center, Size: TVec2;
      const Color: TVec4); overload;

    procedure DrawSprite(const Tex: TTextureHandle; const Center, Size: TVec2;
      const SrcUV: TRect2; const Color: TVec4; const Radians: Single;
      const Origin: TVec2); overload;

    procedure DrawLine(const A, B: TVec2; const Thickness: Single;
      const Color: TVec4);

    procedure DrawRectOutline(const R: TRect2; const Thickness: Single;
      const Color: TVec4);

    property WhiteTexture: TTextureHandle read FWhiteTex;
    property Shader: TShaderHandle read FShader;

    property SpriteCount: Integer read FSprites;

    property FlushCount: Integer read FFlushes;
    property CulledCount: Integer read FDescartados;
    property MaxSpritesPerBatch: Integer read FMaxSprites;
  end;

implementation

const
  VS_SPRITE =
    '#version 330 core' + sLineBreak +
    'layout(location = 0) in vec2 aPos;' + sLineBreak +
    'layout(location = 1) in vec4 aColor;' + sLineBreak +
    'layout(location = 2) in vec2 aUV;' + sLineBreak +
    'uniform mat4 uViewProj;' + sLineBreak +
    'out vec4 vColor;' + sLineBreak +
    'out vec2 vUV;' + sLineBreak +
    'void main()' + sLineBreak +
    '{' + sLineBreak +
    '    vColor = aColor;' + sLineBreak +
    '    vUV = aUV;' + sLineBreak +
    '    gl_Position = uViewProj * vec4(aPos, 0.0, 1.0);' + sLineBreak +
    '}';

  FS_SPRITE =
    '#version 330 core' + sLineBreak +
    'in vec4 vColor;' + sLineBreak +
    'in vec2 vUV;' + sLineBreak +
    'uniform sampler2D uTexture;' + sLineBreak +
    'out vec4 FragColor;' + sLineBreak +
    'void main()' + sLineBreak +
    '{' + sLineBreak +
    '    vec4 c = vColor * texture(uTexture, vUV);' + sLineBreak +
    '    if (c.a < 0.003) discard;' + sLineBreak +
    '    FragColor = c;' + sLineBreak +
    '}';

function ToByte(const V: Single): Byte;
var
  I: Integer;
begin
  I := Round(Saturate(V) * 255.0);
  if I < 0 then I := 0
  else if I > 255 then I := 255;
  Result := Byte(I);
end;

constructor TSpriteBatch.Create(const ADevice: TRHIDevice;
  const AMaxSprites: Integer);
var
  Erro: string;
  Layout: TVertexLayout;
  Indices: array of Word;
  I, V: Integer;
  Branco: array [0 .. 3] of Byte;
  TexDesc: TTextureDesc;
begin
  inherited Create;

  if ADevice = nil then
    raise Exception.Create('TSpriteBatch: device nulo');
  FDevice := ADevice;

  FMaxSprites := AMaxSprites;
  if FMaxSprites < 1 then
    FMaxSprites := 1;
  if FMaxSprites > MAX_SPRITES_POR_LOTE then
  begin
    LogWarn(LOG_RENDER, 'lote de %d sprites excede o limite do indice de 16 ' +
      'bits; usando %d', [FMaxSprites, MAX_SPRITES_POR_LOTE]);
    FMaxSprites := MAX_SPRITES_POR_LOTE;
  end;

  FVertexBytes := FMaxSprites * 4 * SizeOf(TSpriteVertex);

  FShader := FDevice.CreateShader(VS_SPRITE, FS_SPRITE, Erro);
  if FShader.IsNull then
    raise Exception.CreateFmt('TSpriteBatch: shader padrao nao compilou: %s',
      [Erro]);

  FArena.Init(NativeUInt(FVertexBytes));

  FVertexBuffer := FDevice.CreateBuffer(bkVertex, buStream, FVertexBytes, nil);

  SetLength(Indices, FMaxSprites * 6);
  for I := 0 to FMaxSprites - 1 do
  begin
    V := I * 4;
    Indices[I * 6 + 0] := Word(V + 0);
    Indices[I * 6 + 1] := Word(V + 1);
    Indices[I * 6 + 2] := Word(V + 2);
    Indices[I * 6 + 3] := Word(V + 2);
    Indices[I * 6 + 4] := Word(V + 3);
    Indices[I * 6 + 5] := Word(V + 0);
  end;
  FIndexBuffer := FDevice.CreateBuffer(bkIndex, buStatic,
    Length(Indices) * SizeOf(Word), @Indices[0]);

  Layout.Init(SizeOf(TSpriteVertex));
  Layout.Add(0, vfFloat2,  0);
  Layout.Add(1, vfUByte4N, 8);
  Layout.Add(2, vfFloat2,  12);

  FMesh := FDevice.CreateMesh(FVertexBuffer, Layout, FMaxSprites * 4,
    FIndexBuffer, FMaxSprites * 6, ifUInt16);

  Branco[0] := 255; Branco[1] := 255; Branco[2] := 255; Branco[3] := 255;
  TexDesc := TTextureDesc.Default2D(1, 1);
  TexDesc.Filter := tflNearest;
  TexDesc.Wrap := twRepeat;
  TexDesc.Pixels := @Branco[0];
  FWhiteTex := FDevice.CreateTexture(TexDesc);

  FAtivo := False;
  FTexAtual := THandle.Null;
  FBlendAtual := bmAlpha;
  FCullAtivo := False;

  LogInfo(LOG_RENDER, 'sprite batch pronto: ate %d sprites por lote (%d KB)',
    [FMaxSprites, FVertexBytes div 1024]);
end;

destructor TSpriteBatch.Destroy;
begin
  if FDevice <> nil then
  begin
    FDevice.DestroyMesh(FMesh);
    FDevice.DestroyBuffer(FVertexBuffer);
    FDevice.DestroyBuffer(FIndexBuffer);
    FDevice.DestroyTexture(FWhiteTex);
    FDevice.DestroyShader(FShader);
  end;
  FArena.Free;
  inherited;
end;

function TSpriteBatch.SpritesNoLote: Integer;
begin
  Result := Integer(FArena.Used) div (4 * SizeOf(TSpriteVertex));
end;

procedure TSpriteBatch.BeginFrame(const ViewProj: TMat4);
begin
  if FAtivo then
    EndFrame;

  FViewProj := ViewProj;
  FAtivo := True;
  FSprites := 0;
  FFlushes := 0;
  FDescartados := 0;
  FArena.Reset;
  FTexAtual := THandle.Null;

  FDevice.SetShader(FShader);
  FDevice.SetUniformInt('uTexture', 0);
  FDevice.SetUniformMat4('uViewProj', FViewProj);
  FDevice.SetBlend(FBlendAtual);
  FDevice.SetDepthTest(dtOff);
end;

procedure TSpriteBatch.BeginFrame(const Camera: TCamera2D);
begin
  BeginFrame(Camera.ViewProjection);
end;

procedure TSpriteBatch.EndFrame;
begin
  if not FAtivo then
    Exit;
  Flush;
  FAtivo := False;
end;

procedure TSpriteBatch.Flush;
var
  Qtd: Integer;
begin
  Qtd := SpritesNoLote;
  if (Qtd = 0) or FTexAtual.IsNull then
  begin
    FArena.Reset;
    Exit;
  end;

  FDevice.UpdateBufferOrphaned(FVertexBuffer, Integer(FArena.Used),
    FArena.BasePtr);

  FDevice.SetTexture(0, FTexAtual);
  FDevice.DrawIndexed(FMesh, ptTriangles, Qtd * 6, 0);

  Inc(FFlushes);
  FArena.Reset;
end;

procedure TSpriteBatch.EnableCulling(const Bounds: TRect2);
begin
  FCullAtivo := True;
  FCullBounds := Bounds;
end;

procedure TSpriteBatch.DisableCulling;
begin
  FCullAtivo := False;
end;

procedure TSpriteBatch.SetBlend(const Mode: TBlendMode);
begin
  if Mode = FBlendAtual then
    Exit;
  Flush;
  FBlendAtual := Mode;
  FDevice.SetBlend(Mode);
end;

procedure TSpriteBatch.TrocaTextura(const Tex: TTextureHandle);
begin
  if Tex = FTexAtual then
    Exit;
  Flush;
  FTexAtual := Tex;
end;

function TSpriteBatch.ReservaVertices: PSpriteVertex;
var
  P: Pointer;
begin
  P := FArena.TryAlloc(4 * SizeOf(TSpriteVertex), 4);
  if P = nil then
  begin

    Flush;
    P := FArena.TryAlloc(4 * SizeOf(TSpriteVertex), 4);
  end;
  Result := PSpriteVertex(P);
  if Result <> nil then
    Inc(FSprites);
end;

procedure TSpriteBatch.DrawSprite(const Tex: TTextureHandle;
  const Center, Size: TVec2; const SrcUV: TRect2; const Color: TVec4;
  const Radians: Single; const Origin: TVec2);
var
  V: PSpriteVertex;
  HalfW, HalfH, S, C: Single;
  Ox, Oy: Single;
  Cx, Cy: array [0 .. 3] of Single;
  R, G, B, A: Byte;
  I: Integer;
  Caixa: TRect2;
begin
  if not FAtivo then
  begin
    LogError(LOG_RENDER, 'DrawSprite fora de BeginFrame/EndFrame', []);
    Exit;
  end;

  if FCullAtivo then
  begin

    HalfW := (Abs(Size.X) + Abs(Size.Y)) * 0.5;
    Caixa := TRect2.FromCenter(Center, Vec2(HalfW, HalfW));
    if not Caixa.Intersects(FCullBounds) then
    begin
      Inc(FDescartados);
      Exit;
    end;
  end;

  TrocaTextura(Tex);
  V := ReservaVertices;
  if V = nil then
    Exit;

  HalfW := Size.X * 0.5;
  HalfH := Size.Y * 0.5;

  Ox := (0.5 - Origin.X) * Size.X;
  Oy := (0.5 - Origin.Y) * Size.Y;

  Cx[0] := -HalfW + Ox; Cy[0] := -HalfH + Oy;
  Cx[1] :=  HalfW + Ox; Cy[1] := -HalfH + Oy;
  Cx[2] :=  HalfW + Ox; Cy[2] :=  HalfH + Oy;
  Cx[3] := -HalfW + Ox; Cy[3] :=  HalfH + Oy;

  R := ToByte(Color.X);
  G := ToByte(Color.Y);
  B := ToByte(Color.Z);
  A := ToByte(Color.W);

  if NearlyZero(Radians) then
  begin
    for I := 0 to 3 do
    begin
      V[I].X := Center.X + Cx[I];
      V[I].Y := Center.Y + Cy[I];
    end;
  end
  else
  begin

    SinCos(Radians, S, C);
    for I := 0 to 3 do
    begin
      V[I].X := Center.X + Cx[I] * C - Cy[I] * S;
      V[I].Y := Center.Y + Cx[I] * S + Cy[I] * C;
    end;
  end;

  V[0].U := SrcUV.X;             V[0].V := SrcUV.Y;
  V[1].U := SrcUV.X + SrcUV.W;   V[1].V := SrcUV.Y;
  V[2].U := SrcUV.X + SrcUV.W;   V[2].V := SrcUV.Y + SrcUV.H;
  V[3].U := SrcUV.X;             V[3].V := SrcUV.Y + SrcUV.H;

  for I := 0 to 3 do
  begin
    V[I].R := R; V[I].G := G; V[I].B := B; V[I].A := A;
  end;
end;

procedure TSpriteBatch.DrawSprite(const Tex: TTextureHandle;
  const Center, Size: TVec2; const Color: TVec4);
begin
  DrawSprite(Tex, Center, Size, TRect2.Create(0, 0, 1, 1), Color, 0.0,
    Vec2(0.5, 0.5));
end;

procedure TSpriteBatch.DrawRect(const Center, Size: TVec2; const Color: TVec4);
begin
  DrawSprite(FWhiteTex, Center, Size, TRect2.Create(0, 0, 1, 1), Color, 0.0,
    Vec2(0.5, 0.5));
end;

procedure TSpriteBatch.DrawRectRotated(const Center, Size: TVec2;
  const Radians: Single; const Color: TVec4);
begin
  DrawSprite(FWhiteTex, Center, Size, TRect2.Create(0, 0, 1, 1), Color,
    Radians, Vec2(0.5, 0.5));
end;

procedure TSpriteBatch.DrawLine(const A, B: TVec2; const Thickness: Single;
  const Color: TVec4);
var
  D: TVec2;
  Comp, Ang: Single;
begin
  D := B - A;
  Comp := D.Length;
  if Comp <= EPSILON then
    Exit;
  Ang := ArcTan2(D.Y, D.X);

  DrawSprite(FWhiteTex, A, Vec2(Comp, Thickness), TRect2.Create(0, 0, 1, 1),
    Color, Ang, Vec2(0.0, 0.5));
end;

procedure TSpriteBatch.DrawRectOutline(const R: TRect2; const Thickness: Single;
  const Color: TVec4);
var
  Mn, Mx: TVec2;
begin
  Mn := R.Min;
  Mx := R.Max;
  DrawLine(Vec2(Mn.X, Mn.Y), Vec2(Mx.X, Mn.Y), Thickness, Color);
  DrawLine(Vec2(Mx.X, Mn.Y), Vec2(Mx.X, Mx.Y), Thickness, Color);
  DrawLine(Vec2(Mx.X, Mx.Y), Vec2(Mn.X, Mx.Y), Thickness, Color);
  DrawLine(Vec2(Mn.X, Mx.Y), Vec2(Mn.X, Mn.Y), Thickness, Color);
end;

end.
