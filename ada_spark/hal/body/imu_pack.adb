with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

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
      --  TODO
      null;
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

end IMU_Pack;
