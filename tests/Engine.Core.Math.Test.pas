

unit Engine.Core.Math.Test;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

function RunAllMathTests: Boolean;

implementation

uses
  Engine.Core.Math;

var
  GPassed: Integer;
  GFailed: Integer;
  GSection: string;

function FStr(const V: Single): string;
begin
  Str(V: 0: 6, Result);
end;

procedure Section(const Name: string);
begin
  GSection := Name;
end;

procedure Check(const Condition: Boolean; const What: string);
begin
  if Condition then
    Inc(GPassed)
  else
  begin
    Inc(GFailed);
    WriteLn('  FALHOU  [', GSection, '] ', What);
  end;
end;

procedure CheckF(const A, B: Single; const What: string; const Tol: Single = 1.0E-4);
begin
  Check(Abs(A - B) <= Tol, What + '  (got ' + FStr(A) + ', want ' +
    FStr(B) + ')');
end;

procedure CheckV2(const A, B: TVec2; const What: string; const Tol: Single = 1.0E-4);
begin
  Check(A.Equals(B, Tol), What + '  (got ' + FStr(A.X) + ',' +
    FStr(A.Y) + ' want ' + FStr(B.X) + ',' + FStr(B.Y) + ')');
end;

procedure CheckV3(const A, B: TVec3; const What: string; const Tol: Single = 1.0E-4);
begin
  Check(A.Equals(B, Tol), What + '  (got ' + FStr(A.X) + ',' +
    FStr(A.Y) + ',' + FStr(A.Z) + ' want ' + FStr(B.X) +
    ',' + FStr(B.Y) + ',' + FStr(B.Z) + ')');
end;

procedure TestScalars;
begin
  Section('escalares');
  CheckF(Clamp(5, 0, 1), 1, 'Clamp topo');
  CheckF(Clamp(-5, 0, 1), 0, 'Clamp base');
  CheckF(Saturate(0.5), 0.5, 'Saturate passa');
  CheckF(Lerp(0, 10, 0.25), 2.5, 'Lerp');
  CheckF(InvLerp(0, 10, 2.5), 0.25, 'InvLerp');
  CheckF(InvLerp(3, 3, 9), 0, 'InvLerp degenerado nao explode');
  CheckF(Remap(5, 0, 10, 100, 200), 150, 'Remap');
  CheckF(SmoothStep(0, 1, 0.5), 0.5, 'SmoothStep meio');
  CheckF(SmoothStep(0, 1, -5), 0, 'SmoothStep clampa');
  CheckF(MoveTowards(0, 10, 3), 3, 'MoveTowards passo');
  CheckF(MoveTowards(0, 1, 5), 1, 'MoveTowards nao ultrapassa');
  CheckF(SignF(-3), -1, 'SignF negativo');
  CheckF(SignF(0), 0, 'SignF zero');
  CheckF(Wrap(-1, 360), 359, 'Wrap negativo');
  CheckF(Wrap(370, 360), 10, 'Wrap acima');
  CheckF(DeltaAngle(0.1, TAU_F - 0.1), -0.2, 'DeltaAngle pega o caminho curto');
  CheckF(Deg2RadF(180), PI_F, 'Deg2Rad');
  CheckF(Rad2DegF(PI_F), 180, 'Rad2Deg');
end;

procedure TestVec2;
var
  A, B: TVec2;
begin
  Section('TVec2');
  A := Vec2(3, 4);
  CheckF(A.Length, 5, 'Length 3-4-5');
  CheckF(A.LengthSq, 25, 'LengthSq');
  CheckF(A.Normalized.Length, 1, 'Normalized vira unitario');
  CheckV2(TVec2.Zero.Normalized, TVec2.Zero, 'Normalized de zero nao gera NaN');
  CheckV2(A / 0, TVec2.Zero, 'Divisao por zero nao gera Inf');

  B := Vec2(1, 2);
  CheckV2(A + B, Vec2(4, 6), 'Add');
  CheckV2(A - B, Vec2(2, 2), 'Subtract');
  CheckV2(A * 2, Vec2(6, 8), 'Multiply escalar a direita');
  CheckV2(2 * A, Vec2(6, 8), 'Multiply escalar a esquerda');
  CheckV2(A * B, Vec2(3, 8), 'Multiply componente a componente');
  CheckV2(-A, Vec2(-3, -4), 'Negative');
  Check(A = Vec2(3, 4), 'Equal');
  Check(A <> B, 'NotEqual');

  CheckF(TVec2.UnitX.Dot(TVec2.UnitY), 0, 'Dot de perpendiculares');
  CheckF(TVec2.UnitX.Cross(TVec2.UnitY), 1, 'Cross 2D anti-horario positivo');
  CheckV2(TVec2.UnitX.Perp, TVec2.UnitY, 'Perp gira 90 anti-horario');
  CheckV2(TVec2.UnitX.Rotate(HALF_PI_F), TVec2.UnitY, 'Rotate 90 graus');
  CheckF(Vec2(1, 1).Angle, PI_F / 4, 'Angle diagonal');
  CheckF(Distance2(Vec2(0, 0), Vec2(3, 4)), 5, 'Distance2');
  CheckV2(Lerp2(Vec2(0, 0), Vec2(10, 20), 0.5), Vec2(5, 10), 'Lerp2');
