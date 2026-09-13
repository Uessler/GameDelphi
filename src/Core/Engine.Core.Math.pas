

unit Engine.Core.Math;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$SCOPEDENUMS ON}
{$EXCESSPRECISION OFF}

interface

uses
{$IFDEF FPC}
  Math;
{$ELSE}
  System.Math;
{$ENDIF}

const
  EPSILON     = 1.0E-6;
  EPSILON_SQR = EPSILON * EPSILON;
  PI_F        = 3.14159265358979;
  TAU_F       = 6.28318530717959;
  HALF_PI_F   = 1.57079632679490;
  DEG2RAD     = PI_F / 180.0;
  RAD2DEG     = 180.0 / PI_F;

type
  TVec2 = record
  public
    X, Y: Single;

    constructor Create(const AX, AY: Single); overload;
    constructor Create(const AScalar: Single); overload;

    class function Zero: TVec2; static; inline;
    class function One: TVec2; static; inline;
    class function UnitX: TVec2; static; inline;
    class function UnitY: TVec2; static; inline;

    class operator Add(const A, B: TVec2): TVec2; inline;
    class operator Subtract(const A, B: TVec2): TVec2; inline;
    class operator Multiply(const A, B: TVec2): TVec2; inline;
    class operator Multiply(const A: TVec2; const S: Single): TVec2; inline;
    class operator Multiply(const S: Single; const A: TVec2): TVec2; inline;
    class operator Divide(const A: TVec2; const S: Single): TVec2; inline;
    class operator Negative(const A: TVec2): TVec2; inline;
    class operator Equal(const A, B: TVec2): Boolean; inline;
    class operator NotEqual(const A, B: TVec2): Boolean; inline;

    function LengthSq: Single; inline;
    function Length: Single; inline;
    function Normalized: TVec2;
    procedure Normalize;
    function Dot(const B: TVec2): Single; inline;

    function Cross(const B: TVec2): Single; inline;

    function Perp: TVec2; inline;
    function Rotate(const Radians: Single): TVec2;

    function Angle: Single; inline;
    function IsZero: Boolean; inline;
    function Equals(const B: TVec2; const Tol: Single = EPSILON): Boolean;
  end;
  PVec2 = ^TVec2;

  TVec3 = record
  public
    X, Y, Z: Single;

    constructor Create(const AX, AY, AZ: Single); overload;
    constructor Create(const AScalar: Single); overload;
    constructor Create(const XY: TVec2; const AZ: Single); overload;

    class function Zero: TVec3; static; inline;
    class function One: TVec3; static; inline;
    class function UnitX: TVec3; static; inline;
    class function UnitY: TVec3; static; inline;
    class function UnitZ: TVec3; static; inline;

    class function Forward: TVec3; static; inline;
    class function Up: TVec3; static; inline;
    class function Right: TVec3; static; inline;

    class operator Add(const A, B: TVec3): TVec3; inline;
    class operator Subtract(const A, B: TVec3): TVec3; inline;
    class operator Multiply(const A, B: TVec3): TVec3; inline;
    class operator Multiply(const A: TVec3; const S: Single): TVec3; inline;
    class operator Multiply(const S: Single; const A: TVec3): TVec3; inline;
    class operator Divide(const A: TVec3; const S: Single): TVec3; inline;
    class operator Negative(const A: TVec3): TVec3; inline;
    class operator Equal(const A, B: TVec3): Boolean; inline;
    class operator NotEqual(const A, B: TVec3): Boolean; inline;

    function LengthSq: Single; inline;
    function Length: Single; inline;
    function Normalized: TVec3;
    procedure Normalize;
    function Dot(const B: TVec3): Single; inline;
    function Cross(const B: TVec3): TVec3; inline;

    function Reflect(const N: TVec3): TVec3; inline;
    function XY: TVec2; inline;
    function IsZero: Boolean; inline;
    function Equals(const B: TVec3; const Tol: Single = EPSILON): Boolean;
  end;
  PVec3 = ^TVec3;

  TVec4 = record
  public
    X, Y, Z, W: Single;

    constructor Create(const AX, AY, AZ, AW: Single); overload;
    constructor Create(const XYZ: TVec3; const AW: Single); overload;

    class function Zero: TVec4; static; inline;
    class function One: TVec4; static; inline;

    class operator Add(const A, B: TVec4): TVec4; inline;
    class operator Subtract(const A, B: TVec4): TVec4; inline;
    class operator Multiply(const A: TVec4; const S: Single): TVec4; inline;
    class operator Multiply(const S: Single; const A: TVec4): TVec4; inline;
    class operator Divide(const A: TVec4; const S: Single): TVec4; inline;
    class operator Negative(const A: TVec4): TVec4; inline;
    class operator Equal(const A, B: TVec4): Boolean; inline;
    class operator NotEqual(const A, B: TVec4): Boolean; inline;

    function LengthSq: Single; inline;
    function Length: Single; inline;
    function Normalized: TVec4;
    function Dot(const B: TVec4): Single; inline;
    function XYZ: TVec3; inline;
    function Equals(const B: TVec4; const Tol: Single = EPSILON): Boolean;
  end;
  PVec4 = ^TVec4;

  TQuat = record
  public
    X, Y, Z, W: Single;

    constructor Create(const AX, AY, AZ, AW: Single);

    class function Identity: TQuat; static; inline;
    class function FromAxisAngle(const Axis: TVec3; const Radians: Single): TQuat; static;

    class function FromEuler(const Pitch, Yaw, Roll: Single): TQuat; static;

    class function FromTo(const AFrom, ATo: TVec3): TQuat; static;

    class operator Multiply(const A, B: TQuat): TQuat;
    class operator Multiply(const Q: TQuat; const V: TVec3): TVec3;

    function LengthSq: Single; inline;
    function Length: Single; inline;
    function Normalized: TQuat;
    procedure Normalize;
    function Conjugate: TQuat; inline;

    function Inverse: TQuat;
    function Dot(const B: TQuat): Single; inline;
    function Rotate(const V: TVec3): TVec3;
    function Slerp(const B: TQuat; const T: Single): TQuat;
    function Equals(const B: TQuat; const Tol: Single = EPSILON): Boolean;
  end;
  PQuat = ^TQuat;

  TMat4 = record
  public
    M: array [0 .. 15] of Single;

    class function Identity: TMat4; static;
    class function Translation(const T: TVec3): TMat4; static;
    class function Scaling(const S: TVec3): TMat4; overload; static;
    class function Scaling(const S: Single): TMat4; overload; static;
    class function RotationX(const Radians: Single): TMat4; static;
    class function RotationY(const Radians: Single): TMat4; static;
    class function RotationZ(const Radians: Single): TMat4; static;
    class function RotationQuat(const Q: TQuat): TMat4; static;

    class function TRS(const T: TVec3; const R: TQuat; const S: TVec3): TMat4; static;

    class function Ortho(const L, R, B, T, ZNear, ZFar: Single): TMat4; static;

    class function Ortho2D(const Width, Height: Single): TMat4; static;

    class function Perspective(const FovY, Aspect, ZNear, ZFar: Single): TMat4; static;
    class function LookAt(const Eye, Target, UpDir: TVec3): TMat4; static;

    class operator Multiply(const A, B: TMat4): TMat4;
    class operator Multiply(const A: TMat4; const V: TVec4): TVec4;
    class operator Equal(const A, B: TMat4): Boolean;
    class operator NotEqual(const A, B: TMat4): Boolean;

    function Get(const Row, Col: Integer): Single; inline;
    procedure SetValue(const Row, Col: Integer; const Value: Single); inline;

    function TransformPoint(const V: TVec3): TVec3;

    function TransformDirection(const V: TVec3): TVec3;

    function Transposed: TMat4;
    function Determinant: Single;

    function TryInverse(out Dest: TMat4): Boolean;

    function Inverse: TMat4;

    function Equals(const B: TMat4; const Tol: Single = EPSILON): Boolean;

    function Ptr: PSingle; inline;
  end;
  PMat4 = ^TMat4;

  TRect2 = record
  public
    X, Y, W, H: Single;

    constructor Create(const AX, AY, AW, AH: Single);
    class function FromMinMax(const Min, Max: TVec2): TRect2; static;
    class function FromCenter(const Center, HalfSize: TVec2): TRect2; static;

    function Min: TVec2; inline;
    function Max: TVec2; inline;
    function Center: TVec2; inline;
    function Size: TVec2; inline;
    function Contains(const P: TVec2): Boolean; inline;
    function Intersects(const B: TRect2): Boolean; inline;
    function Union(const B: TRect2): TRect2;
    function Expanded(const Amount: Single): TRect2; inline;
  end;
  PRect2 = ^TRect2;

