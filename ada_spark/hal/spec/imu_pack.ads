with Ada.Numerics; use Ada.Numerics;
with Ada.Real_Time; use Ada.Real_Time;

with Types; use Types;
with Filter_Pack; use Filter_Pack;

package IMU_Pack
with SPARK_Mode
is

   --  Types

   --  These ranges are deduced from the MPU9150 specification.
   --  It corresponds to the maximum range of values that can be output
   --  by the IMU.

   --  Type for angular speed output from gyro, degrees/s
   subtype T_Rate is Float range -3_000.0  .. 3_000.0;
   --  Type for angular speed output from gyro, rad/s
   subtype T_Rate_Rad
     is Float range -3_000.0 * Pi / 180.0 .. 3_000.0 * Pi / 180.0;
   --  Type for acceleration output from accelerometer, in G
   subtype T_Acc  is Float range -16.0 .. 16.0;
   --  Type for magnetometer output, in micro-Teslas
   subtype T_Mag  is Float range -1_200.0  .. 1_200.0;

   --  Type used to ensure that accelation normalization can't lead to a
   --  division by zero in SensFusion6_Pack algorithms
   MIN_NON_ZERO_ACC : constant := 2.0 ** (-74);

   subtype T_Acc_Lifted is T_Acc; -- with
--         Static_Predicate => T_Acc_Lifted = 0.0 or else
--         T_Acc_Lifted not in -MIN_NON_ZERO_ACC .. MIN_NON_ZERO_ACC;

   type Gyroscope_Data is record
      X : T_Rate;
      Y : T_Rate;
      Z : T_Rate;
   end record;

   type Accelerometer_Data is record
      X : T_Acc;
      Y : T_Acc;
      Z : T_Acc;
   end record;

   type Magnetometer_Data is record
      X : T_Mag;
      Y : T_Mag;
      Z : T_Mag;
   end record;

   --  Global variables and constants

   IMU_UPDATE_FREQ  : constant := 500.0;
   IMU_UPDATE_DT    : constant := 1.0 / IMU_UPDATE_FREQ;
   IMU_UPDATE_DT_MS : constant Time_Span := Milliseconds (200);

   --  Procedures and functions

   --  Initialize the IMU device/
   procedure IMU_Init;

   --  Test if the IMU device is initialized/
   function IMU_Test return Boolean;

   procedure IMU_6_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data)
     with
       Global => null;

   --  Read gyro, accelerometer and magnetometer measurements.
   procedure IMU_9_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data;
      Mag  : in out Magnetometer_Data)
     with
       Global => null;

   --  Return True if the IMU is correctly calibrated, False otherwise.
   function IMU_6_Calibrated return Boolean;

   --  Return True if the IMU has an initialized barometer, False otherwise.
   function IMU_Has_Barometer return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;
   --  Barometer and magnetometr not avalaible for now.
   --  TODO: add the code to manipulate them
   Is_Barometer_Avalaible   : Boolean := False;
   Is_Magnetomer_Availaible : Boolean := False;

   --  Number of samples used for bias calculation
   IMU_NBR_OF_BIAS_SAMPLES      : constant := 32;
   GYRO_MIN_BIAS_TIMEOUT_MS     : constant Time_Span := Milliseconds (1_000);

   --  Set ACC_WANTED_LPF1_CUTOFF_HZ to the wanted cut-off freq in Hz.
   --  The highest cut-off freq that will have any affect is fs /(2*pi).
   --  E.g. fs = 350 Hz -> highest cut-off = 350/(2*pi) = 55.7 Hz -> 55 Hz
   IMU_ACC_WANTED_LPF_CUTOFF_HZ : constant := 4.0;
   --  Attenuation should be between 1 to 256.
   --  F0 = fs / 2*pi*attenuation ->
   --  Attenuation = fs / 2*pi*f0
   IMU_ACC_IIR_LPF_ATTENUATION : constant Float
     := Float (IMU_UPDATE_FREQ) / (2.0 * Pi * IMU_ACC_WANTED_LPF_CUTOFF_HZ);
   IMU_ACC_IIR_LPF_ATT_FACTOR  : constant T_Uint8
     := T_Uint8 (Float (2 ** IIR_SHIFT) / IMU_ACC_IIR_LPF_ATTENUATION + 0.5);

   Variance_Sample_Time  : Time_Span;
   IMU_Acc_Lp_Att_Factor : T_Uint8;

   Cos_Pitch : Float;
   Sin_Pitch : Float;
   Cos_Roll  : Float;
   Sin_Roll  : Float;

   --  Types

   type Axis3_T_Int16 is record
      X : T_Int16 := 0;
      Y : T_Int16 := 0;
      Z : T_Int16 := 0;
   end record;

   type Bias_Buffer_Array is
     array (1 .. IMU_NBR_OF_BIAS_SAMPLES) of Axis3_T_Int16;

   --  Type used for bias calculation
   type Bias_Object is record
      Bias                : Axis3_T_Int16;
      Buffer              : Bias_Buffer_Array;
      Buffer_Index        : Positive := Bias_Buffer_Array'First;
      Is_Bias_Value_Found : Boolean  := False;
      Is_Buffer_Filled    : Boolean  := False;
   end record;

end IMU_Pack;