end;

procedure TestVec3;
var
  A, B: TVec3;
begin
  Section('TVec3');
  A := Vec3(1, 2, 3);
  B := Vec3(4, 5, 6);

  CheckF(Vec3(0, 3, 4).Length, 5, 'Length');
  CheckF(A.Dot(B), 32, 'Dot');
  CheckV3(A.Cross(B), Vec3(-3, 6, -3), 'Cross');
  CheckV3(TVec3.UnitX.Cross(TVec3.UnitY), TVec3.UnitZ, 'Cross right-handed: X x Y = Z');
  CheckV3(A + B, Vec3(5, 7, 9), 'Add');
  CheckV3(A * 2, Vec3(2, 4, 6), 'Multiply escalar');
  CheckV3(-A, Vec3(-1, -2, -3), 'Negative');
  CheckV3(TVec3.Zero.Normalized, TVec3.Zero, 'Normalized de zero seguro');
  CheckF(A.Normalized.Length, 1, 'Normalized unitario');

  CheckV3(Vec3(1, -1, 0).Reflect(TVec3.Up), Vec3(1, 1, 0), 'Reflect no chao');
  CheckV3(A.Cross(A), TVec3.Zero, 'Cross consigo mesmo e zero');
  CheckV2(A.XY, Vec2(1, 2), 'XY swizzle');
  CheckV3(TVec3.Forward, Vec3(0, 0, -1), 'Forward e -Z (right-handed)');
end;

procedure TestQuat;
var
  Q, R, S: TQuat;
  V: TVec3;
begin
  Section('TQuat');
  Q := TQuat.Identity;
  CheckV3(Q.Rotate(Vec3(1, 2, 3)), Vec3(1, 2, 3), 'Identity nao mexe no vetor');

  Q := TQuat.FromAxisAngle(TVec3.UnitZ, HALF_PI_F);
  CheckV3(Q.Rotate(TVec3.UnitX), TVec3.UnitY, 'Rot 90 em Z: X -> Y');
  CheckV3(Q.Rotate(TVec3.UnitY), -TVec3.UnitX, 'Rot 90 em Z: Y -> -X');
  CheckF(Q.Length, 1, 'FromAxisAngle ja sai normalizado');

  R := TQuat.FromAxisAngle(TVec3.UnitX, HALF_PI_F);
  CheckV3(R.Rotate(TVec3.UnitY), TVec3.UnitZ, 'Rot 90 em X: Y -> Z');

  S := R * Q;
  CheckV3(S.Rotate(TVec3.UnitX), R.Rotate(Q.Rotate(TVec3.UnitX)),
    'A*B aplica B primeiro');

  V := Vec3(0.3, -1.7, 2.2);
  CheckV3(Q.Inverse.Rotate(Q.Rotate(V)), V, 'Inverse desfaz a rotacao');
  CheckV3(Q.Conjugate.Rotate(Q.Rotate(V)), V, 'Conjugate desfaz (normalizado)');

  CheckV3(Q.Slerp(R, 0).Rotate(V), Q.Rotate(V), 'Slerp t=0 e A');
  CheckV3(Q.Slerp(R, 1).Rotate(V), R.Rotate(V), 'Slerp t=1 e B');
  CheckF(Q.Slerp(R, 0.37).Length, 1, 'Slerp devolve normalizado');

  CheckF(Q.Slerp(Q, 0.5).Length, 1, 'Slerp de iguais nao explode');

  S := TQuat.FromTo(TVec3.UnitX, TVec3.UnitY);
  CheckV3(S.Rotate(TVec3.UnitX), TVec3.UnitY, 'FromTo leva um no outro');
  S := TQuat.FromTo(TVec3.UnitX, -TVec3.UnitX);
  CheckV3(S.Rotate(TVec3.UnitX), -TVec3.UnitX, 'FromTo com vetores opostos');

  Q := TQuat.FromEuler(0, HALF_PI_F, 0);
  CheckV3(Q.Rotate(TVec3.UnitZ), TVec3.UnitX, 'Yaw 90: Z -> X');
