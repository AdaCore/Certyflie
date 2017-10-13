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

with Ada.Numerics;  use Ada.Numerics;
with Ada.Real_Time; use Ada.Real_Time;

with Filter;        use Filter;
with MPU9250;       use MPU9250;
with Types;         use Types;

package IMU
with SPARK_Mode,
  Abstract_State => IMU_State
is

   --  These ranges are deduced from the MPU9150 specification.
   --  It corresponds to the maximum range of values that can be output
   --  by the IMU.

   --  Type for angular speed output from gyro, degrees/s.
   subtype T_Rate is Float range -100_000.0  .. 100_000.0;
   --  Type for angular speed output from gyro, rad/s.
   subtype T_Rate_Rad
     is Float range T_Rate'First * Pi / 180.0 .. T_Rate'Last * Pi / 180.0;
   --  Type for acceleration output from accelerometer, in G.
   subtype T_Acc  is Float range -16.0 .. 16.0;
   --  Type for magnetometer output, in micro-Teslas.
   subtype T_Mag  is Float range -1_200.0  .. 1_200.0;

   --  Type used when we want to collect several accelerometer samples.
   type T_Acc_Array is array (Integer range <>) of T_Acc;

   --  Type used to ensure that accelation normalization can't lead to a
   --  division by zero in SensFusion6_Pack algorithms.
   MIN_NON_ZERO_ACC : constant := 2.0 ** (-74);

   subtype T_Acc_Lifted is T_Acc; -- with
   --         Static_Predicate => T_Acc_Lifted = 0.0 or else
   --         T_Acc_Lifted not in -MIN_NON_ZERO_ACC .. MIN_NON_ZERO_ACC;

   --  Type used to represent gyroscope data
   --  along each axis (X, Y, Z).
   type Gyroscope_Data is record
      X : T_Rate;
      Y : T_Rate;
      Z : T_Rate;
   end record;

   --  Type used to represent accelerometer data
   --  along each axis (X, Y, Z).
   type Accelerometer_Data is record
      X : T_Acc;
      Y : T_Acc;
      Z : T_Acc;
   end record;

   --  Type used to represent magnetometer data
   --  along each axis (X, Y, Z).
   type Magnetometer_Data is record
      X : T_Mag;
      Y : T_Mag;
      Z : T_Mag;
   end record;

   --  Global variables and constants

   IMU_UPDATE_FREQ  : constant := 500.0;
   IMU_UPDATE_DT    : constant := 1.0 / IMU_UPDATE_FREQ;
   IMU_UPDATE_DT_MS : constant Time_Span := Milliseconds (2);

   --  Number of samples used for bias calculation
   IMU_NBR_OF_BIAS_SAMPLES      : constant := 1024;
   GYRO_MIN_BIAS_TIMEOUT_MS     : constant Time_Span := Milliseconds (1_000);

   --  Set ACC_WANTED_LPF1_CUTOFF_HZ to the wanted cut-off freq in Hz.
   --  The highest cut-off freq that will have any affect is fs /(2*pi).
   --  E.g. fs = 350 Hz -> highest cut-off = 350/(2*pi) = 55.7 Hz -> 55 Hz
   IMU_ACC_WANTED_LPF_CUTOFF_HZ : constant := 4.0;
   --  Attenuation should be between 1 to 256.
   --  F0 = fs / 2*pi*attenuation ->
   --  Attenuation = fs / 2*pi*f0
   IMU_ACC_IIR_LPF_ATTENUATION  : constant Float
     := Float (IMU_UPDATE_FREQ) / (2.0 * Pi * IMU_ACC_WANTED_LPF_CUTOFF_HZ);
   IMU_ACC_IIR_LPF_ATT_FACTOR   : constant T_Uint8
     := T_Uint8 (Float (2 ** IIR_SHIFT) / IMU_ACC_IIR_LPF_ATTENUATION + 0.5);

   GYRO_VARIANCE_BASE        : constant := 2_000.0;
   GYRO_VARIANCE_THRESHOLD_X : constant := (GYRO_VARIANCE_BASE);
   GYRO_VARIANCE_THRESHOLD_Y : constant := (GYRO_VARIANCE_BASE);
   GYRO_VARIANCE_THRESHOLD_Z : constant := (GYRO_VARIANCE_BASE);

   IMU_DEG_PER_LSB_CFG       : constant := MPU9250_DEG_PER_LSB_2000;
   IMU_G_PER_LSB_CFG         : constant := MPU9250_G_PER_LSB_8;

   IMU_VARIANCE_MAN_TEST_TIMEOUT : constant Time_Span := Milliseconds (1_000);
   IMU_MAN_TEST_LEVEL_MAX : constant := 5.0;

   --  Procedures and functions

   --  Initialize the IMU device/
   procedure IMU_Init (Use_Mag    : Boolean;
                       DLPF_256Hz : Boolean);

   --  Test if the IMU device is initialized/
   function IMU_Test return Boolean;

   --  Manufacting test to ensure that IMU is not broken.
   function IMU_6_Manufacturing_Test return Boolean;

   --  Read gyro and accelerometer measurements from the IMU.
   procedure IMU_6_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data)
     with
       Global => null;

   --  Read gyro, accelerometer and magnetometer measurements from the IMU.
   procedure IMU_9_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data;
      Mag  : in out Magnetometer_Data)
     with
       Global => null;

   --  Calibrates the IMU. Returns True if successful, False otherwise.
   function IMU_6_Calibrate return Boolean
     with
       Global => (Input => IMU_State);

   --  Return True if the IMU has an initialized barometer, False otherwise.
   function IMU_Has_Barometer return Boolean
     with
       Global => (Input => IMU_State);

