------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Interfaces.C;            use Interfaces.C;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

with Commander_Pack;          use Commander_Pack;
with IMU_Pack;                use IMU_Pack;
with FreeRTOS_Pack;           use FreeRTOS_Pack;
with Types;                   use Types;

package Free_Fall_Pack
with SPARK_Mode,
  Abstract_State => (FF_State, FF_Parameters),
  Initializes    => (FF_State, FF_Parameters)
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
   --  Constants and parameters

   --  Number of samples we collect to calculate accelation variance
   --  along Z axis. Used to detect landing.
   LANDING_NUMBER_OF_SAMPLES : constant Natural := 2;

   --  Thrust related variables.
   MAX_RECOVERY_THRUST       : constant T_Uint16 := 48_000;
   MIN_RECOVERY_THRUST       : constant T_Uint16 := 28_000;
   RECOVERY_THRUST_DECREMENT : constant T_Uint16 := 100;

   --  Number of successive times that acceleration along Z axis must
   --  be in the threshold to detect a Free Fall.
   FF_DURATION :  T_Uint16 := 30
     with Part_Of => FF_Parameters;
   pragma Export (C, FF_DURATION, "ffDuration");

   --  Stabiliation period after a landing, during which free falls can't
   --  be detected.
   STABILIZATION_PERIOD_AFTER_LANDING : constant T_Uint16
     := Milliseconds_To_Ticks (1_000);
   --  Used by a watchdog to ensure that we cut the thrust after a free fall,
   --  even if the drone has not recovered.
   RECOVERY_TIMEOUT                   : constant T_Uint16
     := Milliseconds_To_Ticks (6_000);

   --  If the derivative is superior to this value during the recovering phase,
   --  it means that the drone has landed.
   LANDING_DERIVATIVE_THRESHOLD :  T_Alpha := 0.25
     with Part_Of => FF_Parameters;
   pragma Export
     (C, LANDING_DERIVATIVE_THRESHOLD, "landingDerivativeThreshold");

   --  Types

   --  Threshold used to detect when the drone is in Free Fall.
   --  This threshold is compared with accelerometer measurements for
   --  Z axis.
   subtype Free_Fall_Threshold is T_Acc range -0.2 .. 0.2;

   --  Type used to prove that we can't have a buffer overflow
   --  when collecting accelerometer samples.
   subtype T_Acc_Data_Collector_Index is
     Integer range 1 .. LANDING_NUMBER_OF_SAMPLES;

   --  Type used to collect measurement samples and easily calculate
   --  their variance and mean.
   type FF_Acc_Data_Collector  is record
      Samples : T_Acc_Array (T_Acc_Data_Collector_Index) := (others => 0.0);
      Index   : T_Acc_Data_Collector_Index := 1;
   end record;

   --  Used to enable or disable the Free Fall/Recovery feature.
   FF_Mode                            : Free_Fall_Mode := DISABLED
     with Part_Of => FF_Parameters;
   pragma Export (C, FF_Mode, "freeFallMode");

   --  Free Fall features internal variables.
   FF_Duration_Counter      : T_Uint16 := 0
     with Part_Of => FF_State;
   In_Recovery              : bool := 0
     with Part_Of => FF_State;
   Recovery_Thrust          : T_Uint16 := MAX_RECOVERY_THRUST
     with Part_Of => FF_State;
   Landing_Data_Collector   : FF_Acc_Data_Collector
     with Part_Of => FF_State;
   Last_Landing_Time        : T_Uint16 := 0
     with Part_Of => FF_State;
   Last_FF_Detected_Time    : T_Uint16 := 0
     with Part_Of => FF_State;
   pragma Export (C, In_Recovery, "ffInRecovery");

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

   --  Calculate the derivative between the two last accelerometer samples
   --  along the Z axis.
   function Calculate_Last_Derivative
     (Data_Collector : FF_Acc_Data_Collector) return Float;

   --  Get the time since last landing after a recovery from a free fall.
   function Get_Ticks_Since_Last_Landing return T_Uint16 is
     (XTask_Get_Tick_Count - Last_Landing_Time);

   --  Get the time since the last free fall detection.
   function Get_Ticks_Since_Last_Free_Fall return T_Uint16 is
     (XTask_Get_Tick_Count - Last_FF_Detected_Time);

end Free_Fall_Pack;
