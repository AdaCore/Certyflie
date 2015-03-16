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

   procedure Constrain
     (Value     : in out Float;
      Min_Value : Float;
      Max_Value : Float)
     with
       Post => Value in Min_Value .. Max_Value;
   pragma Inline (Constrain);

   procedure Constrain
     (Value     : in out T_Uint16;
      Min_Value : T_Uint16;
      Max_Value : T_Uint16)
     with
       Post => Value in Min_Value .. Max_Value;
   pragma Inline (Constrain);

   --  Truncate a 32-bit Integer into a 16-bit Integer
   function Truncate_To_T_Int16 (Value : Float) return T_Int16;
   pragma Inline (Truncate_To_T_Int16);

end Safety_Pack;
