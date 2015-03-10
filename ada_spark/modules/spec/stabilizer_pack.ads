with Interfaces.C.Extensions; use Interfaces.C.Extensions;

with Types; use Types;
with IMU_Pack; use IMU_Pack;
with LPS25h_pack; use LPS25h_pack;
with Pid_Pack;
pragma Elaborate_All (Pid_Pack);
with Pid_Parameters; use Pid_Parameters;
with Commander_Pack; use Commander_Pack;
with Controller_Pack; use Controller_Pack;

package Stabilizer_Pack
with SPARK_Mode
is
   --  TODO: change altitude types
   package Altitude_Pid is new Pid_Pack (T_Rate'First,
                                         T_Rate'Last,
                                         Float'First / 4.0,
                                         Float'Last / 4.0,
                                         MIN_RATE_COEFF,
                                         MAX_RATE_COEFF);
   --  Types

   --  Variables and constants

   --  Defines in what divided update rate should the attitude
   --  control loop run relative the rate control loop.

   ATTITUDE_UPDATE_RATE_DIVIDER   : constant := 2;
   ATTITUDE_UPDATE_RATE_DIVIDER_F : constant := 2.0;
   FUSION_UPDATE_DT : constant Float :=
                        (1.0 / (IMU_UPDATE_FREQ / ATTITUDE_UPDATE_RATE_DIVIDER_F)); --  250hz

   --  Barometer/ Altitude hold stuff
   ALTHOLD_UPDATE_RATE_DIVIDER   : constant := 5; --  500hz/5 = 100hz for barometer measurements
   ALTHOLD_UPDATE_RATE_DIVIDER_F : constant := 5.0;
   ALTHOLD_UPDATE_DT : constant Float :=
                         (1.0 / (IMU_UPDATE_FREQ / ALTHOLD_UPDATE_RATE_DIVIDER_F));  -- 100hz

   Gyro : Gyroscope_Data     := (0.0, 0.0, 0.0);  --  Gyrometer axis data in deg/s
   Acc  : Accelerometer_Data := (0.0, 0.0, 0.0);  --  Accelerometer axis data in mG
   Mag  : Magnetometer_Data  := (0.0, 0.0, 0.0);  --  Magnetometer axis data in testla

   Euler_Roll_Actual   : T_Angle := 0.0;
   Euler_Pitch_Actual  : T_Angle := 0.0;
   Euler_Yaw_Actual    : T_Angle := 0.0;
   Euler_Roll_Desired  : T_Angle := 0.0;
   Euler_Pitch_Desired : T_Angle := 0.0;
   Euler_Yaw_Desired   : T_Angle := 0.0;
   Roll_Rate_Desired   : T_Rate  := 0.0;
   Pitch_Rate_Desired  : T_Rate  := 0.0;
   Yaw_Rate_Desired    : T_Rate  := 0.0;

   --  Barometer variables
   Temperature  : T_Temperature := 0.0; --  Temperature from barometer
   Pressure     : T_Pressure    := 1000.0; --  Pressure from barometer
   Asl          : T_Altitude    := 0.0; --  Smoothed asl
   Asl_Raw      : T_Altitude    := 0.0; --  Raw asl
   Asl_Long     : T_Altitude    := 0.0; --  Long term asl

   --  Altitude hold variables
   Alt_Hold_PID : Altitude_Pid.Pid_Object;  --  Used for altitute hold mode.
   --  It gets reset when the bat status changes
   Alt_Hold     : bool := 0;  --  Currently in altitude hold mode
   Set_Alt_Hold : bool := 0;  --  Hover mode has just been activated
   Acc_WZ       : Float   := 0.0;
   Acc_MAG      : Float   := 0.0;
   V_Speed_ASL  : Float   := 0.0;
   V_Speed_Acc  : Float   := 0.0;
   --  Vertical speed (world frame) integrated from vertical acceleration
   V_Speed      : T_Speed := 0.0;

   Alt_Hold_PID_Val : Float := 0.0;  --  Output of the PID controller
   Alt_Hold_Err     : Float := 0.0;  --  Altitude error

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
   V_Acc_Deadband       : Positive_Float := 0.05;  --  Vertical acceleration deadband
   V_Speed_ASL_Deadband : Positive_Float := 0.005; --  Vertical speed based on barometer readings deadband
   V_Speed_Limit        : Float := 0.05;    --  used to constrain vertical velocity
   Err_Deadband         : Float := 0.00;    --  error (target - altitude) deadband
   V_Bias_Alpha         : Float := 0.98;    --  Blending factor we use to fuse v_Speed_ASL and v_Speed_Acc
   Asl_Alpha            : Float := 0.92;    --  Short term smoothing
   Asl_Alpha_Long       : Float := 0.93;    --  Long term smoothing

   Alt_Hold_Min_Thrust  : T_Uint16 := 00000; --  Minimum hover thrust - not used yet
   Alt_Hold_Base_Thrust : T_Uint16 := 43000; --  approximate throttle needed when in perfect hover. More weight/older battery can use a higher value
   Alt_Hold_Max_Thrust  : T_Uint16 := 60000; --  max altitude hold thrust

   Roll_Type        : RPY_Type := RATE;
   Pitch_Type       : RPY_Type := RATE;
   Yaw_Type         : RPY_Type := RATE;

   Actuator_Thrust : T_Uint16 := 0;
   Actuator_Roll   : T_Int16  := 0;
   Actuator_Pitch  : T_Int16  := 0;
   Actuator_Yaw    : T_Int16  := 0;

   Motor_Power_M4  : T_Uint16 := 0;
   Motor_Power_M2  : T_Uint16 := 0;
   Motor_Power_M1  : T_Uint16 := 0;
   Motor_Power_M3  : T_Uint16 := 0;

   --  Export all of these varaibles frome the C part,
   --  so the C part can debug/log them easily
   pragma Export (C, Gyro, "gyro");
   pragma Export (C, Acc, "acc");
   pragma Export (C, Mag, "mag");

   pragma Export (C, Euler_Roll_Actual, "eulerRollActual");
   pragma Export (C, Euler_Pitch_Actual, "eulerPitchActual");
   pragma Export (C, Euler_Yaw_Actual, "eulerYawActual");
   pragma Export (C, Euler_Roll_Desired, "eulerRollDesired");
   pragma Export (C, Euler_Pitch_Desired, "eulerPitchDesired");
   pragma Export (C, Euler_Yaw_Desired, "eulerYawDesired");
   pragma Export (C, Roll_Rate_Desired, "rollRateDesired");
   pragma Export (C, Pitch_Rate_Desired, "pitchRateDesired");
   pragma Export (C, Yaw_Rate_Desired, "yawRateDesired");

   pragma Export (C, Temperature, "temperature");
   pragma Export (C, Pressure, "pressure");
   pragma Export (C, Asl, "asl");
   pragma Export (C, Asl_Raw, "aslRaw");
   pragma Export (C, Asl_Long, "aslLong");

   pragma Export (C, Alt_Hold_PID, "altHoldPID");
   pragma Export (C, Alt_Hold, "altHold");
   pragma Export (C, Set_Alt_Hold, "setAltHold");
   pragma Export (C, Acc_WZ, "accWZ");
   pragma Export (C, Acc_MAG, "accMAG");
   pragma Export (C, V_Speed_ASL, "vSpeedASL");
   pragma Export (C, V_Speed_Acc, "vSpeedAcc");
   pragma Export (C, V_Speed, "vSpeed");
   pragma Export (C, Alt_Hold_PID_Val, "altHoldPIDVal");
   pragma Export (C, Alt_Hold_Err, "altHoldErr");

   pragma Export (C, Alt_Hold_Kp, "altHoldKp");
   pragma Export (C, Alt_Hold_Ki, "altHoldKi");
   pragma Export (C, Alt_Hold_Kd, "altHoldKd");
   pragma Export (C, Alt_Hold_Change, "altHoldChange");
   pragma Export (C, Alt_Hold_Target, "altHoldTarget");
   pragma Export (C, Alt_Hold_Err_Max, "altHoldErrMax");
   pragma Export (C, Alt_Hold_Change_SENS, "altHoldChange_SENS");
   pragma Export (C, Pid_Asl_Fac, "pidAslFac");
   pragma Export (C, Pid_Alpha, "pidAlpha");
   pragma Export (C, V_Speed_ASL_Fac, "vSpeedASLFac");
   pragma Export (C, V_Speed_Acc_Fac, "vSpeedAccFac");
   pragma Export (C, V_Acc_Deadband, "vAccDeadband");
   pragma Export (C, V_Speed_ASL_Deadband, "vSpeedASLDeadband");
   pragma Export (C, V_Speed_Limit, "vSpeedLimit");
   pragma Export (C, Err_Deadband, "errDeadband");
   pragma Export (C, V_Bias_Alpha, "vBiasAlpha");
   pragma Export (C, Asl_Alpha, "aslAlpha");
   pragma Export (C, Asl_Alpha_Long, "aslAlphaLong");

   pragma Export (C, Alt_Hold_Min_Thrust, "altHoldMinThrust");
   pragma Export (C, Alt_Hold_Base_Thrust, "altHoldBaseThrust");
   pragma Export (C, Alt_Hold_Max_Thrust, "altHoldMaxThrust");

   pragma Export (C, Actuator_Thrust, "actuatorThrust");
   pragma Export (C, Actuator_Roll, "actuatorRoll");
   pragma Export (C, Actuator_Pitch, "actuatorPitch");
   pragma Export (C, Actuator_Yaw, "actuatorYaw");

   pragma Export (C, Roll_Type, "rollType");
   pragma Export (C, Pitch_Type, "pitchType");
   pragma Export (C, Yaw_Type, "yawType");

   pragma Export (C, Motor_Power_M4, "motorPowerM4");
   pragma Export (C, Motor_Power_M2, "motorPowerM2");
   pragma Export (C, Motor_Power_M1, "motorPowerM1");
   pragma Export (C, Motor_Power_M3, "motorPowerM3");

   procedure Modif_Variables;
   pragma Export (C, Modif_Variables, "ada_modif_variables");

   --  Procedures and functions

   procedure Stabilizer_Control_Loop
     (Attitude_Update_Counter : in out T_Uint32;
      Alt_Hold_Update_Counter : in out T_Uint32)
     with
       Global => (Input  => (V_Acc_Deadband,
                             Alt_Hold),
                  In_Out => (Gyro, Acc, Mag,
                             Euler_Roll_Desired,
                             Euler_Pitch_Desired,
                             Euler_Yaw_Desired,
                             Roll_Rate_Desired,
                             Pitch_Rate_Desired,
                             Yaw_Rate_Desired,
                             Euler_Roll_Actual,
                             Euler_Pitch_Actual,
                             Euler_Yaw_Actual,
                             Roll_Type,
                             Pitch_Type,
                             Yaw_Type,
                             Acc_WZ,
                             Acc_MAG,
                             V_Speed,
                             Actuator_Roll,
                             Actuator_Pitch,
                             Actuator_Yaw,
                             Actuator_Thrust,
                             Motor_Power_M1,
                             Motor_Power_M2,
                             Motor_Power_M3,
                             Motor_Power_M4,
                             Attitude_PIDs,
                             Rate_PIDs)
                 );
   pragma Export (C, Stabilizer_Control_Loop, "ada_stabilizerControlLoop");

