with Types; use Types;

package Maths_Pack
  with SPARK_Mode
is
   --  Constants

   Pi : constant :=
          3.14159_26535_89793_23846_26433_83279_50288_41971_69399_37511;

   --  Types

   --  Angle range type, in radians.
   subtype T_Radians is Float range -2.0 * Pi .. 2.0 * Pi;

   --  Procedures and functions

   --  Fast inverse square root
   --  See: http://en.wikipedia.org/wiki/Fast_inverse_square_root
   function Inv_Sqrt (X : Float) return Float
     with
       Pre  => X >= Float'Succ (0.0),
       Post => Inv_Sqrt'Result > 0.0;

   --  Wrapper for Ada.Numerics.Elementary_Functions.Arctan
   function Atan (Y :  Float; X : Float) return T_Radians;

   --  Wrapper for Ada.Numerics.Elementary_Functions.Arctan
   function Asin (X : Float) return T_Radians;

end Maths_Pack;