function Clamp(const V, Lo, Hi: Single): Single; inline;
function Clampi(const V, Lo, Hi: Integer): Integer; inline;
function Saturate(const V: Single): Single; inline;
function Lerp(const A, B, T: Single): Single; inline;

function InvLerp(const A, B, V: Single): Single; inline;
function Remap(const V, InLo, InHi, OutLo, OutHi: Single): Single; inline;
function SmoothStep(const Edge0, Edge1, V: Single): Single;
function MoveTowards(const Current, Target, MaxDelta: Single): Single;
function NearlyEqual(const A, B: Single; const Tol: Single = EPSILON): Boolean; inline;
function NearlyZero(const V: Single; const Tol: Single = EPSILON): Boolean; inline;
function SignF(const V: Single): Single; inline;

function Wrap(const V, Range: Single): Single;

function DeltaAngle(const A, B: Single): Single;
function LerpAngle(const A, B, T: Single): Single;
function Deg2RadF(const Degrees: Single): Single; inline;
function Rad2DegF(const Radians: Single): Single; inline;

function Vec2(const X, Y: Single): TVec2; inline;
function Vec3(const X, Y, Z: Single): TVec3; inline;
function Vec4(const X, Y, Z, W: Single): TVec4; inline;
function Lerp2(const A, B: TVec2; const T: Single): TVec2; inline;
function Lerp3(const A, B: TVec3; const T: Single): TVec3; inline;
function Distance2(const A, B: TVec2): Single; inline;
function Distance3(const A, B: TVec3): Single; inline;
function DistanceSq2(const A, B: TVec2): Single; inline;
function DistanceSq3(const A, B: TVec3): Single; inline;

implementation

function Clamp(const V, Lo, Hi: Single): Single;
begin
  if V < Lo then Exit(Lo);
  if V > Hi then Exit(Hi);
  Result := V;
end;

function Clampi(const V, Lo, Hi: Integer): Integer;
begin
  if V < Lo then Exit(Lo);
  if V > Hi then Exit(Hi);
  Result := V;
end;

function Saturate(const V: Single): Single;
begin
  Result := Clamp(V, 0.0, 1.0);
end;

function Lerp(const A, B, T: Single): Single;
begin
  Result := A + (B - A) * T;
end;

function InvLerp(const A, B, V: Single): Single;
begin
  if NearlyZero(B - A) then
    Result := 0.0
  else
    Result := (V - A) / (B - A);
end;

function Remap(const V, InLo, InHi, OutLo, OutHi: Single): Single;
begin
  Result := Lerp(OutLo, OutHi, InvLerp(InLo, InHi, V));
end;

function SmoothStep(const Edge0, Edge1, V: Single): Single;
var
  T: Single;
begin
  T := Saturate(InvLerp(Edge0, Edge1, V));
  Result := T * T * (3.0 - 2.0 * T);
end;

function MoveTowards(const Current, Target, MaxDelta: Single): Single;
begin
  if Abs(Target - Current) <= MaxDelta then
    Result := Target
  else
    Result := Current + SignF(Target - Current) * MaxDelta;
end;

function NearlyEqual(const A, B: Single; const Tol: Single): Boolean;
begin
  Result := Abs(A - B) <= Tol;
end;

function NearlyZero(const V: Single; const Tol: Single): Boolean;
begin
  Result := Abs(V) <= Tol;
end;

function SignF(const V: Single): Single;
begin
  if V > 0.0 then Exit(1.0);
  if V < 0.0 then Exit(-1.0);
  Result := 0.0;
end;

function Wrap(const V, Range: Single): Single;
begin
  if NearlyZero(Range) then Exit(0.0);
  Result := V - Int(V / Range) * Range;
  if Result < 0.0 then
    Result := Result + Abs(Range);
