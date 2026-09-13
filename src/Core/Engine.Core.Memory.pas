

unit Engine.Core.Memory;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$POINTERMATH ON}

interface

uses
  SysUtils;

type
  EMemoryError = class(Exception);

const

  DEFAULT_ALIGNMENT = 16;

type
  TArenaMark = type NativeUInt;

  TArena = record
  private
    FBase: PByte;
    FCapacity: NativeUInt;
    FOffset: NativeUInt;
    FPeak: NativeUInt;
    FAllocCount: Int64;
  public
    procedure Init(const CapacityBytes: NativeUInt);
    procedure Free;

    function Alloc(const Size: NativeUInt;
      const Alignment: NativeUInt = DEFAULT_ALIGNMENT): Pointer;

    function TryAlloc(const Size: NativeUInt;
      const Alignment: NativeUInt = DEFAULT_ALIGNMENT): Pointer;

    function AllocZeroed(const Size: NativeUInt;
      const Alignment: NativeUInt = DEFAULT_ALIGNMENT): Pointer;

    function Mark: TArenaMark;

    procedure ReleaseTo(const M: TArenaMark);

    procedure Reset;

    function Used: NativeUInt;
    function Available: NativeUInt;
    function Capacity: NativeUInt;

    function Peak: NativeUInt;
    function AllocCount: Int64;
    function IsValid: Boolean;

    function BasePtr: Pointer;
  end;
  PArena = ^TArena;

type
  TPool = record
  private
    FBase: PByte;
    FBlockSize: NativeUInt;
    FBlockCount: Integer;
    FFreeHead: Integer;
    FUsedCount: Integer;
    FPeakUsed: Integer;
  public
    procedure Init(const BlockSize: NativeUInt; const BlockCount: Integer;
      const Alignment: NativeUInt = DEFAULT_ALIGNMENT);
    procedure Free;

    function Alloc: Pointer;
    function AllocZeroed: Pointer;

    procedure Release(const P: Pointer);

    procedure Reset;

    function Owns(const P: Pointer): Boolean;
    function BlockSize: NativeUInt;
    function BlockCount: Integer;
    function UsedCount: Integer;
    function FreeCount: Integer;
    function PeakUsed: Integer;
    function IsValid: Boolean;
  end;
  PPool = ^TPool;

const
  HANDLE_INDEX_BITS = 20;
  HANDLE_GEN_BITS   = 12;
  HANDLE_INDEX_MASK = (1 shl HANDLE_INDEX_BITS) - 1;
  HANDLE_GEN_MASK   = (1 shl HANDLE_GEN_BITS) - 1;
  HANDLE_MAX_INDEX  = HANDLE_INDEX_MASK;

type
  THandle = record
  public
    Value: UInt32;
    class function Null: THandle; static; inline;
    class function Make(const AIndex, AGeneration: Cardinal): THandle; static; inline;
    function Index: Cardinal; inline;
    function Generation: Cardinal; inline;
    function IsNull: Boolean; inline;
    class operator Equal(const A, B: THandle): Boolean; inline;
    class operator NotEqual(const A, B: THandle): Boolean; inline;
  end;
  PHandle = ^THandle;

type
  TResourcePool<T> = record
  private
    FItems: array of T;
    FGenerations: array of Word;
    FAlive: array of Boolean;
    FFreeList: array of Integer;
    FFreeCount: Integer;
    FHighWater: Integer;
    FLiveCount: Integer;
    FCapacity: Integer;
    function AllocSlot(out H: THandle): Integer;
  public
    procedure Init(const InitialCapacity: Integer = 64);
    procedure Clear;

    function Add(const Item: T): THandle;

    function AddSlot(out H: THandle): Pointer;

    function IsValid(const H: THandle): Boolean;

    function TryGet(const H: THandle; out Item: T): Boolean;

    function GetPtr(const H: THandle): Pointer;
    function TrySet(const H: THandle; const Item: T): Boolean;

    function Remove(const H: THandle): Boolean;

    function FirstAlive: Integer;
    function NextAlive(const FromIndex: Integer): Integer;
    function HandleAt(const SlotIndex: Integer): THandle;
    function PtrAt(const SlotIndex: Integer): Pointer;

    function Count: Integer;
    function Capacity: Integer;
  end;

function AlignUp(const Value, Alignment: NativeUInt): NativeUInt; inline;
function IsPowerOfTwo(const V: NativeUInt): Boolean; inline;

implementation

function IsPowerOfTwo(const V: NativeUInt): Boolean;
begin
  Result := (V <> 0) and ((V and (V - 1)) = 0);
end;

