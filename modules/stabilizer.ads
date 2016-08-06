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

with Ada.Real_Time;    use Ada.Real_Time;

with IMU;              use IMU;
with LPS25h;           use LPS25h;

with Commander;        use Commander;
with Controller;       use Controller;
with CRTP;             use CRTP;
with Free_Fall;        use Free_Fall;
with Motors;           use Motors;
with Pid;
with Pid_Parameters;   use Pid_Parameters;
with Power_Management; use Power_Management;
with SensFusion6;      use SensFusion6;
with Types;            use Types;
pragma Elaborate_All (Pid);

package Stabilizer
with SPARK_Mode,
  Abstract_State => (Stabilizer_State,
                     IMU_Outputs,
                     Actual_Angles,
                     Desired_Angles,
                     Desired_Rates,
                     Command_Types,
                     Actuator_Commands,
                     Motor_Powers,
                     V_Speed_Parameters,
                     Asl_Parameters,
                     Alt_Hold_Parameters,
                     V_Speed_Variables,
                     Asl_Variables,
                     Alt_Hold_Variables),
  Initializes    => (Stabilizer_State,
                     IMU_Outputs,
                     Actual_Angles,
                     Desired_Angles,
                     Desired_Rates,
                     Command_Types,
                     Actuator_Commands,
                     Motor_Powers,
                     V_Speed_Parameters,
                     Asl_Parameters,
                     Alt_Hold_Parameters,
                     V_Speed_Variables,
                     Asl_Variables,
                     Alt_Hold_Variables)
is
   --  Instantiation of PID generic package for Altitude
   package Altitude_Pid is new Pid
     (T_Altitude'First,
      T_Altitude'Last,
      Float'First / 8.0,
      Float'Last / 8.0,
      MIN_ALTITUDE_COEFF,
      MAX_ALTITUDE_COEFF);

   --  Procedures and functions

   --  Initialize the stabilizer module.
   procedure Stabilizer_Init
     with
       Global => (In_Out => (Stabilizer_State,
                             Controller_State,
                             Attitude_PIDs,
                             Rate_PIDs));

   --  Test if stabilizer module is correctly initialized.
   function Stabilizer_Test return Boolean
     with
       Global => (Input => Stabilizer_State);

   --  Main function of the stabilization system. Get the commands, give them
   --  to the PIDs, and get the output to control the actuators.
   procedure Stabilizer_Control_Loop
     (Attitude_Update_Counter : in out T_Uint32;
      Alt_Hold_Update_Counter : in out T_Uint32)
     with
       Global => (Input  => (V_Speed_Parameters,
                             Asl_Parameters,
                             Alt_Hold_Parameters,
                             IMU_State,
                             Power_Management_State,
                             Clock_Time),
                  In_Out => (Commander_State,
                             CRTP_State,
                             FF_State,
                             Motors_State,
                             SensFusion6_State,
                             IMU_Outputs,
                             Desired_Angles,
                             Desired_Rates,
                             Actual_Angles,
                             Command_Types,
                             Actuator_Commands,
                             Motor_Powers,
                             Attitude_PIDs,
                             Rate_PIDs,
                             V_Speed_Variables,
                             Asl_Variables,
                             Alt_Hold_Variables));

   --  Function called when Alt_Hold mode is activated. Holds the drone
   --  at a target altitude.
   procedure Stabilizer_Alt_Hold_Update
     with
       Global => (Input   => (Asl_Parameters,
                              Alt_Hold_Parameters,
                              V_Speed_Parameters,
                              Power_Management_State),
                  In_Out  => (Commander_State,
                              V_Speed_Variables,
                              Asl_Variables,
                              Alt_Hold_Variables,
                              Actuator_Commands));

   --  Update the Attitude PIDs.
   procedure Stabilizer_Update_Attitude
     with
       Global => (Input  => (Desired_Angles,
                             IMU_Outputs,
                             V_Speed_Parameters),
                  Output => (Actual_Angles,
                             Desired_Rates),
                  In_Out => (SensFusion6_State,
                             V_Speed_Variables,
                             Attitude_PIDs));

   --  Update the Rate PIDs.
   procedure Stabilizer_Update_Rate
     with
       Global => (Input  => (Command_Types,
                             Desired_Angles,
                             IMU_Outputs),
                  In_Out => (Actuator_Commands,
                             Desired_Rates,
                             Rate_PIDs));