end;

function DeltaAngle(const A, B: Single): Single;
begin
  Result := Wrap(B - A, TAU_F);
  if Result > PI_F then
    Result := Result - TAU_F;
end;

function LerpAngle(const A, B, T: Single): Single;
begin
  Result := A + DeltaAngle(A, B) * T;
end;

function Deg2RadF(const Degrees: Single): Single;
begin
  Result := Degrees * DEG2RAD;
end;

function Rad2DegF(const Radians: Single): Single;
begin
  Result := Radians * RAD2DEG;
end;

function Vec2(const X, Y: Single): TVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Vec3(const X, Y, Z: Single): TVec3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function Vec4(const X, Y, Z, W: Single): TVec4;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := W;
end;

function Lerp2(const A, B: TVec2; const T: Single): TVec2;
begin
  Result.X := A.X + (B.X - A.X) * T;
  Result.Y := A.Y + (B.Y - A.Y) * T;
end;

function Lerp3(const A, B: TVec3; const T: Single): TVec3;
begin
  Result.X := A.X + (B.X - A.X) * T;
  Result.Y := A.Y + (B.Y - A.Y) * T;
  Result.Z := A.Z + (B.Z - A.Z) * T;
end;

function DistanceSq2(const A, B: TVec2): Single;
begin
  Result := Sqr(B.X - A.X) + Sqr(B.Y - A.Y);
end;

function DistanceSq3(const A, B: TVec3): Single;
begin
  Result := Sqr(B.X - A.X) + Sqr(B.Y - A.Y) + Sqr(B.Z - A.Z);
end;

function Distance2(const A, B: TVec2): Single;
begin
  Result := Sqrt(DistanceSq2(A, B));
end;

function Distance3(const A, B: TVec3): Single;
begin
  Result := Sqrt(DistanceSq3(A, B));
end;

constructor TVec2.Create(const AX, AY: Single);
begin
  X := AX;
  Y := AY;
end;

constructor TVec2.Create(const AScalar: Single);
begin
  X := AScalar;
  Y := AScalar;
end;

class function TVec2.Zero: TVec2;
begin
  Result.X := 0.0; Result.Y := 0.0;
end;

class function TVec2.One: TVec2;
begin
  Result.X := 1.0; Result.Y := 1.0;
end;

class function TVec2.UnitX: TVec2;
begin
  Result.X := 1.0; Result.Y := 0.0;
end;

class function TVec2.UnitY: TVec2;
begin
  Result.X := 0.0; Result.Y := 1.0;
end;

class operator TVec2.Add(const A, B: TVec2): TVec2;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

class operator TVec2.Subtract(const A, B: TVec2): TVec2;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

class operator TVec2.Multiply(const A, B: TVec2): TVec2;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
end;

class operator TVec2.Multiply(const A: TVec2; const S: Single): TVec2;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
end;

class operator TVec2.Multiply(const S: Single; const A: TVec2): TVec2;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
end;

class operator TVec2.Divide(const A: TVec2; const S: Single): TVec2;
var
  Inv: Single;
begin
  if NearlyZero(S) then
    Exit(TVec2.Zero);
  Inv := 1.0 / S;
  Result.X := A.X * Inv;
  Result.Y := A.Y * Inv;
end;

class operator TVec2.Negative(const A: TVec2): TVec2;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
end;

class operator TVec2.Equal(const A, B: TVec2): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TVec2.NotEqual(const A, B: TVec2): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y);
end;

function TVec2.LengthSq: Single;
begin
  Result := X * X + Y * Y;
end;

function TVec2.Length: Single;
begin
  Result := Sqrt(X * X + Y * Y);
end;

function TVec2.Normalized: TVec2;
var
  LenSq, Inv: Single;
begin
  LenSq := X * X + Y * Y;
  if LenSq <= EPSILON_SQR then
    Exit(TVec2.Zero);
  Inv := 1.0 / Sqrt(LenSq);
  Result.X := X * Inv;
  Result.Y := Y * Inv;
end;

procedure TVec2.Normalize;
begin
  Self := Normalized;
end;

function TVec2.Dot(const B: TVec2): Single;
begin
  Result := X * B.X + Y * B.Y;
end;

function TVec2.Cross(const B: TVec2): Single;
begin
  Result := X * B.Y - Y * B.X;
end;

function TVec2.Perp: TVec2;
begin
  Result.X := -Y;
  Result.Y := X;
end;

function TVec2.Rotate(const Radians: Single): TVec2;
var
  S, C: Single;
begin
  SinCos(Radians, S, C);
  Result.X := X * C - Y * S;
  Result.Y := X * S + Y * C;
end;

function TVec2.Angle: Single;
begin
  Result := ArcTan2(Y, X);
end;

function TVec2.IsZero: Boolean;
begin
  Result := LengthSq <= EPSILON_SQR;
end;

function TVec2.Equals(const B: TVec2; const Tol: Single): Boolean;
begin
  Result := NearlyEqual(X, B.X, Tol) and NearlyEqual(Y, B.Y, Tol);
end;

constructor TVec3.Create(const AX, AY, AZ: Single);
begin
  X := AX; Y := AY; Z := AZ;
end;

constructor TVec3.Create(const AScalar: Single);
begin
  X := AScalar; Y := AScalar; Z := AScalar;
end;

constructor TVec3.Create(const XY: TVec2; const AZ: Single);
begin
  X := XY.X; Y := XY.Y; Z := AZ;
end;

class function TVec3.Zero: TVec3;
begin
  Result.X := 0.0; Result.Y := 0.0; Result.Z := 0.0;
end;

class function TVec3.One: TVec3;
begin
  Result.X := 1.0; Result.Y := 1.0; Result.Z := 1.0;
end;

class function TVec3.UnitX: TVec3;
begin
  Result.X := 1.0; Result.Y := 0.0; Result.Z := 0.0;
end;

class function TVec3.UnitY: TVec3;
begin
  Result.X := 0.0; Result.Y := 1.0; Result.Z := 0.0;
end;

class function TVec3.UnitZ: TVec3;
begin
  Result.X := 0.0; Result.Y := 0.0; Result.Z := 1.0;
end;

