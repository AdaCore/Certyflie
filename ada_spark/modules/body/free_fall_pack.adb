package body Free_Fall_Pack
with SPARK_Mode,
  Refined_State => (FF_Parameters => (FF_MODE,
                                      MAX_RECOVERY_THRUST,
                                      MIN_RECOVERY_THRUST,
                                      RECOVERY_THRUST_DECREMENT,
                                      FF_DURATION,
                                      LANDING_DURATION),
                    FF_State => (FF_Duration_Counter,
                                 In_Recovery,
                                 Landing_Duration_Counter,
                                 Recovery_Thrust))
is

   procedure FF_Detect_Free_Fall
     (Acc         :  Accelerometer_Data;
      FF_Detected : out Boolean) is
   begin
      if Acc.X in Free_Fall_Threshold and
        Acc.Y in Free_Fall_Threshold and
        Acc.Z in Free_Fall_Threshold
      then
         FF_Duration_Counter := FF_Duration_Counter + 1;
      else
         FF_Duration_Counter := 0;
      end if;

      FF_Detected := FF_Duration_Counter >= FF_DURATION;
   end FF_Detect_Free_Fall;

   procedure FF_Detect_Landing
     (Acc              : Accelerometer_Data;
      Landing_Detected : out Boolean)
   is
   begin
      if Acc.Z in Landing_Threshold then
         Landing_Duration_Counter := Landing_Duration_Counter + 1;
      else
         Landing_Duration_Counter := 0;
      end if;

      Landing_Detected := Landing_Duration_Counter >= LANDING_DURATION;
   end FF_Detect_Landing;

   procedure FF_Check_Event (Acc : Accelerometer_Data) is
      Has_Detected_FF : Boolean;
      Has_Landed      : Boolean;
   begin
      --  Check if FF Detection is disabled
      if FF_MODE = DISABLED then
         In_Recovery := 0;
         return;
      end if;

      --  Detect if drone has landed during a recovery
      FF_Detect_Landing (Acc, Has_Landed);
      if In_Recovery = 1 and Has_Landed then
         In_Recovery := 0;
      end if;

      --  Detect if the drone is in free fall, to enable recovery
      FF_Detect_Free_Fall (Acc, Has_Detected_FF);
      if Has_Detected_FF then
         In_Recovery := 1;
         Recovery_Thrust := MAX_RECOVERY_THRUST;
      end if;
   end FF_Check_Event;

   procedure FF_Get_Recovery_Commands
     (Euler_Roll_Desired  : in out Float;
      Euler_Pitch_Desired : in out Float;
      Roll_Type           : in out RPY_Type;
      Pitch_Type          : in out RPY_Type) is
   begin
      --  If not in recovery, keep the original commands
      if In_Recovery = 0 then
         return;
      end if;

      --  If in recovery, try to keep the drone straight
      --  by giving it 0 as roll and pitch angles
      Euler_Roll_Desired := 0.0;
      Euler_Pitch_Desired := 0.0;

      --  We change the command types if the drone is ine RATE mode
      Roll_Type := ANGLE;
      Pitch_Type := ANGLE;
   end FF_Get_Recovery_Commands;

   procedure FF_Get_Recovery_Thrust (Thrust : in out T_Uint16) is
   begin
      --  If not in recovery, keep the original thrust
      --  If the pilot has moved his joystick, the drone is not in recovery
      --  anymore
      if In_Recovery = 0 or Thrust > 0 then
         In_Recovery := 0;
         return;
      end if;

      --  If in recovery, decrement the thrust every time this function
      --  is called (In the stabilizer loop)
      Thrust := Recovery_Thrust;
      if Recovery_Thrust > MIN_RECOVERY_THRUST then
         Recovery_Thrust := Recovery_Thrust - RECOVERY_THRUST_DECREMENT;
      end if;
   end FF_Get_Recovery_Thrust;

end Free_Fall_Pack;
