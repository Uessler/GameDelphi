unit Engine.Assets;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Engine.Core.Memory,
  Engine.RHI.Types,
  Engine.RHI.GL.Device;

type
  TAssetHandle = THandle;
  TAssetKind = (akTexture, akShader);
  TAssetState = (astLoading, astReady, astError);

  TAssetEntry = record
    Kind: TAssetKind;
    State: TAssetState;
    Key: string;
    PathA: string;
    PathB: string;
    StampA: TDateTime;
    StampB: TDateTime;
    Filter: TTextureFilter;
    Wrap: TTextureWrap;
    TextureHandle: TTextureHandle;
    ShaderHandle: TShaderHandle;
    Error: string;
  end;

  TAssetManager = class
  private
    FDevice: TRHIDevice;
    FAssets: TResourcePool<TAssetEntry>;
    FByKey: TDictionary<string, TAssetHandle>;
    FPollAccumulator: Single;
    FPollInterval: Single;
    class function CanonicalPath(const FileName: string): string; static;
    class function FileStamp(const FileName: string): TDateTime; static;
    class function TextureKey(const FileName: string;
      const Filter: TTextureFilter; const Wrap: TTextureWrap): string; static;
    class function ShaderKey(const VertexFile, FragmentFile: string): string; static;
    function ReloadTexture(const Entry: Pointer): Boolean;
    function ReloadShader(const Entry: Pointer): Boolean;
    procedure DestroyEntry(const Entry: Pointer);
  public
    constructor Create(const Device: TRHIDevice);
    destructor Destroy; override;
    function LoadTexture(const FileName: string;
      const Filter: TTextureFilter = tflLinear;
      const Wrap: TTextureWrap = twClamp): TAssetHandle;
    function LoadShader(const VertexFile, FragmentFile: string): TAssetHandle;
    function Reload(const Handle: TAssetHandle): Boolean;
    procedure Update(const DeltaSeconds: Single);
    procedure Release(const Handle: TAssetHandle);
    function Texture(const Handle: TAssetHandle): TTextureHandle;
    function Shader(const Handle: TAssetHandle): TShaderHandle;
    function State(const Handle: TAssetHandle): TAssetState;
    function LastError(const Handle: TAssetHandle): string;
    function Count: Integer;
    property PollInterval: Single read FPollInterval write FPollInterval;
  end;

implementation

uses
  System.IOUtils,
  Engine.Assets.Image.WIC;

type
  PAssetEntry = ^TAssetEntry;

constructor TAssetManager.Create(const Device: TRHIDevice);
begin
  inherited Create;
  if Device = nil then
    raise EArgumentNilException.Create('Device');
  FDevice := Device;
  FAssets.Init(64);
  FByKey := TDictionary<string, TAssetHandle>.Create;
  FPollAccumulator := 0;
  FPollInterval := 0.25;
end;

destructor TAssetManager.Destroy;
var
  Slot: Integer;
begin
  Slot := FAssets.FirstAlive;
  while Slot >= 0 do
  begin
    DestroyEntry(FAssets.PtrAt(Slot));
    Slot := FAssets.NextAlive(Slot);
  end;
  FByKey.Free;
  FAssets.Clear;
  inherited;
end;

class function TAssetManager.CanonicalPath(const FileName: string): string;
begin
  Result := ExpandFileName(FileName);
end;

class function TAssetManager.FileStamp(const FileName: string): TDateTime;
begin
  if not TFile.Exists(FileName) then
    Exit(0);
  try
    Result := TFile.GetLastWriteTimeUtc(FileName);
  except
    Result := 0;
  end;
end;

class function TAssetManager.TextureKey(const FileName: string;
  const Filter: TTextureFilter; const Wrap: TTextureWrap): string;
begin
  Result := 'texture|' + LowerCase(CanonicalPath(FileName)) + '|' +
    IntToStr(Ord(Filter)) + '|' + IntToStr(Ord(Wrap));
end;

