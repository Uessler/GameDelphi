

unit Engine.Core.Memory.Test;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$POINTERMATH ON}

interface

function RunAllMemoryTests: Boolean;

implementation

uses
  SysUtils,
  Engine.Core.Memory;

var
  GPassed: Integer;
  GFailed: Integer;
  GSection: string;

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

procedure CheckI(const A, B: Int64; const What: string);
begin
  Check(A = B, What + Format('  (got %d, want %d)', [A, B]));
end;

type
  TBigRec = record
    A, B, C, D: Double;
  end;
  PBigRec = ^TBigRec;

procedure TestArena;
var
  A: TArena;
  P, Q: Pointer;
  M: TArenaMark;
  I: Integer;
  Big: PBigRec;
begin
  Section('TArena');
  A.Init(4096);
  try
    Check(A.IsValid, 'Init aloca');
    CheckI(A.Capacity, 4096, 'Capacity');
    CheckI(A.Used, 0, 'comeca vazia');
    CheckI(A.Available, 4096, 'Available inicial');

    P := A.Alloc(100);
    Check(P <> nil, 'Alloc devolve ponteiro');
    Check(A.Used >= 100, 'Used avanca pelo menos o tamanho pedido');
    Check(NativeUInt(P) mod 16 = 0, 'primeira alocacao ja sai alinhada');

    Q := A.Alloc(16);
    CheckI(NativeUInt(Q) - NativeUInt(P), 112, 'segunda alocacao alinha em 16');
    Check(NativeUInt(Q) mod 16 = 0, 'ponteiro sai alinhado em 16');

    P := A.Alloc(8, 64);
    Check(NativeUInt(P) mod 64 = 0, 'alinhamento customizado de 64 respeitado');

    CheckI(A.AllocCount, 3, 'AllocCount conta as alocacoes');

    M := A.Mark;
    A.Alloc(1000);
    Check(A.Used > NativeUInt(M), 'alocou depois da marca');
    A.ReleaseTo(M);
    CheckI(A.Used, NativeUInt(M), 'ReleaseTo volta exatamente para a marca');

    A.Reset;
    CheckI(A.Used, 0, 'Reset volta ao inicio');
    Check(A.Peak > 0, 'Peak sobrevive ao Reset (e a metrica de dimensionamento)');

    A.Reset;
    P := A.Alloc(64);
    FillChar(P^, 64, $AB);
    A.Reset;
    Big := A.AllocZeroed(SizeOf(TBigRec));
    Check((Big.A = 0) and (Big.B = 0) and (Big.C = 0) and (Big.D = 0),
      'AllocZeroed zera memoria suja de uso anterior');

    A.Reset;
    Big := A.Alloc(SizeOf(TBigRec));
    Big.A := 123.5;
    for I := 1 to 50 do
      A.Alloc(16);
    Check(Big.A = 123.5, 'alocacoes seguintes nao pisam na anterior');
  finally
    A.Free;
  end;
  Check(not A.IsValid, 'Free invalida a arena');
end;

procedure TestArenaEsgotamento;
var
  A: TArena;
  P: Pointer;
  Levantou: Boolean;
begin
  Section('TArena esgotamento');
  A.Init(256);
  try
    A.Alloc(200);
    P := A.TryAlloc(200);
    Check(P = nil, 'TryAlloc devolve nil quando nao cabe');
    CheckI(A.Used, 200, 'TryAlloc que falha nao move o offset');

    Levantou := False;
    try
      A.Alloc(200);
    except
      on EMemoryError do Levantou := True;
    end;
    Check(Levantou, 'Alloc levanta EMemoryError quando nao cabe');

    Levantou := False;
    try
      A.Alloc(16, 17);
    except
      on EMemoryError do Levantou := True;
    end;
    Check(Levantou, 'alinhamento que nao e potencia de 2 e rejeitado');

    P := A.TryAlloc(0);
    Check(P = nil, 'Alloc de zero bytes devolve nil');
  finally
    A.Free;
  end;

  A.Init(0);
  Check(not A.IsValid, 'Init(0) nao aloca');
  Check(A.TryAlloc(10) = nil, 'TryAlloc em arena invalida devolve nil');
  A.Free;
end;

procedure TestPool;
var
  P: TPool;
  A, B, C: Pointer;
  Blocos: array [0 .. 15] of Pointer;
  I, Vivos: Integer;