end;

procedure TestMat4;
var
  I, T, Rot, Sc, M, Inv: TMat4;
  Q: TQuat;
  V, P: TVec3;
  V4: TVec4;
  Clip: TVec4;
begin
  Section('TMat4 basico');
  I := TMat4.Identity;
  CheckV3(I.TransformPoint(Vec3(1, 2, 3)), Vec3(1, 2, 3), 'Identity nao altera ponto');
  Check((I * I).Equals(I), 'Identity * Identity = Identity');
  CheckF(I.Determinant, 1, 'Det(Identity) = 1');

  T := TMat4.Translation(Vec3(5, 6, 7));
  CheckF(T.M[12], 5, 'Translacao em M[12] (column-major)');
  CheckF(T.M[13], 6, 'Translacao em M[13]');
  CheckF(T.M[14], 7, 'Translacao em M[14]');
  CheckV3(T.TransformPoint(TVec3.Zero), Vec3(5, 6, 7), 'TransformPoint translada');
  CheckV3(T.TransformDirection(TVec3.UnitX), TVec3.UnitX,
    'TransformDirection ignora translacao');

  Section('TMat4 rotacao');
  Rot := TMat4.RotationZ(HALF_PI_F);
  CheckV3(Rot.TransformPoint(TVec3.UnitX), TVec3.UnitY, 'RotationZ 90: X -> Y');
  Rot := TMat4.RotationX(HALF_PI_F);
  CheckV3(Rot.TransformPoint(TVec3.UnitY), TVec3.UnitZ, 'RotationX 90: Y -> Z');
  Rot := TMat4.RotationY(HALF_PI_F);
  CheckV3(Rot.TransformPoint(TVec3.UnitZ), TVec3.UnitX, 'RotationY 90: Z -> X');

  Q := TQuat.FromAxisAngle(TVec3.UnitZ, 0.7);
  Check(TMat4.RotationQuat(Q).Equals(TMat4.RotationZ(0.7), 1.0E-4),
    'RotationQuat == RotationZ para o mesmo angulo');
  V := Vec3(1.3, -0.4, 2.0);
  CheckV3(TMat4.RotationQuat(Q).TransformPoint(V), Q.Rotate(V),
    'Matriz de quat e rotacao de quat concordam');

  Section('TMat4 ordem de composicao');

  T := TMat4.Translation(Vec3(10, 0, 0));
  Rot := TMat4.RotationZ(HALF_PI_F);
  M := T * Rot;
  CheckV3(M.TransformPoint(TVec3.UnitX), Vec3(10, 1, 0),
    'T * R: rotaciona e depois translada');
  M := Rot * T;
  CheckV3(M.TransformPoint(TVec3.UnitX), Vec3(0, 11, 0),
    'R * T: translada e depois rotaciona');

  Section('TMat4 TRS');
  Sc := TMat4.Scaling(Vec3(2, 3, 4));
  CheckV3(Sc.TransformPoint(TVec3.One), Vec3(2, 3, 4), 'Scaling');
  Q := TQuat.FromAxisAngle(TVec3.UnitZ, 0.9);
  M := TMat4.TRS(Vec3(1, 2, 3), Q, Vec3(2, 2, 2));
  Check(M.Equals(TMat4.Translation(Vec3(1, 2, 3)) * TMat4.RotationQuat(Q) *
    TMat4.Scaling(2.0), 1.0E-4), 'TRS == T * R * S');

  Section('TMat4 inversa');
  M := TMat4.TRS(Vec3(3, -2, 8), TQuat.FromEuler(0.3, 1.1, -0.7), Vec3(2, 0.5, 3));
  Check(M.TryInverse(Inv), 'TryInverse em matriz valida');
  Check((M * Inv).Equals(TMat4.Identity, 1.0E-3), 'M * M^-1 = I');
  P := Vec3(4, -1, 0.5);
  CheckV3(Inv.TransformPoint(M.TransformPoint(P)), P, 'Inversa desfaz o transform', 1.0E-3);

  Check(not TMat4.Scaling(Vec3(1, 0, 1)).TryInverse(Inv),
    'TryInverse falha em matriz singular');

  Section('TMat4 transposta');
  M := TMat4.TRS(Vec3(1, 2, 3), TQuat.FromEuler(0.2, 0.4, 0.6), TVec3.One);
  Check(M.Transposed.Transposed.Equals(M), 'Transposta duas vezes volta');
  CheckF(M.Get(1, 3), M.Transposed.Get(3, 1), 'Get(row,col) espelha na transposta');
  CheckF(M.Get(0, 3), M.M[12], 'Get(0,3) e o M[12] (translacao X)');

  Section('TMat4 projecao');

  M := TMat4.Ortho2D(800, 600);
  V4 := M * TVec4.Create(TVec3.Zero, 1.0);
  CheckF(V4.X, -1, 'Ortho2D: x=0 vira NDC -1');
  CheckF(V4.Y, -1, 'Ortho2D: y=0 vira NDC -1');
  V4 := M * TVec4.Create(Vec3(800, 600, 0), 1.0);
  CheckF(V4.X, 1, 'Ortho2D: x=800 vira NDC +1');
  CheckF(V4.Y, 1, 'Ortho2D: y=600 vira NDC +1');

  M := TMat4.Perspective(Deg2RadF(60), 16 / 9, 0.1, 100);
  Clip := M * TVec4.Create(Vec3(0, 0, -0.1), 1.0);
  CheckF(Clip.Z / Clip.W, -1, 'Perspective: near plane -> NDC z = -1');
  Clip := M * TVec4.Create(Vec3(0, 0, -100), 1.0);
  CheckF(Clip.Z / Clip.W, 1, 'Perspective: far plane -> NDC z = +1', 1.0E-3);
  Clip := M * TVec4.Create(Vec3(0, 0, -10), 1.0);
  CheckF(Clip.W, 10, 'Perspective: w = -z (divisao de perspectiva)');

  Section('TMat4 LookAt');

  M := TMat4.LookAt(Vec3(0, 0, 5), TVec3.Zero, TVec3.Up);
  CheckV3(M.TransformPoint(TVec3.Zero), Vec3(0, 0, -5), 'LookAt: alvo fica em -Z');
  CheckV3(M.TransformPoint(Vec3(0, 0, 5)), TVec3.Zero, 'LookAt: olho vira a origem');
  CheckV3(M.TransformPoint(Vec3(1, 0, 5)), TVec3.UnitX,
    'LookAt: direita da camera e +X no view space');

  M := TMat4.LookAt(Vec3(5, 0, 0), TVec3.Zero, TVec3.Up);
  CheckV3(M.TransformPoint(TVec3.Zero), Vec3(0, 0, -5), 'LookAt lateral: alvo em -Z');
