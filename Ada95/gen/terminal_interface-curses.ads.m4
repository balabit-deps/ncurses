--  -*- ada -*-
define(`HTMLNAME',`terminal_interface-curses_s.html')dnl
include(M4MACRO)------------------------------------------------------------------------------
--                                                                          --
--                           GNAT ncurses Binding                           --
--                                                                          --
--                         Terminal_Interface.Curses                        --
--                                                                          --
--                                 S P E C                                  --
--                                                                          --
--  Version 00.93                                                           --
--                                                                          --
--  The ncurses Ada95 binding is copyrighted 1996 by                        --
--  Juergen Pfeifer, Email: Juergen.Pfeifer@T-Online.de                     --
--                                                                          --
--  Permission is hereby granted to reproduce and distribute this           --
--  binding by any means and for any fee, whether alone or as part          --
--  of a larger distribution, in source or in binary form, PROVIDED         --
--  this notice is included with any such distribution, and is not          --
--  removed from any of its header files. Mention of ncurses and the        --
--  author of this binding in any applications linked with it is            --
--  highly appreciated.                                                     --
--                                                                          --
--  This binding comes AS IS with no warranty, implied or expressed.        --
------------------------------------------------------------------------------
--  Version Control:
--  $Revision: 1.11 $
------------------------------------------------------------------------------
include(`Base_Defs')
with System;
with Interfaces.C;   --  We need this for some assertions.

package Terminal_Interface.Curses is
   pragma Preelaborate (Curses);
include(`Linker_Options')
   type Window is private;
   Null_Window : constant Window;

   type Line_Position   is new Natural; --  line coordinate
   type Column_Position is new Natural; --  column coordinate

   subtype Line_Count   is Line_Position   range 1 .. Line_Position'Last;
   --  Type to count lines. We do not allow null windows, so must be positive
   subtype Column_Count is Column_Position range 1 .. Column_Position'Last;
   --  Type to count columns. We do not allow null windows, so must be positive

   type Key_Code is new Natural;
   --  That is anything including real characters, special keys and logical
   --  request codes.

   subtype Real_Key_Code is Key_Code range 0 .. M4_KEY_MAX;
   --  This are the codes that potentially represent a real keystroke.
   --  Not all codes may be possible on a specific terminal. To check the
   --  availability of a special key, the Has_Key function is provided.

   subtype Special_Key_Code is Real_Key_Code
     range M4_SPECIAL_FIRST .. Real_Key_Code'Last;
   --  Type for a function- or special key number

   subtype Normal_Key_Code is Real_Key_Code range
     Character'Pos (Character'First) .. Character'Pos (Character'Last);
   --  This are the codes for regular (incl. non-graphical) characters.

   --  Constants for function- and special keys
   --
   Key_None                       : constant Special_Key_Code := M4_SPECIAL_FIRST;
