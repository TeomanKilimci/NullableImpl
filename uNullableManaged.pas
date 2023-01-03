unit uNullableManaged;

interface

uses
  System.SysUtils, System.Classes;

type
  TNullable<T> = packed record
  private
    FHasValue: LongBool;
    FValue: T;
    procedure Clear;
    function GetValue: T;
  public
    {$IF CompilerVersion >= 34}
    class operator Initialize (out Dest: TNullable<T>);
    class operator Assign (var Dest: TNullable<T>; const [ref] Src: TNullable<T>); overload;
    {$ENDIF}

    constructor Create(const Value: T); overload;
    function Equals(const Value: TNullable<T>): Boolean;

    class operator Implicit(const Value: TNullable<T>): T;
    class operator Implicit(const Value: TNullable<T>): Variant;
    class operator Implicit(const Value: Pointer): TNullable<T>;
    class operator Implicit(const Value: Variant): TNullable<T>;
    class operator Implicit(const Value: T): TNullable<T>;
    class operator Equal(const Left, Right: TNullable<T>): Boolean;
    class operator NotEqual(const Left, Right: TNullable<T>): Boolean;

    function GetValueOrDefault: T; overload;
    function GetValueOrDefault(const Default: T): T; overload;

    property HasValue: LongBool read FHasValue;
    property Value: T read GetValue;
  end;

  TNullableStreamWriter = class helper for TStream
  private
    procedure WriteString(const AString: string);
    function ReadString: string;
  public
    procedure WriteNullable(ANullable: TNullable<Boolean>); overload;
    procedure WriteNullable(ANullable: TNullable<Byte>); overload;
    procedure WriteNullable(ANullable: TNullable<Integer>); overload;
    procedure WriteNullable(ANullable: TNullable<Int64>); overload;
    procedure WriteNullable(ANullable: TNullable<Double>); overload;
    procedure WriteNullable(ANullable: TNullable<Currency>); overload;
    procedure WriteNullable(ANullable: TNullable<string>); overload;
    {$IF DEFINED(WIN32) OR DEFINED(WIN64)}
    procedure WriteNullable(ANullable: TNullable<AnsiString>); overload;
    {$ENDIF}
    procedure WriteNullable(ANullable: TNullable<TDate>); overload;
    procedure WriteNullable(ANullable: TNullable<TTime>); overload;
    procedure WriteNullable(ANullable: TNullable<TDateTime>); overload;

    function ReadNullableBoolean: Variant;
    function ReadNullableByte: TNullable<Byte>;
    function ReadNullableInteger: TNullable<Integer>;
    function ReadNullableInt64: TNullable<Int64>;
    function ReadNullableDouble: TNullable<Double>;
    function ReadNullableCurrency: TNullable<Currency>;
    function ReadNullableString: TNullable<string>;
    {$IF DEFINED(WIN32) OR DEFINED(WIN64)}
    function ReadNullableAnsiString: TNullable<AnsiString>;
    {$ENDIF}
    function ReadNullableDate: TNullable<TDate>;
    function ReadNullableTime: TNullable<TTime>;
    function ReadNullableDateTime: TNullable<TDateTime>;
  end;

resourcestring
  RNullableNoValue = 'Nullable type has no value';

implementation

uses
  System.Rtti, System.Variants, System.Generics.Defaults,
  {$IF DEFINED(WIN32) OR DEFINED(WIN64)}
  System.AnsiStrings,
  {$ENDIF}
  System.DateUtils;

{$IF CompilerVersion >= 34}
class operator TNullable<T>.Initialize (out Dest: TNullable<T>);
begin
  Dest.FHasValue := False;
end;

class operator TNullable<T>.Assign (var Dest: TNullable<T>; const [ref] Src: TNullable<T>);
begin
  Dest.FHasValue := Src.FHasValue;
  Dest.FValue := Src.FValue;
end;
{$ENDIF}

class operator TNullable<T>.Implicit(const Value: TNullable<T>): T;
begin
  Result := Value.FValue;
end;

class operator TNullable<T>.Implicit(const Value: TNullable<T>): Variant;
begin
  if Value.FHasValue then
    Result := TValue.From<T>(Value.FValue).AsVariant
  else
    Result := Null;
end;

