

unit Engine.Renderer.Camera2D;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  Math,
{$ELSE}
  System.Math,
{$ENDIF}
  Engine.Core.Math;

type

  TFitMode = (fmLetterbox, fmStretch, fmExpand);

  TViewport = record
    X, Y, W, H: Integer;
  end;

  TCamera2D = record
  public

    Position: TVec2;

    Zoom: Single;

    Rotation: Single;

    WorldWidth, WorldHeight: Single;
    FitMode: TFitMode;

    procedure Init(const AWorldW, AWorldH: Single);

    function ViewProjection: TMat4;

    function ComputeViewport(const WindowW, WindowH: Integer): TViewport;

    function VisibleBounds: TRect2;

    function ScreenToWorld(const ScreenX, ScreenY: Single;
      const Vp: TViewport): TVec2;
    function WorldToScreen(const World: TVec2; const Vp: TViewport): TVec2;

    procedure ZoomAt(const WorldPoint: TVec2; const NewZoom: Single);
  end;
  PCamera2D = ^TCamera2D;

implementation

procedure TCamera2D.Init(const AWorldW, AWorldH: Single);
begin
  Position := Vec2(AWorldW * 0.5, AWorldH * 0.5);
  Zoom := 1.0;
  Rotation := 0.0;
  WorldWidth := AWorldW;
  WorldHeight := AWorldH;
  FitMode := fmLetterbox;
end;

function TCamera2D.ViewProjection: TMat4;
var
  HalfW, HalfH: Single;
begin
  HalfW := WorldWidth * 0.5;
  HalfH := WorldHeight * 0.5;

  Result := TMat4.Ortho(-HalfW, HalfW, -HalfH, HalfH, -1.0, 1.0) *
            TMat4.Scaling(Vec3(Zoom, Zoom, 1.0)) *
            TMat4.RotationZ(-Rotation) *
            TMat4.Translation(Vec3(-Position.X, -Position.Y, 0.0));
end;

function TCamera2D.ComputeViewport(const WindowW, WindowH: Integer): TViewport;
var
  Escala, EscalaX, EscalaY: Single;
begin
  if (WindowW <= 0) or (WindowH <= 0) or
     (WorldWidth <= 0) or (WorldHeight <= 0) then
  begin
    Result.X := 0; Result.Y := 0;
    Result.W := WindowW; Result.H := WindowH;
    Exit;
  end;

  EscalaX := WindowW / WorldWidth;
  EscalaY := WindowH / WorldHeight;

  case FitMode of
    fmStretch:
      begin
        Result.X := 0; Result.Y := 0;
        Result.W := WindowW; Result.H := WindowH;
        Exit;
      end;
    fmExpand:
      if EscalaX > EscalaY then Escala := EscalaX else Escala := EscalaY;
  else

    if EscalaX < EscalaY then Escala := EscalaX else Escala := EscalaY;
  end;

  Result.W := Round(WorldWidth * Escala);
  Result.H := Round(WorldHeight * Escala);
  Result.X := (WindowW - Result.W) div 2;
  Result.Y := (WindowH - Result.H) div 2;
end;

function TCamera2D.VisibleBounds: TRect2;
var
  HalfW, HalfH, S, C, ExtX, ExtY: Single;
begin
  if Zoom <= 0.0 then
    Exit(TRect2.Create(Position.X, Position.Y, 0, 0));

  HalfW := WorldWidth * 0.5 / Zoom;
  HalfH := WorldHeight * 0.5 / Zoom;

  if NearlyZero(Rotation) then
  begin
    ExtX := HalfW;
    ExtY := HalfH;
  end
  else
  begin

    SinCos(Rotation, S, C);
    S := Abs(S);
    C := Abs(C);
    ExtX := HalfW * C + HalfH * S;
    ExtY := HalfW * S + HalfH * C;
  end;

  Result := TRect2.FromCenter(Position, Vec2(ExtX, ExtY));
end;

function TCamera2D.ScreenToWorld(const ScreenX, ScreenY: Single;
  const Vp: TViewport): TVec2;
var
  NdcX, NdcY: Single;
  Inv: TMat4;
  P: TVec4;
begin
  if (Vp.W <= 0) or (Vp.H <= 0) then
    Exit(Position);

  NdcX := (ScreenX - Vp.X) / Vp.W * 2.0 - 1.0;
  NdcY := 1.0 - (ScreenY - Vp.Y) / Vp.H * 2.0;

  Inv := ViewProjection.Inverse;
  P := Inv * TVec4.Create(NdcX, NdcY, 0.0, 1.0);
  if not NearlyZero(P.W) then
    Result := Vec2(P.X / P.W, P.Y / P.W)
  else
    Result := Vec2(P.X, P.Y);
end;

function TCamera2D.WorldToScreen(const World: TVec2; const Vp: TViewport): TVec2;
var
  P: TVec4;
begin
  P := ViewProjection * TVec4.Create(World.X, World.Y, 0.0, 1.0);
  if not NearlyZero(P.W) then
  begin
    P.X := P.X / P.W;
    P.Y := P.Y / P.W;
  end;
  Result.X := Vp.X + (P.X * 0.5 + 0.5) * Vp.W;
  Result.Y := Vp.Y + (0.5 - P.Y * 0.5) * Vp.H;
end;

procedure TCamera2D.ZoomAt(const WorldPoint: TVec2; const NewZoom: Single);
var
  Fator: Single;
begin
  if (NewZoom <= 0.0) or (Zoom <= 0.0) then
    Exit;

  Fator := Zoom / NewZoom;
  Position := WorldPoint + (Position - WorldPoint) * Fator;
  Zoom := NewZoom;
end;

end.
