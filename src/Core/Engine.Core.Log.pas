unit Engine.Core.Log;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes, SyncObjs;

type
  TLogLevel = (llTrace, llDebug, llInfo, llWarn, llError, llFatal, llOff);

  TLogSink = procedure(const Level: TLogLevel; const Category, Text: string;
    const Formatted: string);

const
  LOG_LEVEL_NAMES: array [TLogLevel] of string =
    ('TRACE', 'DEBUG', 'INFO ', 'WARN ', 'ERROR', 'FATAL', 'OFF  ');

procedure LogInit(const MinLevel: TLogLevel = llInfo; const FileName: string = '');
procedure LogShutdown;

procedure LogSetMinLevel(const Level: TLogLevel);
function LogGetMinLevel: TLogLevel;

function LogEnabled(const Level: TLogLevel): Boolean;

function LogAddSink(const Sink: TLogSink): Integer;
procedure LogRemoveSink(const SinkId: Integer);

procedure LogClearSinks;

procedure LogWrite(const Level: TLogLevel; const Category, Fmt: string;
  const Args: array of const);

procedure LogTrace(const Category, Fmt: string; const Args: array of const);
procedure LogDebug(const Category, Fmt: string; const Args: array of const);
procedure LogInfo(const Category, Fmt: string; const Args: array of const);
procedure LogWarn(const Category, Fmt: string; const Args: array of const);
procedure LogError(const Category, Fmt: string; const Args: array of const);
procedure LogFatal(const Category, Fmt: string; const Args: array of const);

function LogWarnCount: Integer;
function LogErrorCount: Integer;

procedure LogConsoleSink(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);

implementation

var

  GConsoleOk: Boolean = True;
  GLock: TCriticalSection;
  GMinLevel: TLogLevel = llInfo;
  GSinks: array of TLogSink;
  GFile: TextFile;
  GHasFile: Boolean = False;
  GWarnCount: Integer = 0;
  GErrorCount: Integer = 0;
  GStart: TDateTime;
  GInitialized: Boolean = False;

procedure LogConsoleSink(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);
begin
  if not GConsoleOk then
    Exit;
  try

    if Level >= llError then
      WriteLn(ErrOutput, Formatted)
    else
      WriteLn(Formatted);
  except

    GConsoleOk := False;
  end;
end;

procedure LogFileSink(const Level: TLogLevel; const Category, Text: string;
  const Formatted: string);
begin
  if not GHasFile then
    Exit;
  try
    WriteLn(GFile, Formatted);

    Flush(GFile);
  except

    GHasFile := False;
  end;
end;

procedure LogInit(const MinLevel: TLogLevel; const FileName: string);
begin
  if GInitialized then
    Exit;

  GLock := TCriticalSection.Create;
  GMinLevel := MinLevel;
  GWarnCount := 0;
  GErrorCount := 0;
  GStart := Now;
  GConsoleOk := True;
  SetLength(GSinks, 0);
  GInitialized := True;

  LogAddSink(LogConsoleSink);

  if FileName <> '' then
  begin
    AssignFile(GFile, FileName);
    {$I-}
    Rewrite(GFile);
    {$I+}
    GHasFile := IOResult = 0;
    if GHasFile then
      LogAddSink(LogFileSink);
  end;
end;

procedure LogShutdown;
begin
  if not GInitialized then
    Exit;

  if GHasFile then
  begin
    Flush(GFile);
    CloseFile(GFile);
    GHasFile := False;
  end;

  SetLength(GSinks, 0);
  FreeAndNil(GLock);
  GInitialized := False;
end;

procedure LogSetMinLevel(const Level: TLogLevel);
begin
  GMinLevel := Level;
end;

function LogGetMinLevel: TLogLevel;
begin
  Result := GMinLevel;
end;

function LogEnabled(const Level: TLogLevel): Boolean;
begin
  Result := GInitialized and (Level >= GMinLevel) and (GMinLevel <> llOff);
end;

function LogAddSink(const Sink: TLogSink): Integer;
var
  I, N: Integer;
begin
  Result := -1;
  if (not GInitialized) or (not Assigned(Sink)) then
    Exit;
  GLock.Enter;
  try

    for I := 0 to High(GSinks) do
      if not Assigned(GSinks[I]) then
      begin
        GSinks[I] := Sink;
        Exit(I);
      end;
    N := Length(GSinks);
    SetLength(GSinks, N + 1);
    GSinks[N] := Sink;
    Result := N;
  finally
    GLock.Leave;
  end;
end;

procedure LogRemoveSink(const SinkId: Integer);
begin
  if not GInitialized then
    Exit;
  GLock.Enter;
  try

    if (SinkId >= 0) and (SinkId <= High(GSinks)) then
      GSinks[SinkId] := nil;
  finally
    GLock.Leave;
  end;
end;

procedure LogClearSinks;
begin
  if not GInitialized then
    Exit;
  GLock.Enter;
  try
    SetLength(GSinks, 0);
  finally
    GLock.Leave;
  end;
end;

procedure LogWrite(const Level: TLogLevel; const Category, Fmt: string;
  const Args: array of const);
var
  Text, Formatted, Stamp: string;
  I: Integer;
begin

  if not LogEnabled(Level) then
    Exit;

  if Level = llWarn then
    Inc(GWarnCount)
  else if Level >= llError then
    Inc(GErrorCount);

  try
    Text := Format(Fmt, Args);
  except

    on E: Exception do
      Text := '<log malformado: ' + Fmt + ' (' + E.Message + ')>';
  end;

  Stamp := FormatDateTime('hh:nn:ss.zzz', Now);
  Formatted := Format('[%s] %s [%-8s] %s',
    [Stamp, LOG_LEVEL_NAMES[Level], Category, Text]);

  GLock.Enter;
  try
    for I := 0 to High(GSinks) do
      if Assigned(GSinks[I]) then
        GSinks[I](Level, Category, Text, Formatted);
  finally
    GLock.Leave;
  end;
end;

procedure LogTrace(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llTrace, Category, Fmt, Args);
end;

procedure LogDebug(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llDebug, Category, Fmt, Args);
end;

procedure LogInfo(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llInfo, Category, Fmt, Args);
end;

procedure LogWarn(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llWarn, Category, Fmt, Args);
end;

procedure LogError(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llError, Category, Fmt, Args);
end;

procedure LogFatal(const Category, Fmt: string; const Args: array of const);
begin
  LogWrite(llFatal, Category, Fmt, Args);
end;

function LogWarnCount: Integer;
begin
  Result := GWarnCount;
end;

function LogErrorCount: Integer;
begin
  Result := GErrorCount;
end;

initialization

finalization
  LogShutdown;

end.