class function TVec3.Forward: TVec3;
begin
  Result.X := 0.0; Result.Y := 0.0; Result.Z := -1.0;
end;

class function TVec3.Up: TVec3;
begin
  Result.X := 0.0; Result.Y := 1.0; Result.Z := 0.0;
end;

class function TVec3.Right: TVec3;
begin
  Result.X := 1.0; Result.Y := 0.0; Result.Z := 0.0;
end;

class operator TVec3.Add(const A, B: TVec3): TVec3;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TVec3.Subtract(const A, B: TVec3): TVec3;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TVec3.Multiply(const A, B: TVec3): TVec3;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
end;

class operator TVec3.Multiply(const A: TVec3; const S: Single): TVec3;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
  Result.Z := A.Z * S;
end;

class operator TVec3.Multiply(const S: Single; const A: TVec3): TVec3;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
  Result.Z := A.Z * S;
end;

class operator TVec3.Divide(const A: TVec3; const S: Single): TVec3;
var
  Inv: Single;
begin
  if NearlyZero(S) then
    Exit(TVec3.Zero);
  Inv := 1.0 / S;
  Result.X := A.X * Inv;
  Result.Y := A.Y * Inv;
  Result.Z := A.Z * Inv;
end;

class operator TVec3.Negative(const A: TVec3): TVec3;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
end;

class operator TVec3.Equal(const A, B: TVec3): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TVec3.NotEqual(const A, B: TVec3): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y) or (A.Z <> B.Z);
end;

function TVec3.LengthSq: Single;
begin
  Result := X * X + Y * Y + Z * Z;
end;

function TVec3.Length: Single;
begin
  Result := Sqrt(X * X + Y * Y + Z * Z);
end;

function TVec3.Normalized: TVec3;
var
  LenSq, Inv: Single;
begin
  LenSq := X * X + Y * Y + Z * Z;
  if LenSq <= EPSILON_SQR then
    Exit(TVec3.Zero);
  Inv := 1.0 / Sqrt(LenSq);
  Result.X := X * Inv;
  Result.Y := Y * Inv;
  Result.Z := Z * Inv;
end;

procedure TVec3.Normalize;
begin
  Self := Normalized;
end;

function TVec3.Dot(const B: TVec3): Single;
begin
  Result := X * B.X + Y * B.Y + Z * B.Z;
end;

function TVec3.Cross(const B: TVec3): TVec3;
begin
  Result.X := Y * B.Z - Z * B.Y;
  Result.Y := Z * B.X - X * B.Z;
  Result.Z := X * B.Y - Y * B.X;
end;

function TVec3.Reflect(const N: TVec3): TVec3;
var
  D: Single;
begin
  D := 2.0 * Dot(N);
  Result.X := X - N.X * D;
  Result.Y := Y - N.Y * D;
  Result.Z := Z - N.Z * D;
end;

function TVec3.XY: TVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function TVec3.IsZero: Boolean;
begin
  Result := LengthSq <= EPSILON_SQR;
end;

function TVec3.Equals(const B: TVec3; const Tol: Single): Boolean;
begin
  Result := NearlyEqual(X, B.X, Tol) and NearlyEqual(Y, B.Y, Tol) and
            NearlyEqual(Z, B.Z, Tol);
end;

constructor TVec4.Create(const AX, AY, AZ, AW: Single);
begin
  X := AX; Y := AY; Z := AZ; W := AW;
end;

constructor TVec4.Create(const XYZ: TVec3; const AW: Single);
begin
  X := XYZ.X; Y := XYZ.Y; Z := XYZ.Z; W := AW;
end;

class function TVec4.Zero: TVec4;
begin
  Result.X := 0.0; Result.Y := 0.0; Result.Z := 0.0; Result.W := 0.0;
end;

class function TVec4.One: TVec4;
begin
  Result.X := 1.0; Result.Y := 1.0; Result.Z := 1.0; Result.W := 1.0;
end;

class operator TVec4.Add(const A, B: TVec4): TVec4;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
  Result.W := A.W + B.W;
end;

class operator TVec4.Subtract(const A, B: TVec4): TVec4;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
  Result.W := A.W - B.W;
end;

class operator TVec4.Multiply(const A: TVec4; const S: Single): TVec4;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
  Result.Z := A.Z * S;
  Result.W := A.W * S;
end;

class operator TVec4.Multiply(const S: Single; const A: TVec4): TVec4;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
  Result.Z := A.Z * S;
  Result.W := A.W * S;
end;

class operator TVec4.Divide(const A: TVec4; const S: Single): TVec4;
var
  Inv: Single;
begin
  if NearlyZero(S) then
    Exit(TVec4.Zero);
  Inv := 1.0 / S;
  Result.X := A.X * Inv;
  Result.Y := A.Y * Inv;
  Result.Z := A.Z * Inv;
  Result.W := A.W * Inv;
end;

class operator TVec4.Negative(const A: TVec4): TVec4;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
  Result.W := -A.W;
end;

class operator TVec4.Equal(const A, B: TVec4): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and (A.W = B.W);
end;

class operator TVec4.NotEqual(const A, B: TVec4): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y) or (A.Z <> B.Z) or (A.W <> B.W);
end;

function TVec4.LengthSq: Single;
begin
  Result := X * X + Y * Y + Z * Z + W * W;
end;

function TVec4.Length: Single;
begin
  Result := Sqrt(LengthSq);
end;

function TVec4.Normalized: TVec4;
var
  LenSq, Inv: Single;
begin
  LenSq := LengthSq;
  if LenSq <= EPSILON_SQR then
    Exit(TVec4.Zero);
  Inv := 1.0 / Sqrt(LenSq);
  Result.X := X * Inv;
  Result.Y := Y * Inv;
  Result.Z := Z * Inv;
  Result.W := W * Inv;
end;

function TVec4.Dot(const B: TVec4): Single;
begin
  Result := X * B.X + Y * B.Y + Z * B.Z + W * B.W;
end;

function TVec4.XYZ: TVec3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function TVec4.Equals(const B: TVec4; const Tol: Single): Boolean;
begin
  Result := NearlyEqual(X, B.X, Tol) and NearlyEqual(Y, B.Y, Tol) and
            NearlyEqual(Z, B.Z, Tol) and NearlyEqual(W, B.W, Tol);
