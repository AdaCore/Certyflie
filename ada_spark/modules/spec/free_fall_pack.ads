with Types; use Types;
with IMU_Pack; use IMU_Pack;
with Commander_Pack; use Commander_Pack;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;


package Free_Fall_Pack
with SPARK_Mode,
  Abstract_State => (FF_Parameters, FF_State),
  Initializes => (FF_Parameters, FF_State)
is
   --  Types

   type Free_Fall_Mode is (DISABLED, ENABLED);
   for Free_Fall_Mode use (DISABLED => 0, ENABLED => 1);
   for Free_Fall_Mode'Size use Interfaces.C.int'Size;

   --  Procedures and functions

   --  Check if an event (Free fall or Landing) has occured giving it
   --  accelerometer data.
   procedure FF_Check_Event (Acc         : Accelerometer_Data);

   --  Override the previous commands if in recovery mode.
   procedure FF_Get_Recovery_Commands
     (Euler_Roll_Desired  : in out Float;
      Euler_Pitch_Desired : in out Float;
      Roll_Type           : in out RPY_Type;
      Pitch_Type          : in out RPY_Type);

   --  Override the previous thrust if in recovery mode.
   procedure FF_Get_Recovery_Thrust (Thrust : in out T_Uint16);

private
   --  Types
   subtype Free_Fall_Threshold is T_Acc range -0.2 .. 0.2;
   subtype Landing_Threshold   is T_Acc range 0.97 .. 1.1;

   --  Global variables

   FF_MODE                   : Free_Fall_Mode := ENABLED
     with Part_Of => FF_Parameters;
   MAX_RECOVERY_THRUST       : T_Uint16 := 59_000
     with Part_Of => FF_Parameters;
   MIN_RECOVERY_THRUST       : T_Uint16 := 36_000
     with Part_Of => FF_Parameters;
   RECOVERY_THRUST_DECREMENT : T_Uint16 := 100
     with Part_Of => FF_Parameters;
   FF_DURATION               : T_Uint16 := 30
     with Part_Of => FF_Parameters;
   LANDING_DURATION          : T_Uint16 := 15
     with Part_Of => FF_Parameters;

   --  Exported variables to modify from the client
   pragma Export (C, FF_MODE, "freeFallMode");
   pragma Export (C, MAX_RECOVERY_THRUST, "maxRecoveryThrust");
   pragma Export (C, MIN_RECOVERY_THRUST, "minRecoveryThrust");
   pragma Export (C, RECOVERY_THRUST_DECREMENT, "recoveryThrustDecrement");
   pragma Export (C, FF_DURATION, "ffDuration");
   pragma Export (C, LANDING_DURATION, "landingDuration");

   FF_Duration_Counter      : T_Uint16 := 0
     with Part_Of => FF_State;
   In_Recovery              : bool := 0
     with Part_Of => FF_State;
   Landing_Duration_Counter : T_Uint16 := 0
     with Part_Of => FF_State;
   Recovery_Thrust          : T_Uint16 := MAX_RECOVERY_THRUST
     with Part_Of => FF_State;

   --  Exported variables to log from the client
   pragma Export (C, In_Recovery, "inRecovery");

   --  Detect if the drone is ine free fall with accelerometer data
   procedure FF_Detect_Free_Fall
     (Acc         : Accelerometer_Data;
      FF_Detected : out Boolean);

   --  Detect if the drone has landed with accelerometer data
   procedure FF_Detect_Landing
     (Acc              : Accelerometer_Data;
      Landing_Detected : out Boolean);

end Free_Fall_Pack;
