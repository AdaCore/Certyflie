package body Safety_Pack is

   procedure Constrain (Value     : in out Float;
                        Min_Value : Float;
                        Max_Value : Float) is
   begin
      if Value < Min_Value then
         Value := Min_Value;
      elsif Value > Max_Value then
         Value := Max_Value;
      end if;
   end Constrain;

   function Dead_Band (Value     : Float;
                       Threshold : Positive_Float) return Float is
      Res : Float := Value;
   begin
      if Value in -Threshold .. Threshold then
         Res := 0.0;
      elsif Value > 0.0 then
         Res := Res - Threshold;
      elsif Value < 0.0 then
         Res := Res + Threshold;
      end if;

      return Res;
   end Dead_Band;

end Safety_Pack;