class function TAssetManager.ShaderKey(const VertexFile,
  FragmentFile: string): string;
begin
  Result := 'shader|' + LowerCase(CanonicalPath(VertexFile)) + '|' +
    LowerCase(CanonicalPath(FragmentFile));
end;

function TAssetManager.LoadTexture(const FileName: string;
  const Filter: TTextureFilter; const Wrap: TTextureWrap): TAssetHandle;
var
  Entry: TAssetEntry;
  Key: string;
begin
  Key := TextureKey(FileName, Filter, Wrap);
  if FByKey.TryGetValue(Key, Result) then
    Exit;

  Entry.Kind := akTexture;
  Entry.State := astLoading;
  Entry.Key := Key;
  Entry.PathA := CanonicalPath(FileName);
  Entry.PathB := '';
  Entry.StampA := 0;
  Entry.StampB := 0;
  Entry.Filter := Filter;
  Entry.Wrap := Wrap;
  Entry.TextureHandle := THandle.Null;
  Entry.ShaderHandle := THandle.Null;
  Entry.Error := '';
  Result := FAssets.Add(Entry);
  FByKey.Add(Key, Result);
  Reload(Result);
end;

function TAssetManager.LoadShader(const VertexFile,
  FragmentFile: string): TAssetHandle;
var
  Entry: TAssetEntry;
  Key: string;
begin
  Key := ShaderKey(VertexFile, FragmentFile);
  if FByKey.TryGetValue(Key, Result) then
    Exit;

  Entry.Kind := akShader;
  Entry.State := astLoading;
  Entry.Key := Key;
  Entry.PathA := CanonicalPath(VertexFile);
  Entry.PathB := CanonicalPath(FragmentFile);
  Entry.StampA := 0;
  Entry.StampB := 0;
  Entry.Filter := tflLinear;
  Entry.Wrap := twClamp;
  Entry.TextureHandle := THandle.Null;
  Entry.ShaderHandle := THandle.Null;
  Entry.Error := '';
  Result := FAssets.Add(Entry);
  FByKey.Add(Key, Result);
  Reload(Result);
end;

function TAssetManager.ReloadTexture(const Entry: Pointer): Boolean;
var
  Asset: PAssetEntry;
  Pixels: TBytes;
  Width, Height: Integer;
  Error: string;
  Desc: TTextureDesc;
  NewHandle, OldHandle: TTextureHandle;
begin
  Result := False;
  Asset := Entry;
  if not LoadPngRGBA8(Asset.PathA, Width, Height, Pixels, Error) then
  begin
    Asset.State := astError;
    Asset.Error := Error;
    Exit;
  end;

  Desc := TTextureDesc.Default2D(Width, Height);
  Desc.Filter := Asset.Filter;
  Desc.Wrap := Asset.Wrap;
  Desc.Pixels := @Pixels[0];
  NewHandle := FDevice.CreateTexture(Desc);
  if NewHandle.IsNull then
  begin
    Asset.State := astError;
    Asset.Error := 'falha ao criar textura na GPU';
    Exit;
  end;

  OldHandle := Asset.TextureHandle;
  Asset.TextureHandle := NewHandle;
  Asset.State := astReady;
  Asset.Error := '';
  if not OldHandle.IsNull then
    FDevice.DestroyTexture(OldHandle);
  Result := True;
end;

function TAssetManager.ReloadShader(const Entry: Pointer): Boolean;
var
  Asset: PAssetEntry;
  VertexSource, FragmentSource, Error: string;
  NewHandle, OldHandle: TShaderHandle;
