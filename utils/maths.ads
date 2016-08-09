with Ada.Numerics; use Ada.Numerics;

package Maths
  with SPARK_Mode
is

   --  Types

   --  Angle range type, in radians.
   subtype T_Radians is Float range -2.0 * Pi .. 2.0 * Pi;

   --  Procedures and functions

   --  Return the square root using the sqrtf builtin.
   function Sqrtf (X : Float) return Float with
     Global => null,
     Pre    => X >= 0.0,
     Post   => Sqrtf'Result in 0.0 .. 1.85E+19,
       Import, Convention => Intrinsic, External_Name => "__builtin_sqrtf";

   --  Return the inverse square root using the sqrtf builtin.
   function Inv_Sqrt (X : Float) return Float
     with
       Pre  => X >= Float'Succ (0.0),
       Post => Inv_Sqrt'Result > 0.0 and Inv_Sqrt'Result < 2.7E+22;

   --  Wrapper for Ada.Numerics.Elementary_Functions.Arctan.
   function Atan (Y :  Float; X : Float) return T_Radians;

   --  Wrapper for Ada.Numerics.Elementary_Functions.Arctan.
   function Asin (X : Float) return T_Radians;

end Maths;
