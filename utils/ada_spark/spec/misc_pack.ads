with Interfaces.C; use Interfaces.C;

package Misc_Pack is

   --  Functions and procedures
   function C_ConsolePuts(Str : Char_Array) return Integer;
   pragma Import(C, C_ConsolePuts, "consolePuts");

   function C_ConsolePutchar(Ch : Integer) return Integer;
   pragma Import(C, C_ConsolePutchar, "consolePutchar");

   procedure Zboob;
end Misc_Pack;