begin
  Result := False;
  Asset := Entry;
  try
    VertexSource := TFile.ReadAllText(Asset.PathA, TEncoding.UTF8);
    FragmentSource := TFile.ReadAllText(Asset.PathB, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      Asset.State := astError;
      Asset.Error := E.Message;
      Exit;
    end;
  end;

  NewHandle := FDevice.CreateShader(VertexSource, FragmentSource, Error);
  if NewHandle.IsNull then
  begin
    Asset.State := astError;
    Asset.Error := Error;
    Exit;
  end;

  OldHandle := Asset.ShaderHandle;
  Asset.ShaderHandle := NewHandle;
  Asset.State := astReady;
  Asset.Error := '';
  if not OldHandle.IsNull then
    FDevice.DestroyShader(OldHandle);
  Result := True;
end;

function TAssetManager.Reload(const Handle: TAssetHandle): Boolean;
var
  Entry: PAssetEntry;
begin
  Entry := FAssets.GetPtr(Handle);
  if Entry = nil then
    Exit(False);
  Entry.StampA := FileStamp(Entry.PathA);
  Entry.StampB := FileStamp(Entry.PathB);
  case Entry.Kind of
    akTexture: Result := ReloadTexture(Entry);
    akShader: Result := ReloadShader(Entry);
  else
    Result := False;
  end;
end;

procedure TAssetManager.Update(const DeltaSeconds: Single);
var
  Slot: Integer;
  Entry: PAssetEntry;
  StampA, StampB: TDateTime;
begin
  if DeltaSeconds > 0 then
    FPollAccumulator := FPollAccumulator + DeltaSeconds;
  if (FPollInterval > 0) and (FPollAccumulator < FPollInterval) then
    Exit;
  FPollAccumulator := 0;

  Slot := FAssets.FirstAlive;
  while Slot >= 0 do
  begin
    Entry := FAssets.PtrAt(Slot);
    StampA := FileStamp(Entry.PathA);
    StampB := FileStamp(Entry.PathB);
    if (StampA <> Entry.StampA) or (StampB <> Entry.StampB) then
      Reload(FAssets.HandleAt(Slot));
    Slot := FAssets.NextAlive(Slot);
  end;
end;

procedure TAssetManager.DestroyEntry(const Entry: Pointer);
var
  Asset: PAssetEntry;
begin
  Asset := Entry;
  if Asset = nil then
    Exit;
  case Asset.Kind of
    akTexture:
      if not Asset.TextureHandle.IsNull then
        FDevice.DestroyTexture(Asset.TextureHandle);
    akShader:
      if not Asset.ShaderHandle.IsNull then
        FDevice.DestroyShader(Asset.ShaderHandle);
  end;
end;

procedure TAssetManager.Release(const Handle: TAssetHandle);
var
  Entry: PAssetEntry;
  Key: string;
begin
  Entry := FAssets.GetPtr(Handle);
  if Entry = nil then
    Exit;
  Key := Entry.Key;
  DestroyEntry(Entry);
  FByKey.Remove(Key);
  FAssets.Remove(Handle);
end;

function TAssetManager.Texture(const Handle: TAssetHandle): TTextureHandle;
var
  Entry: PAssetEntry;
begin
  Result := THandle.Null;
  Entry := FAssets.GetPtr(Handle);
  if (Entry <> nil) and (Entry.Kind = akTexture) then
    Result := Entry.TextureHandle;
end;

function TAssetManager.Shader(const Handle: TAssetHandle): TShaderHandle;
var
  Entry: PAssetEntry;
begin
  Result := THandle.Null;
  Entry := FAssets.GetPtr(Handle);
  if (Entry <> nil) and (Entry.Kind = akShader) then
    Result := Entry.ShaderHandle;
end;

function TAssetManager.State(const Handle: TAssetHandle): TAssetState;
var
  Entry: PAssetEntry;
begin
  Entry := FAssets.GetPtr(Handle);
  if Entry = nil then
    Exit(astError);
  Result := Entry.State;
end;

function TAssetManager.LastError(const Handle: TAssetHandle): string;
var
  Entry: PAssetEntry;
begin
  Entry := FAssets.GetPtr(Handle);
  if Entry = nil then
    Exit('asset handle invalido');
  Result := Entry.Error;
end;

function TAssetManager.Count: Integer;
begin
  Result := FAssets.Count;
end;

end.
