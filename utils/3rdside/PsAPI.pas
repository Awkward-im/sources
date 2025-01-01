{$T-}
{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{                                                       }
{     Copyright (c) 1985-1999, Microsoft Corporation    }
{                                                       }
{       Translator: Borland Software Corporation        }
{                                                       }
{*******************************************************}

{*******************************************************}
{       WinNT process API Interface Unit                }
{*******************************************************}

unit PsAPI;

interface

uses Windows;

type
  PPointer = ^Pointer;
  PHMODULE = ^HMODULE;
{$IFNDEF FPC}
  size_t   = integer;
{$ENDIF}

  TEnumProcesses        = function (lpidProcess: LPDWORD; cb: DWORD; var cbNeeded: DWORD): BOOL stdcall;
  TEnumProcessModules   = function (hProcess:THANDLE; lphModule: PHMODULE; cb: DWORD; var lpcbNeeded: DWORD): BOOL stdcall;
  TGetModuleBaseNameA   = function (hProcess:THANDLE; hModule:HMODULE; lpBaseName:PAnsiChar; nSize:DWORD): DWORD stdcall;
  TGetModuleBaseNameW   = function (hProcess:THANDLE; hModule:HMODULE; lpBaseName:PWideChar; nSize:DWORD): DWORD stdcall;
  TGetModuleBaseName    = TGetModuleBaseNameW;
  TGetModuleFileNameExA = function (hProcess:THANDLE; hModule:HMODULE; lpFilename:PAnsiChar; nSize:DWORD): DWORD stdcall;
  TGetModuleFileNameExW = function (hProcess:THANDLE; hModule:HMODULE; lpFilename:PWideChar; nSize:DWORD): DWORD stdcall;
  TGetModuleFileNameEx = TGetModuleFileNameExW;

  _MODULEINFO = packed record
    lpBaseOfDll: Pointer;
    SizeOfImage: DWORD;
    EntryPoint : Pointer;
  end;
  MODULEINFO   =  _MODULEINFO;
  LPMODULEINFO = ^_MODULEINFO;
  TModuleInfo  =  _MODULEINFO;
  PModuleInfo  = LPMODULEINFO;

  TGetModuleInformation        = function (hProcess:THANDLE; hModule:HMODULE; lpmodinfo:LPMODULEINFO; cb:DWORD): BOOL stdcall;
  TQueryWorkingSet             = function (hProcess:THANDLE; pv:Pointer; cb:DWORD): BOOL stdcall;
  TEmptyWorkingSet             = function (hProcess:THANDLE): BOOL stdcall;
  TInitializeProcessForWsWatch = function (hProcess:THANDLE): BOOL stdcall;

  _PSAPI_WS_WATCH_INFORMATION = packed record
    FaultingPc: Pointer;
    FaultingVa: Pointer;
  end;
  PSAPI_WS_WATCH_INFORMATION  =  _PSAPI_WS_WATCH_INFORMATION;
  PPSAPI_WS_WATCH_INFORMATION = ^_PSAPI_WS_WATCH_INFORMATION;
  TPSAPIWsWatchInformation    =  _PSAPI_WS_WATCH_INFORMATION;
  PPSAPIWsWatchInformation    =  PPSAPI_WS_WATCH_INFORMATION;

  TGetWsChanges = function (hProcess: THandle; lpWatchInfo: PPSAPI_WS_WATCH_INFORMATION;
    cb: DWORD): BOOL stdcall;

  TGetMappedFileNameA = function (hProcess:THANDLE; lpv:Pointer; lpFilename:PAnsiChar; nSize:DWORD): DWORD stdcall;
  TGetMappedFileNameW = function (hProcess:THANDLE; lpv:Pointer; lpFilename:PWideChar; nSize:DWORD): DWORD stdcall;
  TGetMappedFileName = TGetMappedFileNameW;
  TGetDeviceDriverBaseNameA = function (ImageBase: Pointer; lpBaseName: PAnsiChar; nSize: DWORD): DWORD stdcall;
  TGetDeviceDriverBaseNameW = function (ImageBase: Pointer; lpBaseName: PWideChar; nSize: DWORD): DWORD stdcall;
  TGetDeviceDriverBaseName  = TGetDeviceDriverBaseNameW;
  TGetDeviceDriverFileNameA = function (ImageBase: Pointer; lpFileName: PAnsiChar; nSize: DWORD): DWORD stdcall;
  TGetDeviceDriverFileNameW = function (ImageBase: Pointer; lpFileName: PWideChar; nSize: DWORD): DWORD stdcall;
  TGetDeviceDriverFileName  = TGetDeviceDriverFileNameW;
  TGetProcessImageFileNameA = function (hProcess: HANDLE; lpImageFileName: PAnsiChar; nSize: DWORD): DWORD; stdcall;
  TGetProcessImageFileNameW = function (hProcess: HANDLE; lpImageFileName: PWideChar; nSize: DWORD): DWORD; stdcall;
  TGetProcessImageFileName  = TGetProcessImageFileNameW;

  TEnumDeviceDrivers = function (lpImageBase: PPointer; cb: DWORD; var lpcbNeeded: DWORD): BOOL stdcall;

  _PROCESS_MEMORY_COUNTERS = packed record
    cb                        : DWORD;
    PageFaultCount            : DWORD;
    PeakWorkingSetSize        : size_t;
    WorkingSetSize            : size_t;
    QuotaPeakPagedPoolUsage   : size_t;
    QuotaPagedPoolUsage       : size_t;
    QuotaPeakNonPagedPoolUsage: size_t;
    QuotaNonPagedPoolUsage    : size_t;
    PagefileUsage             : size_t;
    PeakPagefileUsage         : size_t;
  end;
  PROCESS_MEMORY_COUNTERS  =  _PROCESS_MEMORY_COUNTERS;
  PPROCESS_MEMORY_COUNTERS = ^_PROCESS_MEMORY_COUNTERS;
  TProcessMemoryCounters   =  _PROCESS_MEMORY_COUNTERS;
  PProcessMemoryCounters   = ^_PROCESS_MEMORY_COUNTERS;

  TGetProcessMemoryInfo = function (Process: THandle;
    ppsmemCounters: PPROCESS_MEMORY_COUNTERS; cb: DWORD): BOOL stdcall;

function EnumProcesses(lpidProcess: LPDWORD; cb: DWORD; var cbNeeded: DWORD): BOOL;
function EnumProcessModules  (hProcess:THANDLE; lphModule:PHMODULE ; cb: DWORD; var lpcbNeeded: DWORD): BOOL;
function GetModuleBaseName   (hProcess:THANDLE; hModule:HMODULE; lpBaseName:PWideChar; nSize:DWORD): DWORD;
function GetModuleBaseNameA  (hProcess:THANDLE; hModule:HMODULE; lpBaseName:PAnsiChar; nSize:DWORD): DWORD;
function GetModuleBaseNameW  (hProcess:THANDLE; hModule:HMODULE; lpBaseName:PWideChar; nSize:DWORD): DWORD;
function GetModuleFileNameEx (hProcess:THANDLE; hModule:HMODULE; lpFilename:PWideChar; nSize:DWORD): DWORD;
function GetModuleFileNameExA(hProcess:THANDLE; hModule:HMODULE; lpFilename:PAnsiChar; nSize:DWORD): DWORD;
function GetModuleFileNameExW(hProcess:THANDLE; hModule:HMODULE; lpFilename:PWideChar; nSize:DWORD): DWORD;
function GetModuleInformation(hProcess:THANDLE; hModule:HMODULE; lpmodinfo: LPMODULEINFO; cb:DWORD): BOOL;
function GetMappedFileName   (hProcess:THANDLE; lpv:Pointer; lpFilename:PWideChar; nSize:DWORD): DWORD;
function GetMappedFileNameA  (hProcess:THANDLE; lpv:Pointer; lpFilename:PAnsiChar; nSize:DWORD): DWORD;
function GetMappedFileNameW  (hProcess:THANDLE; lpv:Pointer; lpFilename:PWideChar; nSize:DWORD): DWORD;
function GetProcessImageFileNameA(hProcess: THANDLE; lpImageFileName: PAnsiChar; nSize: DWORD): DWORD;
function GetProcessImageFileNameW(hProcess: THANDLE; lpImageFileName: PWideChar; nSize: DWORD): DWORD;
function GetProcessImageFileName (hProcess: THANDLE; lpImageFileName: PWideChar; nSize: DWORD): DWORD;
function EmptyWorkingSet            (hProcess: THANDLE): BOOL;
function QueryWorkingSet            (hProcess: THANDLE; pv: Pointer; cb: DWORD): BOOL;
function InitializeProcessForWsWatch(hProcess: THANDLE): BOOL;
function GetDeviceDriverBaseName (ImageBase: Pointer; lpBaseName: PWideChar; nSize: DWORD): DWORD;
function GetDeviceDriverBaseNameA(ImageBase: Pointer; lpBaseName: PAnsiChar; nSize: DWORD): DWORD;
function GetDeviceDriverBaseNameW(ImageBase: Pointer; lpBaseName: PWideChar; nSize: DWORD): DWORD;
function GetDeviceDriverFileName (ImageBase: Pointer; lpFileName: PWideChar; nSize: DWORD): DWORD;
function GetDeviceDriverFileNameA(ImageBase: Pointer; lpFileName: PAnsiChar; nSize: DWORD): DWORD;
function GetDeviceDriverFileNameW(ImageBase: Pointer; lpFileName: PWideChar; nSize: DWORD): DWORD;
function EnumDeviceDrivers(lpImageBase: PPointer; cb: DWORD; var lpcbNeeded: DWORD): BOOL;
function GetProcessMemoryInfo(Process: THANDLE; ppsmemCounters: PPROCESS_MEMORY_COUNTERS; cb: DWORD): BOOL;


implementation

var
  hPSAPI: THANDLE;
var
  _EnumProcesses              : TEnumProcesses;
  _EnumProcessModules         : TEnumProcessModules;
  _GetModuleBaseName          : TGetModuleBaseNameW;
  _GetModuleFileNameEx        : TGetModuleFileNameExW;
  _GetModuleBaseNameA         : TGetModuleBaseNameA;
  _GetModuleFileNameExA       : TGetModuleFileNameExA;
  _GetModuleBaseNameW         : TGetModuleBaseNameW;
  _GetModuleFileNameExW       : TGetModuleFileNameExW;
  _GetModuleInformation       : TGetModuleInformation;
  _EmptyWorkingSet            : TEmptyWorkingSet;
  _QueryWorkingSet            : TQueryWorkingSet;
  _InitializeProcessForWsWatch: TInitializeProcessForWsWatch;
  _GetMappedFileName          : TGetMappedFileNameW;
  _GetDeviceDriverBaseName    : TGetDeviceDriverBaseNameW;
  _GetDeviceDriverFileName    : TGetDeviceDriverFileNameW;
  _GetMappedFileNameA         : TGetMappedFileNameA;
  _GetDeviceDriverBaseNameA   : TGetDeviceDriverBaseNameA;
  _GetDeviceDriverFileNameA   : TGetDeviceDriverFileNameA;
  _GetMappedFileNameW         : TGetMappedFileNameW;
  _GetDeviceDriverBaseNameW   : TGetDeviceDriverBaseNameW;
  _GetDeviceDriverFileNameW   : TGetDeviceDriverFileNameW;
  _EnumDeviceDrivers          : TEnumDeviceDrivers;
  _GetProcessMemoryInfo       : TGetProcessMemoryInfo;
  _GetProcessImageFileName    : TGetProcessImageFileName;
  _GetProcessImageFileNameA   : TGetProcessImageFileNameA;
  _GetProcessImageFileNameW   : TGetProcessImageFileNameW;

function CheckPSAPILoaded: Boolean;
begin
  if hPSAPI = 0 then
  begin
    hPSAPI := LoadLibrary('PSAPI.dll');
    if hPSAPI < 32 then
    begin
      hPSAPI := 0;
      Result := False;
      Exit;
    end;
    _EnumProcesses               := TEnumProcesses              (GetProcAddress(hPSAPI, PAnsiChar('EnumProcesses')));
    _EnumProcessModules          := TEnumProcessModules         (GetProcAddress(hPSAPI, PAnsiChar('EnumProcessModules')));
    _GetModuleBaseName           := TGetModuleBaseNameW         (GetProcAddress(hPSAPI, PAnsiChar('GetModuleBaseNameW')));
    _GetModuleFileNameEx         := TGetModuleFileNameEx        (GetProcAddress(hPSAPI, PAnsiChar('GetModuleFileNameExW')));
    _GetModuleBaseNameA          := TGetModuleBaseNameA         (GetProcAddress(hPSAPI, PAnsiChar('GetModuleBaseNameA')));
    _GetModuleFileNameExA        := TGetModuleFileNameExA       (GetProcAddress(hPSAPI, PAnsiChar('GetModuleFileNameExA')));
    _GetModuleBaseNameW          := TGetModuleBaseNameW         (GetProcAddress(hPSAPI, PAnsiChar('GetModuleBaseNameW')));
    _GetModuleFileNameExW        := TGetModuleFileNameExW       (GetProcAddress(hPSAPI, PAnsiChar('GetModuleFileNameExW')));
    _GetModuleInformation        := TGetModuleInformation       (GetProcAddress(hPSAPI, PAnsiChar('GetModuleInformation')));
    _EmptyWorkingSet             := TEmptyWorkingSet            (GetProcAddress(hPSAPI, PAnsiChar('EmptyWorkingSet')));
    _QueryWorkingSet             := TQueryWorkingSet            (GetProcAddress(hPSAPI, PAnsiChar('QueryWorkingSet')));
    _InitializeProcessForWsWatch := TInitializeProcessForWsWatch(GetProcAddress(hPSAPI, PAnsiChar('InitializeProcessForWsWatch')));
    _GetMappedFileName           := TGetMappedFileName          (GetProcAddress(hPSAPI, PAnsiChar('GetMappedFileNameW')));
    _GetDeviceDriverBaseName     := TGetDeviceDriverBaseName    (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverBaseNameW')));
    _GetDeviceDriverFileName     := TGetDeviceDriverFileName    (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverFileNameW')));
    _GetMappedFileNameA          := TGetMappedFileNameA         (GetProcAddress(hPSAPI, PAnsiChar('GetMappedFileNameA')));
    _GetDeviceDriverBaseNameA    := TGetDeviceDriverBaseNameA   (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverBaseNameA')));
    _GetDeviceDriverFileNameA    := TGetDeviceDriverFileNameA   (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverFileNameA')));
    _GetMappedFileNameW          := TGetMappedFileNameW         (GetProcAddress(hPSAPI, PAnsiChar('GetMappedFileNameW')));
    _GetDeviceDriverBaseNameW    := TGetDeviceDriverBaseNameW   (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverBaseNameW')));
    _GetDeviceDriverFileNameW    := TGetDeviceDriverFileNameW   (GetProcAddress(hPSAPI, PAnsiChar('GetDeviceDriverFileNameW')));
    _EnumDeviceDrivers           := TEnumDeviceDrivers          (GetProcAddress(hPSAPI, PAnsiChar('EnumDeviceDrivers')));
    _GetProcessMemoryInfo        := TGetProcessMemoryInfo       (GetProcAddress(hPSAPI, PAnsiChar('GetProcessMemoryInfo')));
    _GetProcessImageFileNameA    := TGetProcessImageFileNameA   (GetProcAddress(hPSAPI, PAnsiChar('GetProcessImageFileNameA')));
    _GetProcessImageFileNameW    := TGetProcessImageFileNameW   (GetProcAddress(hPSAPI, PAnsiChar('GetProcessImageFileNameW')));
    _GetProcessImageFileName     := TGetProcessImageFileName    (GetProcAddress(hPSAPI, PAnsiChar('GetProcessImageFileNameW')));
  end;
  Result := True;
end;

function EnumProcesses(lpidProcess: LPDWORD; cb: DWORD; var cbNeeded: DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _EnumProcesses(lpidProcess, cb, cbNeeded)
  else Result := False;
end;

function EnumProcessModules(hProcess:THANDLE; lphModule:PHMODULE; cb:DWORD; var lpcbNeeded:DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _EnumProcessModules(hProcess, lphModule, cb, lpcbNeeded)
  else Result := False;
end;

function GetProcessImageFileName(hProcess: HANDLE; lpImageFileName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetProcessImageFileName(hProcess, lpImageFileName, nSize)
  else Result := 0;
end;

function GetProcessImageFileNameA(hProcess: HANDLE; lpImageFileName: PAnsiChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetProcessImageFileNameA(hProcess, lpImageFileName, nSize)
  else Result := 0;
end;

function GetProcessImageFileNameW(hProcess: HANDLE; lpImageFileName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetProcessImageFileNameW(hProcess, lpImageFileName, nSize)
  else Result := 0;
end;

function GetModuleBaseName(hProcess:THANDLE; hModule:HMODULE; lpBaseName:PWideChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleBaseName(hProcess, hModule, lpBaseName, nSize)
  else Result := 0;
end;

function GetModuleBaseNameA(hProcess:THANDLE; hModule:HMODULE; lpBaseName:PAnsiChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleBaseNameA(hProcess, hModule, lpBaseName, nSize)
  else Result := 0;
end;

function GetModuleBaseNameW(hProcess:THANDLE; hModule:HMODULE; lpBaseName:PWideChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleBaseNameW(hProcess, hModule, lpBaseName, nSize)
  else Result := 0;
end;

function GetModuleFileNameEx(hProcess:THANDLE; hModule:HMODULE; lpFilename:PWideChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleFileNameEx(hProcess, hModule, lpFileName, nSize)
  else Result := 0;
end;

function GetModuleFileNameExA(hProcess:THANDLE; hModule:HMODULE; lpFilename:PAnsiChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleFileNameExA(hProcess, hModule, lpFileName, nSize)
  else Result := 0;
end;

function GetModuleFileNameExW(hProcess:THANDLE; hModule:HMODULE; lpFilename:PWideChar; nSize:DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleFileNameExW(hProcess, hModule, lpFileName, nSize)
  else Result := 0;
end;

function GetModuleInformation(hProcess:THANDLE; hModule:HMODULE; lpmodinfo:LPMODULEINFO; cb:DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _GetModuleInformation(hProcess, hModule, lpmodinfo, cb)
  else Result := False;
end;

function EmptyWorkingSet(hProcess: THandle): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _EmptyWorkingSet(hProcess)
  else Result := False;
end;

function QueryWorkingSet(hProcess: THandle; pv: Pointer; cb: DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _QueryWorkingSet(hProcess, pv, cb)
  else Result := False;
end;

function InitializeProcessForWsWatch(hProcess: THandle): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _InitializeProcessForWsWatch(hProcess)
  else Result := False;
end;

function GetMappedFileName(hProcess: THandle; lpv: Pointer; lpFilename: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetMappedFileName(hProcess, lpv, lpFileName, nSize)
  else Result := 0;
end;

function GetMappedFileNameA(hProcess: THandle; lpv: Pointer; lpFilename: PAnsiChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetMappedFileNameA(hProcess, lpv, lpFileName, nSize)
  else Result := 0;
end;

function GetMappedFileNameW(hProcess: THandle; lpv: Pointer; lpFilename: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetMappedFileNameW(hProcess, lpv, lpFileName, nSize)
  else Result := 0;
end;

function GetDeviceDriverBaseName(ImageBase: Pointer; lpBaseName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverBasename(ImageBase, lpBaseName, nSize)
  else Result := 0;
end;

function GetDeviceDriverBaseNameA(ImageBase: Pointer; lpBaseName: PAnsiChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverBasenameA(ImageBase, lpBaseName, nSize)
  else Result := 0;
end;

function GetDeviceDriverBaseNameW(ImageBase: Pointer; lpBaseName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverBasenameW(ImageBase, lpBaseName, nSize)
  else Result := 0;
end;

function GetDeviceDriverFileName(ImageBase: Pointer; lpFileName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverFileName(ImageBase, lpFileName, nSize)
  else Result := 0;
end;

function GetDeviceDriverFileNameA(ImageBase: Pointer; lpFileName: PAnsiChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverFileNameA(ImageBase, lpFileName, nSize)
  else Result := 0;
end;

function GetDeviceDriverFileNameW(ImageBase: Pointer; lpFileName: PWideChar; nSize: DWORD): DWORD;
begin
  if CheckPSAPILoaded then
    Result := _GetDeviceDriverFileNameW(ImageBase, lpFileName, nSize)
  else Result := 0;
end;

function EnumDeviceDrivers(lpImageBase: PPointer; cb: DWORD; var lpcbNeeded: DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _EnumDeviceDrivers(lpImageBase, cb, lpcbNeeded)
  else Result := False;
end;

function GetProcessMemoryInfo(Process: THANDLE; ppsmemCounters: PPROCESS_MEMORY_COUNTERS; cb: DWORD): BOOL;
begin
  if CheckPSAPILoaded then
    Result := _GetProcessMemoryInfo(Process, ppsmemCounters, cb)
  else Result := False;
end;

end.
