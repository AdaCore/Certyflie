with Types; use Types;

package Safety_Pack
  with SPARK_Mode
is

   --  Procedures and functions

   function Dead_Band
     (Value     : Float;
      Threshold : Positive_Float) return Float

     with
       Post => abs Dead_Band'Result <= Value;
   pragma Inline (Dead_Band);

   Function Constrain
     (Value     : Float;
      Min_Value : Float;
      Max_Value : Float) return Float
     with
       Post => Constrain'Result in Min_Value .. Max_Value;
   pragma Inline (Constrain);

   function Constrain
     (Value     : T_Uint16;
      Min_Value : T_Uint16;
      Max_Value : T_Uint16) return T_Uint16
     with
       Post => Constrain'Result in Min_Value .. Max_Value;
   pragma Inline (Constrain);

   --  Truncate a 32-bit Integer into a 16-bit Integer
   function Truncate_To_T_Int16 (Value : Float) return T_Int16;
   pragma Inline (Truncate_To_T_Int16);

end Safety_Pack;
