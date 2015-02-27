with Interfaces.C; use Interfaces.C;

package Debug_Pack is

   --  Functions and procedures

   --  Wrapper for the 'consolePuts' function declared in 'utils/interface/debug.h'
   function C_ConsolePuts(Str : Char_Array) return Integer;
   pragma Import(C, C_ConsolePuts, "consolePuts");

   --  Wrapper for the 'consolePutchar' function declared in 'utils/interface/debug.h'
   function C_ConsolePutchar(Ch : Integer) return Integer;
   pragma Import(C, C_ConsolePutchar, "consolePutchar");

end Debug_Pack;
