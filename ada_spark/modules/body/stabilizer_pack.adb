with Interfaces.C; use Interfaces.C;

with Config; use Config;
with Safety_Pack; use Safety_Pack;
with Motors_Pack; use Motors_Pack;
with SensFusion6_Pack; use SensFusion6_Pack;
with PM_Pack; use PM_Pack;

package body Stabilizer_Pack
with SPARK_Mode
is

   --  Private procedures and functions

   function Limit_Thrust (Value : T_Int32) return T_Uint16 is
      Res : T_Uint16;
   begin
      if Value > T_Int32 (T_Uint16'Last) then
         Res := T_Uint16'Last;
      elsif Value < 0 then
         Res := 0;
      else
         pragma Assert (Value <= T_Int32 (T_Uint16'Last));
         Res := T_Uint16 (Value);
      end if;

      return Res;
   end Limit_Thrust;

   procedure Stabilizer_Distribute_Power
     (Thrust : T_Uint16;
      Roll   : T_Int16;
      Pitch  : T_Int16;
      Yaw    : T_Int16) is
      T : T_Int32 := T_Int32 (Thrust);
      R : T_Int32 := T_Int32 (Roll);
      P : T_Int32 := T_Int32 (Pitch);
      Y : T_Int32 := T_Int32 (Yaw);
   begin
      if QUAD_FORMATION_X then
         R := R / 2;
         P := P / 2;

         Motor_Power_M1 := Limit_Thrust (T - R + P + Y);
         Motor_Power_M2 := Limit_Thrust (T - R - P - Y);
         Motor_Power_M3 := Limit_Thrust (T + R - P + Y);
         Motor_Power_M4 := Limit_Thrust (T + R + P - Y);
      else
         Motor_Power_M1 := Limit_Thrust (T + P + Y);
         Motor_Power_M2 := Limit_Thrust (T - R - Y);
         Motor_Power_M3 := Limit_Thrust (T - P + Y);
         Motor_Power_M4 := Limit_Thrust (T + R - Y);
      end if;

      Motor_Set_Ratio (MOTOR_M1, Motor_Power_M1);
      Motor_Set_Ratio (MOTOR_M2, Motor_Power_M2);
      Motor_Set_Ratio (MOTOR_M3, Motor_Power_M3);
      Motor_Set_Ratio (MOTOR_M4, Motor_Power_M4);
   end Stabilizer_Distribute_Power;

   function Stabilizer_Detect_Free_Fall return Boolean is
   begin
      if Acc.X in Free_Fall_Threshold and
         Acc.Y in Free_Fall_Threshold and
         Acc.Z in Free_Fall_Threshold
      then
         FF_Duration_Counter := FF_Duration_Counter + 1;
      else
         FF_Duration_Counter := 0;
      end if;

      return FF_Duration_Counter > 30;
   end Stabilizer_Detect_Free_Fall;

   function Stabilizer_Detect_Landing return Boolean is
   begin
      if Acc.Z in Landing_Threshold then
         Landing_Duration_Counter := Landing_Duration_Counter + 1;
      else
         Landing_Duration_Counter := 0;
      end if;

      return Landing_Duration_Counter > 30;
   end Stabilizer_Detect_Landing;

   procedure Stabilizer_Update_Attitude is
      V_Speed_Tmp : Float;
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
      V_Speed_Tmp := V_Speed +
        Dead_Band (Acc_WZ, V_Acc_Deadband) * FUSION_UPDATE_DT;

      Constrain (V_Speed_Tmp, -V_Speed_Limit, V_Speed_Limit);
      V_Speed := V_Speed_Tmp;

      --  Get the rate commands from the roll, pitch, yaw attitude PID's
      Controller_Correct_Attitude_Pid (Euler_Roll_Actual,
                                       Euler_Pitch_Actual,
                                       Euler_Yaw_Actual,
                                       Euler_Roll_Desired,
                                       Euler_Pitch_Desired,
                                       -Euler_Yaw_Desired);
      Controller_Get_Desired_Rate (Roll_Rate_Desired, Pitch_Rate_Desired,
                                   Yaw_Rate_Desired);
   end Stabilizer_Update_Attitude;

   procedure Stabilizer_Update_Rate is
   begin
      --  If CF is in Rate mode, give the angles given by the pilot
      --  as input for the Rate PIDs
      if Roll_Type = RATE then
         Roll_Rate_Desired := Euler_Roll_Desired;
      end if;

      if Pitch_Type = RATE then
         Pitch_Rate_Desired := Euler_Pitch_Desired;
      end if;

      if Yaw_Type = RATE then
         Yaw_Rate_Desired := -Euler_Yaw_Desired;
      end if;

      Controller_Correct_Rate_PID (Gyro.X, -Gyro.Y, Gyro.Z,
                                   Roll_Rate_Desired,
                                   Pitch_Rate_Desired,
                                   Yaw_Rate_Desired);
      Controller_Get_Actuator_Output (Actuator_Roll,
                                      Actuator_Pitch,
                                      Actuator_Yaw);
   end Stabilizer_Update_Rate;

   procedure Stabilizer_Alt_Hold_Update is
      Asl_Tmp             : Float;
      Asl_Long_Tmp        : Float;
      V_Speed_Tmp         : Float;
      V_Speed_ASL_Tmp     : Float;
      Alt_Hold_Target_Tmp : Float;
      LPS25H_Data_Valid   : Boolean;
      Prev_Integ          : Float;
      Baro_V_Speed        : Float;
      Alt_Hold_PID_Out    : Float;
      Raw_Thrust          : T_Int16;
   begin
      --  Get altitude hold commands from the pilot
      Commander_Get_Alt_Hold (Alt_Hold, Set_Alt_Hold, Alt_Hold_Change);

      --  Get barometer altitude estimations
      LPS25h_Get_Data (Pressure, Temperature, Asl_Raw, LPS25H_Data_Valid);
      if LPS25H_Data_Valid then
         Asl_Tmp := Asl * Asl_Alpha + Asl_Raw * (1.0 - Asl_Alpha);
         Asl_Long_Tmp := Asl_Long * Asl_Alpha_Long
           + Asl_Raw * (1.0 - Asl_Alpha_Long);
         Constrain (Asl_Tmp, T_Altitude'First, T_Altitude'Last);
         Constrain (Asl_Long_Tmp, T_Altitude'First, T_Altitude'Last);
         Asl := Asl_Tmp;
         Asl_Long := Asl_Long_Tmp;
      end if;

      --  Estimate vertical speed based on successive barometer readings
      V_Speed_ASL_Tmp := Dead_Band (Asl - Asl_Long, V_Speed_ASL_Deadband);
      Constrain (V_Speed_ASL_Tmp, -V_Speed_Limit, V_Speed_Limit);
      V_Speed_ASL := V_Speed_ASL_Tmp;
      --  Estimate vertical speed based on Acc - fused with baro
      --  to reduce drift
      V_Speed_Tmp := V_Speed * V_Bias_Alpha +
        V_Speed_ASL * (1.0 - V_Bias_Alpha);
      Constrain (V_Speed_Tmp, -V_Speed_Limit, V_Speed_Limit);
      V_Speed := V_Speed_Tmp;
      V_Speed_Acc := V_Speed;

      --  Reset Integral gain of PID controller if being charged
      if PM_Is_Discharging = 0 then
         Alt_Hold_PID.Integ := 0.0;
      end if;

      --  Altitude hold mode just activated, set target altitude as current
      --  altitude. Reuse previous integral term as a starting point
      if Set_Alt_Hold = 1 then
         --  Set target altitude to current altitude
         Alt_Hold_Target := Asl;
         --  Cache last integral term for reuse after PID init
         Prev_Integ := Alt_Hold_PID.Integ;

         --  Reset PID controller
         Altitude_Pid.Pid_Init (Alt_Hold_PID,
                                Asl,
                                ALT_HOLD_KP,
                                ALT_HOLD_KP,
                                ALT_HOLD_KD,
                                -DEFAULT_PID_INTEGRATION_LIMIT,
                                DEFAULT_PID_INTEGRATION_LIMIT,
                                ALTHOLD_UPDATE_DT);

         Alt_Hold_PID.Integ := Prev_Integ;

         Altitude_Pid.Pid_Update (Alt_Hold_PID, Asl, False);
         Alt_Hold_PID_Val := Altitude_Pid.Pid_Get_Output (Alt_Hold_PID);
      end if;

      if Alt_Hold = 1 then
         --  Update the target altitude and the PID
         Alt_Hold_Target_Tmp := Alt_Hold_Target +
           Alt_Hold_Change / Alt_Hold_Change_SENS;
         Constrain (Alt_Hold_Target_Tmp, T_Altitude'First, T_Altitude'Last);
         Alt_Hold_Target := Alt_Hold_Target_Tmp;
         Altitude_Pid.Pid_Set_Desired (Alt_Hold_PID, Alt_Hold_Target);

         --  Compute error (current - target), limit the error
         Alt_Hold_Err := Dead_Band (Asl - Alt_Hold_Target, Err_Deadband);
         Constrain (Alt_Hold_Err, -Alt_Hold_Err_Max, Alt_Hold_Err_Max);
         pragma Assert (Alt_Hold_Err
                 in Altitude_Pid.T_Error'First .. Altitude_Pid.T_Error'Last);
         Altitude_Pid.Pid_Set_Error (Alt_Hold_PID, -Alt_Hold_Err);
         --  TODO: Pid Update ...
         Altitude_Pid.Pid_Update (Alt_Hold_PID, Asl, False);

         Baro_V_Speed := (1.0 - Pid_Alpha) * ((V_Speed_Acc * V_Speed_Acc_Fac)
                                           + (V_Speed_ASL * V_Speed_ASL_Fac));
         Constrain (Baro_V_Speed, T_Speed'First, T_Speed'Last);
         Alt_Hold_PID_Out := Altitude_Pid.Pid_Get_Output (Alt_Hold_PID);
         Constrain (Alt_Hold_PID_Out, T_Altitude'First, T_Altitude'Last);
         Constrain (Alt_Hold_PID_Val, T_Altitude'First, T_Altitude'Last);
         pragma Assert (Pid_Alpha in T_Alpha'First * 1.0 .. T_Alpha'Last);
         Alt_Hold_PID_Val := Pid_Alpha * Alt_Hold_PID_Val +
           Baro_V_Speed + Alt_Hold_PID_Out;
         Constrain (Alt_Hold_PID_Val, T_Altitude'First, T_Altitude'Last);
         pragma Assert (Pid_Asl_Fac
                        in T_Motor_Fac'First * 1.0 .. T_Motor_Fac'Last);
         Raw_Thrust := Truncate_To_T_Int16 (Alt_Hold_PID_Val * Pid_Asl_Fac);
         Actuator_Thrust := Limit_Thrust (T_Int32 (Raw_Thrust)
                                          + T_Int32 (Alt_Hold_Base_Thrust));
         Constrain (Actuator_Thrust, Alt_Hold_Min_Thrust, Alt_Hold_Max_Thrust);
      end if;

   end Stabilizer_Alt_Hold_Update;

   --  Public functions

   procedure Stabilizer_Control_Loop
     (Attitude_Update_Counter : in out T_Uint32;
      Alt_Hold_Update_Counter : in out T_Uint32)
   is
   begin
      --  Magnetometer not used for the moment
      IMU_9_Read (Gyro, Acc, Mag);

      --  Do nothing if IMU is not calibrated correctly
      if not IMU_6_Calibrated then
         return;
      end if;

      --  Increment the counters
      Attitude_Update_Counter := Attitude_Update_Counter + 1;
      Alt_Hold_Update_Counter := Alt_Hold_Update_Counter + 1;

      --  Get commands from the pilot
      Commander_Get_RPY (Euler_Roll_Desired,
                         Euler_Pitch_Desired,
                         Euler_Yaw_Desired);
      Commander_Get_RPY_Type (Roll_Type, Pitch_Type, Yaw_Type);

      --  Detect if the CF is landed
      if FF_Recovery_Mode = 1 and Stabilizer_Detect_Landing then
         FF_Recovery_Mode := 0;
      end if;

      --  Detect if the CF is in free fall
      if Stabilizer_Detect_Free_Fall then
         FF_Recovery_Mode := 1;
         Stabilizer_Distribute_Power (T_Uint16'Last,
                                      0,
                                      0,
                                      0);
         return;
      end if;

      --  Update attitude at IMU_UPDATE_FREQ / ATTITUDE_UPDATE_RATE_DIVIDER
      --  By default the result is 250 Hz
      if Attitude_Update_Counter >= ATTITUDE_UPDATE_RATE_DIVIDER then
         --  Update attitude
         Stabilizer_Update_Attitude;
         --  Reset the counter
         Attitude_Update_Counter := 0;
      end if;

      if IMU_Has_Barometer and
        Alt_Hold_Update_Counter >= ALTHOLD_UPDATE_RATE_DIVIDER
      then
         --  Altidude hold mode update
         Stabilizer_Alt_Hold_Update;
         --  Reset the counter
         Alt_Hold_Update_Counter := 0;
         null;
      end if;

      Stabilizer_Update_Rate;

      if Alt_Hold = 0 or not IMU_Has_Barometer then
         --  Get thrust from the commander if alt hold mode
         --  not activated/working
         Commander_Get_Thrust (Actuator_Thrust);
      else
         --  Added so thrust can be set to 0 while in altitude hold mode
         --  after disconnect
         Commander_Watchdog;
      end if;

      if Actuator_Thrust > 0 then
         --  Ensure that there is no overflow when changing Yaw sign
         if Actuator_Yaw = T_Int16'First then
            Actuator_Yaw := -T_Int16'Last;
         end if;

         Stabilizer_Distribute_Power (Actuator_Thrust, Actuator_Roll,
                                      Actuator_Pitch, -Actuator_Yaw);
      else
         Stabilizer_Distribute_Power (0, 0, 0, 0);
         Controller_Reset_All_Pid;
      end if;
   end Stabilizer_Control_Loop;

end Stabilizer_Pack;
