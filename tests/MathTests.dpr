program MathTests;

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  Engine.Core.Math in '..\src\Core\Engine.Core.Math.pas',
  Engine.Core.Math.Test in 'Engine.Core.Math.Test.pas';

begin
  if not RunAllMathTests then
    ExitCode := 1;
  WriteLn('(enter para sair)');
  ReadLn;
end.
