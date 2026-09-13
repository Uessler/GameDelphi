

unit Engine.Core.Log.Test;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

function RunAllLogTests: Boolean;

implementation

uses
  SysUtils,
  Engine.Core.Log;

var
  GPassed: Integer;
  GFailed: Integer;
  GSection: string;

  GCapturedCount: Integer;
  GLastLevel: TLogLevel;
  GLastCategory: string;
  GLastText: string;
  GLastFormatted: string;

  GCaptured2Count: Integer;

procedure CaptureSink(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);
begin
  Inc(GCapturedCount);
  GLastLevel := Level;
  GLastCategory := Category;
  GLastText := Text;
  GLastFormatted := Formatted;
end;

procedure CaptureSink2(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);
begin
  Inc(GCaptured2Count);
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
begin
  Check(A = B, What + Format('  (got %d, want %d)', [A, B]));
end;

procedure ResetCapture;
begin
  GCapturedCount := 0;
  GCaptured2Count := 0;
  GLastCategory := '';
  GLastText := '';
  GLastFormatted := '';
end;

procedure TestFiltro;
begin
  Section('nivel minimo');
  ResetCapture;

  LogSetMinLevel(llInfo);
  Check(not LogEnabled(llTrace), 'trace desligado abaixo do minimo');
  Check(not LogEnabled(llDebug), 'debug desligado abaixo do minimo');
  Check(LogEnabled(llInfo), 'info ligado no minimo');
  Check(LogEnabled(llError), 'error ligado acima do minimo');

  LogTrace('teste', 'nao deve aparecer', []);
  LogDebug('teste', 'nao deve aparecer', []);
  CheckI(GCapturedCount, 0, 'mensagem abaixo do minimo nao chega no sink');

  LogInfo('teste', 'deve aparecer', []);
  CheckI(GCapturedCount, 1, 'mensagem no nivel chega');
  Check(GLastText = 'deve aparecer', 'texto preservado');
  Check(GLastCategory = 'teste', 'categoria preservada');
  Check(GLastLevel = llInfo, 'nivel preservado');

  LogSetMinLevel(llTrace);
  ResetCapture;
  LogTrace('teste', 'agora sim', []);
  CheckI(GCapturedCount, 1, 'baixar o minimo libera o trace');

  LogSetMinLevel(llOff);
  ResetCapture;
  LogFatal('teste', 'nem fatal passa', []);
  CheckI(GCapturedCount, 0, 'llOff cala tudo');

  LogSetMinLevel(llTrace);
end;

procedure TestFormatacao;
begin
  Section('formatacao');
  ResetCapture;
  LogSetMinLevel(llTrace);

  LogInfo('rhi', 'contexto %d.%d criado com %s', [3, 3, 'core']);
  Check(GLastText = 'contexto 3.3 criado com core', 'Format aplicado aos args');
  Check(Pos('INFO', GLastFormatted) > 0, 'linha formatada traz o nivel');
  Check(Pos('rhi', GLastFormatted) > 0, 'linha formatada traz a categoria');
  Check(Pos('contexto 3.3', GLastFormatted) > 0, 'linha formatada traz o texto');

  ResetCapture;
  LogInfo('teste', 'faltou argumento: %d %d', [1]);
  CheckI(GCapturedCount, 1, 'formato invalido ainda emite alguma coisa');
  Check(Pos('malformado', GLastText) > 0, 'e a mensagem diz que o formato quebrou');
end;

procedure TestContadores;
var
  W0, E0: Integer;
begin
  Section('contadores');
  LogSetMinLevel(llTrace);
  W0 := LogWarnCount;
  E0 := LogErrorCount;

  LogInfo('teste', 'info nao conta', []);
  CheckI(LogWarnCount - W0, 0, 'info nao incrementa warn');
  CheckI(LogErrorCount - E0, 0, 'info nao incrementa error');

  LogWarn('teste', 'aviso', []);
  CheckI(LogWarnCount - W0, 1, 'warn incrementa');

  LogError('teste', 'erro', []);
  LogFatal('teste', 'fatal', []);
  CheckI(LogErrorCount - E0, 2, 'error e fatal contam juntos');
end;

procedure TestSinks;
var
  Id1, Id2, Id3: Integer;
begin
  Section('sinks');
  LogSetMinLevel(llTrace);

  LogClearSinks;
  Id1 := LogAddSink(CaptureSink);
  Id2 := LogAddSink(CaptureSink2);
  Check(Id1 >= 0, 'AddSink devolve ID valido');
  Check(Id1 <> Id2, 'IDs distintos para sinks distintos');

  ResetCapture;
  LogInfo('teste', 'para os dois', []);
  CheckI(GCapturedCount, 1, 'sink 1 recebeu');
  CheckI(GCaptured2Count, 1, 'sink 2 recebeu - a mensagem vai para todos');

  LogRemoveSink(Id2);
  ResetCapture;
  LogInfo('teste', 'so o primeiro', []);
  CheckI(GCapturedCount, 1, 'sink 1 continua depois de remover o outro');
  CheckI(GCaptured2Count, 0, 'RemoveSink removeu o sink 2');

  Check(Id1 = 0, 'o ID do sink 1 nao mudou quando o 2 saiu');

  LogRemoveSink(Id2);
  LogRemoveSink(-1);
  LogRemoveSink(9999);
  ResetCapture;
  LogInfo('teste', 'ids invalidos', []);
  CheckI(GCapturedCount, 1, 'remover ID invalido ou repetido e no-op');

  Id3 := LogAddSink(CaptureSink2);
  CheckI(Id3, Id2, 'novo sink reaproveita o slot que vagou');

  LogClearSinks;
  ResetCapture;
  LogInfo('teste', 'ninguem ouve', []);
  CheckI(GCapturedCount, 0, 'ClearSinks tira todos');

  LogAddSink(CaptureSink);
end;

function RunAllLogTests: Boolean;
begin
  GPassed := 0;
  GFailed := 0;

  WriteLn('=== Engine.Core.Log - testes ===');

  LogInit(llTrace);

  LogClearSinks;
  LogAddSink(CaptureSink);
  try
    TestFiltro;
    TestFormatacao;
    TestContadores;
    TestSinks;
  finally
    LogShutdown;
  end;

  WriteLn;
  WriteLn('passou: ', GPassed, '   falhou: ', GFailed);
  Result := GFailed = 0;
  if Result then
    WriteLn('OK')
  else
    WriteLn('FALHAS ACIMA');
end;

end.