end;

constructor TQuat.Create(const AX, AY, AZ, AW: Single);
begin
  X := AX; Y := AY; Z := AZ; W := AW;
end;

class function TQuat.Identity: TQuat;
begin
  Result.X := 0.0; Result.Y := 0.0; Result.Z := 0.0; Result.W := 1.0;
end;

class function TQuat.FromAxisAngle(const Axis: TVec3; const Radians: Single): TQuat;
var
  N: TVec3;
  S, C: Single;
begin
  N := Axis.Normalized;
  if N.IsZero then
    Exit(TQuat.Identity);
  SinCos(Radians * 0.5, S, C);
  Result.X := N.X * S;
  Result.Y := N.Y * S;
  Result.Z := N.Z * S;
  Result.W := C;
end;

class function TQuat.FromEuler(const Pitch, Yaw, Roll: Single): TQuat;
var
  SP, CP, SY, CY, SR, CR: Single;
begin
  SinCos(Pitch * 0.5, SP, CP);
  SinCos(Yaw * 0.5, SY, CY);
  SinCos(Roll * 0.5, SR, CR);

  Result.X := CY * SP * CR + SY * CP * SR;
  Result.Y := SY * CP * CR - CY * SP * SR;
  Result.Z := CY * CP * SR - SY * SP * CR;
  Result.W := CY * CP * CR + SY * SP * SR;
end;

class function TQuat.FromTo(const AFrom, ATo: TVec3): TQuat;
var
  A, B, Axis: TVec3;
  D: Single;
begin
  A := AFrom.Normalized;
  B := ATo.Normalized;
  D := A.Dot(B);

  if D >= 1.0 - EPSILON then
    Exit(TQuat.Identity);

  if D <= -1.0 + EPSILON then
  begin

    Axis := TVec3.UnitX.Cross(A);
    if Axis.LengthSq < EPSILON_SQR then
      Axis := TVec3.UnitY.Cross(A);
    Exit(TQuat.FromAxisAngle(Axis.Normalized, PI_F));
  end;

  Axis := A.Cross(B);
  Result.X := Axis.X;
  Result.Y := Axis.Y;
  Result.Z := Axis.Z;
  Result.W := 1.0 + D;
  Result.Normalize;
end;

class operator TQuat.Multiply(const A, B: TQuat): TQuat;
begin
  Result.W := A.W * B.W - A.X * B.X - A.Y * B.Y - A.Z * B.Z;
  Result.X := A.W * B.X + A.X * B.W + A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.W * B.Y - A.X * B.Z + A.Y * B.W + A.Z * B.X;
  Result.Z := A.W * B.Z + A.X * B.Y - A.Y * B.X + A.Z * B.W;
end;

class operator TQuat.Multiply(const Q: TQuat; const V: TVec3): TVec3;
begin
  Result := Q.Rotate(V);
end;

function TQuat.LengthSq: Single;
begin
  Result := X * X + Y * Y + Z * Z + W * W;
end;

function TQuat.Length: Single;
begin
  Result := Sqrt(LengthSq);
end;

function TQuat.Normalized: TQuat;
var
  LenSq, Inv: Single;
begin
  LenSq := LengthSq;
  if LenSq <= EPSILON_SQR then
    Exit(TQuat.Identity);
  Inv := 1.0 / Sqrt(LenSq);
  Result.X := X * Inv;
  Result.Y := Y * Inv;
  Result.Z := Z * Inv;
  Result.W := W * Inv;
end;

procedure TQuat.Normalize;
begin
  Self := Normalized;
end;

function TQuat.Conjugate: TQuat;
begin
  Result.X := -X;
  Result.Y := -Y;
  Result.Z := -Z;
  Result.W := W;
end;

function TQuat.Inverse: TQuat;
var
  LenSq, Inv: Single;
begin
  LenSq := LengthSq;
  if LenSq <= EPSILON_SQR then
    Exit(TQuat.Identity);
  Inv := 1.0 / LenSq;
  Result.X := -X * Inv;
  Result.Y := -Y * Inv;
  Result.Z := -Z * Inv;
  Result.W :=  W * Inv;
end;

function TQuat.Dot(const B: TQuat): Single;
begin
  Result := X * B.X + Y * B.Y + Z * B.Z + W * B.W;
end;

function TQuat.Rotate(const V: TVec3): TVec3;
var
  U, T: TVec3;
begin

  U := Vec3(X, Y, Z);
  T := U.Cross(V) + V * W;
  Result := V + U.Cross(T) * 2.0;
end;

function TQuat.Slerp(const B: TQuat; const T: Single): TQuat;
var
  CosOm, Scale0, Scale1, Om, SinOm, InvSin: Single;
  Target: TQuat;
begin
  CosOm := Dot(B);
  Target := B;

  if CosOm < 0.0 then
  begin
    CosOm := -CosOm;
    Target.X := -Target.X;
    Target.Y := -Target.Y;
    Target.Z := -Target.Z;
    Target.W := -Target.W;
  end;

  if CosOm > 1.0 - EPSILON then
  begin

    Scale0 := 1.0 - T;
    Scale1 := T;
  end
  else
  begin
    Om := ArcCos(CosOm);
    SinOm := Sin(Om);
    InvSin := 1.0 / SinOm;
    Scale0 := Sin((1.0 - T) * Om) * InvSin;
    Scale1 := Sin(T * Om) * InvSin;
  end;

  Result.X := Scale0 * X + Scale1 * Target.X;
  Result.Y := Scale0 * Y + Scale1 * Target.Y;
  Result.Z := Scale0 * Z + Scale1 * Target.Z;
  Result.W := Scale0 * W + Scale1 * Target.W;
  Result.Normalize;
end;

function TQuat.Equals(const B: TQuat; const Tol: Single): Boolean;
begin
  Result := NearlyEqual(X, B.X, Tol) and NearlyEqual(Y, B.Y, Tol) and
            NearlyEqual(Z, B.Z, Tol) and NearlyEqual(W, B.W, Tol);
end;

class function TMat4.Identity: TMat4;
begin
  FillChar(Result.M, SizeOf(Result.M), 0);
  Result.M[0]  := 1.0;
  Result.M[5]  := 1.0;
  Result.M[10] := 1.0;
  Result.M[15] := 1.0;
