unit myconsole;

interface

const
  CL_RESET = #27'[0m'; // reset color parameter
  CL_CLS   = #27'[2J'; // clear screen and go up/left (0, 0 position)
  CL_CLL   = #27'[K';  // clear line from actual position to end of the line

// font settings
  CL_BOLD   = #27'[1m'; // use bold for font
  CL_NORM   = CL_RESET;
  CL_NORMAL = CL_RESET;
  CL_NONE   = CL_RESET;
// foreground color and bold font (bright color on windows)
  CL_GRAY    = #27'[1;30m';
  CL_RED     = #27'[1;31m';
  CL_GREEN   = #27'[1;32m';
  CL_YELLOW  = #27'[1;33m';
  CL_BLUE    = #27'[1;34m';
  CL_MAGENTA = #27'[1;35m';
  CL_CYAN    = #27'[1;36m';
  CL_WHITE   = #27'[1;37m';

// background color
  CL_BG_BLACK   = #27'[40m';
  CL_BG_RED     = #27'[41m';
  CL_BG_GREEN   = #27'[42m';
  CL_BG_YELLOW  = #27'[43m';
  CL_BG_BLUE    = #27'[44m';
  CL_BG_MAGENTA = #27'[45m';
  CL_BG_CYAN    = #27'[46m';
  CL_BG_WHITE   = #27'[47m';
// foreground color and normal font (normal color on windows)
  CL_LT_BLACK   = #27'[0;30m';
  CL_LT_RED     = #27'[0;31m';
  CL_LT_GREEN   = #27'[0;32m';
  CL_LT_YELLOW  = #27'[0;33m';
  CL_LT_BLUE    = #27'[0;34m';
  CL_LT_MAGENTA = #27'[0;35m';
  CL_LT_CYAN    = #27'[0;36m';
  CL_LT_WHITE   = #27'[0;37m';
// foreground color and bold font (bright color on windows)
  CL_BT_BLACK   = #27'[1;30m';
  CL_BT_RED     = #27'[1;31m';
  CL_BT_GREEN   = #27'[1;32m';
  CL_BT_YELLOW  = #27'[1;33m';
  CL_BT_BLUE    = #27'[1;34m';
  CL_BT_MAGENTA = #27'[1;35m';
  CL_BT_CYAN    = #27'[1;36m';
  CL_BT_WHITE   = #27'[1;37m';

  CL_WTBL     = #27'[37;44m';   // white on blue
  CL_XXBL     = #27'[0;44m';    // default on blue
  CL_PASS     = #27'[0;32;42m'; // green on green

implementation

end.
