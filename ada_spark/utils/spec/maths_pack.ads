with Types; use Types;
with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package Maths_Pack
  with SPARK_Mode
is
   --  Types

   --  Angle range type, in radians.
   subtype T_Radians is Float range -2.0 * Pi .. 2.0 * Pi;

   --  Procedures and functions

   --  Fast inverse square root
   --  See: http://en.wikipedia.org/wiki/Fast_inverse_square_root
   function Inv_Sqrt (X : Float) return Float
     with
       Pre  => X >= Float'Succ (0.0),
       Post => Inv_Sqrt'Result > 0.0 and Inv_Sqrt'Result < 2.0E+20;

   --  Imported atan2f function from C
   function Atan_2 (X : Float; Y : Float) return T_Radians
     with Global => null;
   pragma Import (C, Atan_2, "atan2f");


   --  Imported asin function from C
   function Asin (X : Float) return T_Radians
     with Global => null;
   pragma Import (C, Asin, "asinf");

end Maths_Pack;
