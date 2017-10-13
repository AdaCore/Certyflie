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

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

with STM32.Board;                       use STM32.Board;
with STM32.I2C;
with Crazyflie_Config;                  use Crazyflie_Config;
with Console;                           use Console;

with AK8963;                            use AK8963;

package body IMU
with Refined_State => (IMU_State => (Is_Init,
                                     Is_Barometer_Avalaible,
                                     Is_Magnetomer_Availaible,
                                     Is_Calibrated,
                                     Variance_Sample_Time,
                                     IMU_Acc_Lp_Att_Factor,
                                     Accel_IMU,
                                     Gyro_IMU,
                                     Accel_LPF,
                                     Accel_Stored_Values,
                                     Accel_LPF_Aligned,
                                     Cos_Pitch,
                                     Sin_Pitch,
                                     Cos_Roll,
                                     Sin_Roll,
                                     Gyro_Bias))

is

   --------------
   -- IMU_Init --
   --------------

   procedure IMU_Init (Use_Mag    : Boolean;
                       DLPF_256Hz : Boolean) is
      Delay_After_Reset_Time : Time;
   begin
      if Is_Init then
         return;
      end if;

      Initialize_I2C_GPIO (STM32.I2C.I2C_Port (MPU_Device.Port.all));
      Configure_I2C (STM32.I2C.I2C_Port (MPU_Device.Port.all));

      MPU9250_Init (MPU_Device);
      MPU9250_Reset (MPU_Device);

      --  Wait 50 ms after a reset has been performed
      Delay_After_Reset_Time := Clock + Milliseconds (50);
      delay until Delay_After_Reset_Time;

      --  Activate MPU9250
      MPU9250_Set_Sleep_Enabled (MPU_Device, False);
      --  Enable temp sensor
      MPU9250_Set_Temp_Sensor_Enabled (MPU_Device, True);
      --  Disable interrupts
      MPU9250_Set_Int_Enabled (MPU_Device, False);
      --  Connect the HMC5883L to the main I2C bus
      MPU9250_Set_I2C_Bypass_Enabled (MPU_Device, True);
      --  Set x-axis gyro as clock source
      MPU9250_Set_Clock_Source (MPU_Device, X_Gyro_Clk);
      --  Set gyro full-scale range
      MPU9250_Set_Full_Scale_Gyro_Range (MPU_Device, IMU_GYRO_FS_CONFIG);
      --  Set accel full-scale range
      MPU9250_Set_Full_Scale_Accel_Range (MPU_Device, IMU_ACCEL_FS_CONFIG);

      if DLPF_256Hz then
         --  256Hz digital low-pass filter only works with little vibrations
         --  Set output rate (15): 8000 / (1 + 15) = 500Hz
         MPU9250_Set_Rate (MPU_Device, 15);
         MPU9250_Set_DLPF_Mode (MPU_Device, MPU9250_DLPF_BW_256);
      else
         --  To low DLPF bandwidth might cause instability and decrease
         --  agility but it works well for handling vibrations and
         --  unbalanced propellers.
         --  Set output rate (1): 1000 / (1 + 1) = 500Hz
         MPU9250_Set_Rate (MPU_Device, 1);
         --  Set digital low-pass bandwidth
         MPU9250_Set_DLPF_Mode (MPU_Device, MPU9250_DLPF_BW_98);
      end if;

      if Use_Mag then
         Initialize (STM32.Board.MAG_Device);
         if Test_Connection (STM32.Board.MAG_Device) then
            Is_Magnetomer_Availaible := True;
            Set_Mode (MAG_Device, Continuous_2, Mode_16bit);
         end if;
      end if;

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

   function IMU_Test return Boolean
   is
   begin
      if not MPU9250_Test_Connection (MPU_Device) then
         return False;
      end if;

      if not MPU9250_Self_Test
        (MPU_Device, Console.Console_Test, Console.Console_Put_Line'Access)
      then
         return False;
      end if;

      if Is_Magnetomer_Availaible
        and then not Self_Test (MAG_Device)
      then
         return False;
      end if;

      return True;
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
      Test_Status := MPU9250_Self_Test
        (MPU_Device, Console.Console_Test, Console.Console_Put_Line'Access);
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

   ---------------------
   -- IMU_6_Calibrate --
   ---------------------

   function IMU_6_Calibrate return Boolean
   is
      Has_Found_Bias : Boolean;
      Next_Period    : Time;
   begin
      case Is_Calibrated is
         when Not_Calibrated =>
            null;
            --  Fall through
         when Calibrated =>
            return True;

         when Calibration_Error =>
            return False;
      end case;

      if Is_Calibrated = Not_Calibrated then
         Next_Period := Clock + IMU_UPDATE_DT_MS;
         Variance_Sample_Time := Clock;

         loop
            MPU9250_Get_Motion_6 (MPU_Device,
                                  Accel_IMU.Y, Accel_IMU.X, Accel_IMU.Z,
                                  Gyro_IMU.Y, Gyro_IMU.X, Gyro_IMU.Z);
            IMU_Add_Bias_Value (Gyro_Bias, Gyro_IMU);

            if Gyro_Bias.Is_Buffer_Filled then
               IMU_Find_Bias_Value (Gyro_Bias, Has_Found_Bias);

               if Has_Found_Bias then
                  --  TODO: led sequence to indicate that it is calibrated
                  Is_Calibrated := Calibrated;

                  return True;
               else
                  Is_Calibrated := Calibration_Error;

                  return False;
               end if;
            end if;

            Next_Period := Next_Period + IMU_UPDATE_DT_MS;
            delay until Next_Period;
         end loop;
      end if;

      return False;
   end IMU_6_Calibrate;

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
   begin
      --  We invert X and Y because the chip is almso inverted.
      MPU9250_Get_Motion_6 (MPU_Device,
                            Accel_IMU.Y, Accel_IMU.X, Accel_IMU.Z,
                            Gyro_IMU.Y, Gyro_IMU.X, Gyro_IMU.Z);

      IMU_Acc_IRR_LP_Filter
        (Input         => Accel_IMU,
         Output        => Accel_LPF,
         Stored_Values => Accel_Stored_Values,
         Attenuation   => T_Int32 (IMU_Acc_Lp_Att_Factor));
      IMU_Acc_Align_To_Gravity (Accel_LPF, Accel_LPF_Aligned);

      --  Re-map outputs
      Gyro.X :=
        -(Float (Gyro_IMU.X) - Gyro_Bias.Bias.X) * IMU_DEG_PER_LSB_CFG;
      Gyro.Y :=
        (Float (Gyro_IMU.Y) - Gyro_Bias.Bias.Y) * IMU_DEG_PER_LSB_CFG;
      Gyro.Z :=
        (Float (Gyro_IMU.Z) - Gyro_Bias.Bias.Z) * IMU_DEG_PER_LSB_CFG;

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
      Mag  : in out Magnetometer_Data)
   is
   begin
      IMU_6_Read (Gyro,
                  Acc);
      if not Is_Magnetomer_Availaible then
         Mag := (others => 0.0);

      else
         declare
            Mx, My, Mz : Gauss;
            Dead       : Boolean with Unreferenced;
         begin
            Get_Heading (MAG_Device, Mx, My, Mz);
            --  Get_Overflow_Status clears ST1 by reading ST2
            Dead := Get_Overflow_Status (MAG_Device);
            Mag  := (X => Mx,
                     Y => My,
                     Z => Mz);
         end;
      end if;
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
            Variance : Axis3_Float;
            Mean     : Axis3_Float;
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
      Variance : out Axis3_Float;
      Mean     : out Axis3_Float)
   is
      Sum        : Axis3_Float := (others => 0.0);

   begin
      for Value of Bias_Obj.Buffer loop
         Sum := Sum + Value;
      end loop;

      Mean := Sum / IMU_NBR_OF_BIAS_SAMPLES;

      Sum := (others => 0.0);

      for Value of Bias_Obj.Buffer loop
         Sum := Sum + (Mean - Value) ** 2;
      end loop;

      Variance := Sum / IMU_NBR_OF_BIAS_SAMPLES;
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

end IMU;
