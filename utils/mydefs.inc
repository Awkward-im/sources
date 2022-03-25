{.$DEFINE UseWinAPI}
{$I-}
{$UNDEF AllowInline}

{$IFDEF FPC}
  {$mode objfpc}
  {$modeswitch advancedrecords}

  {$MACRO ON}
  {$INLINE ON} // default for Delphi and ObjFPC modes
  {$DEFINE AllowInline}
  {.$INCLUDE Header.inc}

  //----- Aliases -----
(*
  {$IFDEF MSWINDOWS}
    {$DEFINE WinAPI := stdcall}
  {$ELSE}
    {$DEFINE WinAPI := cdecl}
  {$ENDIF}
*)
  {$DEFINE dbass := fpc.dynamic_bass}

{$ENDIF}
