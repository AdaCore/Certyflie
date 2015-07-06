with Ada.Real_Time; use Ada.Real_Time;

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
   procedure FF_Check_Event (Acc : Accelerometer_Data);

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
   subtype Landing_Threshold   is T_Acc range 0.954 .. 0.99;

   type FF_Acc_Data_Collector (Number_Of_Samples : Natural) is record
      Samples : T_Acc_Array (1 .. Number_Of_Samples) := (others => 0.0);
      Index   : Integer := 1;
   end record;

   --  Global variables and constants

   FF_MODE                   : Free_Fall_Mode := ENABLED
     with Part_Of => FF_Parameters;
   MAX_RECOVERY_THRUST       : T_Uint16 := 59_000
     with Part_Of => FF_Parameters;
   MIN_RECOVERY_THRUST       : T_Uint16 := 30_000
     with Part_Of => FF_Parameters;
   RECOVERY_THRUST_DECREMENT : T_Uint16 := 100
     with Part_Of => FF_Parameters;
   FF_DURATION               : T_Uint16 := 30
     with Part_Of => FF_Parameters;
   LANDING_NUMBER_OF_SAMPLES : Natural := 15
     with Part_Of => FF_Parameters;
   STABILIZATION_PERIOD_AFTER_LANDING : Time_Span := Milliseconds (1_000)
     with Part_Of => FF_Parameters;
   RECOVERY_TIMEOUT : Time_Span := Milliseconds (2_000)
     with Part_Of => FF_Parameters;

   FF_Duration_Counter      : T_Uint16 := 0
     with Part_Of => FF_State;
   In_Recovery              : bool := 0
     with Part_Of => FF_State;
   Recovery_Thrust          : T_Uint16 := MAX_RECOVERY_THRUST
     with Part_Of => FF_State;
   Last_Landing_Time        : Time := Time_First
     with Part_Of => FF_State;
   Last_FF_Detected_Time    : Time := Time_First
     with Part_Of => FF_State;
   Landing_Data_Collector   : FF_Acc_Data_Collector (LANDING_NUMBER_OF_SAMPLES)
     with Part_Of => FF_State;

   --  Procedures and functions

   --  Detect if the drone is in free fall with accelerometer data.
   procedure FF_Detect_Free_Fall
     (Acc         : Accelerometer_Data;
      FF_Detected : out Boolean);

   --  Detect if the drone has landed with accelerometer data.
   procedure FF_Detect_Landing (Landing_Detected : out Boolean);

   --  Ensures that we cut the recovery after a certain time, even if it has
   --  not recovered.
   procedure FF_Watchdog;

   --  Add accelerometer sample for Z axis
   --  to the specified FF_Acc_Data_Collector.
   procedure Add_Acc_Z_Sample
     (Acc_Z          : T_Acc;
      Data_Collector : in out FF_Acc_Data_Collector);
   pragma Inline (Add_Acc_Z_Sample);

   --  Calculate variance and mean
   procedure Calculate_Variance_And_Mean
     (Data_Collector : FF_Acc_Data_Collector;
      Variance       : out Float;
      Mean           : out Float);
   pragma Inline (Calculate_Variance_And_Mean);

   --  Get the time since last landing after a recovery from a free fall.
   function Get_Time_Since_Last_Landing return Time_Span is
     (Clock - Last_Landing_Time);
   pragma Inline (Get_Time_Since_Last_Landing);

   --  Get the time since the last free fall detection.
   function Get_Time_Since_Last_Free_Fall return Time_Span is
     (Clock - Last_FF_Detected_Time);

end Free_Fall_Pack;
