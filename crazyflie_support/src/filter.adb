with Ada.Unchecked_Conversion;

package body Filter
  with SPARK_Mode
is

   procedure IIR_LP_Filter_Single
     (Input       : T_Int32;
      Attenuation : T_Int32;
      Filter      : in out T_Int32;
      Result      : out T_Int32) is
      function T_Int32_To_T_Uint32 is new Ada.Unchecked_Conversion
        (T_Int32, T_Uint32);
      function T_Uint32_To_T_Int32 is new Ada.Unchecked_Conversion
        (T_Uint32, T_Int32);
      Tmp_Input       : constant T_Uint32 := T_Int32_To_T_Uint32 (Input);
      Tmp_Attenuation : T_Uint32 := T_Int32_To_T_Uint32 (Attenuation);
      In_Scaled       : T_Uint32;
      Tmp_Filter      : T_Uint32 := T_Int32_To_T_Uint32 (Filter);
      Output          : T_Uint32;
   begin
      if Tmp_Attenuation > Shift_Left (1, IIR_SHIFT) then
         Tmp_Attenuation := Shift_Left (1, IIR_SHIFT);
      elsif Tmp_Attenuation < 1 then
         Tmp_Attenuation := 1;
      end if;

      --  Shift to keep accuracy
      In_Scaled := Shift_Left (Tmp_Input, IIR_SHIFT);
      --  Calculate IIR filter
      Tmp_Filter := Tmp_Filter +
        (Shift_Right_Arithmetic (In_Scaled - Tmp_Filter, IIR_SHIFT)
         * Tmp_Attenuation);
      --  Scale and round
      Output := Shift_Right_Arithmetic (Tmp_Filter, IIR_SHIFT) +
        Shift_Right_Arithmetic
          (Tmp_Filter and Shift_Left (1, IIR_SHIFT - 1), IIR_SHIFT - 1);
      Filter := T_Uint32_To_T_Int32 (Tmp_Filter);

      Result := T_Uint32_To_T_Int32 (Output);
   end IIR_LP_Filter_Single;

end Filter;
