with Types; use Types;

package Safety_Pack
  with SPARK_Mode
is

   --  Procedures and functions

   function Dead_Band (Value     : Float;
                       Threshold : Positive_Float) return Float;
   pragma Inline (Dead_Band);

   procedure Constrain (Value     : in out Float;
                        Min_Value : Float;
                        Max_Value : Float)
     with
       Post => Value in Min_Value .. Max_Value;
   pragma Inline (Constrain);

end Safety_Pack;
