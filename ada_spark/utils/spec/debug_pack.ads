with Interfaces.C; use Interfaces.C;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

package Debug_Pack is

   --  Functions and procedures

   --  Wrapper for the 'consolePuts' function
   --  declared in 'utils/interface/debug.h'
   function C_ConsolePuts (Str : char_array) return Integer;
   pragma Import (C, C_ConsolePuts, "consolePuts");

   --  Wrapper for the 'consolePutchar' function
   --  declared in 'utils/interface/debug.h'
   function C_ConsolePutchar (Ch : Integer) return Integer;
   pragma Import (C, C_ConsolePutchar, "consolePutchar");

end Debug_Pack;