class operator TNullable<T>.Implicit(const Value: Pointer): TNullable<T>;
begin
  if Value = nil then
    Result.Clear
  else
    Result := TNullable<T>.Create(T(Value^));
end;

class operator TNullable<T>.Implicit(const Value: Variant): TNullable<T>;
begin
  if VarIsNull(Value) then
    Result.Clear
  else
  begin
    Result.FHasValue := True;
    Result.FValue := TValue.FromVariant(Value).AsType<T>;
  end;
end;

class operator TNullable<T>.Implicit(const Value: T): TNullable<T>;
begin
  Result := TNullable<T>.Create(Value);
end;

class operator TNullable<T>.Equal(const Left, Right: TNullable<T>): Boolean;
begin
  Result := Left.Equals(Right);
end;

class operator TNullable<T>.NotEqual(const Left, Right: TNullable<T>): Boolean;
begin
  Result := not Left.Equals(Right);
end;

constructor TNullable<T>.Create(const Value: T);
begin
  FHasValue := True;
  FValue := Value;
end;

function TNullable<T>.Equals(const Value: TNullable<T>): Boolean;
begin
  if FHasValue and Value.FHasValue then
    Result := TEqualityComparer<T>.Default.Equals(Self.FValue, Value.FValue)
  else
    Result := FHasValue = Value.FHasValue;
end;

procedure TNullable<T>.Clear;
begin
  FHasValue := False;
  FValue := Default(T);
end;

function TNullable<T>.GetValueOrDefault: T;
begin
  Result := GetValueOrDefault(Default(T));
end;

function TNullable<T>.GetValueOrDefault(const Default: T): T;
begin
  if HasValue then
    Result := FValue
  else
    Result := Default;
end;

function TNullable<T>.GetValue: T;
begin
  if FHasValue then
    Result := FValue
  else
    raise EInvalidOpException.CreateRes(@RNullableNoValue);
end;

procedure TNullableStreamWriter.WriteString(const AString: string);
var
  Len: Integer;
begin
  Len := Length(AString);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    WriteBuffer(Pointer(AString)^, Len * SizeOf(Char));
end;

function TNullableStreamWriter.ReadString: string;
var
  StrLen : integer;
  TempStr: string;
begin
  TempStr := '';
  ReadBuffer(StrLen, SizeOf(StrLen));
  if StrLen > -1 then
  begin
    SetLength(TempStr, StrLen);
    ReadBuffer(Pointer(TempStr)^, StrLen * SizeOf(Char));
    Result := TempStr;
  end
  else
    Result := '';
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Boolean>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Byte>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Integer>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Int64>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Double>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<Currency>);
begin
  Write(ANullable, SizeOf(ANullable));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<string>);
var
  HasValue: LongBool;
begin
  HasValue := ANullable.FHasValue;
  Write(HasValue, SizeOf(HasValue));
  WriteString(ANullable.FValue);
end;

{$IF DEFINED(WIN32) OR DEFINED(WIN64)}
procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<AnsiString>);
var
  Len: Integer;
begin
  Write(ANullable.FHasValue, SizeOf(ANullable.FHasValue));

  Len := Length(ANullable.GetValueOrDefault);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    WriteBuffer(Pointer(ANullable.Value)^, Len * SizeOf(AnsiChar));
end;
{$ENDIF}

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<TDate>);
var
  HasValue: LongBool;
  Year, Month, Day: Word;
begin
  DecodeDate(ANullable.FValue, Year, Month, Day);
  HasValue := ANullable.FHasValue;
  Write(HasValue, SizeOf(HasValue));
  Write(Year, SizeOf(Year));
  Write(Month, SizeOf(Month));
  Write(Day, SizeOf(Day));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<TTime>);
var
  HasValue: LongBool;
  Hour, Minute, Second, MilliSecond: Word;
begin
  DecodeTime(ANullable.FValue, Hour, Minute, Second, MilliSecond);
  HasValue := ANullable.FHasValue;
  Write(HasValue, SizeOf(HasValue));
  Write(Hour, SizeOf(Hour));
  Write(Minute, SizeOf(Minute));
  Write(Second, SizeOf(Second));
  Write(MilliSecond, SizeOf(MilliSecond));
end;

procedure TNullableStreamWriter.WriteNullable(ANullable: TNullable<TDateTime>);
var
  HasValue: LongBool;
  Year, Month, Day: Word;
  Hour, Minute, Second, MilliSecond: Word;