private

   --  Global variables and constants

   --  Defines in what divided update rate should the attitude
   --  control loop run relative the rate control loop.

   ATTITUDE_UPDATE_RATE_DIVIDER   : constant := 2;
   ATTITUDE_UPDATE_RATE_DIVIDER_F : constant := 2.0;
   --  500 Hz
   FUSION_UPDATE_DT : constant Float :=
                        (1.0 / (IMU_UPDATE_FREQ /
                           ATTITUDE_UPDATE_RATE_DIVIDER_F));

   --  500hz/5 = 100hz for barometer measurements
   ALTHOLD_UPDATE_RATE_DIVIDER   : constant := 5;
   ALTHOLD_UPDATE_RATE_DIVIDER_F : constant := 5.0;
   --  200 Hz
   ALTHOLD_UPDATE_DT : constant Float :=
                                     (1.0 / (IMU_UPDATE_FREQ));

   Is_Init : Boolean := False
     with Part_Of => Stabilizer_State;

   --  IMU outputs. The IMU is composed of an accelerometer, a gyroscope
   --  and a magnetometer (notused yet).
   Gyro : Gyroscope_Data     := (0.0, 0.0, 0.0)
     with Part_Of => IMU_Outputs;
   Acc  : Accelerometer_Data := (0.0, 0.0, 0.0)
     with Part_Of => IMU_Outputs;
   Mag  : Magnetometer_Data  := (0.0, 0.0, 0.0)
     with Part_Of => IMU_Outputs;

   --  Actual angles. These angles are calculated by fusing
   --  accelerometer and gyro data in the Sensfusion algorithms.
   Euler_Roll_Actual   : T_Degrees := 0.0
     with Part_Of => Actual_Angles;
   Euler_Pitch_Actual  : T_Degrees := 0.0
     with Part_Of => Actual_Angles;
   Euler_Yaw_Actual    : T_Degrees := 0.0
     with Part_Of => Actual_Angles;

   --  Desired angles. Obtained directly from the pilot.
   Euler_Roll_Desired  : T_Degrees := 0.0
     with Part_Of => Desired_Angles;
   Euler_Pitch_Desired : T_Degrees := 0.0
     with Part_Of => Desired_Angles;
   Euler_Yaw_Desired   : T_Degrees := 0.0
     with Part_Of => Desired_Angles;

   --  Desired rates. Obtained directly from the pilot when
   --  commands are in RATE mode, or from the rate PIDs when commands
   --  are in ANGLE mode.
   Roll_Rate_Desired   : T_Rate  := 0.0
     with Part_Of => Desired_Rates;
   Pitch_Rate_Desired  : T_Rate  := 0.0
     with Part_Of => Desired_Rates;
   Yaw_Rate_Desired    : T_Rate  := 0.0
     with Part_Of => Desired_Rates;

   --  Variables used to calculate the altitude above see level (ASL).
   Temperature  : T_Temperature := 0.0 --  Temperature
     with Part_Of => Asl_Variables;
   Pressure     : T_Pressure    := 1000.0
     with Part_Of => Asl_Variables;    --  Pressure from barometer
   Asl          : T_Altitude    := 0.0
     with Part_Of => Asl_Variables;    --  Smoothed asl
   Asl_Raw      : T_Altitude    := 0.0
     with Part_Of => Asl_Variables;    --  Raw asl
   Asl_Long     : T_Altitude    := 0.0
     with Part_Of => Asl_Variables;    --  Long term asl

   --  Variables used to calculate the vertical speed
   Acc_WZ       : Float   := 0.0
     with Part_Of => V_Speed_Variables;
   Acc_MAG      : Float   := 0.0
     with Part_Of => V_Speed_Variables;
   V_Speed_ASL  : T_Speed := 0.0
     with Part_Of => V_Speed_Variables;
   V_Speed_Acc  : T_Speed   := 0.0
     with Part_Of => V_Speed_Variables;
   V_Speed      : T_Speed := 0.0
     with Part_Of => V_Speed_Variables; --  Vertical speed (world frame)
                                        --  integrated from vertical
                                        --  acceleration.

   --  Variables used for the Altitude Hold mode.
   Alt_Hold_PID : Altitude_Pid.Pid_Object :=
                    (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                     0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1)
     with Part_Of => Alt_Hold_Variables; --  Used for altitute hold mode.
                                         --  It gets reset when the bat status
                                         --  changes.
   Alt_Hold     : Boolean := False
     with Part_Of => Alt_Hold_Variables; --  Currently in altitude hold mode.
   Set_Alt_Hold : Boolean := False
     with Part_Of => Alt_Hold_Variables; --  Hover mode just being activated.
   Alt_Hold_PID_Val : T_Altitude := 0.0
     with Part_Of => Alt_Hold_Variables; --  Output of the PID controller.
   Alt_Hold_Err     : Float := 0.0
     with Part_Of => Alt_Hold_Variables; --  Altitude error.
   Alt_Hold_Change  : T_Altitude := 0.0
     with Part_Of => Alt_Hold_Variables; --  Change in target altitude.
   Alt_Hold_Target  : T_Altitude := -1.0
     with Part_Of => Alt_Hold_Variables; --  Target altitude.

   --  Altitude hold & barometer params

   --  PID gain constants used everytime we reinitialise the PID controller.
   ALT_HOLD_KP          : constant Float := 0.5;
   ALT_HOLD_KI          : constant Float := 0.18;
   ALT_HOLD_KD          : constant Float := 0.0;

   --  Parameters used to calculate the vertical speed.
   V_Speed_ASL_Fac      : T_Speed := 0.0
     with Part_Of => V_Speed_Parameters; --  Multiplier.
   V_Speed_Acc_Fac      : T_Speed := -48.0
     with Part_Of => V_Speed_Parameters; --  Multiplier.
   V_Acc_Deadband       : Natural_Float := 0.05
     with Part_Of => V_Speed_Parameters; --  Vertical acceleration deadband.
   V_Speed_ASL_Deadband : Natural_Float := 0.005
     with Part_Of => V_Speed_Parameters; --  Vertical speed barometer deadband.
   V_Speed_Limit        : T_Speed := 0.05
     with Part_Of => V_Speed_Parameters; --  To saturate vertical velocity.
   V_Bias_Alpha         : T_Alpha := 0.98
     with Part_Of => V_Speed_Parameters; --  Fusing factor used in ASL calc.

   --  Parameters used to calculate the altitude above see level (ASL).
   Asl_Err_Deadband     : Natural_Float := 0.00
     with Part_Of => Asl_Parameters; --  error (target - altitude) deadband.
   Asl_Alpha            : T_Alpha := 0.92
     with Part_Of => Asl_Parameters; --  Short term smoothing.
   Asl_Alpha_Long       : T_Alpha := 0.93
     with Part_Of => Asl_Parameters; --  Long term smoothing.

   --  Parameters used for the Altitude Hold mode.
   Alt_Hold_Err_Max     : T_Alpha := 1.0
     with Part_Of => Alt_Hold_Parameters; --  Max cap on current
                                          --  estimated altitude
                                          --  vs target altitude in meters.
   Alt_Hold_Change_SENS : T_Sensitivity := 200.0
     with Part_Of => Alt_Hold_Parameters; --  Sensitivity of target altitude
                                          --  change (thrust input control)
                                          --  while hovering.
                                          --  Lower = more sensitive.
   --  & faster changes
   Alt_Pid_Asl_Fac          : T_Motor_Fac := 13000.0
     with Part_Of => Alt_Hold_Parameters; --  Relates meters asl to thrust.
   Alt_Pid_Alpha            : T_Alpha := 0.8
     with Part_Of => Alt_Hold_Parameters; --  PID Smoothing.
   Alt_Hold_Min_Thrust      : T_Uint16 := 00000
     with Part_Of => Alt_Hold_Parameters; --  Minimum hover thrust.
   Alt_Hold_Base_Thrust     : T_Uint16 := 43000
     with Part_Of => Alt_Hold_Parameters; --  Approximate throttle needed when
                                          --  in perfect hover.
                                          --  More weight / older battery can
                                          --  use a higher value.
   Alt_Hold_Max_Thrust  : T_Uint16 := 60000
     with Part_Of => Alt_Hold_Parameters; --  Max altitude hold thrust.

   --  Command types used to control each angle.
   Roll_Type            : RPY_Type := ANGLE
     with Part_Of => Command_Types;
   Pitch_Type           : RPY_Type := ANGLE
     with Part_Of => Command_Types;
   Yaw_Type             : RPY_Type := RATE
     with Part_Of => Command_Types;

   --  Variables output from each rate PID, and from the Pilot (Thrust).
   Actuator_Thrust : T_Uint16 := 0
     with Part_Of => Actuator_Commands;
   Actuator_Roll   : T_Int16  := 0
     with Part_Of => Actuator_Commands;
   Actuator_Pitch  : T_Int16  := 0
     with Part_Of => Actuator_Commands;
   Actuator_Yaw    : T_Int16  := 0
     with Part_Of => Actuator_Commands;

   --  Variables used to control each motor's power.
   Motor_Power_M4  : T_Uint16 := 0
     with Part_Of => Motor_Powers;
   Motor_Power_M2  : T_Uint16 := 0
     with Part_Of => Motor_Powers;
   Motor_Power_M1  : T_Uint16 := 0
     with Part_Of => Motor_Powers;
   Motor_Power_M3  : T_Uint16 := 0
     with Part_Of => Motor_Powers;

   --  Distribute power to the actuators with the PIDs outputs.
   procedure Stabilizer_Distribute_Power
     (Thrust : T_Uint16;
      Roll   : T_Int16;
      Pitch  : T_Int16;
      Yaw    : T_Int16)
     with
       Global => (Output => Motor_Powers,
                  In_Out => Motors_State);

   --  Limit the given thrust to the maximum thrust supported by the motors.
   function Limit_Thrust (Value : T_Int32) return T_Uint16;
   pragma Inline (Limit_Thrust);

end Stabilizer;