function AlignUp(const Value, Alignment: NativeUInt): NativeUInt;
begin
  Result := (Value + (Alignment - 1)) and not (Alignment - 1);
end;

procedure TArena.Init(const CapacityBytes: NativeUInt);
begin
  FBase := nil;
  FCapacity := 0;
  FOffset := 0;
  FPeak := 0;
  FAllocCount := 0;

  if CapacityBytes = 0 then
    Exit;

  GetMem(Pointer(FBase), CapacityBytes);
  if FBase = nil then
    raise EMemoryError.CreateFmt('TArena.Init: nao consegui %d bytes',
      [CapacityBytes]);
  FCapacity := CapacityBytes;
end;

procedure TArena.Free;
begin
  if FBase <> nil then
  begin
    FreeMem(Pointer(FBase));
    FBase := nil;
  end;
  FCapacity := 0;
  FOffset := 0;
end;

function TArena.TryAlloc(const Size, Alignment: NativeUInt): Pointer;
var
  Aligned, NewOffset: NativeUInt;
begin
  Result := nil;
  if (FBase = nil) or (Size = 0) then
    Exit;
  if not IsPowerOfTwo(Alignment) then
    raise EMemoryError.CreateFmt('TArena: alinhamento %d nao e potencia de 2',
      [Alignment]);

  Aligned := AlignUp(NativeUInt(FBase) + FOffset, Alignment);
  NewOffset := (Aligned - NativeUInt(FBase)) + Size;
  if NewOffset > FCapacity then
    Exit;

  Result := Pointer(Aligned);
  FOffset := NewOffset;
  if FOffset > FPeak then
    FPeak := FOffset;
  Inc(FAllocCount);
end;

function TArena.Alloc(const Size, Alignment: NativeUInt): Pointer;
begin
  Result := TryAlloc(Size, Alignment);
  if Result = nil then
    raise EMemoryError.CreateFmt(
      'TArena esgotada: pediu %d bytes, sobram %d de %d (pico %d). ' +
      'Aumente a capacidade no Init.',
      [Size, Available, FCapacity, FPeak]);
end;

function TArena.AllocZeroed(const Size, Alignment: NativeUInt): Pointer;
begin
  Result := Alloc(Size, Alignment);
  FillChar(Result^, Size, 0);
end;

function TArena.Mark: TArenaMark;
begin
  Result := TArenaMark(FOffset);
end;

procedure TArena.ReleaseTo(const M: TArenaMark);
begin
  if NativeUInt(M) <= FOffset then
    FOffset := NativeUInt(M);
end;

procedure TArena.Reset;
begin
  FOffset := 0;
end;

function TArena.Used: NativeUInt;
begin
  Result := FOffset;
end;

function TArena.Available: NativeUInt;
begin
  if FCapacity >= FOffset then
    Result := FCapacity - FOffset
  else
    Result := 0;
end;

function TArena.Capacity: NativeUInt;
begin
  Result := FCapacity;
end;

function TArena.Peak: NativeUInt;
begin
  Result := FPeak;
end;

function TArena.AllocCount: Int64;
begin
  Result := FAllocCount;
end;

function TArena.IsValid: Boolean;
begin
  Result := FBase <> nil;
end;

function TArena.BasePtr: Pointer;
begin
  Result := FBase;
end;

procedure TPool.Init(const BlockSize: NativeUInt; const BlockCount: Integer;
  const Alignment: NativeUInt);
var
  I: Integer;
  Size: NativeUInt;
begin
  FBase := nil;
  FBlockSize := 0;
  FBlockCount := 0;
  FFreeHead := -1;
  FUsedCount := 0;
  FPeakUsed := 0;

  if (BlockSize = 0) or (BlockCount <= 0) then
    Exit;
  if not IsPowerOfTwo(Alignment) then
    raise EMemoryError.CreateFmt('TPool: alinhamento %d nao e potencia de 2',
      [Alignment]);

  Size := BlockSize;
  if Size < SizeOf(Integer) then
    Size := SizeOf(Integer);
  Size := AlignUp(Size, Alignment);

  GetMem(Pointer(FBase), Size * NativeUInt(BlockCount));
  if FBase = nil then
    raise EMemoryError.CreateFmt('TPool.Init: nao consegui %d bytes',
      [Size * NativeUInt(BlockCount)]);

  FBlockSize := Size;
  FBlockCount := BlockCount;

  for I := 0 to BlockCount - 2 do
    PInteger(FBase + NativeUInt(I) * Size)^ := I + 1;
  PInteger(FBase + NativeUInt(BlockCount - 1) * Size)^ := -1;
  FFreeHead := 0;
end;