begin
  Section('TPool');
  P.Init(64, 16);
  try
    Check(P.IsValid, 'Init aloca');
    CheckI(P.BlockCount, 16, 'BlockCount');
    CheckI(P.BlockSize, 64, 'BlockSize');
    CheckI(P.UsedCount, 0, 'comeca vazio');
    CheckI(P.FreeCount, 16, 'FreeCount inicial');

    A := P.Alloc;
    B := P.Alloc;
    Check((A <> nil) and (B <> nil), 'Alloc devolve blocos');
    Check(A <> B, 'blocos diferentes');
    CheckI(P.UsedCount, 2, 'UsedCount sobe');
    Check(P.Owns(A), 'Owns reconhece bloco proprio');

    P.Release(A);
    CheckI(P.UsedCount, 1, 'Release baixa o UsedCount');

    C := P.Alloc;
    Check(C = A, 'o bloco liberado e reaproveitado (LIFO)');

    P.Reset;
    Vivos := 0;
    for I := 0 to 15 do
    begin
      Blocos[I] := P.Alloc;
      if Blocos[I] <> nil then
        Inc(Vivos);
    end;
    CheckI(Vivos, 16, 'aloca exatamente a capacidade');
    CheckI(P.FreeCount, 0, 'pool cheio');
    Check(P.Alloc = nil, 'pool cheio devolve nil');
    CheckI(P.PeakUsed, 16, 'PeakUsed registra o maximo');

    Check(NativeUInt(Blocos[0]) mod 16 = 0, 'blocos alinhados');
    CheckI(NativeUInt(Blocos[1]) - NativeUInt(Blocos[0]), 64, 'blocos contiguos');

    FillChar(Blocos[3]^, 64, $11);
    FillChar(Blocos[4]^, 64, $22);
    Check(PByte(Blocos[3])[63] = $11, 'bloco 3 intacto ate o ultimo byte');
    Check(PByte(Blocos[4])[0] = $22, 'bloco 4 intacto no primeiro byte');

    P.Reset;
    CheckI(P.UsedCount, 0, 'Reset libera tudo');
    Check(P.Alloc <> nil, 'da para alocar de novo depois do Reset');
  finally
    P.Free;
  end;
end;

procedure TestPoolProtecoes;
var
  P: TPool;
  Fora: Integer;
  Bloco: Pointer;
  Levantou: Boolean;
begin
  Section('TPool protecoes');
  P.Init(64, 4);
  try
    Bloco := P.Alloc;

    Levantou := False;
    try
      P.Release(@Fora);
    except
      on EMemoryError do Levantou := True;
    end;
    Check(Levantou, 'Release de ponteiro de fora do pool e rejeitado');

    Levantou := False;
    try
      P.Release(PByte(Bloco) + 8);
    except
      on EMemoryError do Levantou := True;
    end;
    Check(Levantou, 'Release no meio de um bloco e rejeitado');

    P.Release(nil);
    CheckI(P.UsedCount, 1, 'Release(nil) e no-op');
  finally
    P.Free;
  end;

  P.Init(1, 8);
  try
    Check(P.BlockSize >= SizeOf(Integer),
      'bloco menor que Integer e arredondado (free list intrusiva)');
    Check(P.Alloc <> nil, 'e continua alocando normal');
  finally
    P.Free;
  end;
end;

procedure TestHandle;
var
  H: THandle;
begin
  Section('THandle');
  Check(THandle.Null.IsNull, 'Null e nulo');
  CheckI(THandle.Null.Value, 0, 'Null vale zero');

  H := THandle.Make(5, 3);
  CheckI(H.Index, 5, 'Index sobrevive ao empacotamento');
  CheckI(H.Generation, 3, 'Generation sobrevive ao empacotamento');
  Check(not H.IsNull, 'handle valido nao e nulo');

  H := THandle.Make(HANDLE_MAX_INDEX, HANDLE_GEN_MASK);
  CheckI(H.Index, HANDLE_MAX_INDEX, 'indice maximo cabe');
  CheckI(H.Generation, HANDLE_GEN_MASK, 'geracao maxima cabe');

  Check(THandle.Make(7, 1) = THandle.Make(7, 1), 'handles iguais comparam igual');
  Check(THandle.Make(7, 1) <> THandle.Make(7, 2),
    'mesma posicao com geracao diferente NAO e o mesmo handle');
  Check(SizeOf(THandle) = 4, 'THandle tem 4 bytes');
end;

type
  TFakeTexture = record
    GLId: Cardinal;
    Width, Height: Integer;
    Name: string;
  end;

procedure TestResourcePool;
var
  Pool: TResourcePool<TFakeTexture>;
  T: TFakeTexture;
  H1, H2, H3, HVelho: THandle;
  Got: TFakeTexture;
  P: Pointer;
  I, N, Slot: Integer;
  Handles: array [0 .. 99] of THandle;