end;

class function TMat4.Translation(const T: TVec3): TMat4;
begin
  Result := TMat4.Identity;
  Result.M[12] := T.X;
  Result.M[13] := T.Y;
  Result.M[14] := T.Z;
end;

class function TMat4.Scaling(const S: TVec3): TMat4;
begin
  FillChar(Result.M, SizeOf(Result.M), 0);
  Result.M[0]  := S.X;
  Result.M[5]  := S.Y;
  Result.M[10] := S.Z;
  Result.M[15] := 1.0;
end;

class function TMat4.Scaling(const S: Single): TMat4;
begin
  Result := TMat4.Scaling(Vec3(S, S, S));
end;

class function TMat4.RotationX(const Radians: Single): TMat4;
var
  S, C: Single;
begin
  SinCos(Radians, S, C);
  Result := TMat4.Identity;
  Result.M[5]  :=  C;
  Result.M[6]  :=  S;
  Result.M[9]  := -S;
  Result.M[10] :=  C;
end;

class function TMat4.RotationY(const Radians: Single): TMat4;
var
  S, C: Single;
begin
  SinCos(Radians, S, C);
  Result := TMat4.Identity;
  Result.M[0]  :=  C;
  Result.M[2]  := -S;
  Result.M[8]  :=  S;
  Result.M[10] :=  C;
end;

class function TMat4.RotationZ(const Radians: Single): TMat4;
var
  S, C: Single;
begin
  SinCos(Radians, S, C);
  Result := TMat4.Identity;
  Result.M[0] :=  C;
  Result.M[1] :=  S;
  Result.M[4] := -S;
  Result.M[5] :=  C;
end;

class function TMat4.RotationQuat(const Q: TQuat): TMat4;
var
  N: TQuat;
  XX, YY, ZZ, XY, XZ, YZ, WX, WY, WZ: Single;
begin
  N := Q.Normalized;
  XX := N.X * N.X;  YY := N.Y * N.Y;  ZZ := N.Z * N.Z;
  XY := N.X * N.Y;  XZ := N.X * N.Z;  YZ := N.Y * N.Z;
  WX := N.W * N.X;  WY := N.W * N.Y;  WZ := N.W * N.Z;

  Result.M[0]  := 1.0 - 2.0 * (YY + ZZ);
  Result.M[1]  :=       2.0 * (XY + WZ);
  Result.M[2]  :=       2.0 * (XZ - WY);
  Result.M[3]  := 0.0;

  Result.M[4]  :=       2.0 * (XY - WZ);
  Result.M[5]  := 1.0 - 2.0 * (XX + ZZ);
  Result.M[6]  :=       2.0 * (YZ + WX);
  Result.M[7]  := 0.0;

  Result.M[8]  :=       2.0 * (XZ + WY);
  Result.M[9]  :=       2.0 * (YZ - WX);
  Result.M[10] := 1.0 - 2.0 * (XX + YY);
  Result.M[11] := 0.0;

  Result.M[12] := 0.0;
  Result.M[13] := 0.0;
  Result.M[14] := 0.0;
  Result.M[15] := 1.0;
end;

class function TMat4.TRS(const T: TVec3; const R: TQuat; const S: TVec3): TMat4;
begin

  Result := TMat4.RotationQuat(R);
  Result.M[0]  := Result.M[0]  * S.X;
  Result.M[1]  := Result.M[1]  * S.X;
  Result.M[2]  := Result.M[2]  * S.X;
  Result.M[4]  := Result.M[4]  * S.Y;
  Result.M[5]  := Result.M[5]  * S.Y;
  Result.M[6]  := Result.M[6]  * S.Y;
  Result.M[8]  := Result.M[8]  * S.Z;
  Result.M[9]  := Result.M[9]  * S.Z;
  Result.M[10] := Result.M[10] * S.Z;
  Result.M[12] := T.X;
  Result.M[13] := T.Y;
  Result.M[14] := T.Z;
end;

class function TMat4.Ortho(const L, R, B, T, ZNear, ZFar: Single): TMat4;
begin
  FillChar(Result.M, SizeOf(Result.M), 0);
  Result.M[0]  :=  2.0 / (R - L);
  Result.M[5]  :=  2.0 / (T - B);
  Result.M[10] := -2.0 / (ZFar - ZNear);
  Result.M[12] := -(R + L) / (R - L);
  Result.M[13] := -(T + B) / (T - B);
  Result.M[14] := -(ZFar + ZNear) / (ZFar - ZNear);
  Result.M[15] :=  1.0;
end;

class function TMat4.Ortho2D(const Width, Height: Single): TMat4;
begin
  Result := TMat4.Ortho(0.0, Width, 0.0, Height, -1.0, 1.0);
end;

class function TMat4.Perspective(const FovY, Aspect, ZNear, ZFar: Single): TMat4;
var
  F: Single;
begin
  FillChar(Result.M, SizeOf(Result.M), 0);
  F := 1.0 / Tan(FovY * 0.5);
  Result.M[0]  := F / Aspect;
  Result.M[5]  := F;
  Result.M[10] := (ZFar + ZNear) / (ZNear - ZFar);
  Result.M[11] := -1.0;
  Result.M[14] := (2.0 * ZFar * ZNear) / (ZNear - ZFar);
  Result.M[15] := 0.0;
end;

class function TMat4.LookAt(const Eye, Target, UpDir: TVec3): TMat4;
var
  XAxis, YAxis, ZAxis: TVec3;
begin
  ZAxis := (Eye - Target).Normalized;
  XAxis := UpDir.Cross(ZAxis).Normalized;
  YAxis := ZAxis.Cross(XAxis);

  Result.M[0]  := XAxis.X;
  Result.M[1]  := YAxis.X;
  Result.M[2]  := ZAxis.X;
  Result.M[3]  := 0.0;

  Result.M[4]  := XAxis.Y;
  Result.M[5]  := YAxis.Y;
  Result.M[6]  := ZAxis.Y;
  Result.M[7]  := 0.0;

  Result.M[8]  := XAxis.Z;
  Result.M[9]  := YAxis.Z;
  Result.M[10] := ZAxis.Z;
  Result.M[11] := 0.0;

  Result.M[12] := -XAxis.Dot(Eye);
  Result.M[13] := -YAxis.Dot(Eye);
  Result.M[14] := -ZAxis.Dot(Eye);
  Result.M[15] := 1.0;
