package Maths_Pack
  with SPARK_Mode
is
   --  Constants

   PI : constant :=
          3.14159_26535_89793_23846_26433_83279_50288_41971_69399_37511;

   --  Procedures and functions

   --  Fast inverse square root
   function Inv_Sqrt (X : Float) return Float;

   function Atan_2 (X : Float; Y : Float) return Float;
   pragma Import (C, Atan_2, "atan2");

   function Asin (X : Float) return Float;
   pragma Import (C, Asin, "asin");

end Maths_Pack;