begin
  Section('TResourcePool');
  Pool.Init(4);
  CheckI(Pool.Count, 0, 'comeca vazio');

  T.GLId := 10; T.Width := 256; T.Height := 256; T.Name := 'atlas';
  H1 := Pool.Add(T);
  Check(not H1.IsNull, 'Add devolve handle valido');
  Check(Pool.IsValid(H1), 'handle recem-criado e valido');
  CheckI(Pool.Count, 1, 'Count sobe');

  Check(Pool.TryGet(H1, Got), 'TryGet acha');
  CheckI(Got.GLId, 10, 'o valor guardado volta certo');
  Check(Got.Name = 'atlas', 'campo string sobrevive');

  T.GLId := 20; T.Name := 'fonte';
  H2 := Pool.Add(T);
  Check(H1 <> H2, 'handles distintos');
  CheckI(Pool.Count, 2, 'dois vivos');

  P := Pool.GetPtr(H1);
  Check(P <> nil, 'GetPtr devolve ponteiro para handle vivo');
  TFakeTexture(P^).Width := 512;
  Pool.TryGet(H1, Got);
  CheckI(Got.Width, 512, 'escrita pelo ponteiro e vista pelo TryGet');

  Section('TResourcePool geracao');
  HVelho := H1;
  Check(Pool.Remove(H1), 'Remove devolve True');
  CheckI(Pool.Count, 1, 'Count cai');
  Check(not Pool.IsValid(HVelho), 'handle do recurso destruido nao valida mais');
  Check(Pool.GetPtr(HVelho) = nil, 'GetPtr de handle morto devolve nil');
  Check(not Pool.TryGet(HVelho, Got), 'TryGet de handle morto falha');
  Check(not Pool.Remove(HVelho), 'Remove duplo devolve False');

  T.GLId := 30; T.Name := 'novo';
  H3 := Pool.Add(T);
  CheckI(H3.Index, HVelho.Index, 'o slot liberado foi reaproveitado');
  Check(H3 <> HVelho, 'mas o handle novo e diferente do antigo');
  Check(Pool.IsValid(H3), 'handle novo vale');
  Check(not Pool.IsValid(HVelho),
    'handle antigo do MESMO slot continua invalido - e este o ponto da geracao');
  Pool.TryGet(H3, Got);
  CheckI(Got.GLId, 30, 'o slot reaproveitado tem o dado novo');

  Section('TResourcePool crescimento');
  Pool.Init(2);
  for I := 0 to 99 do
  begin
    T.GLId := Cardinal(I);
    T.Name := 'tex';
    Handles[I] := Pool.Add(T);
  end;
  CheckI(Pool.Count, 100, 'cresceu para 100 itens');
  Check(Pool.Capacity >= 100, 'capacidade acompanhou');

  N := 0;
  for I := 0 to 99 do
    if Pool.IsValid(Handles[I]) then
    begin
      Pool.TryGet(Handles[I], Got);
      if Got.GLId = Cardinal(I) then
        Inc(N);
    end;
  CheckI(N, 100, 'todos os handles continuam validos e apontam certo depois de crescer');

  for I := 0 to 99 do
    if I mod 2 = 0 then
      Pool.Remove(Handles[I]);
  CheckI(Pool.Count, 50, 'metade removida');

  N := 0;
  Slot := Pool.FirstAlive;
  while Slot >= 0 do
  begin
    Inc(N);
    Slot := Pool.NextAlive(Slot);
  end;
  CheckI(N, 50, 'iteracao visita exatamente os vivos');

  N := 0;
  for I := 0 to 99 do
    if (I mod 2 = 0) = Pool.IsValid(Handles[I]) then
      Inc(N);
  CheckI(N, 0, 'todo handle removido invalidou e todo handle vivo continua valido');

  Pool.Clear;
  CheckI(Pool.Count, 0, 'Clear esvazia');
  Check(not Pool.IsValid(Handles[1]), 'Clear tambem invalida os handles antigos');
end;

function RunAllMemoryTests: Boolean;
begin
  GPassed := 0;
  GFailed := 0;

  WriteLn('=== Engine.Core.Memory - testes ===');
  TestArena;
  TestArenaEsgotamento;
  TestPool;
  TestPoolProtecoes;
  TestHandle;
  TestResourcePool;

  WriteLn;
  WriteLn('passou: ', GPassed, '   falhou: ', GFailed);
  Result := GFailed = 0;
  if Result then
    WriteLn('OK')
  else
    WriteLn('FALHAS ACIMA');
end;

end.
