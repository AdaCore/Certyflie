with SensFusion6_Pack; use SensFusion6_Pack;

package body Stabilizer_Pack
  with SPARK_Mode
is

   --  For testing purpose
   procedure Modif_Variables is
   begin
      Gyro.X := 12.0;
      Acc.Y  := 13.0;
      Mag.Z  := 14.0;
   end Modif_Variables;

   procedure Stabilizer_Control_Loop (Attitude_Update_Counter : in out Integer;
                                      Alt_Hold_Update_Counter : in out Integer)
   is
   begin
      --  Magnetometer not used for the moment
      IMU_9_Read (Gyro, Acc, Mag);

      --  Do nothing if IMU is not calibrated correctly
      if not IMU_6_Calibrated then
         return;
      end if;

      --  TODO: Increment the update counters. Maybe do this in the C part?
      --Attitude_Update_Counter := Attitude_Update_Counter + 1;
      --Alt_Hold_Update_Counter := Alt_Hold_Update_Counter + 1;

      --  Get commands from the pilot
      Commander_Get_RPY (Euler_Roll_Desired,
                         Euler_Pitch_Desired,
                         Euler_Yaw_Desired);
      Commander_Get_RPY_Type (Roll_Type, Pitch_Type, Yaw_Type);

      --  Update attitude at IMU_UPDATE_FREQ / ATTITUDE_UPDATE_RATE_DIVIDER
      --  By default the result is 250 Hz
      if Attitude_Update_Counter >= ATTITUDE_UPDATE_RATE_DIVIDER then
         --  Update attitude
         Stabilizer_Update_Attitude;
         --  Reset the counter
         pragma Warnings (GNATprove, Off, "unused assignment",
                    Reason => "This function is called periodically.");
         Attitude_Update_Counter := 0;
      end if;
   end Stabilizer_Control_Loop;

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

   procedure Stabilizer_Update_Attitude is
      Raw_V_Speed : Float;
   begin
      SensFusion6_Update_Q (Gyro.X, Gyro.Y, Gyro.Z,
                            Acc.X, Acc.Y, Acc.Z,
                            FUSION_UPDATE_DT);
      --  Get Euler angles
      SensFusion6_Get_Euler_RPY (Euler_Roll_Actual,
                                 Euler_Pitch_Actual,
                                 Euler_Yaw_Actual);
      --  Vertical acceleration woithout gravity
      Acc_WZ := SensFusion6_Get_AccZ_Without_Gravity (Acc.X,
                                                      Acc.Y,
                                                      Acc.Z);
      Acc_MAG := (Acc.X * Acc.X) + (Acc.Y * Acc.Y) + (Acc.Z * Acc.Z);

      --  Estimate vertical speed from acceleration and constrain
      --  it within a limit
      Raw_V_Speed := V_Speed +
        Dead_Band (Acc_WZ, V_Acc_Deadband) * FUSION_UPDATE_DT;

      if Raw_V_Speed > T_Speed'Last then
         V_Speed := T_Speed'Last;
      elsif Raw_V_Speed < T_Speed'First then
         V_Speed := T_Speed'First;
      end if;
   end Stabilizer_Update_Attitude;




end Stabilizer_Pack;
