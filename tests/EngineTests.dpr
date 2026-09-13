

program EngineTests;

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  Engine.Core.Math in '..\src\Core\Engine.Core.Math.pas',
  Engine.Core.Loop in '..\src\Core\Engine.Core.Loop.pas',
  Engine.Core.Log in '..\src\Core\Engine.Core.Log.pas',
  Engine.Core.Memory in '..\src\Core\Engine.Core.Memory.pas',
  Engine.Core.Math.Test in 'Engine.Core.Math.Test.pas',
  Engine.Core.Loop.Test in 'Engine.Core.Loop.Test.pas',
  Engine.Core.Memory.Test in 'Engine.Core.Memory.Test.pas',
  Engine.Core.Log.Test in 'Engine.Core.Log.Test.pas';

var
  AllOk: Boolean;

begin
  AllOk := True;

  if not RunAllMathTests then
    AllOk := False;
  WriteLn;

  if not RunAllLoopTests then
    AllOk := False;
  WriteLn;

  if not RunAllMemoryTests then
    AllOk := False;
  WriteLn;

  if not RunAllLogTests then
    AllOk := False;
  WriteLn;

  if AllOk then
    WriteLn('=== TUDO PASSOU ===')
  else
  begin
    WriteLn('=== HOUVE FALHAS ===');
    ExitCode := 1;
  end;

  WriteLn('(enter para sair)');
  ReadLn;
end.