begin
  DecodeDateTime(ANullable.FValue, Year, Month, Day, Hour, Minute, Second, MilliSecond);
  HasValue := ANullable.FHasValue;
  Write(HasValue, SizeOf(HasValue));
  Write(Year, SizeOf(Year));
  Write(Month, SizeOf(Month));
  Write(Day, SizeOf(Day));
  Write(Hour, SizeOf(Hour));
  Write(Minute, SizeOf(Minute));
  Write(Second, SizeOf(Second));
  Write(MilliSecond, SizeOf(MilliSecond));
end;

function TNullableStreamWriter.ReadNullableBoolean: Variant;
var
  V: TNullable<Boolean>;
begin
  Read(V, SizeOf(V));
  if V.HasValue then
    Result := V.Value
  else
    Result := Null;
end;

function TNullableStreamWriter.ReadNullableByte: TNullable<Byte>;
begin
  Read(Result, SizeOf(Result));
end;

function TNullableStreamWriter.ReadNullableInteger: TNullable<Integer>;
begin
  Read(Result, SizeOf(Result));
end;

function TNullableStreamWriter.ReadNullableInt64: TNullable<Int64>;
begin
  Read(Result, SizeOf(Result));
end;

function TNullableStreamWriter.ReadNullableDouble: TNullable<Double>;
begin
  Read(Result, SizeOf(Result));
end;

function TNullableStreamWriter.ReadNullableCurrency: TNullable<Currency>;
begin
  Read(Result, SizeOf(Result));
end;

function TNullableStreamWriter.ReadNullableString: TNullable<string>;
var
  HasValue: LongBool;
begin
  Read(HasValue, SizeOf(HasValue));
  Result.FHasValue := HasValue;
  Result.FValue := ReadString;
end;

{$IF DEFINED(WIN32) OR DEFINED(WIN64)}
function TNullableStreamWriter.ReadNullableAnsiString: TNullable<AnsiString>;
var
  StrLen : integer;
  TempStr: AnsiString;
begin
  Read(Result.FHasValue, SizeOf(Result.FHasValue));
  TempStr := '';
  ReadBuffer(StrLen, SizeOf(StrLen));
  if StrLen > -1 then
  begin
    SetLength(TempStr, StrLen);
    ReadBuffer(Pointer(TempStr)^, StrLen * SizeOf(AnsiChar));
    Result := TNullable<AnsiString>.Create(TempStr);
  end
  else
    Result.Clear;
end;
{$ENDIF}

function TNullableStreamWriter.ReadNullableDate: TNullable<TDate>;
var
  HasValue: LongBool;
  Year, Month, Day: Word;
begin
  Read(HasValue, SizeOf(HasValue));
  Result.FHasValue := HasValue;
  Read(Year, SizeOf(Year));
  Read(Month, SizeOf(Month));
  Read(Day, SizeOf(Day));
  Result.FValue := EncodeDate(Year, Month, Day);
end;

function TNullableStreamWriter.ReadNullableTime: TNullable<TTime>;
var
  HasValue: LongBool;
  Hour, Minute, Second, MilliSecond: Word;
begin
  Read(HasValue, SizeOf(HasValue));
  Result.FHasValue := HasValue;
  Read(Hour, SizeOf(Hour));
  Read(Minute, SizeOf(Minute));
  Read(Second, SizeOf(Second));
  Read(MilliSecond, SizeOf(MilliSecond));
  Result.FValue := EncodeTime(Hour, Minute, Second, MilliSecond);
end;

function TNullableStreamWriter.ReadNullableDateTime: TNullable<TDateTime>;
var
  HasValue: LongBool;
  Year, Month, Day, Hour, Minute, Second, MilliSecond: Word;
begin
  Read(HasValue, SizeOf(HasValue));
  Result.FHasValue := HasValue;
  Read(Year, SizeOf(Year));
  Read(Month, SizeOf(Month));
  Read(Day, SizeOf(Day));
  Read(Hour, SizeOf(Hour));
  Read(Minute, SizeOf(Minute));
  Read(Second, SizeOf(Second));
  Read(MilliSecond, SizeOf(MilliSecond));
  Result.FValue := EncodeDateTime(Year, Month, Day, Hour, Minute, Second, MilliSecond);
end;

end.
