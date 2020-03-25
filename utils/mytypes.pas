unit mytypes;

interface

uses windows;

{$IFNDEF FPC}
const
  CP_ACP = windows.CP_ACP;
{$ENDIF}

type
{$IFNDEF FPC}
  {$IFDEF WIN32}
  // delphi 64 must have these types anyway
  int_ptr   = integer;
  uint_ptr  = cardinal;
  {$ENDIF}
  long      = longint;
  plong     = ^long;
  {$IFDEF VER130}
  uint64    = int64;
  pword     = ^word;
  pinteger  = ^integer;
  pcardinal = ^cardinal;
  pbyte     = ^byte;
  IntPtr    = longint;
  UIntPtr   = longword;
  {$ENDIF}
  {$IFDEF VER150}
  UnicodeString = WideString;
  ULONG_PTR = longword;
  {$ENDIF}
  DWORD_PTR = ULONG_PTR;
  size_t    = ULONG_PTR;
  PIntPtr   = ^IntPtr;
  PUIntPtr  = ^UIntPtr;
{$ENDIF}
  pint_ptr  = ^int_ptr;
  puint_ptr = ^uint_ptr;
  time_t    = ulong;
  int       = integer;
  TLPARAM   = LPARAM;
  TWPARAM   = WPARAM;

{$IFDEF FPC}
  TWNDPROC = WNDPROC;
{$ELSE}
  TWNDPROC = TFNWndProc;
{$ENDIF}

implementation

end.