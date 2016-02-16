with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

with Config; use Config;

package body IMU_Pack is

   --------------
   -- IMU_Init --
   --------------

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

      Variance_Sample_Time := Time_First;
      IMU_Acc_Lp_Att_Factor := IMU_ACC_IIR_LPF_ATT_FACTOR;

      Cos_Pitch := Cos (0.0);
      Sin_Pitch := Sin (0.0);
      Cos_Roll := Cos (0.0);
      Sin_Roll := Sin (0.0);

      Is_Init := True;
   end IMU_Init;

   --------------
   -- IMU_Test --
   --------------

   function IMU_Test return Boolean is
      Is_Connected     : Boolean;
      Self_Test_Passed : Boolean;
   begin
      --  TODO: implement the complete function
      Is_Connected := MPU9250_Test_Connection;
      Self_Test_Passed := MPU9250_Self_Test;

      return Is_Init and Is_Connected and Self_Test_Passed;
   end IMU_Test;

   ------------------------------
   -- IMU_6_Manufacturing_Test --
   ------------------------------

   function IMU_6_Manufacturing_Test return Boolean is
      Test_Status : Boolean := False;
      Gyro_Out    : Gyroscope_Data;
      Acc_Out     : Accelerometer_Data;
      Pitch, Roll : T_Degrees;
      Start_Time  : Time;
   begin
      Test_Status := MPU9250_Self_Test;
      Start_Time := Clock;

      if Test_Status then
         while Clock < Start_Time + IMU_VARIANCE_MAN_TEST_TIMEOUT loop
            IMU_6_Read (Gyro_Out, Acc_Out);
            exit when Gyro_Bias.Is_Bias_Value_Found;
         end loop;

         if Gyro_Bias.Is_Bias_Value_Found then
            Pitch
              := Tan (-Acc_Out.X /
                        Sqrt (Acc_Out.Y * Acc_Out.Y + Acc_Out.Z * Acc_Out.Z)) *
                180.0 / Pi;
            Roll := Tan (Acc_Out.Y / Acc_Out.Z) * 180.0 * Pi;

            if abs (Roll) < IMU_MAN_TEST_LEVEL_MAX
               and abs (Pitch) < IMU_MAN_TEST_LEVEL_MAX
            then
               Test_Status := True;
            else
               Test_Status := False;
            end if;
         else
            Test_Status := False;
         end if;
      end if;

      return Test_Status;
   end IMU_6_Manufacturing_Test;

   ----------------------
   -- IMU_6_Calibrated --
   ----------------------

   function IMU_6_Calibrated return Boolean is
   begin
      return Is_Calibrated;
   end IMU_6_Calibrated;

   -----------------------
   -- IMU_Has_Barometer --
   -----------------------

   function IMU_Has_Barometer return Boolean is
   begin
      return Is_Barometer_Avalaible;
   end IMU_Has_Barometer;

   ----------------
   -- IMU_6_Read --
   ----------------

   procedure IMU_6_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data)
   is
      Has_Found_Bias : Boolean;
   begin
      --  We invert X and Y because the chip is almso inverted.
      MPU9250_Get_Motion_6 (Accel_IMU.Y, Accel_IMU.X, Accel_IMU.Z,
                            Gyro_IMU.Y, Gyro_IMU.X, Gyro_IMU.Z);
      IMU_Add_Bias_Value (Gyro_Bias, Gyro_IMU);

      if not Gyro_Bias.Is_Bias_Value_Found then
         IMU_Find_Bias_Value (Gyro_Bias, Has_Found_Bias);
         if Has_Found_Bias then
            --  TODO: led sequence to indicate that it is calibrated
            Is_Calibrated := True;
         end if;
      end if;

      IMU_Acc_IRR_LP_Filter
        (Input         => Accel_IMU,
         Output        => Accel_LPF,
         Stored_Values => Accel_Stored_Values,
         Attenuation   => T_Int32 (IMU_Acc_Lp_Att_Factor));
      IMU_Acc_Align_To_Gravity (Accel_LPF, Accel_LPF_Aligned);

      --  Re-map outputs
      Gyro.X :=
        -(Float (Gyro_IMU.X - Gyro_Bias.Bias.X)) * IMU_DEG_PER_LSB_CFG;
      Gyro.Y :=
        (Float (Gyro_IMU.Y - Gyro_Bias.Bias.Y)) * IMU_DEG_PER_LSB_CFG;
      Gyro.Z :=
        (Float (Gyro_IMU.Z - Gyro_Bias.Bias.Z)) * IMU_DEG_PER_LSB_CFG;

      Acc.X := (-Accel_LPF_Aligned.X) * IMU_G_PER_LSB_CFG;
      Acc.Y := Accel_LPF_Aligned.Y * IMU_G_PER_LSB_CFG;
      Acc.Z := Accel_LPF_Aligned.Z * IMU_G_PER_LSB_CFG;
   end IMU_6_Read;

   ----------------
   -- IMU_9_Read --
   ----------------

   procedure IMU_9_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data;
      Mag  : in out Magnetometer_Data) is
   begin
      IMU_6_Read (Gyro,
                  Acc);
      --  TODO: implement drivers for magnetometer if we want to
      --  use it.
      Mag.X := 0.0;
      Mag.Y := 0.0;
      Mag.Z := 0.0;
   end IMU_9_Read;

   ------------------------
   -- IMU_Add_Bias_Value --
   ------------------------

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

   -------------------------
   -- IMU_Find_Bias_Value --
   -------------------------

   procedure IMU_Find_Bias_Value
     (Bias_Obj       : in out Bias_Object;
      Has_Found_Bias : out Boolean) is
   begin
      Has_Found_Bias := False;
      if Bias_Obj.Is_Buffer_Filled then
         declare
            Variance : Axis3_T_Int16;
            Mean     : Axis3_T_Int16;
         begin
            IMU_Calculate_Variance_And_Mean
              (Bias_Obj, Variance, Mean);

            if Variance.X < GYRO_VARIANCE_THRESHOLD_X and
              Variance.Y < GYRO_VARIANCE_THRESHOLD_Y and
              Variance.Z < GYRO_VARIANCE_THRESHOLD_Z and
              Clock > Variance_Sample_Time + GYRO_MIN_BIAS_TIMEOUT_MS
            then
               Variance_Sample_Time := Clock;
               Bias_Obj.Bias.X := Mean.X;
               Bias_Obj.Bias.Y := Mean.Y;
               Bias_Obj.Bias.Z := Mean.Z;
               Has_Found_Bias := True;
               Bias_Obj.Is_Bias_Value_Found := True;
            end if;
         end;
      end if;
   end IMU_Find_Bias_Value;

   -------------------------------------
   -- IMU_Calculate_Variance_And_Mean --
   -------------------------------------

   procedure IMU_Calculate_Variance_And_Mean
     (Bias_Obj : Bias_Object;
      Variance : out Axis3_T_Int16;
      Mean     : out Axis3_T_Int16)
   is
      Sum        : T_Int32_Array (1 .. 3) := (others => 0);
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

      Variance.X :=
        T_Int16 (Sum_Square (1) -
                     T_Int64 (Sum (1) * Sum (1)) / IMU_NBR_OF_BIAS_SAMPLES);
      Variance.Y :=
        T_Int16 (Sum_Square (2) -
                     T_Int64 (Sum (2) * Sum (2)) / IMU_NBR_OF_BIAS_SAMPLES);
      Variance.Z :=
        T_Int16 (Sum_Square (3) -
                     T_Int64 (Sum (3) * Sum (3)) / IMU_NBR_OF_BIAS_SAMPLES);

      Mean.X := T_Int16 (Sum (1) / IMU_NBR_OF_BIAS_SAMPLES);
      Mean.Y := T_Int16 (Sum (2) / IMU_NBR_OF_BIAS_SAMPLES);
      Mean.Z := T_Int16 (Sum (3) / IMU_NBR_OF_BIAS_SAMPLES);
   end IMU_Calculate_Variance_And_Mean;

   ---------------------------
   -- IMU_Acc_IRR_LP_Filter --
   ---------------------------

   procedure IMU_Acc_IRR_LP_Filter
     (Input         : Axis3_T_Int16;
      Output        : out Axis3_T_Int32;
      Stored_Values : in out Axis3_T_Int32;
      Attenuation   : T_Int32) is
   begin
      IIR_LP_Filter_Single
        (T_Int32 (Input.X),
         Attenuation,
         Stored_Values.X,
         Output.X);
      IIR_LP_Filter_Single
        (T_Int32 (Input.Y),
         Attenuation,
         Stored_Values.Y,
         Output.Y);
      IIR_LP_Filter_Single
        (T_Int32 (Input.Z),
         Attenuation,
         Stored_Values.Z,
         Output.Z);
   end IMU_Acc_IRR_LP_Filter;

   ------------------------------
   -- IMU_Acc_Align_To_Gravity --
   ------------------------------

   procedure IMU_Acc_Align_To_Gravity
     (Input  : Axis3_T_Int32;
      Output : out Axis3_Float)
   is
      Input_F : constant Axis3_Float :=
                  (Float (Input.X), Float (Input.Y), Float (Input.Z));
      Rx      : Axis3_Float;
      Ry      : Axis3_Float;
   begin
      --  Rotate around X-Axis
      Rx.X := Input_F.X;
      Rx.Y := Input_F.Y * Cos_Roll - Input_F.Z * Sin_Roll;
      Rx.Z := Input_F.Y * Sin_Roll + Input_F.Z * Cos_Roll;

      --  Rotate around Y-Axis
      Ry.X := Rx.X * Cos_Pitch - Rx.Z * Sin_Pitch;
      Ry.Y := Rx.Y;
      Ry.Z := -Rx.X * Sin_Pitch + Rx.Z * Cos_Pitch;

      Output.X := Ry.X;
      Output.Y := Ry.Y;
      Output.Z := Ry.Z;
   end IMU_Acc_Align_To_Gravity;

end IMU_Pack;
