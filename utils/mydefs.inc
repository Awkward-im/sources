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

  {$IFDEF MSWINDOWS}
    {$DEFINE CallConv := stdcall}
  {$ELSE}
    {$DEFINE CallConv := cdecl}
  {$ENDIF}

  {$DEFINE dbass := fpc.dynamic_bass}

{$ENDIF}
