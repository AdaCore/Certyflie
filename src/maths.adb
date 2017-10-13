with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Safety;                            use Safety;

package body Maths
  with SPARK_Mode
is

   function Inv_Sqrt (X : Float) return Float is
   begin
      return 1.0 / Sqrtf (X);
   end Inv_Sqrt;

   function Atan (Y :  Float; X : Float) return T_Radians is
   begin
      --  We constrain the return value accordingly to
      --  the Ada RM specification for Arctan
      --  (A.5.1 Elementary Functions)
      return Saturate (Arctan (Y, X), -Pi, Pi);
   end Atan;

   function Asin (X : Float) return T_Radians is
   begin
      --  We constrain the return value accordingly to
      --  the Ada RM specification for Arcsin
      --  (A.5.1 Elementary Functions)
      return Saturate (Arcsin (X), -Pi / 2.0, Pi / 2.0);
   end Asin;

end Maths;
