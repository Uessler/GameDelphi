

unit Engine.RHI.Types;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$SCOPEDENUMS OFF}

interface

uses
  Engine.Core.Memory;

type
  TBufferHandle  = THandle;
  TShaderHandle  = THandle;
  TTextureHandle = THandle;
  TMeshHandle    = THandle;
  TRenderTargetHandle = THandle;

  TBufferKind = (bkVertex, bkIndex, bkUniform);

  TBufferUsage = (buStatic, buDynamic, buStream);

  TVertexFormat = (
    vfFloat1, vfFloat2, vfFloat3, vfFloat4,
    vfUByte4, vfUByte4N,
    vfShort2, vfShort2N, vfShort4, vfShort4N
  );

  TVertexAttrib = record

    Location: Integer;
    Format: TVertexFormat;

    Offset: Integer;
  end;

  TVertexLayout = record
  private
    FAttribs: array [0 .. 15] of TVertexAttrib;
    FCount: Integer;
    FStride: Integer;
  public
    procedure Init(const AStride: Integer);

    procedure Add(const ALocation: Integer; const AFormat: TVertexFormat;
      const AOffset: Integer);

    procedure AddPacked(const ALocation: Integer; const AFormat: TVertexFormat);

    function PackedSize: Integer;

    function Count: Integer;
    function Stride: Integer;
    function Attrib(const I: Integer): TVertexAttrib;
  end;

  TPrimitive = (ptTriangles, ptTriangleStrip, ptTriangleFan, ptLines,
    ptLineStrip, ptPoints);

  TIndexFormat = (ifUInt16, ifUInt32);

  TTextureFormat = (tfR8, tfRGB8, tfRGBA8, tfSRGBA8);
  TTextureFilter = (tflNearest, tflLinear, tflLinearMipmap);
  TTextureWrap = (twRepeat, twClamp, twMirror);

  TTextureDesc = record
    Width, Height: Integer;
    Format: TTextureFormat;
    Filter: TTextureFilter;
    Wrap: TTextureWrap;
    GenerateMipmaps: Boolean;

    Pixels: Pointer;

    class function Default2D(const W, H: Integer): TTextureDesc; static;
  end;

  TBlendMode = (bmNone, bmAlpha, bmAdditive, bmPremultiplied);

  TDepthTest = (dtOff, dtLess, dtLessEqual, dtAlways);
  TCullMode = (cmNone, cmBack, cmFront);

  TClearFlag = (cfColor, cfDepth, cfStencil);
  TClearFlags = set of TClearFlag;

  TRHIStats = record
    DrawCalls: Integer;
    Triangles: Int64;
    StateChanges: Integer;
    BufferUploads: Integer;
    BufferBytesUploaded: Int64;
    procedure Reset;
  end;

function VertexFormatSize(const F: TVertexFormat): Integer;

function VertexFormatComponents(const F: TVertexFormat): Integer;
function VertexFormatIsNormalized(const F: TVertexFormat): Boolean;
function IndexFormatSize(const F: TIndexFormat): Integer;
function TextureFormatBytesPerPixel(const F: TTextureFormat): Integer;

implementation

function VertexFormatSize(const F: TVertexFormat): Integer;
begin
  case F of
    vfFloat1: Result := 4;
    vfFloat2: Result := 8;
    vfFloat3: Result := 12;
    vfFloat4: Result := 16;
    vfUByte4, vfUByte4N: Result := 4;
    vfShort2, vfShort2N: Result := 4;
    vfShort4, vfShort4N: Result := 8;
  else
    Result := 0;
  end;
end;

function VertexFormatComponents(const F: TVertexFormat): Integer;
begin
  case F of
    vfFloat1: Result := 1;
    vfFloat2, vfShort2, vfShort2N: Result := 2;
    vfFloat3: Result := 3;
    vfFloat4, vfUByte4, vfUByte4N, vfShort4, vfShort4N: Result := 4;
  else
    Result := 0;
  end;
end;

function VertexFormatIsNormalized(const F: TVertexFormat): Boolean;
begin
  Result := F in [vfUByte4N, vfShort2N, vfShort4N];
end;

function IndexFormatSize(const F: TIndexFormat): Integer;
begin
  if F = ifUInt16 then
    Result := 2
  else
    Result := 4;
end;

function TextureFormatBytesPerPixel(const F: TTextureFormat): Integer;
begin
  case F of
    tfR8: Result := 1;
    tfRGB8: Result := 3;
    tfRGBA8, tfSRGBA8: Result := 4;
  else
    Result := 0;
  end;
end;

procedure TVertexLayout.Init(const AStride: Integer);
begin
  FCount := 0;
  FStride := AStride;
end;

procedure TVertexLayout.Add(const ALocation: Integer;
  const AFormat: TVertexFormat; const AOffset: Integer);
begin
  if FCount > High(FAttribs) then
    Exit;
  FAttribs[FCount].Location := ALocation;
  FAttribs[FCount].Format := AFormat;
  FAttribs[FCount].Offset := AOffset;
  Inc(FCount);
end;

procedure TVertexLayout.AddPacked(const ALocation: Integer;
  const AFormat: TVertexFormat);
begin
  Add(ALocation, AFormat, PackedSize);
end;

function TVertexLayout.PackedSize: Integer;
var
  I, Total: Integer;
begin
  Total := 0;
  for I := 0 to FCount - 1 do
    Inc(Total, VertexFormatSize(FAttribs[I].Format));
  Result := Total;
end;

function TVertexLayout.Count: Integer;
begin
  Result := FCount;
end;

function TVertexLayout.Stride: Integer;
begin
  Result := FStride;
end;

function TVertexLayout.Attrib(const I: Integer): TVertexAttrib;
begin
  Result := FAttribs[I];
end;

class function TTextureDesc.Default2D(const W, H: Integer): TTextureDesc;
begin
  Result.Width := W;
  Result.Height := H;
  Result.Format := tfRGBA8;
  Result.Filter := tflLinear;
  Result.Wrap := twClamp;
  Result.GenerateMipmaps := False;
  Result.Pixels := nil;
end;

procedure TRHIStats.Reset;
begin
  DrawCalls := 0;
  Triangles := 0;
  StateChanges := 0;
  BufferUploads := 0;
  BufferBytesUploaded := 0;
end;

end.