private
   --  Types

   type Axis3_T_Int16 is record
      X : T_Int16 := 0;
      Y : T_Int16 := 0;
      Z : T_Int16 := 0;
   end record;

   type Axis3_T_Int32 is record
      X : T_Int32 := 0;
      Y : T_Int32 := 0;
      Z : T_Int32 := 0;
   end record;

   type Axis3_Float is record
      X : Float := 0.0;
      Y : Float := 0.0;
      Z : Float := 0.0;
   end record;

   function "+" (A1 : Axis3_Float; A2 : Axis3_Float) return Axis3_Float
   is ((X => A1.X + A2.X,
        Y => A1.Y + A2.Y,
        Z => A1.Z + A2.Z));

   function "+" (AF : Axis3_Float; AI : Axis3_T_Int16) return Axis3_Float
   is ((X => AF.X + Float (AI.X),
        Y => AF.Y + Float (AI.Y),
        Z => AF.Z + Float (AI.Z)));

   function "**" (AF : Axis3_Float; E : Integer) return Axis3_Float
   is ((X => AF.X ** E,
        Y => AF.Y ** E,
        Z => AF.Z ** E));

   function "-" (AF : Axis3_Float; AI : Axis3_T_Int16) return Axis3_Float
   is ((X => AF.X - Float (AI.X),
        Y => AF.Y - Float (AI.Y),
        Z => AF.Z - Float (AI.Z)));

   function "/" (AF : Axis3_Float; Val : Integer) return Axis3_Float
   is ((X => AF.X / Float (Val),
        Y => AF.Y / Float (Val),
        Z => AF.Z / Float (Val)));

   type Bias_Buffer_Array is
     array (1 .. IMU_NBR_OF_BIAS_SAMPLES) of Axis3_T_Int16;

   --  Type used for bias calculation
   type Bias_Object is record
      Bias                : Axis3_Float;
      Buffer              : Bias_Buffer_Array;
      Buffer_Index        : Positive := Bias_Buffer_Array'First;
      Is_Bias_Value_Found : Boolean  := False;
      Is_Buffer_Filled    : Boolean  := False;
   end record;

   --  Global variables and constants

   Is_Init : Boolean := False
     with
       Part_Of => IMU_State;

   type Calibration_Status is
     (Not_Calibrated,
      Calibrated,
      Calibration_Error);

   --  Barometer and magnetometer not avalaible for now.
   --  TODO: add the code to manipulate them
   Is_Barometer_Avalaible   : Boolean := False
     with
       Part_Of => IMU_State;
   Is_Magnetomer_Availaible : Boolean := False
     with
       Part_Of => IMU_State;
   Is_Calibrated            : Calibration_Status := Not_Calibrated
     with
       Part_Of => IMU_State;

   Variance_Sample_Time  : Time
     with
       Part_Of => IMU_State;
   IMU_Acc_Lp_Att_Factor : T_Uint8
     with
       Part_Of => IMU_State;

   --  Raw values retrieved from IMU
   Accel_IMU           : Axis3_T_Int16
     with
       Part_Of => IMU_State;
   Gyro_IMU            : Axis3_T_Int16
     with
       Part_Of => IMU_State;
   --  Acceleration after applying the IIR LPF filter
   Accel_LPF           : Axis3_T_Int32
     with
       Part_Of => IMU_State;
   --  Use to stor the IIR LPF filter feedback
   Accel_Stored_Values : Axis3_T_Int32
     with
       Part_Of => IMU_State;
   --  Acceleration after aligning with gravity
   Accel_LPF_Aligned   : Axis3_Float
     with
       Part_Of => IMU_State;

   Cos_Pitch : Float
     with
       Part_Of => IMU_State;
   Sin_Pitch : Float
     with
       Part_Of => IMU_State;
   Cos_Roll  : Float
     with
       Part_Of => IMU_State;
   Sin_Roll  : Float
     with
       Part_Of => IMU_State;

   --  Bias objects used for bias calculation
   Gyro_Bias : Bias_Object
     with
       Part_Of => IMU_State;

   --  Procedures and functions

   --  Add a new value to the variance buffer and if it is full
   --  replace the oldest one. Thus a circular buffer.
   procedure IMU_Add_Bias_Value
     (Bias_Obj : in out Bias_Object;
      Value    : Axis3_T_Int16);

   --  Check if the variances is below the predefined thresholds.
   --  The bias value should have been added before calling this.
   procedure IMU_Find_Bias_Value
     (Bias_Obj       : in out Bias_Object;
      Has_Found_Bias : out Boolean);

   --  Calculate the variance and mean for the bias buffer.
   procedure IMU_Calculate_Variance_And_Mean
     (Bias_Obj : Bias_Object;
      Variance : out Axis3_Float;
      Mean     : out Axis3_Float);

   --  Apply IIR LP Filter on each axis.
   procedure IMU_Acc_IRR_LP_Filter
     (Input         : Axis3_T_Int16;
      Output        : out Axis3_T_Int32;
      Stored_Values : in out Axis3_T_Int32;
      Attenuation   : T_Int32);

   --  Compensate for a miss-aligned accelerometer. It uses the trim
   --  data gathered from the UI and written in the config-block to
   --  rotate the accelerometer to be aligned with gravity.
   procedure IMU_Acc_Align_To_Gravity
     (Input  : Axis3_T_Int32;
      Output : out Axis3_Float);

end IMU;