end;

class operator TMat4.Multiply(const A, B: TMat4): TMat4;
var
  Col, Row: Integer;
  Sum: Single;
begin
  for Col := 0 to 3 do
    for Row := 0 to 3 do
    begin
      Sum := A.M[0 * 4 + Row] * B.M[Col * 4 + 0] +
             A.M[1 * 4 + Row] * B.M[Col * 4 + 1] +
             A.M[2 * 4 + Row] * B.M[Col * 4 + 2] +
             A.M[3 * 4 + Row] * B.M[Col * 4 + 3];
      Result.M[Col * 4 + Row] := Sum;
    end;
end;

class operator TMat4.Multiply(const A: TMat4; const V: TVec4): TVec4;
begin
  Result.X := A.M[0] * V.X + A.M[4] * V.Y + A.M[8]  * V.Z + A.M[12] * V.W;
  Result.Y := A.M[1] * V.X + A.M[5] * V.Y + A.M[9]  * V.Z + A.M[13] * V.W;
  Result.Z := A.M[2] * V.X + A.M[6] * V.Y + A.M[10] * V.Z + A.M[14] * V.W;
  Result.W := A.M[3] * V.X + A.M[7] * V.Y + A.M[11] * V.Z + A.M[15] * V.W;
end;

class operator TMat4.Equal(const A, B: TMat4): Boolean;
var
  I: Integer;
begin
  for I := 0 to 15 do
    if A.M[I] <> B.M[I] then
      Exit(False);
  Result := True;
end;

class operator TMat4.NotEqual(const A, B: TMat4): Boolean;
begin
  Result := not (A = B);
end;

function TMat4.Get(const Row, Col: Integer): Single;
begin
  Result := M[Col * 4 + Row];
end;

procedure TMat4.SetValue(const Row, Col: Integer; const Value: Single);
begin
  M[Col * 4 + Row] := Value;
end;

function TMat4.TransformPoint(const V: TVec3): TVec3;
var
  W: Single;
begin
  Result.X := M[0] * V.X + M[4] * V.Y + M[8]  * V.Z + M[12];
  Result.Y := M[1] * V.X + M[5] * V.Y + M[9]  * V.Z + M[13];
  Result.Z := M[2] * V.X + M[6] * V.Y + M[10] * V.Z + M[14];
  W        := M[3] * V.X + M[7] * V.Y + M[11] * V.Z + M[15];
  if (W <> 1.0) and (Abs(W) > EPSILON) then
    Result := Result / W;
end;

function TMat4.TransformDirection(const V: TVec3): TVec3;
begin
  Result.X := M[0] * V.X + M[4] * V.Y + M[8]  * V.Z;
  Result.Y := M[1] * V.X + M[5] * V.Y + M[9]  * V.Z;
  Result.Z := M[2] * V.X + M[6] * V.Y + M[10] * V.Z;
end;

function TMat4.Transposed: TMat4;
var
  Row, Col: Integer;
begin
  for Col := 0 to 3 do
    for Row := 0 to 3 do
      Result.M[Col * 4 + Row] := M[Row * 4 + Col];
end;

function TMat4.Determinant: Single;
var
  C0, C4, C8, C12: Single;
begin

  C0 := M[5]  * M[10] * M[15] - M[5]  * M[11] * M[14] -
        M[9]  * M[6]  * M[15] + M[9]  * M[7]  * M[14] +
        M[13] * M[6]  * M[11] - M[13] * M[7]  * M[10];

  C4 := -M[4] * M[10] * M[15] + M[4]  * M[11] * M[14] +
        M[8]  * M[6]  * M[15] - M[8]  * M[7]  * M[14] -
        M[12] * M[6]  * M[11] + M[12] * M[7]  * M[10];

  C8 := M[4]  * M[9]  * M[15] - M[4]  * M[11] * M[13] -
        M[8]  * M[5]  * M[15] + M[8]  * M[7]  * M[13] +
        M[12] * M[5]  * M[11] - M[12] * M[7]  * M[9];

  C12 := -M[4] * M[9] * M[14] + M[4]  * M[10] * M[13] +
         M[8]  * M[5] * M[14] - M[8]  * M[6]  * M[13] -
         M[12] * M[5] * M[10] + M[12] * M[6]  * M[9];

  Result := M[0] * C0 + M[1] * C4 + M[2] * C8 + M[3] * C12;
end;

function TMat4.TryInverse(out Dest: TMat4): Boolean;
var
  Inv: TMat4;
  Det, InvDet: Single;
  I: Integer;
