with IMU_Pack; use IMU_Pack;
with Pid_Pack; use Pid_Pack;
with Interfaces; use Interfaces;
with Interfaces.C; use Interfaces.C;

package Stabilizer_Pack is

   --  Types
   type Axis_3F is record
      X : Float;
      Y : Float;
      Z : Float;
   end record;
   pragma Convention (C, Axis_3F);

   type RPY_Type is (RATE, ANGLE);
   for RPY_Type use (RATE => 0, ANGLE => 1);
   --pragma Convention (C, RPY_Type);
   for RPY_Type'Size use Interfaces.C.int'Size;

   --  Variables and constants

   --  Defines in what divided update rate should the attitude
   --  control loop run relative the rate control loop.

   ATTITUDE_UPDATE_RATE_DIVIDER : Unsigned_32 := 2;
   FUSION_UPDATE_DT : Float :=
     (1.0 / (IMU_UPDATE_FREQ / Float(ATTITUDE_UPDATE_RATE_DIVIDER))); --  250hz

   --  Barometer/ Altitude hold stuff
   ALTHOLD_UPDATE_RATE_DIVIDER : Unsigned_32 := 5; --  500hz/5 = 100hz for barometer measurements
   ALTHOLD_UPDATE_DT : Float :=
     (1.0 / (IMU_UPDATE_FREQ / Float(ALTHOLD_UPDATE_RATE_DIVIDER)));  -- 500hz

   Gyro : Axis_3F := (0.0, 0.0, 0.0);  --  Gyrometer axis data in deg/s
   Acc  : Axis_3F := (0.0, 0.0, 0.0);  --  Accelerometer axis data in mG
   Mag  : Axis_3F := (0.0, 0.0, 0.0);  --  Magnetometer axis data in testla

   Euler_Roll_Actual   : Float;
   Euler_Pitch_Actual  : Float;
   Euler_Yaw_Actual    : Float;
   Euler_Roll_Desired  : Float;
   Euler_Pitch_Desired : Float;
   Euler_Yaw_Desired   : Float;
   Roll_Rate_Desired   : Float;
   Pitch_Rate_Desired  : Float;
   Yaw_Rate_Desired    : Float;

   --  Barometer variables
   Temperature  : Float; --  Temperature from barometer
   Pressure     : Float; --  Pressure from barometer
   Asl          : Float; --  Smoothed asl
   Asl_Raw      : Float; --  Raw asl
   Asl_Long     : Float; --  Long term asl

   --  Altitude hold variables
   Alt_Hold_PID : Pid_Object;        --  Used for altitute hold mode.
   --  It gets reset when the bat status changes
   Alt_Hold     : Boolean := False;  --  Currently in altitude hold mode
   Set_Alt_Hold : Boolean := False;  --  Hover mode has just been activated
   Acc_WZ       : Float   := 0.0;
   Acc_MAG      : Float   := 0.0;
   V_Speed_ASL  : Float   := 0.0;
   V_Speed_Acc  : Float   := 0.0;
   V_Speed      : Float   := 0.0;    --  Vertical speed (world frame) integrated
   --  from vertical acceleration
   Alt_Hold_PID_Val : Float;         --  Output of the PID controller
   Alt_Hold_Err     : Float;         --  Different between target and current altitude

   --  Altitude hold & barometer params

   --  PID gain constantsused everytime we reinitialise the PID controller
   Alt_Hold_Kp          : Float := 0.5;
   Alt_Hold_Ki          : Float := 0.18;
   Alt_Hold_Kd          : Float := 0.0;
   Alt_Hold_Change      : Float := 0.0;     --  Change in target altitude
   Alt_Hold_Target      : Float := -1.0;    --  Target altitude
   Alt_Hold_Err_Max     : Float := 1.0;     --  Max cap on current estimated altitude vs target altitude in meters
   Alt_Hold_Change_SENS : Float := 200.0;   --  Sensitivity of target altitude change (thrust input control) while hovering. Lower = more sensitive & faster changes

   Pid_Asl_Fac          : Float := 13000.0; --  Relates meters asl to thrust
   Pid_Alpha            : Float := 0.8;     --  PID Smoothing //TODO: shouldnt need to do this

   V_Speed_ASL_Fac      : Float := 0.0;     --  Multiplier
   V_Speed_Acc_Fac      : Float := -48.0;   --  Multiplier
   V_Acc_Deadband       : Float := 0.05;    --  Vertical acceleration deadband
   V_Speed_ASL_Deadband : Float := 0.005;   --  Vertical speed based on barometer readings deadband
   V_Speed_Limit        : Float := 0.05;    --  used to constrain vertical velocity
   Err_Deadband         : Float := 0.00;    --  error (target - altitude) deadband
   V_Bias_Alpha         : Float := 0.98;    --  Blending factor we use to fuse v_Speed_ASL and v_Speed_Acc
   Asl_Alpha            : Float := 0.92;    --  Short term smoothing
   Asl_Alpha_Long       : Float := 0.93;    --  Long term smoothing

   Alt_Hold_Min_Thrust  : Unsigned_16 := 00000; --  Minimum hover thrust - not used yet
   Alt_Hold_Base_Thrust : Unsigned_16 := 43000; --  approximate throttle needed when in perfect hover. More weight/older battery can use a higher value
   Alt_Hold_Max_Thrust  : Unsigned_16 := 60000; --  max altitude hold thrust

   Roll_Type  : RPY_Type;
   Pitch_Type : RPY_Type;
   Yaw_Type   : RPY_Type;

   Actuator_Thrust : Unsigned_16;
   Actuator_Roll   : Integer_16;
   Actuator_Pitch  : Integer_16;
   Actuator_Yaw    : Integer_16;

   Motor_Power_M4  : Unsigned_32;
   Motor_Power_M2  : Unsigned_32;
   Motor_Power_M1  : Unsigned_32;
   Motor_Power_M3  : Unsigned_32;

   --  Import all of these varaibles frome the C part,
   --  so the C part can debug/log them easily
   pragma Export(C, Gyro, "gyro");
   pragma Export(C, Acc , "acc");
   pragma Export(C, Mag , "mag");

   pragma Export(C, Euler_Roll_Actual  , "eulerRollActual");
   pragma Export(C, Euler_Pitch_Actual , "eulerPitchActual");
   pragma Export(C, Euler_Yaw_Actual   , "eulerYawActual");
   pragma Export(C, Euler_Roll_Desired , "eulerRollDesired");
   pragma Export(C, Euler_Pitch_Desired, "eulerPitchDesired");
   pragma Export(C, Euler_Yaw_Desired  , "eulerYawDesired");
   pragma Export(C, Roll_Rate_Desired  , "rollRateDesired");
   pragma Export(C, Pitch_Rate_Desired , "pitchRateDesired");
   pragma Export(C, Yaw_Rate_Desired   , "yawRateDesired");

   pragma Export(C, Temperature, "temperature");
   pragma Export(C, Pressure   , "pressure");
   pragma Export(C, Asl        , "asl");
   pragma Export(C, Asl_Raw    , "aslRaw");
   pragma Export(C, Asl_Long   , "aslLong");

   pragma Export(C, Alt_Hold_PID    , "altHoldPID");
   pragma Export(C, Alt_Hold        , "altHold");
   pragma Export(C, Set_Alt_Hold    , "setAltHold");
   pragma Export(C, Acc_WZ          , "accWZ");
   pragma Export(C, Acc_MAG         , "accMAG");
   pragma Export(C, V_Speed_ASL     , "vSpeedASL");
   pragma Export(C, V_Speed_Acc     , "vSpeedAcc");
   pragma Export(C, V_Speed         , "vSpeed");
   pragma Export(C, Alt_Hold_PID_Val, "altHoldPIDVal");
   pragma Export(C, Alt_Hold_Err    , "altHoldErr");

   pragma Export(C, Alt_Hold_Kp         , "altHoldKp");
   pragma Export(C, Alt_Hold_Ki         , "altHoldKi");
   pragma Export(C, Alt_Hold_Kd         , "altHoldKd");
   pragma Export(C, Alt_Hold_Change     , "altHoldChange");
   pragma Export(C, Alt_Hold_Target     , "altHoldTarget");
   pragma Export(C, Alt_Hold_Err_Max    , "altHoldErrMax");
   pragma Export(C, Alt_Hold_Change_SENS, "altHoldChange_SENS");
   pragma Export(C, Pid_Asl_Fac         , "pidAslFac");
   pragma Export(C, Pid_Alpha           , "pidAlpha");
   pragma Export(C, V_Speed_ASL_Fac     , "vSpeedASLFac");
   pragma Export(C, V_Speed_Acc_Fac     , "vSpeedAccFac");
   pragma Export(C, V_Acc_Deadband      , "vAccDeadband");
   pragma Export(C, V_Speed_ASL_Deadband, "vSpeedASLDeadband");
   pragma Export(C, V_Speed_Limit       , "vSpeedLimit");
   pragma Export(C, Err_Deadband        , "errDeadband");
   pragma Export(C, V_Bias_Alpha        , "vBiasAlpha");
   pragma Export(C, Asl_Alpha           , "aslAlpha");
   pragma Export(C, Asl_Alpha_Long      , "aslAlphaLong");

   pragma Export(C, Alt_Hold_Min_Thrust , "altHoldMinThrust");
   pragma Export(C, Alt_Hold_Base_Thrust, "altHoldBaseThrust");
   pragma Export(C, Alt_Hold_Max_Thrust , "altHoldMaxThrust");

   pragma Export(C, Actuator_Thrust, "actuatorThrust");
   pragma Export(C, Actuator_Roll  , "actuatorRoll");
   pragma Export(C, Actuator_Pitch , "actuatorPitch");
   pragma Export(C, Actuator_Yaw   , "actuatorYaw");

   pragma Export(C, Roll_Type , "rollType");
   pragma Export(C, Pitch_Type, "pitchType");
   pragma Export(C, Yaw_Type  , "yawType");

   pragma Export(C, Motor_Power_M4, "motorPowerM4");
   pragma Export(C, Motor_Power_M2, "motorPowerM2");
   pragma Export(C, Motor_Power_M1, "motorPowerM1");
   pragma Export(C, Motor_Power_M3, "motorPowerM3");

   procedure Modif_Variables;
   pragma Export (C, Modif_Variables, "ada_modif_variables");

end Stabilizer_Pack;
