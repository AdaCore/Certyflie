with Ada.Unchecked_Conversion;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

package Conversion_Pack is

   --  Functions and procedures

   --  Convert an Float value into an Integer value.
   function Float_To_Int is new Ada.Unchecked_Conversion (Float, Integer);
   function Unsigned_32_To_Float is new Ada.Unchecked_Conversion (Unsigned_32,
                                                                  Float);
end Conversion_Pack;