begin
  Inv.M[0] := M[5]  * M[10] * M[15] - M[5]  * M[11] * M[14] -
              M[9]  * M[6]  * M[15] + M[9]  * M[7]  * M[14] +
              M[13] * M[6]  * M[11] - M[13] * M[7]  * M[10];

  Inv.M[4] := -M[4] * M[10] * M[15] + M[4]  * M[11] * M[14] +
              M[8]  * M[6]  * M[15] - M[8]  * M[7]  * M[14] -
              M[12] * M[6]  * M[11] + M[12] * M[7]  * M[10];

  Inv.M[8] := M[4]  * M[9]  * M[15] - M[4]  * M[11] * M[13] -
              M[8]  * M[5]  * M[15] + M[8]  * M[7]  * M[13] +
              M[12] * M[5]  * M[11] - M[12] * M[7]  * M[9];

  Inv.M[12] := -M[4] * M[9] * M[14] + M[4]  * M[10] * M[13] +
               M[8]  * M[5] * M[14] - M[8]  * M[6]  * M[13] -
               M[12] * M[5] * M[10] + M[12] * M[6]  * M[9];

  Inv.M[1] := -M[1] * M[10] * M[15] + M[1]  * M[11] * M[14] +
              M[9]  * M[2]  * M[15] - M[9]  * M[3]  * M[14] -
              M[13] * M[2]  * M[11] + M[13] * M[3]  * M[10];

  Inv.M[5] := M[0]  * M[10] * M[15] - M[0]  * M[11] * M[14] -
              M[8]  * M[2]  * M[15] + M[8]  * M[3]  * M[14] +
              M[12] * M[2]  * M[11] - M[12] * M[3]  * M[10];

  Inv.M[9] := -M[0] * M[9]  * M[15] + M[0]  * M[11] * M[13] +
              M[8]  * M[1]  * M[15] - M[8]  * M[3]  * M[13] -
              M[12] * M[1]  * M[11] + M[12] * M[3]  * M[9];

  Inv.M[13] := M[0] * M[9]  * M[14] - M[0]  * M[10] * M[13] -
               M[8] * M[1]  * M[14] + M[8]  * M[2]  * M[13] +
               M[12] * M[1] * M[10] - M[12] * M[2]  * M[9];

  Inv.M[2] := M[1]  * M[6]  * M[15] - M[1]  * M[7]  * M[14] -
              M[5]  * M[2]  * M[15] + M[5]  * M[3]  * M[14] +
              M[13] * M[2]  * M[7]  - M[13] * M[3]  * M[6];

  Inv.M[6] := -M[0] * M[6]  * M[15] + M[0]  * M[7]  * M[14] +
              M[4]  * M[2]  * M[15] - M[4]  * M[3]  * M[14] -
              M[12] * M[2]  * M[7]  + M[12] * M[3]  * M[6];

  Inv.M[10] := M[0] * M[5]  * M[15] - M[0]  * M[7]  * M[13] -
               M[4] * M[1]  * M[15] + M[4]  * M[3]  * M[13] +
               M[12] * M[1] * M[7]  - M[12] * M[3]  * M[5];

  Inv.M[14] := -M[0] * M[5] * M[14] + M[0]  * M[6]  * M[13] +
               M[4]  * M[1] * M[14] - M[4]  * M[2]  * M[13] -
               M[12] * M[1] * M[6]  + M[12] * M[2]  * M[5];

  Inv.M[3] := -M[1] * M[6]  * M[11] + M[1]  * M[7]  * M[10] +
              M[5]  * M[2]  * M[11] - M[5]  * M[3]  * M[10] -
              M[9]  * M[2]  * M[7]  + M[9]  * M[3]  * M[6];

  Inv.M[7] := M[0]  * M[6]  * M[11] - M[0]  * M[7]  * M[10] -
              M[4]  * M[2]  * M[11] + M[4]  * M[3]  * M[10] +
              M[8]  * M[2]  * M[7]  - M[8]  * M[3]  * M[6];

  Inv.M[11] := -M[0] * M[5] * M[11] + M[0]  * M[7]  * M[9] +
               M[4]  * M[1] * M[11] - M[4]  * M[3]  * M[9] -
               M[8]  * M[1] * M[7]  + M[8]  * M[3]  * M[5];

  Inv.M[15] := M[0] * M[5]  * M[10] - M[0]  * M[6]  * M[9] -
               M[4] * M[1]  * M[10] + M[4]  * M[2]  * M[9] +
               M[8] * M[1]  * M[6]  - M[8]  * M[2]  * M[5];

  Det := M[0] * Inv.M[0] + M[1] * Inv.M[4] + M[2] * Inv.M[8] + M[3] * Inv.M[12];
  if Abs(Det) <= EPSILON then
    Exit(False);

  InvDet := 1.0 / Det;
  for I := 0 to 15 do
    Dest.M[I] := Inv.M[I] * InvDet;
  Result := True;
end;

function TMat4.Inverse: TMat4;
begin
  if not TryInverse(Result) then
    Result := TMat4.Identity;
end;

function TMat4.Equals(const B: TMat4; const Tol: Single): Boolean;
var
  I: Integer;
begin
  for I := 0 to 15 do
    if not NearlyEqual(M[I], B.M[I], Tol) then
      Exit(False);
  Result := True;
end;

function TMat4.Ptr: PSingle;
begin
  Result := @M[0];
end;

constructor TRect2.Create(const AX, AY, AW, AH: Single);
begin
  X := AX; Y := AY; W := AW; H := AH;
end;

class function TRect2.FromMinMax(const Min, Max: TVec2): TRect2;
begin
  Result.X := Min.X;
  Result.Y := Min.Y;
  Result.W := Max.X - Min.X;
  Result.H := Max.Y - Min.Y;
end;

class function TRect2.FromCenter(const Center, HalfSize: TVec2): TRect2;
begin
  Result.X := Center.X - HalfSize.X;
  Result.Y := Center.Y - HalfSize.Y;
  Result.W := HalfSize.X * 2.0;
  Result.H := HalfSize.Y * 2.0;
end;

function TRect2.Min: TVec2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function TRect2.Max: TVec2;
begin
  Result.X := X + W;
  Result.Y := Y + H;
end;

function TRect2.Center: TVec2;
begin
  Result.X := X + W * 0.5;
  Result.Y := Y + H * 0.5;
end;

function TRect2.Size: TVec2;
begin
  Result.X := W;
  Result.Y := H;
end;

function TRect2.Contains(const P: TVec2): Boolean;
begin
  Result := (P.X >= X) and (P.X <= X + W) and (P.Y >= Y) and (P.Y <= Y + H);
end;

function TRect2.Intersects(const B: TRect2): Boolean;
begin
  Result := (X < B.X + B.W) and (X + W > B.X) and
            (Y < B.Y + B.H) and (Y + H > B.Y);
end;

function TRect2.Union(const B: TRect2): TRect2;
var
  MinX, MinY, MaxX, MaxY: Single;
begin
  if X < B.X then MinX := X else MinX := B.X;
  if Y < B.Y then MinY := Y else MinY := B.Y;
  if X + W > B.X + B.W then MaxX := X + W else MaxX := B.X + B.W;
  if Y + H > B.Y + B.H then MaxY := Y + H else MaxY := B.Y + B.H;
  Result.X := MinX;
  Result.Y := MinY;
  Result.W := MaxX - MinX;
  Result.H := MaxY - MinY;
end;

function TRect2.Expanded(const Amount: Single): TRect2;
begin
  Result.X := X - Amount;
  Result.Y := Y - Amount;
  Result.W := W + Amount * 2.0;
  Result.H := H + Amount * 2.0;
end;

end.
