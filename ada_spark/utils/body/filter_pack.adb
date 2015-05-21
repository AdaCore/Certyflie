package body Filter_Pack is

   function IIR_LP_Filter_Single
     (Input       : T_Uint32;
      Attenuation : T_Uint32;
      Filter      : in out T_Uint32) return T_Uint32 is
      Tmp_Attenuation : T_Uint32 := Attenuation;
      In_Scaled       : T_Uint32;
      Tmp_Filter      : T_Uint32 := Filter;
      Output          : T_Uint32;
   begin
      if Tmp_Attenuation > Shift_Left (1, IIR_SHIFT) then
         Tmp_Attenuation := Shift_Left (1, IIR_SHIFT);
      elsif Tmp_Attenuation < 1 then
        Tmp_Attenuation := 1;
      end if;

      --  Shift to keep accuracy
      In_Scaled := Shift_Left (Input, IIR_SHIFT);
      --  Calculate IIR filter
      Tmp_Filter := Tmp_Filter +
        (Shift_Right (In_Scaled - Tmp_Filter, IIR_SHIFT) * Tmp_Attenuation);
      --  Scale and round
      Output := Shift_Right (Tmp_Filter, IIR_SHIFT) +
        Shift_Right
          (Tmp_Filter and Shift_Left (1, IIR_SHIFT - 1), IIR_SHIFT - 1);
      Filter := Tmp_Filter;

      return Output;
   end IIR_LP_Filter_Single;

end Filter_Pack;
