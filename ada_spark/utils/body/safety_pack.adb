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

   procedure Constrain (Value     : in out T_Uint16;
                        Min_Value : T_Uint16;
                        Max_Value : T_Uint16) is
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

   function Truncate_To_T_Int16 (Value : Float) return T_Int16 is
      Res : T_Int16;
   begin
      if Value > Float (T_Int16'Last) then
         Res :=  T_Int16'Last;
      elsif Value < Float (T_Int16'First) then
         Res :=  T_Int16'First;
      else
         Res := T_Int16 (Value);
      end if;

      return Res;
   end Truncate_To_T_Int16;
end Safety_Pack;