end;

procedure TestRect2;
var
  A, B: TRect2;
begin
  Section('TRect2');
  A := TRect2.Create(0, 0, 10, 10);
  B := TRect2.Create(5, 5, 10, 10);
  Check(A.Contains(Vec2(5, 5)), 'Contains dentro');
  Check(not A.Contains(Vec2(11, 5)), 'Contains fora');
  Check(A.Intersects(B), 'Intersects sobrepostos');
  Check(not A.Intersects(TRect2.Create(20, 20, 1, 1)), 'Intersects separados');
  CheckV2(A.Center, Vec2(5, 5), 'Center');
  CheckV2(A.Union(B).Size, Vec2(15, 15), 'Union');
  CheckV2(A.Expanded(1).Min, Vec2(-1, -1), 'Expanded');
  CheckV2(TRect2.FromCenter(Vec2(10, 10), Vec2(2, 3)).Min, Vec2(8, 7), 'FromCenter');
  CheckV2(TRect2.FromMinMax(Vec2(1, 2), Vec2(4, 6)).Size, Vec2(3, 4), 'FromMinMax');
end;

procedure TestLayout;
begin
  Section('layout de memoria');

  Check(SizeOf(TVec2) = 8, 'SizeOf(TVec2) = 8');
  Check(SizeOf(TVec3) = 12, 'SizeOf(TVec3) = 12');
  Check(SizeOf(TVec4) = 16, 'SizeOf(TVec4) = 16');
  Check(SizeOf(TQuat) = 16, 'SizeOf(TQuat) = 16');
  Check(SizeOf(TMat4) = 64, 'SizeOf(TMat4) = 64');
  Check(TMat4.Identity.Ptr <> nil, 'Ptr devolve endereco valido');
end;

function RunAllMathTests: Boolean;
begin
  GPassed := 0;
  GFailed := 0;

  WriteLn('=== Engine.Core.Math - testes ===');
  TestScalars;
  TestVec2;
  TestVec3;
  TestQuat;
  TestMat4;
  TestRect2;
  TestLayout;

  WriteLn;
  WriteLn('passou: ', GPassed, '   falhou: ', GFailed);
  Result := GFailed = 0;
  if Result then
    WriteLn('OK')
  else
    WriteLn('FALHAS ACIMA');
end;

end.
