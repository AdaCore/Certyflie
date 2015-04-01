with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Maths_Pack
  with SPARK_Mode
is

   function Inv_Sqrt (X : Float) return Float is
      function Sqrtf (X : Float) return Float with
        Global => null,
        Pre    => X >= Float'Succ (0.0),
        Post   => Sqrtf'Result in 3.75E-23 .. 1.85E+19,
        Import, Convention => Intrinsic, External_Name => "__builtin_sqrtf";
   begin
      return 1.0 / Sqrtf (X);
   end Inv_Sqrt;

end Maths_Pack;