procedure TPool.Free;
begin
  if FBase <> nil then
  begin
    FreeMem(Pointer(FBase));
    FBase := nil;
  end;
  FBlockCount := 0;
  FFreeHead := -1;
  FUsedCount := 0;
end;

function TPool.Alloc: Pointer;
var
  Idx: Integer;
begin
  if (FBase = nil) or (FFreeHead < 0) then
    Exit(nil);

  Idx := FFreeHead;
  Result := FBase + NativeUInt(Idx) * FBlockSize;
  FFreeHead := PInteger(Result)^;
  Inc(FUsedCount);
  if FUsedCount > FPeakUsed then
    FPeakUsed := FUsedCount;
end;

function TPool.AllocZeroed: Pointer;
begin
  Result := Alloc;
  if Result <> nil then
    FillChar(Result^, FBlockSize, 0);
end;

procedure TPool.Release(const P: Pointer);
var
  Offset: NativeUInt;
  Idx: Integer;
begin
  if P = nil then
    Exit;
  if not Owns(P) then
    raise EMemoryError.Create('TPool.Release: ponteiro nao pertence a este pool');

  Offset := NativeUInt(P) - NativeUInt(FBase);
  if Offset mod FBlockSize <> 0 then
    raise EMemoryError.Create('TPool.Release: ponteiro nao esta no inicio de um bloco');

  Idx := Integer(Offset div FBlockSize);
  PInteger(P)^ := FFreeHead;
  FFreeHead := Idx;
  Dec(FUsedCount);
end;

procedure TPool.Reset;
var
  I: Integer;
begin
  if FBase = nil then
    Exit;
  for I := 0 to FBlockCount - 2 do
    PInteger(FBase + NativeUInt(I) * FBlockSize)^ := I + 1;
  PInteger(FBase + NativeUInt(FBlockCount - 1) * FBlockSize)^ := -1;
  FFreeHead := 0;
  FUsedCount := 0;
end;

function TPool.Owns(const P: Pointer): Boolean;
begin
  Result := (FBase <> nil) and (NativeUInt(P) >= NativeUInt(FBase)) and
    (NativeUInt(P) < NativeUInt(FBase) + FBlockSize * NativeUInt(FBlockCount));
end;

function TPool.BlockSize: NativeUInt;
begin
  Result := FBlockSize;
end;

function TPool.BlockCount: Integer;
begin
  Result := FBlockCount;
end;

function TPool.UsedCount: Integer;
begin
  Result := FUsedCount;
end;

function TPool.FreeCount: Integer;
begin
  Result := FBlockCount - FUsedCount;
end;

function TPool.PeakUsed: Integer;
begin
  Result := FPeakUsed;
end;

function TPool.IsValid: Boolean;
begin
  Result := FBase <> nil;
end;

class function THandle.Null: THandle;
begin
  Result.Value := 0;
end;

class function THandle.Make(const AIndex, AGeneration: Cardinal): THandle;
begin
  Result.Value := (AIndex and HANDLE_INDEX_MASK) or
    ((AGeneration and HANDLE_GEN_MASK) shl HANDLE_INDEX_BITS);
end;

function THandle.Index: Cardinal;
begin
  Result := Value and HANDLE_INDEX_MASK;
end;

function THandle.Generation: Cardinal;
begin
  Result := (Value shr HANDLE_INDEX_BITS) and HANDLE_GEN_MASK;
end;

function THandle.IsNull: Boolean;
begin
  Result := Value = 0;
end;

class operator THandle.Equal(const A, B: THandle): Boolean;
begin
  Result := A.Value = B.Value;
end;

class operator THandle.NotEqual(const A, B: THandle): Boolean;
begin
  Result := A.Value <> B.Value;
end;

procedure TResourcePool<T>.Init(const InitialCapacity: Integer);
var
  Cap: Integer;
begin
  Cap := InitialCapacity;
  if Cap < 1 then
    Cap := 1;

  SetLength(FItems, Cap);
  SetLength(FGenerations, Cap);
  SetLength(FAlive, Cap);
  SetLength(FFreeList, Cap);

  FCapacity := Cap;
  FHighWater := 0;
  FLiveCount := 0;
  FFreeCount := 0;

  FillChar(FAlive[0], Cap * SizeOf(Boolean), 0);
  FillChar(FGenerations[0], Cap * SizeOf(Word), 0);
end;

procedure TResourcePool<T>.Clear;
var
  I: Integer;
begin
  for I := 0 to FCapacity - 1 do
    if FAlive[I] then
    begin
      FAlive[I] := False;
      FGenerations[I] := (FGenerations[I] + 1) and HANDLE_GEN_MASK;
      if FGenerations[I] = 0 then
        FGenerations[I] := 1;
    end;
  FHighWater := 0;
  FLiveCount := 0;
  FFreeCount := 0;
