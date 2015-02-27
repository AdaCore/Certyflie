package body Controller_Pack
  with SPARK_Mode
is
   procedure Controller_Init is
   begin
      Pid_Init(Roll_Rate_Pid, 0.0, PID_ROLL_RATE_KP,
               PID_ROLL_RATE_KI, PID_ROLL_RATE_KD, IMU_UPDATE_DT);
      Pid_Init(Pitch_Rate_Pid, 0.0, PID_ROLL_RATE_KP,
               PID_ROLL_RATE_KI, PID_ROLL_RATE_KD, IMU_UPDATE_DT);
      Pid_Init(Yaw_Rate_Pid, 0.0, PID_ROLL_RATE_KP,
               PID_ROLL_RATE_KI, PID_ROLL_RATE_KD, IMU_UPDATE_DT);

      Pid_Set_Integral_Limit(Roll_Rate_Pid, PID_ROLL_RATE_INTEGRATION_LIMIT);
      Pid_Set_Integral_Limit(Pitch_Rate_Pid, PID_PITCH_RATE_INTEGRATION_LIMIT);
      Pid_Set_Integral_Limit(Yaw_Rate_Pid, PID_YAW_RATE_INTEGRATION_LIMIT);

      Pid_Init(Roll_Pid, 0.0, PID_ROLL_KP,
               PID_ROLL_KI, PID_ROLL_KD, IMU_UPDATE_DT);
      Pid_Init(Pitch_Pid, 0.0, PID_ROLL_KP,
               PID_ROLL_KI, PID_ROLL_KD, IMU_UPDATE_DT);
      Pid_Init(Yaw_Pid, 0.0, PID_ROLL_KP,
               PID_ROLL_KI, PID_ROLL_KD, IMU_UPDATE_DT);

      Pid_Set_Integral_Limit(Roll_Pid, PID_ROLL_INTEGRATION_LIMIT);
      Pid_Set_Integral_Limit(Pitch_Pid, PID_PITCH_INTEGRATION_LIMIT);
      Pid_Set_Integral_Limit(Yaw_Pid, PID_YAW_INTEGRATION_LIMIT);

      Is_Init := True;
   end Controller_Init;

   function Controller_Test return Boolean is
   begin
      return Is_Init;
   end Controller_Test;

   procedure Controller_Correct_Rate_PID(Roll_Rate_Actual   : Allowed_Floats;
                                         Pitch_Rate_Actual  : Allowed_Floats;
                                         Yaw_Rate_Actual    : Allowed_Floats;
                                         Roll_Rate_Desired  : Allowed_Floats;
                                         Pitch_Rate_Desired : Allowed_Floats;
                                         Yaw_Rate_Desired   : Allowed_Floats) is
   begin
      Pid_Set_Desired(Roll_Rate_Pid, Roll_Rate_Desired);
      Pid_Set_Desired(Pitch_Rate_Pid, Pitch_Rate_Desired);
      Pid_Set_Desired(Yaw_Rate_Pid, Yaw_Rate_Desired);

      Pid_Update(Pitch_Rate_Pid, Pitch_Rate_Actual, True);
      Pid_Update(Roll_Rate_Pid, Roll_Rate_Actual, True);
      Pid_Update(Yaw_Rate_Pid, Yaw_Rate_Actual, True);

   end Controller_Correct_Rate_PID;

   procedure Controller_Reset_All_Pid is
   begin
      Pid_Reset(Roll_Rate_Pid);
      Pid_Reset(Roll_Pid);
      Pid_Reset(Pitch_Rate_Pid);
      Pid_Reset(Pitch_Pid);
      Pid_Reset(Yaw_Rate_Pid);
      Pid_Reset(Yaw_Pid);
   end Controller_Reset_All_Pid;

   procedure Controller_Get_Actuator_Output(Actuator_Roll  : out Integer;
                                            Actuator_Pitch : out Integer;
                                            Actuator_Yaw   : out Integer) is
   begin
      Actuator_Roll := Integer(Pid_Get_Output(Roll_Rate_Pid));
      Actuator_Pitch := Integer(Pid_Get_Output(Roll_Rate_Pid));
      Actuator_Yaw := Integer(Pid_Get_Output(Yaw_Rate_Pid));
   end Controller_Get_Actuator_Output;

end Controller_Pack;
