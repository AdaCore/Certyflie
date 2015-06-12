with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

with Safety_Pack; use Safety_Pack;
with MPU9250_Pack; use MPU9250_Pack;
with Config; use Config;

package body IMU_Pack is

   procedure IMU_Init is
      Delay_After_Reset_Time : Time;
   begin
      if Is_Init then
         return;
      end if;

      MPU9250_Init;
      MPU9250_Reset;

      --  Wait 50 ms after a reset has been performed
      Delay_After_Reset_Time := Clock + Milliseconds (50);
      delay until Delay_After_Reset_Time;

      --  Activate MPU9250
      MPU9250_Set_Sleep_Enabled (False);
      --  Enable temp sensor
      MPU9250_Set_Temp_Sensor_Enabled (True);
      --  Disable interrupts
      MPU9250_Set_Int_Enabled (False);
      --  Connect the HMC5883L to the main I2C bus
      MPU9250_Set_I2C_Bypass_Enabled (True);
      --  Set x-axis gyro as clock source
      MPU9250_Set_Clock_Source (X_Gyro_Clk);
      --  Set gyro full-scale range
      MPU9250_Set_Full_Scale_Gyro_Range (IMU_GYRO_FS_CONFIG);
      --  Set accel full-scale range
      MPU9250_Set_Full_Scale_Accel_Range (IMU_ACCEL_FS_CONFIG);
      --  To low DLPF bandwidth might cause instability and decrease agility
      --  but it works well for handling vibrations and unbalanced propellers
      --  Set output rate (1): 1000 / (1 + 1) = 500Hz
      MPU9250_Set_Rate (1);
      --  Set digital low-pass bandwidth
      MPU9250_Set_DLPF_Mode (MPU9250_DLPF_BW_98);

      Variance_Sample_Time := Milliseconds (0);
      IMU_Acc_Lp_Att_Factor := IMU_ACC_IIR_LPF_ATT_FACTOR;

      Cos_Pitch := Cos (0.0);
      Sin_Pitch := Sin (0.0);
      Cos_Roll := Cos (0.0);
      Sin_Roll := Sin (0.0);

      Is_Init := True;
   end IMU_Init;

   --  Test if the IMU device is initialized/
   function IMU_Test return Boolean is
      Is_Connected : Boolean;
      Self_Test_Passed : Boolean;
   begin
      --  TODO: implement the complete function
      Is_Connected := MPU9250_Test_Connection;
      Self_Test_Passed := MPU9250_Self_Test;

      return Is_Init and Is_Connected and Self_Test_Passed;
   end IMU_Test;

   function IMU_6_Calibrated return Boolean is
   begin
      return True;
   end IMU_6_Calibrated;

   function IMU_Has_Barometer return Boolean is
   begin
      return Is_Barometer_Avalaible;
   end IMU_Has_Barometer;

   procedure IMU_6_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data) is
   begin
      MPU9250_Get_Motion_6 (Accel_IMU.X, Accel_IMU.Y, Accel_IMU.Z,
                            Gyro_IMU.X, Gyro_IMU.Y, Gyro_IMU.Z);

   end IMU_6_Read;

   procedure IMU_9_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data;
      Mag  : in out Magnetometer_Data) is
   begin
      --  TODO: implement the real function when drivers will be done
      Gyro.X := 0.0;
      Gyro.Y := 0.0;
      Gyro.Z := 0.0;

      Acc.X := 0.0;
      Acc.Y := 0.0;
      Acc.Z := 0.0;

      Mag.X := 0.0;
      Mag.Y := 0.0;
      Mag.Z := 0.0;
   end IMU_9_Read;

   procedure IMU_Add_Bias_Value
     (Bias_Obj : in out Bias_Object;
      Value    : Axis3_T_Int16) is
   begin
      Bias_Obj.Buffer (Bias_Obj.Buffer_Index) := Value;

      Bias_Obj.Buffer_Index := Bias_Obj.Buffer_Index + 1;

      if Bias_Obj.Buffer_Index > Bias_Obj.Buffer'Last then
         Bias_Obj.Is_Buffer_Filled := True;
         Bias_Obj.Buffer_Index := Bias_Obj.Buffer'First;
      end if;
   end IMU_Add_Bias_Value;

   procedure IMU_Find_Bias_Value (Bias_Obj : Bias_Object) is
      Bias_Found : Boolean := False;
    begin
      if Bias_Obj.Is_Buffer_Filled then
         declare
            Variance : Axis3_T_Int16;
            Mean     : Axis3_T_Int16;
         begin
            null;
         end;
      end if;
   end IMU_Find_Bias_Value;

   procedure IMU_Calculate_Variance_And_Mean
     (Bias_Obj : Bias_Object;
      Variance : out Axis3_T_Int16;
      Mean     : out Axis3_T_Int16) is
      Sum : T_Int32_Array (1 .. 3) := (others => 0);
      Sum_Square : T_Int64_Array (1 .. 3) := (others => 0);
   begin
      for Value of Bias_Obj.Buffer loop
         Sum (1) := Sum (1) + T_Int32 (Value.X);
         Sum (2) := Sum (2) + T_Int32 (Value.Y);
         Sum (3) := Sum (3) + T_Int32 (Value.Z);

         Sum_Square (1) := Sum_Square (1) + T_Int64 (Value.X * Value.X);
         Sum_Square (2) := Sum_Square (2) + T_Int64 (Value.Y * Value.Y);
         Sum_Square (3) := Sum_Square (3) + T_Int64 (Value.Z * Value.Z);
      end loop;

      --  TODO: the rest of the function, in a safe way
   end IMU_Calculate_Variance_And_Mean;

end IMU_Pack;
