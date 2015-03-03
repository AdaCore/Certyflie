with Ada.Unchecked_Conversion;

package Conversion_Pack is

   --  Functions and procedures

   --  Convert an Float value into an Integer value.
   function Float_To_Int is new Ada.Unchecked_Conversion (Float, Integer);

end Conversion_Pack;
