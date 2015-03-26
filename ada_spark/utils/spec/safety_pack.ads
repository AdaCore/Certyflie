with Types; use Types;

package Safety_Pack
  with SPARK_Mode
is

   --  Procedures and functions

   function Dead_Band
     (Value     : Float;
      Threshold : Positive_Float) return Float

     with
       Contract_Cases => ((Value in -Threshold .. Threshold) =>
                                Dead_Band'Result = 0.0,
                          Value > Threshold                  =>
                            Dead_Band'Result = Value - Threshold,
                          Value < -Threshold                 =>
                            Dead_Band'Result = Value + Threshold);
   pragma Inline (Dead_Band);

   --  Saturate a Float value within a given range
   Function Constrain
     (Value     : Float;
      Min_Value : Float;
      Max_Value : Float) return Float
     with
       Pre => Min_Value < Max_Value,
       Contract_Cases => (Value < Min_Value => Constrain'Result = Min_Value,
                          Value > Max_value => Constrain'Result = Max_Value,
                          others            => Constrain'Result = Value);

   pragma Inline (Constrain);

   --  Saturate a T_Uint16 value within a given range
   function Constrain
     (Value     : T_Uint16;
      Min_Value : T_Uint16;
      Max_Value : T_Uint16) return T_Uint16
     with
       Pre => Min_Value < Max_Value,
       Contract_Cases => (Value < Min_Value => Constrain'Result = Min_Value,
                          Value > Max_value => Constrain'Result = Max_Value,
                          others            => Constrain'Result = Value);
       pragma Inline (Constrain);

   --  Truncate a 32-bit Integer into a 16-bit Integer
   function Truncate_To_T_Int16 (Value : Float) return T_Int16;
   pragma Inline (Truncate_To_T_Int16);

end Safety_Pack;
