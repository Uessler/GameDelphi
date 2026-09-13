unit Engine.Assets.Image.WIC;

interface

uses
  System.SysUtils;

function LoadPngRGBA8(const FileName: string; out Width, Height: Integer;
  out Pixels: TBytes; out Error: string): Boolean;

implementation

uses
  Winapi.Windows,
  Winapi.ActiveX,
  Winapi.Wincodec;

function HResultError(const Operation: string; const Value: HRESULT): string;
begin
  Result := Format('%s falhou (0x%.8x)', [Operation, Cardinal(Value)]);
end;

function LoadPngRGBA8(const FileName: string; out Width, Height: Integer;
  out Pixels: TBytes; out Error: string): Boolean;
var
  ComResult: HRESULT;
  MustUninitialize: Boolean;
  Factory: IWICImagingFactory;
  Decoder: IWICBitmapDecoder;
  Frame: IWICBitmapFrameDecode;
  Converter: IWICFormatConverter;
  W, H, Stride, BufferSize: UINT;
  ByteCount: UInt64;
  Row, HalfRows: Integer;
  TempRow: TBytes;
begin
  Result := False;
  Width := 0;
  Height := 0;
  Pixels := nil;
  Error := '';

  if not FileExists(FileName) then
  begin
    Error := 'arquivo nao encontrado: ' + FileName;
    Exit;
  end;

  if not SameText(ExtractFileExt(FileName), '.png') then
  begin
    Error := 'formato nao suportado: ' + ExtractFileExt(FileName);
    Exit;
  end;

  ComResult := CoInitializeEx(nil, COINIT_MULTITHREADED);
  MustUninitialize := (ComResult = S_OK) or (ComResult = S_FALSE);
  if Failed(ComResult) and (ComResult <> RPC_E_CHANGED_MODE) then
  begin
    Error := HResultError('CoInitializeEx', ComResult);
    Exit;
  end;

  try
    try
      ComResult := CoCreateInstance(CLSID_WICImagingFactory, nil,
      CLSCTX_INPROC_SERVER, IUnknown, Factory);
      if Failed(ComResult) or (Factory = nil) then
      begin
        Error := HResultError('CoCreateInstance WIC', ComResult);
        Exit;
      end;

      ComResult := Factory.CreateDecoderFromFilename(PChar(FileName), GUID_NULL,
        GENERIC_READ, WICDecodeMetadataCacheOnLoad, Decoder);
      if Failed(ComResult) or (Decoder = nil) then
      begin
        Error := HResultError('CreateDecoderFromFilename', ComResult);
        Exit;
      end;

      ComResult := Decoder.GetFrame(0, Frame);
      if Failed(ComResult) or (Frame = nil) then
      begin
        Error := HResultError('GetFrame', ComResult);
        Exit;
      end;

      ComResult := Frame.GetSize(W, H);
      if Failed(ComResult) or (W = 0) or (H = 0) then
      begin
        Error := HResultError('GetSize', ComResult);
        Exit;
      end;

      ByteCount := UInt64(W) * UInt64(H) * 4;
      if (W > High(UINT) div 4) or (ByteCount > UInt64(MaxInt)) then
      begin
        Error := 'imagem grande demais';
        Exit;
      end;

      ComResult := Factory.CreateFormatConverter(Converter);
      if Failed(ComResult) or (Converter = nil) then
      begin
        Error := HResultError('CreateFormatConverter', ComResult);
        Exit;
      end;

      ComResult := Converter.Initialize(Frame, GUID_WICPixelFormat32bppRGBA,
        WICBitmapDitherTypeNone, nil, 0, WICBitmapPaletteTypeCustom);
      if Failed(ComResult) then
      begin
        Error := HResultError('FormatConverter.Initialize', ComResult);
        Exit;
      end;

      Stride := W * 4;
      BufferSize := UINT(ByteCount);
      SetLength(Pixels, Integer(ByteCount));
      ComResult := Converter.CopyPixels(nil, Stride, BufferSize, @Pixels[0]);
      if Failed(ComResult) then
      begin
        Pixels := nil;
        Error := HResultError('CopyPixels', ComResult);
        Exit;
      end;

      SetLength(TempRow, Stride);
      HalfRows := Integer(H) div 2;
      for Row := 0 to HalfRows - 1 do
      begin
        Move(Pixels[Row * Integer(Stride)], TempRow[0], Stride);
        Move(Pixels[(Integer(H) - 1 - Row) * Integer(Stride)],
          Pixels[Row * Integer(Stride)], Stride);
        Move(TempRow[0], Pixels[(Integer(H) - 1 - Row) * Integer(Stride)],
          Stride);
      end;

      Width := Integer(W);
      Height := Integer(H);
      Result := True;
    except
      on E: Exception do
      begin
        Pixels := nil;
        Width := 0;
        Height := 0;
        Error := E.Message;
      end;
    end;
  finally
    Converter := nil;
    Frame := nil;
    Decoder := nil;
    Factory := nil;
    if MustUninitialize then
      CoUninitialize;
  end;
end;

end.
