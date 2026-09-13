

unit Engine.Core.Loop.Test;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

function RunAllLoopTests: Boolean;

implementation

uses
  Engine.Core.Loop;

var
  GPassed: Integer;
  GFailed: Integer;
  GSection: string;

function FStr(const V: Double): string;
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

procedure CheckI(const A, B: Integer; const What: string);
var
  SA, SB: string;
begin
  Str(A, SA);
  Str(B, SB);
  Check(A = B, What + '  (got ' + SA + ', want ' + SB + ')');
end;

procedure CheckF(const A, B: Double; const What: string; const Tol: Double = 1.0E-4);
begin
  Check(Abs(A - B) <= Tol, What + '  (got ' + FStr(A) + ', want ' + FStr(B) + ')');
end;

procedure TestBasico;
var
  S: TFixedStep;
begin
  Section('passo fixo basico');
  S.Init(1.0 / 60.0);

  CheckF(S.StepsPerSecond, 60, 'StepsPerSecond');
  CheckI(S.Advance(0.0), 0, 'delta zero nao roda passo');
  CheckF(S.Alpha, 0, 'alpha zero no inicio');

  S.Init(1.0 / 60.0);
  CheckI(S.Advance(1.0 / 60.0), 1, 'delta igual ao passo roda exatamente 1');
  CheckF(S.Alpha, 0, 'alpha volta a zero apos consumir o passo inteiro');

  S.Init(1.0 / 60.0);
  CheckI(S.Advance(1.0 / 120.0), 0, 'meio passo nao roda nada');
  CheckF(S.Alpha, 0.5, 'meio passo deixa alpha em 0.5');
  CheckI(S.Advance(1.0 / 120.0), 1, 'a outra metade completa o passo');

  S.Init(1.0 / 60.0);
  CheckI(S.Advance(3.5 / 60.0), 3, 'tres passos e meio rodam 3');
  CheckF(S.Alpha, 0.5, 'e sobram 0.5 no alpha');
end;

procedure TestAcumulacao;
var
  S: TFixedStep;
  I, Total: Integer;
begin
  Section('acumulacao');

  S.Init(1.0 / 60.0);
  Total := 0;
  for I := 1 to 120 do
    Inc(Total, S.Advance(1.0 / 120.0));
  CheckI(Total, 60, '1s de tempo real a 120fps da 60 passos de 60Hz');
  CheckF(S.SimTime, 1.0, 'SimTime bate com 1 segundo', 1.0E-3);
  Check(S.TotalFrames = 120, 'TotalFrames conta os frames');
  Check(S.TotalSteps = 60, 'TotalSteps conta os passos');

  S.Init(1.0 / 60.0);
  for I := 1 to 100 do
    S.Advance(0.0071);
  CheckF(S.TotalSteps * S.FixedDelta + S.Accumulator, 0.71,
    'nada de tempo se perde quando nao ha starvation', 1.0E-3);
end;

procedure TestProtecoes;
var
  S: TFixedStep;
  N: Integer;
begin
  Section('protecoes');

  S.Init(1.0 / 60.0, 5, 0.25);
  N := S.Advance(10.0);
  Check(S.Clamped, 'delta de 10s e marcado como Clamped');
  Check(N <= 5, 'delta gigante nao dispara mais que MaxSteps passos');
  Check(S.Starved, 'e o frame e marcado como Starved');
  CheckF(S.Accumulator, 0, 'acumulador e zerado apos starvation');

  N := S.Advance(1.0 / 60.0);
  CheckI(N, 1, 'o frame seguinte volta ao normal (sem spiral of death)');

  S.Init(1.0 / 60.0);
  CheckI(S.Advance(-5.0), 0, 'delta negativo nao roda passo');
  CheckF(S.Accumulator, 0, 'delta negativo nao deixa acumulador negativo');

  S.Init(1.0 / 60.0);
  S.Advance(10.0);
  Check((S.Alpha >= 0.0) and (S.Alpha <= 1.0), 'alpha fica em 0..1 mesmo com starvation');

  S.Init(1.0 / 60.0, 1);
  CheckI(S.Advance(1.0), 1, 'MaxSteps=1 limita a um passo');

  S.Init(0.0, 0);
  Check(S.FixedDelta > 0, 'FixedDelta zero vira padrao');
  Check(S.MaxSteps >= 1, 'MaxSteps zero vira 1');
end;

procedure TestDeterminismo;
var
  A, B: TFixedStep;
  I: Integer;
  Seed: Cardinal;
  Dt: Single;
begin
  Section('determinismo');

  A.Init(1.0 / 60.0);
  B.Init(1.0 / 60.0);
  Seed := 12345;
  for I := 1 to 2000 do
  begin
    Seed := Seed * 1103515245 + 12345;
    Dt := 0.004 + (Seed shr 16 and $FF) / 255.0 * 0.020;
    A.Advance(Dt);
    B.Advance(Dt);
  end;
  Check(A.TotalSteps = B.TotalSteps, 'mesma sequencia de deltas = mesmos passos');
  CheckF(A.SimTime, B.SimTime, 'e mesmo tempo de simulacao');

  A.Init(1.0 / 60.0);
  for I := 1 to 600 do
  begin
    if I mod 7 = 0 then
      A.Advance(0.050)
    else
      A.Advance(0.010);
  end;

  Check((A.TotalSteps >= 560) and (A.TotalSteps <= 572),
    'frame irregular nao faz a simulacao derivar');
end;

procedure TestReset;
var
  S: TFixedStep;
begin
  Section('reset');
  S.Init(1.0 / 60.0);
  S.Advance(0.008);
  Check(S.Accumulator > 0, 'sobra acumulada antes do reset');
  S.Reset;
  CheckF(S.Accumulator, 0, 'Reset zera o acumulador');
  CheckF(S.Alpha, 0, 'Reset zera o alpha');
  CheckF(S.FixedDelta, 1.0 / 60.0, 'Reset preserva a configuracao');
end;

procedure TestFrameCounter;
var
  F: TFrameCounter;
  I: Integer;
  Fired: Boolean;
begin
  Section('TFrameCounter');
  F.Init(0.5);
  Fired := False;
  for I := 1 to 30 do
    if F.Tick(1.0 / 60.0) then
      Fired := True;
  Check(Fired, 'dispara ao completar o intervalo');
  CheckF(F.FPS, 60, 'mede 60 fps', 0.5);
  CheckF(F.FrameMS, 1000.0 / 60.0, 'mede o tempo de frame em ms', 0.1);

  F.Init(0.5);
  for I := 1 to 29 do
    F.Tick(1.0 / 60.0);
  Check(F.FPS = 0, 'antes de fechar a janela nao publica valor');
end;

function RunAllLoopTests: Boolean;
begin
  GPassed := 0;
  GFailed := 0;

  WriteLn('=== Engine.Core.Loop - testes ===');
  TestBasico;
  TestAcumulacao;
  TestProtecoes;
  TestDeterminismo;
  TestReset;
  TestFrameCounter;

  WriteLn;
  WriteLn('passou: ', GPassed, '   falhou: ', GFailed);
  Result := GFailed = 0;
  if Result then
    WriteLn('OK')
  else
    WriteLn('FALHAS ACIMA');
end;

end.
