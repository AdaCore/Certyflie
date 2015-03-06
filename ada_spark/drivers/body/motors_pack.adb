package body Motors_Pack is

   procedure Motor_Set_ratio (ID          : Motor_ID;
                              Motor_Power : Unsigned_32) is

      procedure Motor_Set_Ratio_Wrapper (ID          : Integer_16;
                                      Motor_Power : Unsigned_32);
      pragma Import (C, Motor_Set_Ratio_Wrapper, "motorSetRatio");
   begin
      Motor_Set_Ratio_Wrapper (Motor_ID'Pos (ID), Motor_Power);
   end Motor_Set_ratio;

end Motors_Pack;
