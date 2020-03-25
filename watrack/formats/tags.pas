unit tags;
{$include compilers.inc}
interface

{$DEFINE Interface}
{$include tag_id3v2.inc}
{$include tag_id3v1.inc}
{$include tag_apev2.inc}

implementation

uses
  wat_api,
  common,
  awkmedia,
  utils;

{$UNDEF Interface}
{$include tag_id3v2.inc}
{$include tag_id3v1.inc}
{$include tag_apev2.inc}

end.