private

   procedure Stabilizer_Alt_Hold_Update;

   procedure Stabilizer_Update_Attitude
     with
       Global => (Input  => (Euler_Roll_Desired,
                             Euler_Pitch_Desired,
                             Euler_Yaw_Desired,
                             Gyro,
                             Acc,
                             V_Acc_Deadband),
                  Output => (Euler_Roll_Actual,
                             Euler_Pitch_Actual,
                             Euler_Yaw_Actual,
                             Roll_Rate_Desired,
                             Pitch_Rate_Desired,
                             Yaw_Rate_Desired,
                             Acc_WZ,
                             Acc_MAG),
                  In_Out => (V_Speed,
                             Attitude_PIDs));

   procedure Stabilizer_Update_Rate
     with
       Global => (Input  => (Roll_Type,
                             Pitch_Type,
                             Yaw_Type,
                             Euler_Roll_Desired,
                             Euler_Pitch_Desired,
                             Euler_Yaw_Desired,
                             Gyro),
                  Output => (Actuator_Roll,
                             Actuator_Pitch,
                             Actuator_Yaw),
                  In_Out => (Roll_Rate_Desired,
                             Pitch_Rate_Desired,
                             Yaw_Rate_Desired,
                             Rate_PIDs));

   procedure Stabilizer_Distribute_Power (Thrust : T_Uint16;
                                          Roll   : T_Int16;
                                          Pitch  : T_Int16;
                                          Yaw    : T_Int16)
     with
       Global => (Output => (Motor_Power_M1,
                             Motor_Power_M2,
                             Motor_Power_M3,
                             Motor_Power_M4));

   function Dead_Band (Value     : Float;
                       Threshold : Positive_Float) return Float;
   pragma Inline (Dead_Band);

   function Limit_Thrust (Value : T_Int32) return T_Uint16;
   pragma Inline (Limit_Thrust);

end Stabilizer_Pack;