include(`Key_Definitions')
   Key_Max                        : constant Special_Key_Code
     := Special_Key_Code'Last;

   subtype User_Key_Code is Key_Code
     range (Key_Max + 129) .. Key_Code'Last;
   --  This is reserved for user defined key codes. The range between Key_Max
   --  and the first user code is reserved for subsystems like menu and forms.

   --  For those who like to use the original key names we produce them were
   --  they differ from the original. Please note that they may differ in
   --  lower/upper case.
include(`Old_Keys')

------------------------------------------------------------------------------

   type Color_Number is range 0 .. Integer (Interfaces.C.short'Last);
   for Color_Number'Size use Interfaces.C.short'Size;
   --  (n)curses uses a short for the color index
   --  The model is, that a Color_Number is an index into an array of
   --  (potentially) definable colors. Some of those indices are
   --  predefined (see below), although they may not really exist.

include(`Color_Defs')
   type RGB_Value is range 0 .. Integer (Interfaces.C.Short'Last);
   for RGB_Value'Size use Interfaces.C.short'Size;
   --  Some system may allow to redefine a color by setting RGB values.

   type Color_Pair is range 0 .. 255;
   for Color_Pair'Size use 8;
   subtype Redefinable_Color_Pair is Color_Pair range 1 .. 255;
   --  (n)curses reserves 1 Byte for the color-pair number. Color Pair 0
   --  is fixed (Black & White). A color pair is simply a combination of
   --  two colors described by Color_Numbers, one for the foreground and
   --  the other for the background

include(`Character_Attribute_Set_Rep')
   --  (n)curses uses half of an integer for attributes.

   Normal_Video : constant Character_Attribute_Set := (others => False);

   type Attributed_Character is
      record
         Attr  : Character_Attribute_Set := Normal_Video;
         Color : Color_Pair := 0;
         Ch    : Character  := ' ';
      end record;
   pragma Convention (C, Attributed_Character);
   --  This is the counterpart for the chtype in C.

include(`AC_Rep')
   Default_Character : constant Attributed_Character
     := (Ch    => Character'First,
         Color => Color_Pair'First,
         Attr  => Normal_Video);

   type Attributed_String is array (Positive range <>) of Attributed_Character;
   pragma Pack (Attributed_String);
   --  In this binding we allow strings of attributed characters.

   ------------------
   --  Exceptions  --
   ------------------
   Curses_Exception : exception;

   --  Those exceptions are raised by the ETI (Extended Terminal Interface)
   --  subpackets for Menu and Forms handling.
   --
   Eti_System_Error    : exception;
   Eti_Bad_Argument    : exception;
   Eti_Posted          : exception;
   Eti_Connected       : exception;
   Eti_Bad_State       : exception;
   Eti_No_Room         : exception;
   Eti_Not_Posted      : exception;
   Eti_Unknown_Command : exception;
   Eti_No_Match        : exception;
   Eti_Not_Selectable  : exception;
   Eti_Not_Connected   : exception;
   Eti_Request_Denied  : exception;
   Eti_Invalid_Field   : exception;
   Eti_Current         : exception;

   --------------------------------------------------------------------------
   --  External C variables
   --  Conceptually even in C this are kind of constants, but they are
   --  initialized and sometimes changed by the library routines at runtime
   --  depending on the type of terminal. I believe the best way to model
   --  this is to use functions.
   --------------------------------------------------------------------------

   function Lines            return Line_Count;
   pragma Inline (Lines);

   function Columns          return Column_Count;
   pragma Inline (Columns);

   function Tab_Size         return Natural;
   pragma Inline (Tab_Size);

   function Number_Of_Colors return Natural;
   pragma Inline (Number_Of_Colors);

   function Number_Of_Color_Pairs return Natural;
   pragma Inline (Number_Of_Color_Pairs);

   ACS_Map : array (Character'Val (0) .. Character'Val (127)) of
     Attributed_Character;
   pragma Import (C, ACS_Map, "acs_map");
   --
   --
   --  Constants for several symbols from the Alternate Character Set
   --  You must use this constants as indices into the ACS_Map array
   --  to get the corresponding attributed character at runtime.
   --
include(`ACS_Map')

   --  MANPAGE(`curs_initscr.3x')
   --  | Not implemented: newterm, set_term, delscreen

   --  ANCHOR(`stdscr',`Standard_Window')
   function Standard_Window return Window;
   --  AKA
   pragma Inline (Standard_Window);

   --  ANCHOR(`initscr()',`Init_Screen')
   procedure Init_Screen;

   --  ANCHOR(`initscr()',`Init_Windows')
   procedure Init_Windows renames Init_Screen;
   --  AKA
   pragma Inline (Init_Screen);
   pragma Inline (Init_Windows);

   --  ANCHOR(`endwin()',`End_Windows')
   procedure End_Windows;
   --  AKA
   procedure End_Screen renames End_Windows;
   pragma Inline (End_Windows);
   pragma Inline (End_Screen);

   --  ANCHOR(`isendwin()',`Is_End_Window')
   function Is_End_Window return Boolean;
   --  AKA
   pragma Inline (Is_End_Window);

   --  MANPAGE(`curs_move.3x')

   --  ANCHOR(`wmove()',`Move_Cursor')
   procedure Move_Cursor (Win    : in Window := Standard_Window;
                          Line   : in Line_Position;
                          Column : in Column_Position);
   --  AKA
   pragma Inline (Move_Cursor);

   --  MANPAGE(`curs_addch.3x')

   --  ANCHOR(`waddch()',`Add')
   procedure Add (Win :  in Window := Standard_Window;
                  Ch  :  in Attributed_Character);
   --  AKA

   procedure Add (Win :  in Window := Standard_Window;
                  Ch  :  in Character);
   --  Add a single character at the current logical cursor position to
   --  the window. Use the current windows attributes.

   --  ANCHOR(`mvwaddch()',`Add')
   procedure Add
     (Win    : in Window := Standard_Window;
      Line   : in Line_Position;
      Column : in Column_Position;
      Ch     : in Attributed_Character);
   --  AKA

   procedure Add
     (Win    : in Window := Standard_Window;
      Line   : in Line_Position;
      Column : in Column_Position;
      Ch     : in Character);
   --  Move to the position and add a single character into the window
   --  There are more Add routines, so the Inline pragma follows later

   --  ANCHOR(`wechochar()',`Add_With_Immediate_Echo')
   procedure Add_With_Immediate_Echo
     (Win : in Window := Standard_Window;
      Ch  : in Attributed_Character);
   --  AKA

   procedure Add_With_Immediate_Echo
     (Win : in Window := Standard_Window;
      Ch  : in Character);
   --  Add a character and do an immediate resfresh of the screen.
   pragma Inline (Add_With_Immediate_Echo);

   --  MANPAGE(`curs_window.3x')

   --  ANCHOR(`newwin()',`Create')
   function Create
     (Number_Of_Lines       : Line_Count;
      Number_Of_Columns     : Column_Count;
      First_Line_Position   : Line_Position;
      First_Column_Position : Column_Position) return Window;
   --  AKA
   pragma Inline (Create);

   function New_Window
     (Number_Of_Lines       : Line_Count;
      Number_Of_Columns     : Column_Count;
      First_Line_Position   : Line_Position;
      First_Column_Position : Column_Position) return Window
     renames Create;
   pragma Inline (New_Window);

   --  ANCHOR(`delwin()',`Delete')
   procedure Delete (Win : in out Window);
   --  AKA
   --  Reset Win to Null_Window
   pragma Inline (Delete);

   --  ANCHOR(`subwin()',`Sub_Window')
   function Sub_Window
     (Win                   : Window := Standard_Window;
      Number_Of_Lines       : Line_Count;
      Number_Of_Columns     : Column_Count;
      First_Line_Position   : Line_Position;
      First_Column_Position : Column_Position) return Window;
   --  AKA
   pragma Inline (Sub_Window);

   --  ANCHOR(`derwin()',`Derived_Window')
   function Derived_Window
     (Win                   : Window := Standard_Window;
      Number_Of_Lines       : Line_Count;
      Number_Of_Columns     : Column_Count;
      First_Line_Position   : Line_Position;
      First_Column_Position : Column_Position) return Window;
   --  AKA
   pragma Inline (Derived_Window);

   --  ANCHOR(`dupwin()',`Duplicate')
   function Duplicate (Win : Window) return Window;
   --  AKA
   pragma Inline (Duplicate);

   --  ANCHOR(`mvwin()',`Move_Window')
   procedure Move_Window (Win    : in Window;
                          Line   : in Line_Position;
                          Column : in Column_Position);
   --  AKA
   pragma Inline (Move_Window);

   --  ANCHOR(`mvderwin()',`Move_Derived_Window')
   procedure Move_Derived_Window (Win    : in Window;
                                  Line   : in Line_Position;
                                  Column : in Column_Position);
   --  AKA
   pragma Inline (Move_Derived_Window);

   --  ANCHOR(`wsyncup()',`Synchronize_Upwards')
   procedure Synchronize_Upwards (Win : in Window);
   --  AKA
   pragma Import (C, Synchronize_Upwards, "wsyncup");

   --  ANCHOR(`wsyncdown()',`Synchronize_Downwards')
   procedure Synchronize_Downwards (Win : in Window);
   --  AKA
   pragma Import (C, Synchronize_Downwards, "wsyncdown");

   --  ANCHOR(`syncok()',`Set_Synch_Mode')
   procedure Set_Synch_Mode (Win  : in Window := Standard_Window;
                             Mode : in Boolean := False);
   --  AKA
   pragma Inline (Set_Synch_Mode);

   --  MANPAGE(`curs_addstr.3x')

   --  ANCHOR(`waddnstr()',`Add')
   procedure Add (Win : in Window := Standard_Window;
                  Str : in String;
                  Len : in Integer := -1);
   --  AKA
   --  ALIAS(`waddstr()')

   --  ANCHOR(`mvwaddnstr()',`Add')
   procedure Add (Win    : in Window := Standard_Window;
                  Line   : in Line_Position;
                  Column : in Column_Position;
                  Str    : in String;
                  Len    : in Integer := -1);
   --  AKA
   --  ALIAS(`mvwaddstr()')

   --  MANPAGE(`curs_addchstr.3x')

   --  ANCHOR(`waddchnstr()',`Add')
   procedure Add (Win : in Window := Standard_Window;
                  Str : in Attributed_String;
                  Len : in Integer := -1);
   --  AKA
   --  ALIAS(`waddchstr()')

   --  ANCHOR(`mvwaddchnstr()',`Add')
   procedure Add (Win    : in Window := Standard_Window;
                  Line   : in Line_Position;
                  Column : in Column_Position;
                  Str    : in Attributed_String;
                  Len    : in Integer := -1);
   --  AKA
   --  ALIAS(`mvwaddchstr()')
   pragma Inline (Add);

   --  MANPAGE(`curs_border.3x')

   --  ANCHOR(`wborder()',`Border')
   procedure Border
     (Win                       : in Window := Standard_Window;
      Left_Side_Symbol          : in Attributed_Character := Default_Character;
      Right_Side_Symbol         : in Attributed_Character := Default_Character;
      Top_Side_Symbol           : in Attributed_Character := Default_Character;
      Bottom_Side_Symbol        : in Attributed_Character := Default_Character;
      Upper_Left_Corner_Symbol  : in Attributed_Character := Default_Character;
      Upper_Right_Corner_Symbol : in Attributed_Character := Default_Character;
      Lower_Left_Corner_Symbol  : in Attributed_Character := Default_Character;
      Lower_Right_Corner_Symbol : in Attributed_Character := Default_Character
     );
   --  AKA
   pragma Inline (Border);

   --  ANCHOR(`box()',`Box')
   procedure Box
     (Win               : in Window := Standard_Window;
      Vertical_Symbol   : in Attributed_Character := Default_Character;
      Horizontal_Symbol : in Attributed_Character := Default_Character);
   --  AKA
   pragma Inline (Box);

   --  ANCHOR(`whline()',`Horizontal_Line')
   procedure Horizontal_Line
     (Win         : in Window := Standard_Window;
      Line_Size   : in Natural;
      Line_Symbol : in Attributed_Character := Default_Character);
   --  AKA
   pragma Inline (Horizontal_Line);

   --  ANCHOR(`wvline()',`Vertical_Line')
   procedure Vertical_Line
     (Win         : in Window := Standard_Window;
      Line_Size   : in Natural;
      Line_Symbol : in Attributed_Character := Default_Character);
   --  AKA
   pragma Inline (Vertical_Line);

   --  MANPAGE(`curs_getch.3x')

   --  ANCHOR(`wgetch()',`Get_Keystroke')
   function Get_Keystroke (Win : Window := Standard_Window)
                           return Real_Key_Code;
   --  AKA
   --  Get a character from the keyboard and echo it - if enabled - to the
   --  window.
   --  If for any reason (i.e. a timeout) we couldn't get a character the
   --  returned keycode is Key_None.
   pragma Inline (Get_Keystroke);

   --  ANCHOR(`ungetch()',`Undo_Keystroke')
   procedure Undo_Keystroke (Key : in Real_Key_Code);
   --  AKA
   pragma Inline (Undo_Keystroke);

   --  ANCHOR(`has_key()',`Has_Key')
   function Has_Key (Key : Special_Key_Code) return Boolean;
   --  AKA
   pragma Inline (Has_Key);

   --  |
   --  | Some helper functions
   --  |
   function Is_Function_Key (Key : Special_Key_Code) return Boolean;
   --  Return True if the Key is a function key (i.e. one of F0 .. F63)
   pragma Inline (Is_Function_Key);

   subtype Function_Key_Number is Integer range 0 .. 63;
   --  (n)curses allows for 64 function keys.

   function Function_Key (Key : Real_Key_Code) return Function_Key_Number;
   --  Return the number of the function key. If the code is not a
   --  function key, a CONSTRAINT_ERROR will be raised.
   pragma Inline (Function_Key);

   function Function_Key_Code (Key : Function_Key_Number) return Real_Key_Code;
   --  Return the key code for a given functionkey number.
   pragma Inline (Function_Key_Code);

   --  MANPAGE(`curs_attr.3x')

   --  ANCHOR(`wattron()',`Switch_Character_Attribute')
   procedure Switch_Character_Attribute
     (Win  : in Window := Standard_Window;
      Attr : in Character_Attribute_Set := Normal_Video;
      On   : in Boolean := True); --  if False we switch Off.
   --  AKA
   --  ALIAS(`wattroff()')

   --  ANCHOR(`wattrset()',`Set_Character_Attributes')
   procedure Set_Character_Attributes
     (Win   : in Window := Standard_Window;
      Attr  : in Character_Attribute_Set := Normal_Video;
      Color : in Color_Pair := Color_Pair'First);
   --  AKA
   pragma Inline (Set_Character_Attributes);

   --  ANCHOR(`wattr_get()',`Get_Character_Attributes')
   function Get_Character_Attribute
     (Win : in Window := Standard_Window) return Character_Attribute_Set;
   --  AKA

   --  ANCHOR(`wattr_get()',`Get_Character_Attribute')
   function Get_Character_Attribute
     (Win : in Window := Standard_Window) return Color_Pair;
   --  AKA
   pragma Inline (Get_Character_Attribute);

   --  ANCHOR(`wchgat()',`Change_Attributes')
   procedure Change_Attributes
     (Win   : in Window := Standard_Window;
      Count : in Integer := -1;
      Attr  : in Character_Attribute_Set := Normal_Video;
      Color : in Color_Pair := Color_Pair'First);
   --  AKA

   --  ANCHOR(`mvwchgat()',`Change_Attributes')
   procedure Change_Attributes
     (Win    : in Window := Standard_Window;
      Line   : in Line_Position := Line_Position'First;
      Column : in Column_Position := Column_Position'First;
      Count  : in Integer := -1;
      Attr   : in Character_Attribute_Set := Normal_Video;
      Color  : in Color_Pair := Color_Pair'First);
   --  AKA
   pragma Inline (Change_Attributes);

   --  MANPAGE(`curs_beep.3x')

   --  ANCHOR(`beep()',`Beep')
   procedure Beep;
   --  AKA
   pragma Inline (Beep);

   --  ANCHOR(`flash()',`Flash_Screen')
   procedure Flash_Screen;
   --  AKA
   pragma Inline (Flash_Screen);

   --  MANPAGE(`curs_inopts.3x')

   --  | Not implemented : typeahead
   --
   --  ANCHOR(`cbreak()',`Set_Cbreak_Mode')
   procedure Set_Cbreak_Mode (SwitchOn : in Boolean := True);
   --  AKA
   --  ALIAS(`nocbreak()')
   pragma Inline (Set_Cbreak_Mode);

   --  ANCHOR(`raw()',`Set_Raw_Mode')
   procedure Set_Raw_Mode (SwitchOn : in Boolean := True);
   --  AKA
   --  ALIAS(`noraw()')
   pragma Inline (Set_Raw_Mode);

   --  ANCHOR(`echo()',`Set_Echo_Mode')
   procedure Set_Echo_Mode (SwitchOn : in Boolean := True);
   --  AKA
   --  ALIAS(`noecho()')
   pragma Inline (Set_Echo_Mode);

   --  ANCHOR(`meta()',`Set_Meta_Mode')
   procedure Set_Meta_Mode (Win      : in Window := Standard_Window;
                            SwitchOn : in Boolean := True);
   --  AKA
   pragma Inline (Set_Meta_Mode);

   --  ANCHOR(`keypad()',`Set_KeyPad_Mode')
   procedure Set_KeyPad_Mode (Win      : in Window := Standard_Window;
                              SwitchOn : in Boolean := True);
   --  AKA
   pragma Inline (Set_KeyPad_Mode);

   type Half_Delay_Amount is range 1 .. 255;

   --  ANCHOR(`halfdelay()',`Half_Delay')
   procedure Half_Delay (Amount : in Half_Delay_Amount);
   --  AKA
   pragma Inline (Half_Delay);

   --  ANCHOR(`intrflush()',`Set_Flush_On_Interrupt_Mode')
   procedure Set_Flush_On_Interrupt_Mode
     (Win  : in Window := Standard_Window;
      Mode : in Boolean := True);
   --  AKA
   pragma Inline (Set_Flush_On_Interrupt_Mode);

   --  ANCHOR(`qiflush()',`Set_Queue_Interrupt_Mode')
   procedure Set_Queue_Interrupt_Mode
     (Win   : in Window := Standard_Window;
      Flush : in Boolean := True);
   --  AKA
   --  ALIAS(`noqiflush()')
   pragma Inline (Set_Queue_Interrupt_Mode);

   --  ANCHOR(`nodelay()',`Set_NoDelay_Mode')
   procedure Set_NoDelay_Mode
     (Win  : in Window := Standard_Window;
      Mode : in Boolean := False);
   --  AKA
   pragma Inline (Set_NoDelay_Mode);

   type Timeout_Mode is (Blocking, Non_Blocking, Delayed);

   --  ANCHOR(`wtimeout()',`Set_Timeout_Mode')
   procedure Set_Timeout_Mode (Win    : in Window := Standard_Window;
                               Mode   : in Timeout_Mode;
                               Amount : in Natural); --  in Miliseconds
   --  AKA
   --  Instead of overloading the semantic of the sign of amount, we
   --  introduce the Timeout_Mode parameter. This should improve
   --  readability. For Blocking and Non_Blocking, the Amount is not
   --  evaluated.
   --  We don't inline this procedure.

   --  ANCHOR(`notimeout()',`Set_Escape_Time_Mode')
   procedure Set_Escape_Timer_Mode
     (Win       : in Window := Standard_Window;
      Timer_Off : in Boolean := False);
   --  AKA
   pragma Inline (Set_Escape_Timer_Mode);

   --  MANPAGE(`curs_outopts.3x')

   --  ANCHOR(`nl()',`Set_NL_Mode')
   procedure Set_NL_Mode (SwitchOn : in Boolean := True);
   --  AKA
   --  ALIAS(`nonl()')
   pragma Inline (Set_NL_Mode);

   --  ANCHOR(`clearok()',`Clear_On_Next_Update')
   procedure Clear_On_Next_Update
     (Win      : in Window := Standard_Window;
      Do_Clear : in Boolean := True);
   --  AKA
   pragma Inline (Clear_On_Next_Update);

   --  ANCHOR(`idlok()',`Use_Insert_Delete_Line')
   procedure Use_Insert_Delete_Line
     (Win    : in Window := Standard_Window;
      Do_Idl : in Boolean := True);
   --  AKA
   pragma Inline (Use_Insert_Delete_Line);

   --  ANCHOR(`idcok()',`Use_Insert_Delete_Character')
   procedure Use_Insert_Delete_Character
     (Win    : in Window := Standard_Window;
      Do_Idc : in Boolean := True);
   --  AKA
   pragma Inline (Use_Insert_Delete_Character);

   --  ANCHOR(`leaveok()',`Leave_Cursor_After_Update')
   procedure Leave_Cursor_After_Update
     (Win      : in Window := Standard_Window;
      Do_Leave : in Boolean := True);
   --  AKA
   pragma Inline (Leave_Cursor_After_Update);

   --  ANCHOR(`immedok()',`Immediate_Update_Mode')
   procedure Immediate_Update_Mode
     (Win  : in Window := Standard_Window;
      Mode : in Boolean := False);
   --  AKA
   pragma Inline (Immediate_Update_Mode);

   --  ANCHOR(`scrollok()',`Allow_Scrolling')
   procedure Allow_Scrolling
     (Win  : in Window := Standard_Window;
      Mode : in Boolean := False);
   --  AKA
   pragma Inline (Allow_Scrolling);

   function Scrolling_Allowed (Win : Window := Standard_Window) return Boolean;
   --  There is no such function in the C interface.
   pragma Inline (Scrolling_Allowed);

   --  ANCHOR(`wsetscrreg()',`Set_Scroll_Region')
   procedure Set_Scroll_Region
     (Win         : in Window := Standard_Window;
      Top_Line    : in Line_Position;
      Bottom_Line : in Line_Position);
   --  AKA
   pragma Inline (Set_Scroll_Region);

   --  MANPAGE(`curs_refresh.3x')

   --  ANCHOR(`doupdate()',`Update_Screen')
   procedure Update_Screen;
   --  AKA
   pragma Inline (Update_Screen);

   --  ANCHOR(`wrefresh()',`Refresh')
   procedure Refresh (Win : in Window := Standard_Window);
   --  AKA
   --  There is an overloaded Refresh for Pads.
   --  The Inline pragma appears there

   --  ANCHOR(`wnoutrefresh()',`Refresh_Without_Update')
   procedure Refresh_Without_Update
     (Win : in Window := Standard_Window);
   --  AKA
   --  There is an overloaded Refresh_Without_Update for Pads.
   --  The Inline pragma appears there

   --  ANCHOR(`redrawwin()',`Redraw')
   procedure Redraw (Win : in Window := Standard_Window);
   --  AKA

   --  ANCHOR(`wredrawln()',`Redraw')
   procedure Redraw (Win        : in Window := Standard_Window;
                     Begin_Line : in Line_Position;
                     Line_Count : in Positive);
   --  AKA
   pragma Inline (Redraw);

   --  MANPAGE(`curs_clear.3x')

   --  ANCHOR(`werase()',`Erase')
   procedure Erase (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Erase);

   --  ANCHOR(`wclear()',`Clear')
   procedure Clear
     (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Clear);

   --  ANCHOR(`wclrtobot()',`Clear_To_End_Of_Screen')
   procedure Clear_To_End_Of_Screen
     (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Clear_To_End_Of_Screen);

   --  ANCHOR(`wclrtoeol()',`Clear_To_End_Of_Line')
   procedure Clear_To_End_Of_Line
     (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Clear_To_End_Of_Line);

   --  MANPAGE(`curs_bkgd.3x')

   --  ANCHOR(`wbkgdset()',`Set_Background')
   procedure Set_Background
     (Win : in Window := Standard_Window;
      Ch  : in Attributed_Character);
   --  AKA
   pragma Inline (Set_Background);

   --  ANCHOR(`wbkgd()',`Change_Background')
   procedure Change_Background
     (Win : in Window := Standard_Window;
      Ch  : in Attributed_Character);
   --  AKA
   pragma Inline (Change_Background);

   --  ANCHOR(`wbkgdget()',`Get_Background')
   function Get_Background (Win : Window := Standard_Window)
     return Attributed_Character;
   --  AKA
   pragma Inline (Get_Background);

   --  MANPAGE(`curs_touch.3x')

   --  ANCHOR(`untouchwin()',`Untouch')
   procedure Untouch (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Untouch);

   --  ANCHOR(`touchwin()',`Touch')
   procedure Touch (Win : in Window := Standard_Window);
   --  AKA

   --  ANCHOR(`touchline()',`Touch')
   procedure Touch (Win   : in Window := Standard_Window;
                    Start : in Line_Position;
                    Count : in Positive);
   --  AKA
   pragma Inline (Touch);

   --  ANCHOR(`wtouchln()',`Change_Line_Status')
   procedure Change_Lines_Status (Win   : in Window := Standard_Window;
                                  Start : in Line_Position;
                                  Count : in Positive;
                                  State : in Boolean);
   --  AKA
   pragma Inline (Change_Lines_Status);

   --  ANCHOR(`is_linetouched()',`Is_Touched')
   function Is_Touched (Win  : Window := Standard_Window;
                        Line : Line_Position) return Boolean;
   --  AKA

   --  ANCHOR(`is_wintouched()',`Is_Touched')
   function Is_Touched (Win : Window := Standard_Window) return Boolean;
   --  AKA
   pragma Inline (Is_Touched);

   --  MANPAGE(`curs_overlay.3x')

   --  ANCHOR(`copywin()',`Copy')
   procedure Copy
     (Source_Window            : in Window;
      Destination_Window       : in Window;
      Source_Top_Row           : in Line_Position;
      Source_Left_Column       : in Column_Position;
      Destination_Top_Row      : in Line_Position;
      Destination_Left_Column  : in Column_Position;
      Destination_Bottom_Row   : in Line_Position;
      Destination_Right_Column : in Column_Position;
      Non_Destructive_Mode     : in Boolean := True);
   --  AKA
   pragma Inline (Copy);

   --  ANCHOR(`overwrite()',`Overwrite')
   procedure Overwrite (Source_Window      : in Window;
                        Destination_Window : in Window);
   --  AKA
   pragma Inline (Overwrite);

   --  ANCHOR(`overlay()',`Overlay')
   procedure Overlay (Source_Window      : in Window;
                      Destination_Window : in Window);
   --  AKA
   pragma Inline (Overlay);

   --  MANPAGE(`curs_deleteln.3x')

   --  ANCHOR(`winsdelln()',`Insert_Delete_Lines')
   procedure Insert_Delete_Lines
     (Win   : in Window  := Standard_Window;
      Lines : in Integer := 1); --  default is to insert one line above
   --  AKA
   pragma Inline (Insert_Delete_Lines);

   --  ANCHOR(`wdeleteln()',`Delete_Line')
   procedure Delete_Line (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Delete_Line);

   --  ANCHOR(`winsertln()',`Insert_Line')
   procedure Insert_Line (Win : in Window := Standard_Window);
   --  AKA
   pragma Inline (Insert_Line);

   --  MANPAGE(`curs_getyx.3x')

   --  ANCHOR(`getmaxyx()',`Get_Size')
   procedure Get_Size
     (Win               : in Window := Standard_Window;
      Number_Of_Lines   : out Line_Count;
      Number_Of_Columns : out Column_Count);
   --  AKA
   pragma Inline (Get_Size);

   --  ANCHOR(`getbegyx()',`Get_Window_Position')
   procedure Get_Window_Position
     (Win             : in Window := Standard_Window;
      Top_Left_Line   : out Line_Position;
      Top_Left_Column : out Column_Position);
   --  AKA
   pragma Inline (Get_Window_Position);

   --  ANCHOR(`getyx()',`Get_Cursor_Position')
   procedure Get_Cursor_Position
     (Win    : in  Window := Standard_Window;
      Line   : out Line_Position;
      Column : out Column_Position);
   --  AKA
   pragma Inline (Get_Cursor_Position);

   --  ANCHOR(`getparyx()',`Get_Origin_Relative_To_Parent')
   procedure Get_Origin_Relative_To_Parent
     (Win                : in  Window;
      Top_Left_Line      : out Line_Position;
      Top_Left_Column    : out Column_Position;
      Is_Not_A_Subwindow : out Boolean);
   --  AKA
   --  Instead of placing -1 in the coordinates as return, we use a boolean
   --  to return the info that the window has no parent.
   pragma Inline (Get_Origin_Relative_To_Parent);

   --  MANPAGE(`curs_pad.3x')

   --  ANCHOR(`newpad()',`New_Pad')
   function New_Pad (Lines   : Line_Count;
                     Columns : Column_Count) return Window;
   --  AKA
   pragma Inline (New_Pad);

   --  ANCHOR(`subpad()',`Sub_Pad')
   function Sub_Pad
     (Pad                   : Window;
      Number_Of_Lines       : Line_Count;
      Number_Of_Columns     : Column_Count;
      First_Line_Position   : Line_Position;
      First_Column_Position : Column_Position) return Window;
   --  AKA
   pragma Inline (Sub_Pad);

   --  ANCHOR(`prefresh()',`Refresh')
   procedure Refresh
     (Pad                      : in Window;
      Source_Top_Row           : in Line_Position;
      Source_Left_Column       : in Column_Position;
      Destination_Top_Row      : in Line_Position;
      Destination_Left_Column  : in Column_Position;
      Destination_Bottom_Row   : in Line_Position;
      Destination_Right_Column : in Column_Position);
   --  AKA
   pragma Inline (Refresh);

   --  ANCHOR(`pnoutrefresh()',`Refresh_Without_Update')
   procedure Refresh_Without_Update
     (Pad                      : in Window;
      Source_Top_Row           : in Line_Position;
      Source_Left_Column       : in Column_Position;
      Destination_Top_Row      : in Line_Position;
      Destination_Left_Column  : in Column_Position;
      Destination_Bottom_Row   : in Line_Position;
      Destination_Right_Column : in Column_Position);
   --  AKA
   pragma Inline (Refresh_Without_Update);

   --  ANCHOR(`pechochar()',`Add_Character_To_Pad_And_Echo_It')
   procedure Add_Character_To_Pad_And_Echo_It
     (Pad : in Window;
      Ch  : in Attributed_Character);
   --  AKA

   procedure Add_Character_To_Pad_And_Echo_It
     (Pad : in Window;
      Ch  : in Character);
   pragma Inline (Add_Character_To_Pad_And_Echo_It);

   --  MANPAGE(`curs_scroll.3x')

   --  ANCHOR(`wscrl()',`Scroll')
   procedure Scroll (Win    : in Window  := Standard_Window;
                     Amount : in Integer := 1);
   --  AKA
   pragma Inline (Scroll);

   --  MANPAGE(`curs_delch.3x')

   --  ANCHOR(`wdelch()',`Delete_Character')
   procedure Delete_Character (Win : in Window := Standard_Window);
   --  AKA

   --  ANCHOR(`mvwdelch()',`Delete_Character')
   procedure Delete_Character
     (Win    : in Window := Standard_Window;
      Line   : in Line_Position;
      Column : in Column_Position);
   --  AKA
   pragma Inline (Delete_Character);

   --  MANPAGE(`curs_inch.3x')

   --  ANCHOR(`winch()',`Peek')
   function Peek (Win : Window := Standard_Window)
     return Attributed_Character;
   --  AKA

   --  ANCHOR(`mvwinch()',`Peek')
   function Peek
     (Win    : Window := Standard_Window;
      Line   : Line_Position;
      Column : Column_Position) return Attributed_Character;
   --  AKA
   --  More Peek's follow, pragma Inline appears later.

   --  MANPAGE(`curs_winch.3x')

   --  ANCHOR(`winsch()',`Insert')
   procedure Insert (Win : in Window := Standard_Window;
                     Ch  : in Attributed_Character);
   --  AKA

   --  ANCHOR(`mvwinsch()',`Insert')
   procedure Insert (Win    : in Window := Standard_Window;
                     Line   : in Line_Position;
                     Column : in Column_Position;
                     Ch     : in Attributed_Character);
   --  AKA

   --  MANPAGE(`curs_winch.3x')

   --  ANCHOR(`winsnstr()',`Insert')
   procedure Insert (Win : in Window := Standard_Window;
                     Str : in String;
                     Len : in Integer := -1);
   --  AKA
   --  ALIAS(`winsstr()')

   --  ANCHOR(`mvwinsnstr()',`Insert')
   procedure Insert (Win    : in Window := Standard_Window;
                     Line   : in Line_Position;
                     Column : in Column_Position;
                     Str    : in String;
                     Len    : in Integer := -1);
   --  AKA
   --  ALIAS(`mvwinsstr()')
   pragma Inline (Insert);

   --  MANPAGE(`curs_instr.3x')

   --  ANCHOR(`winnstr()',`Peek')
   procedure Peek (Win : in  Window := Standard_Window;
                   Str : out String;
                   Len : in  Integer := -1);
   --  AKA
   --  ALIAS(`winstr()')

   --  ANCHOR(`mvwinnstr()',`Peek')
   procedure Peek (Win    : in  Window := Standard_Window;
                   Line   : in  Line_Position;
                   Column : in  Column_Position;
                   Str    : out String;
                   Len    : in  Integer := -1);
   --  AKA
   --  ALIAS(`mvwinstr()')

   --  MANPAGE(`curs_inchstr.3x')

   --  ANCHOR(`winchnstr()',`Peek')
   procedure Peek (Win : in  Window := Standard_Window;
                   Str : out Attributed_String;
                   Len : in  Integer := -1);
   --  AKA
   --  ALIAS(`winchstr()')

   --  ANCHOR(`mvwinchnstr()',`Peek')
   procedure Peek (Win    : in  Window := Standard_Window;
                   Line   : in  Line_Position;
                   Column : in  Column_Position;
                   Str    : out Attributed_String;
                   Len    : in  Integer := -1);
   --  AKA
   --  ALIAS(`mvwinchstr()')
   --  We don't inline the Peek procedures

   --  MANPAGE(`curs_getstr.3x')

   --  ANCHOR(`wgetnstr()',`Get')
   procedure Get (Win : in  Window := Standard_Window;
                  Str : out String;
                  Len : in  Integer := -1);
   --  AKA
   --  ALIAS(`wgetstr()')

   procedure Get (Win    : in  Window := Standard_Window;
                  Line   : in  Line_Position;
                  Column : in  Column_Position;
                  Str    : out String;
                  Len    : in  Integer := -1);
   --  AKA
   --  not specified in ncurses, should be: mvwgetnstr()
   --       and mvwgetstr() (which exists)
   --  Get is not inlined

   --  MANPAGE(`curs_slk.3x')

   type Soft_Label_Key_Format is (Three_Two_Three,
                                  Four_Four,
                                  PC_Style,              --  ncurses specific
                                  PC_Style_With_Index);  --  "
   type Label_Number is new Positive range 1 .. 12;
   type Label_Justification is (Left, Centered, Right);

   --  ANCHOR(`slk_init()',`Init_Soft_Label_Keys')
   procedure Init_Soft_Label_Keys
     (Format : in Soft_Label_Key_Format := Three_Two_Three);
   --  AKA
   pragma Inline (Init_Soft_Label_Keys);

   --  ANCHOR(`slk_set()',`Set_Soft_Label_Key')
   procedure Set_Soft_Label_Key (Label : in Label_Number;
                                 Text  : in String;
                                 Fmt   : in Label_Justification := Left);
   --  AKA
   --  We don't inline this procedure

   --  ANCHOR(`slk_refresh()',`Refresh_Soft_Label_Key')
   procedure Refresh_Soft_Label_Keys;
   --  AKA
   pragma Inline (Refresh_Soft_Label_Keys);

   --  ANCHOR(`slk_noutrefresh()',`Refresh_Soft_Label_Keys_Without_Update')
   procedure Refresh_Soft_Label_Keys_Without_Update;
   --  AKA
   pragma Inline (Refresh_Soft_Label_Keys_Without_Update);

   --  ANCHOR(`slk_label()',`Get_Soft_Label_Key')
   procedure Get_Soft_Label_Key (Label : in Label_Number;
                                 Text  : out String);
   --  AKA

   --  ANCHOR(`slk_label()',`Get_Soft_Label_Key')
   function Get_Soft_Label_Key (Label : in Label_Number) return String;
   --  AKA
   --  Same as function
   pragma Inline (Get_Soft_Label_Key);

   --  ANCHOR(`slk_clear()',`Clear_Soft_Label_Keys')
   procedure Clear_Soft_Label_Keys;
   --  AKA
   pragma Inline (Clear_Soft_Label_Keys);

   --  ANCHOR(`slk_restore()',`Restore_Soft_Label_Keys')
   procedure Restore_Soft_Label_Keys;
   --  AKA
   pragma Inline (Restore_Soft_Label_Keys);

   --  ANCHOR(`slk_touch()',`Touch_Soft_Label_Keys')
   procedure Touch_Soft_Label_Keys;
   --  AKA
   pragma Inline (Touch_Soft_Label_Keys);

   --  ANCHOR(`slk_attron()',`Switch_Soft_Label_Key_Attributes')
   procedure Switch_Soft_Label_Key_Attributes
     (Attr : in Character_Attribute_Set;
      On   : in Boolean := True);
   --  AKA
   --  ALIAS(`slk_attroff()')
   pragma Inline (Switch_Soft_Label_Key_Attributes);

   --  ANCHOR(`slk_attrset()',`Set_Soft_Label_Key_Attributes')
   procedure Set_Soft_Label_Key_Attributes
     (Attr  : in Character_Attribute_Set := Normal_Video;
      Color : in Color_Pair := Color_Pair'First);
   --  AKA
   pragma Inline (Set_Soft_Label_Key_Attributes);

   --  ANCHOR(`slk_attr()',`Get_Soft_Label_Key_Attributes')
   function Get_Soft_Label_Key_Attributes return Character_Attribute_Set;
   --  AKA

   --  ANCHOR(`slk_attr()',`Get_Soft_Label_Key_Attributes')
   function Get_Soft_Label_Key_Attributes return Color_Pair;
   --  AKA
   pragma Inline (Get_Soft_Label_Key_Attributes);

   --  MANPAGE(`keyok.3x')

   --  ANCHOR(`keyok()',`Enable_Key')
   procedure Enable_Key (Key    : in Special_Key_Code;
                         Enable : in Boolean := True);
   --  AKA
   pragma Inline (Enable_Key);

   --  MANPAGE(`define_key.3x')

   --  ANCHOR(`define_key()',`Define_Key')
   procedure Define_Key (Definition : in String;
                         Key        : in Special_Key_Code);
   --  AKA
   pragma Inline (Define_Key);

   --  MANPAGE(`curs_util.3x')

   --  | Not implemented : filter, use_env, putwin, getwin
   --
   --  ANCHOR(`keyname()',`Key_Name')
   procedure Key_Name (Key  : in  Real_Key_Code;
                       Name : out String);
   --  AKA
   --  The external name for a real keystroke.

   --  ANCHOR(`keyname()',`Key_Name')
   function Key_Name (Key  : in  Real_Key_Code) return String;
   --  AKA
   --  Same as function
   --  We don't inline this routine

   --  ANCHOR(`unctrl()',`Un_Control')
   procedure Un_Control (Ch  : in Attributed_Character;
                         Str : out String);
   --  AKA

   --  ANCHOR(`unctrl()',`Un_Control')
   function Un_Control (Ch  : in Attributed_Character) return String;
   --  AKA
   --  Same as function
   pragma Inline (Un_Control);

   --  ANCHOR(`delay_output()',`Delay_Output')
   procedure Delay_Output (Msecs : in Natural);
   --  AKA
   pragma Inline (Delay_Output);

   --  ANCHOR(`flushinp()',`Flush_Input')
   procedure Flush_Input;
   --  AKA
   pragma Inline (Flush_Input);

   --  MANPAGE(`curs_termattrs.3x')

   --  ANCHOR(`baudrate()',`Baudrate')
   function Baudrate return Natural;
   --  AKA
   pragma Inline (Baudrate);

   --  ANCHOR(`erasechar()',`Erase_Character')
   function Erase_Character return Character;
   --  AKA
   pragma Inline (Erase_Character);

   --  ANCHOR(`killchar()',`Kill_Character')
   function Kill_Character return Character;
   --  AKA
   pragma Inline (Kill_Character);

   --  ANCHOR(`has_ic()',`Has_Insert_Character')
   function Has_Insert_Character return Boolean;
   --  AKA
   pragma Inline (Has_Insert_Character);

   --  ANCHOR(`has_il()',`Has_Insert_Line')
   function Has_Insert_Line return Boolean;
   --  AKA
   pragma Inline (Has_Insert_Line);

   --  ANCHOR(`termattrs()',`Supported_Attributes')
   function Supported_Attributes return Character_Attribute_Set;
   --  AKA
   pragma Inline (Supported_Attributes);

   --  ANCHOR(`longname()',`Long_Name')
   procedure Long_Name (Name : out String);
   --  AKA

   --  ANCHOR(`longname()',`Long_Name')
   function Long_Name return String;
   --  AKA
   --  Same as function
   pragma Inline (Long_Name);

   --  ANCHOR(`termname()',`Terminal_Name')
   procedure Terminal_Name (Name : out String);
   --  AKA

   --  ANCHOR(`termname()',`Terminal_Name')
   function Terminal_Name return String;
   --  AKA
   --  Same as function
   pragma Inline (Terminal_Name);

   --  MANPAGE(`curs_color.3x')

   --  ANCHOR(`start_clolor()',`Start_Color')
   procedure Start_Color;
   --  AKA
   pragma Import (C, Start_Color, "start_color");

   --  ANCHOR(`init_pair()',`Init_Pair')
   procedure Init_Pair (Pair : in Redefinable_Color_Pair;
                        Fore : in Color_Number;
                        Back : in Color_Number);
   --  AKA
   pragma Inline (Init_Pair);

   --  ANCHOR(`pair_content()',`Pair_Content')
   procedure Pair_Content (Pair : in Color_Pair;
                           Fore : out Color_Number;
                           Back : out Color_Number);
   --  AKA
   pragma Inline (Pair_Content);

   --  ANCHOR(`has_colors()',`Has_Colors')
   function Has_Colors return Boolean;
   --  AKA
   pragma Inline (Has_Colors);

   --  ANCHOR(`init_color()',`Init_Color')
   procedure Init_Color (Color : in Color_Number;
                         Red   : in RGB_Value;
                         Green : in RGB_Value;
                         Blue  : in RGB_Value);
   --  AKA
   pragma Inline (Init_Color);

   --  ANCHOR(`can_change_color()',`Can_Change_Color')
   function Can_Change_Color return Boolean;
   --  AKA
   pragma Inline (Can_Change_Color);

   --  ANCHOR(`color_content()',`Color_Content')
   procedure Color_Content (Color : in  Color_Number;
                            Red   : out RGB_Value;
                            Green : out RGB_Value;
                            Blue  : out RGB_Value);
   --  AKA
   pragma Inline (Color_Content);

   --  MANPAGE(`curs_kernel.3x')

   --  | Not implemented: getsyx, setsyx
   --
   type Curses_Mode is (Curses, Shell);

   --  ANCHOR(`def_prog_mode()',`Save_Curses_Mode')
   procedure Save_Curses_Mode (Mode : in Curses_Mode);
   --  AKA
   --  ALIAS(`def_shell_mode()')
   pragma Inline (Save_Curses_Mode);

   --  ANCHOR(`reset_prog_mode()',`Reset_Curses_Mode')
   procedure Reset_Curses_Mode (Mode : in Curses_Mode);
   --  AKA
   --  ALIAS(`reset_shell_mode()')
   pragma Inline (Reset_Curses_Mode);

   --  ANCHOR(`savetty()',`Save_Terminal_State')
   procedure Save_Terminal_State;
   --  AKA
   pragma Inline (Save_Terminal_State);

   --  ANCHOR(`resetty();',`Reset_Terminal_State')
   procedure Reset_Terminal_State;
   --  AKA
   pragma Inline (Reset_Terminal_State);

   type Stdscr_Init_Proc is access
      function (Win     : Window;
                Columns : Column_Count) return Integer;
   pragma Convention (C, Stdscr_Init_Proc);
   --  N.B.: the return value is actually ignored, but it seems to be
   --        a good practice to return 0 if you think all went fine
   --        and -1 otherwise.

   --  ANCHOR(`ripoffline()',`Rip_Off_Lines')
   procedure Rip_Off_Lines (Lines : in Integer;
                            Proc  : in Stdscr_Init_Proc);
   --  AKA
   --  N.B.: to be more precise, this uses a ncurses specific enhancement of
   --        ripoffline(), in which the Lines argument absolute value is the
   --        number of lines to be ripped of. The official ripoffline() only
   --        uses the sign of Lines to rip of a single line from bottom or top.
   pragma Inline (Rip_Off_Lines);

   type Cursor_Visibility is (Invisible, Normal, Very_Visible);

   --  ANCHOR(`curs_set()',`Set_Cursor_Visibility')
   procedure Set_Cursor_Visibility (Visibility : in out Cursor_Visibility);
   --  AKA
   pragma Inline (Set_Cursor_Visibility);

   --  ANCHOR(`napms()',`Nap_Milli_Seconds')
   procedure Nap_Milli_Seconds (Ms : in Natural);
   --  AKA
   pragma Inline (Nap_Milli_Seconds);

   --  |=====================================================================
   --  | Some usefull helpers.
   --  |=====================================================================
   type Transform_Direction is (From_Screen, To_Screen);
   procedure Transform_Coordinates
     (W      : in Window := Standard_Window;
      Line   : in out Line_Position;
      Column : in out Column_Position;
      Dir    : in Transform_Direction := From_Screen);
   --  This procedure transforms screen coordinates into coordinates relative
   --  to the window and vice versa, depending on the Dir parmeter.
   --  Screen coordinates are the position informations on the physical device.
   --  An Curses_Exception will be raised if Line and Column are not in the
   --  Window or if you pass the Null_Window as argument.
   --  We don't inline this procedure

private
   type Window is new System.Address;
   Null_Window : constant Window := Window (System.Null_Address);

end Terminal_Interface.Curses;