end;

function TResourcePool<T>.AllocSlot(out H: THandle): Integer;
var
  Slot, NewCap, I: Integer;
begin
  if FFreeCount > 0 then
  begin
    Dec(FFreeCount);
    Slot := FFreeList[FFreeCount];
  end
  else
  begin
    if FHighWater >= FCapacity then
    begin
      NewCap := FCapacity * 2;
      if NewCap > HANDLE_MAX_INDEX then
        NewCap := HANDLE_MAX_INDEX;
      if NewCap <= FCapacity then
        raise EMemoryError.CreateFmt(
          'TResourcePool cheio: %d slots e o limite do handle de %d bits',
          [FCapacity, HANDLE_INDEX_BITS]);

      SetLength(FItems, NewCap);
      SetLength(FGenerations, NewCap);
      SetLength(FAlive, NewCap);
      SetLength(FFreeList, NewCap);
      for I := FCapacity to NewCap - 1 do
      begin
        FAlive[I] := False;
        FGenerations[I] := 0;
      end;
      FCapacity := NewCap;
    end;
    Slot := FHighWater;
    Inc(FHighWater);
  end;

  if FGenerations[Slot] = 0 then
    FGenerations[Slot] := 1;

  FAlive[Slot] := True;
  Inc(FLiveCount);

  H := THandle.Make(Cardinal(Slot), FGenerations[Slot]);
  Result := Slot;
end;

function TResourcePool<T>.AddSlot(out H: THandle): Pointer;
var
  Slot: Integer;
begin

  Slot := AllocSlot(H);
  Result := @FItems[Slot];
end;

function TResourcePool<T>.Add(const Item: T): THandle;
var
  Slot: Integer;
begin
  Slot := AllocSlot(Result);
  FItems[Slot] := Item;
end;

function TResourcePool<T>.IsValid(const H: THandle): Boolean;
var
  Idx: Integer;
begin
  if H.IsNull then
    Exit(False);
  Idx := Integer(H.Index);
  Result := (Idx >= 0) and (Idx < FCapacity) and FAlive[Idx] and
    (FGenerations[Idx] = H.Generation);
end;

function TResourcePool<T>.TryGet(const H: THandle; out Item: T): Boolean;
begin
  Result := IsValid(H);
  if Result then
    Item := FItems[H.Index];
end;

function TResourcePool<T>.GetPtr(const H: THandle): Pointer;
begin
  if IsValid(H) then
    Result := @FItems[H.Index]
  else
    Result := nil;
end;

function TResourcePool<T>.TrySet(const H: THandle; const Item: T): Boolean;
begin
  Result := IsValid(H);
  if Result then
    FItems[H.Index] := Item;
end;

function TResourcePool<T>.Remove(const H: THandle): Boolean;
var
  Idx: Integer;
begin
  Result := IsValid(H);
  if not Result then
    Exit;

  Idx := Integer(H.Index);
  FAlive[Idx] := False;
  Dec(FLiveCount);

  FGenerations[Idx] := (FGenerations[Idx] + 1) and HANDLE_GEN_MASK;
  if FGenerations[Idx] = 0 then
    FGenerations[Idx] := 1;

  if FFreeCount >= Length(FFreeList) then
    SetLength(FFreeList, FFreeCount + 16);
  FFreeList[FFreeCount] := Idx;
  Inc(FFreeCount);
end;

function TResourcePool<T>.FirstAlive: Integer;
begin
  Result := NextAlive(-1);
end;

function TResourcePool<T>.NextAlive(const FromIndex: Integer): Integer;
var
  I: Integer;
begin
  for I := FromIndex + 1 to FHighWater - 1 do
    if FAlive[I] then
      Exit(I);
  Result := -1;
end;

function TResourcePool<T>.HandleAt(const SlotIndex: Integer): THandle;
begin
  if (SlotIndex >= 0) and (SlotIndex < FCapacity) and FAlive[SlotIndex] then
    Result := THandle.Make(Cardinal(SlotIndex), FGenerations[SlotIndex])
  else
    Result := THandle.Null;
end;

function TResourcePool<T>.PtrAt(const SlotIndex: Integer): Pointer;
begin
  if (SlotIndex >= 0) and (SlotIndex < FCapacity) and FAlive[SlotIndex] then
    Result := @FItems[SlotIndex]
  else
    Result := nil;
end;

function TResourcePool<T>.Count: Integer;
begin
  Result := FLiveCount;
end;

function TResourcePool<T>.Capacity: Integer;
begin
  Result := FCapacity;
end;

end.
