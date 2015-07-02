with Ada.Unchecked_Conversion;

with STM32F4.RCC; use STM32F4.RCC;

with Console_Pack; use Console_Pack;

package body MPU9250_Pack is

   --  Public procedures and functions

   procedure MPU9250_Init is
      Delay_Time : Time;
   begin
      if Is_Init then
         return;
      end if;

      --  Wait for MPU9250 startup
      while (Clock < MPU9250_STARTUP_TIME_MS) loop
         null;
      end loop;

      --  Set the device address
      Device_Address := Shift_Left (MPU9250_ADDRESS_AD0_HIGH, 1);

      --  Init and configure GPIO pins and I2C
      MPU9250_Init_Control_Lines;

      --  Delay to wait for the state initialization of SCL and SDA
      Delay_Time := Clock + Milliseconds (5);
      delay until Delay_Time;

      MPU9250_Configure_I2C;
   end MPU9250_Init;

   procedure MPU9250_Init_Control_Lines is
      GPIO_Conf : GPIO_Port_Configuration;
   begin
      Enable_Clock (MPU9250_SDA_GPIO);
      Enable_Clock (MPU9250_SCL_GPIO);

      Enable_Clock (MPU9250_I2C_PORT);

      Reset (MPU9250_I2C_PORT);

      Enable_Clock (MPU9250_I2C_PORT);

      Configure_Alternate_Function
        (MPU9250_SCL_GPIO, MPU9250_SCL_Pin, MPU9250_SCL_AF);
      Configure_Alternate_Function
        (MPU9250_SDA_GPIO, MPU9250_SDA_Pin, MPU9250_SDA_AF);

      GPIO_Conf.Speed       := Speed_25MHz;
      GPIO_Conf.Mode        := Mode_AF;
      GPIO_Conf.Output_Type := Open_Drain;
      GPIO_Conf.Resistors   := Pull_Up;
      GPIO_Conf.Locked      := True;
      Configure_IO (MPU9250_SCL_GPIO, MPU9250_SCL_Pin, GPIO_Conf);
      Configure_IO (MPU9250_SDA_GPIO, MPU9250_SDA_Pin, GPIO_Conf);
   end MPU9250_Init_Control_Lines;

   procedure MPU9250_Configure_I2C is
   begin
      I2C3_Force_Reset;
      I2C3_Release_Reset;

      Configure
        (Port        => MPU9250_I2C_PORT,
         Mode        => I2C_Mode,
         Duty_Cycle  => DutyCycle_2,
         Own_Address => MPU9250_I2C_OWN_ADDR,
         Ack         => Ack_Enable,
         Ack_Address => AcknowledgedAddress_7bit,
         Clock_Speed => 100_000);

      Set_State (MPU9250_I2C_PORT, Enabled);
   end MPU9250_Configure_I2C;

   function MPU9250_Test return Boolean is
   begin
      return Is_Init;
   end MPU9250_Test;

   function MPU9250_Test_Connection return Boolean is
      Who_Am_I : Byte;
   begin
      MPU9250_Read_Byte_At_Register
        (Reg_Addr => MPU9250_RA_WHO_AM_I,
         Data     => Who_Am_I);

      return Who_Am_I = MPU9250_DEVICE_ID;
   end MPU9250_Test_Connection;

   function MPU9250_Self_Test return Boolean is
      subtype T_Int32_Array_3 is T_Int32_Array (1 .. 3);
      subtype T_Int32_Array_6 is T_Int32_Array (1 .. 6);
      subtype Float_Array_3 is Float_Array (1 .. 3);

      Raw_Data    : I2C_Data (1 .. 6) := (others => 0);
      Saved_Reg   : I2C_Data (1 .. 5) := (others => 0);
      Self_Test   : I2C_Data (1 .. 6) := (others => 0);
      Acc_Avg     : T_Int32_Array_3 := (others => 0);
      Gyro_Avg    : T_Int32_Array_3 := (others => 0);
      Acc_ST_Avg  : T_Int32_Array_3 := (others => 0);
      Gyro_ST_Avg : T_Int32_Array_3 := (others => 0);

      Factory_Trim : T_Int32_Array_6 := (others => 0);
      Acc_Diff     : Float_Array_3;
      Gyro_Diff    : Float_Array_3;
      FS           : constant Natural := 0;

      Next_Period : Time;
      Test_Status : Boolean;
   begin
      --  Save old configuration
      MPU9250_Read_Byte_At_Register (MPU9250_RA_SMPLRT_DIV, Saved_Reg (1));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_CONFIG, Saved_Reg (2));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_GYRO_CONFIG, Saved_Reg (3));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG_2, Saved_Reg (4));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG, Saved_Reg (5));

      --  Write test configuration
      MPU9250_Write_Byte_At_Register (MPU9250_RA_SMPLRT_DIV, 16#00#);
      MPU9250_Write_Byte_At_Register (MPU9250_RA_CONFIG, 16#02#);
      MPU9250_Write_Byte_At_Register (MPU9250_RA_GYRO_CONFIG,
                                      Shift_Left (1, FS));
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG_2, 16#02#);
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG,
                                      Shift_Left (1, FS));

      --  Get average current values of gyro and accelerometer
      for I in 1 .. 200 loop
         MPU9250_Read_Register (MPU9250_RA_ACCEL_XOUT_H, Raw_Data);
         Acc_Avg (1) :=
           Acc_Avg (1) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Acc_Avg (2) :=
           Acc_Avg (2) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Acc_Avg (3) :=
           Acc_Avg (3) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));

         MPU9250_Read_Register (MPU9250_RA_GYRO_XOUT_H, Raw_Data);
         Gyro_Avg (1) :=
           Gyro_Avg (1) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Gyro_Avg (2) :=
           Gyro_Avg (2) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Gyro_Avg (3) :=
           Gyro_Avg (3) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));
      end loop;

      --  Get average of 200 values and store as average current readings
      for I in T_Int32_Array_3'Range loop
         Acc_Avg (I) := Acc_Avg (I) / 200;
         Gyro_Avg (I) := Gyro_Avg (I) / 200;
      end loop;

      --  Configure the acceleromter for self test
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG, 16#E0#);
      MPU9250_Write_Byte_At_Register (MPU9250_RA_GYRO_CONFIG, 16#E0#);

      --  Delay a while to let the device stabilize
      Next_Period := Clock + Milliseconds (25);
      delay until Next_Period;

      --  Get average self-test values of gyro and accelerometer
      for I in 1 .. 200 loop
         MPU9250_Read_Register (MPU9250_RA_ACCEL_XOUT_H, Raw_Data);
         Acc_ST_Avg (1) :=
           Acc_ST_Avg (1) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Acc_ST_Avg (2) :=
           Acc_ST_Avg (2) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Acc_ST_Avg (3) :=
           Acc_ST_Avg (3) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));

         MPU9250_Read_Register (MPU9250_RA_GYRO_XOUT_H, Raw_Data);
         Gyro_ST_Avg (1) :=
           Gyro_ST_Avg (1) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (1), Raw_Data (2)));
         Gyro_ST_Avg (2) :=
           Gyro_ST_Avg (2) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (3), Raw_Data (4)));
         Gyro_ST_Avg (3) :=
           Gyro_ST_Avg (3) +
           T_Int32 (Fuse_Low_And_High_Register_Parts
                    (Raw_Data (5), Raw_Data (6)));
      end loop;

      --  Get average of 200 values and store as average self-test readings
      for I in T_Int32_Array_3'Range loop
         Acc_ST_Avg (I) := Acc_ST_Avg (I) / 200;
         Gyro_ST_Avg (I) := Gyro_ST_Avg (I) / 200;
      end loop;

      --  Configure the gyro and accelerometer for normal operation
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG, 16#00#);
      MPU9250_Write_Byte_At_Register (MPU9250_RA_GYRO_CONFIG, 16#00#);

      --  Delay a while to let the device stabilize
      Next_Period := Clock + Milliseconds (25);
      delay until Next_Period;

      --  Retrieve Accelerometer and Gyro Factory Self - Test Code From USR_Reg
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_X_ACCEL, Self_Test (1));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_Y_ACCEL, Self_Test (2));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_Z_ACCEL, Self_Test (3));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_X_GYRO, Self_Test (4));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_Y_GYRO, Self_Test (5));
      MPU9250_Read_Byte_At_Register (MPU9250_RA_ST_Z_GYRO, Self_Test (6));

      for I in 1 .. 6 loop
         if Self_Test (I) /= 0 then
            Factory_Trim (I) := T_Int32
              (MPU9250_ST_TB (Integer (Self_Test (I))));
         else
            Factory_Trim (I) := 0;
         end if;
      end loop;

      --  Report results as a ratio of (STR - FT)/FT; the change from
      --  Factory Trim of the Self - Test Response
      --  To get percent, must multiply by 100

      for I in 1 .. 3 loop
         Acc_Diff (I) :=
           100.0 * (Float (Acc_ST_Avg (I) - Acc_Avg (I) - Factory_Trim (I)) /
                      Float (Factory_Trim (I)));
         Gyro_Diff (I) :=
           100.0 * (Float (Gyro_ST_Avg (I) - Gyro_Avg (I) -
                      Factory_Trim (I + 3)) /
                      Float (Factory_Trim (I + 3)));
      end loop;

      --  Restore old configuration
      MPU9250_Write_Byte_At_Register (MPU9250_RA_SMPLRT_DIV, Saved_Reg (1));
      MPU9250_Write_Byte_At_Register (MPU9250_RA_CONFIG, Saved_Reg (2));
      MPU9250_Write_Byte_At_Register (MPU9250_RA_GYRO_CONFIG, Saved_Reg (3));
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG_2, Saved_Reg (4));
      MPU9250_Write_Byte_At_Register (MPU9250_RA_ACCEL_CONFIG, Saved_Reg (5));

      --  Check result
      Test_Status := MPU9250_Evaluate_Self_Test
        (MPU9250_ST_GYRO_LOW, MPU9250_ST_GYRO_HIGH, Gyro_Diff (1), "gyro X");
      Test_Status := Test_Status and
        MPU9250_Evaluate_Self_Test
          (MPU9250_ST_GYRO_LOW, MPU9250_ST_GYRO_HIGH, Gyro_Diff (2), "gyro Y");
      Test_Status := Test_Status and
        MPU9250_Evaluate_Self_Test
          (MPU9250_ST_GYRO_LOW, MPU9250_ST_GYRO_HIGH, Gyro_Diff (3), "gyro Z");
      Test_Status := Test_Status and
        MPU9250_Evaluate_Self_Test
          (MPU9250_ST_ACCEL_LOW, MPU9250_ST_ACCEL_HIGH, Acc_Diff (1), "acc X");
      Test_Status := Test_Status and
        MPU9250_Evaluate_Self_Test
          (MPU9250_ST_ACCEL_LOW, MPU9250_ST_ACCEL_HIGH, Acc_Diff (2), "acc Y");
      Test_Status := Test_Status and
        MPU9250_Evaluate_Self_Test
          (MPU9250_ST_ACCEL_LOW, MPU9250_ST_ACCEL_HIGH, Acc_Diff (3), "acc Z");

      return Test_Status;
   end MPU9250_Self_Test;

   procedure MPU9250_Reset is
   begin
      MPU9250_Write_Bit_At_Register
        (Reg_Addr  => MPU9250_RA_PWR_MGMT_1,
         Bit_Pos   => MPU9250_PWR1_DEVICE_RESET_BIT,
         Bit_Value => True);
   end MPU9250_Reset;

   procedure MPU9250_Get_Motion_6
     (Acc_X  : out T_Int16;
      Acc_Y  : out T_Int16;
      Acc_Z  : out T_Int16;
      Gyro_X : out T_Int16;
      Gyro_Y : out T_Int16;
      Gyro_Z : out T_Int16) is
      Raw_Data : I2C_Data (1 .. 14);
   begin
      MPU9250_Read_Register
        (Reg_Addr => MPU9250_RA_ACCEL_XOUT_H,
         Data     => Raw_Data);

      Acc_X :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (1), Raw_Data (2));
      Acc_Y :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (3), Raw_Data (4));
      Acc_Z :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (5), Raw_Data (6));

      Gyro_X :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (9), Raw_Data (10));
      Gyro_Y :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (11), Raw_Data (12));
      Gyro_Z :=
        Fuse_Low_And_High_Register_Parts (Raw_Data (13), Raw_Data (14));
   end MPU9250_Get_Motion_6;

   procedure MPU9250_Set_Clock_Source (Clock_Source : MPU9250_Clock_Source) is
   begin
      MPU9250_Write_Bits_At_Register
        (Reg_Addr      => MPU9250_RA_PWR_MGMT_1,
         Start_Bit_Pos => MPU9250_PWR1_CLKSEL_BIT,
         Data          => MPU9250_Clock_Source'Enum_Rep (Clock_Source),
         Length        => MPU9250_PWR1_CLKSEL_LENGTH);
   end MPU9250_Set_Clock_Source;

   procedure MPU9250_Set_DLPF_Mode (DLPF_Mode : MPU9250_DLPF_Bandwidth_Mode) is
   begin
      MPU9250_Write_Bits_At_Register
        (Reg_Addr      => MPU9250_RA_CONFIG,
         Start_Bit_Pos => MPU9250_CFG_DLPF_CFG_BIT,
         Data          => MPU9250_DLPF_Bandwidth_Mode'Enum_Rep (DLPF_Mode),
         Length        => MPU9250_CFG_DLPF_CFG_LENGTH);
   end MPU9250_Set_DLPF_Mode;

   procedure MPU9250_Set_Full_Scale_Gyro_Range
     (FS_Range : MPU9250_FS_Gyro_Range) is
   begin
      MPU9250_Write_Bits_At_Register
        (Reg_Addr      => MPU9250_RA_GYRO_CONFIG,
         Start_Bit_Pos => MPU9250_GCONFIG_FS_SEL_BIT,
         Data          => MPU9250_FS_Gyro_Range'Enum_Rep (FS_Range),
         Length        => MPU9250_GCONFIG_FS_SEL_LENGTH);
   end MPU9250_Set_Full_Scale_Gyro_Range;

   procedure MPU9250_Set_Full_Scale_Accel_Range
           (FS_Range : MPU9250_FS_Accel_Range) is
   begin
      MPU9250_Write_Bits_At_Register
        (Reg_Addr      => MPU9250_RA_ACCEL_CONFIG,
         Start_Bit_Pos => MPU9250_ACONFIG_AFS_SEL_BIT,
         Data          => MPU9250_FS_Accel_Range'Enum_Rep (FS_Range),
         Length        => MPU9250_ACONFIG_AFS_SEL_LENGTH);
   end MPU9250_Set_Full_Scale_Accel_Range;

   procedure MPU9250_Set_I2C_Bypass_Enabled (Value : Boolean) is
   begin
      MPU9250_Write_Bit_At_Register
        (Reg_Addr  => MPU9250_RA_INT_PIN_CFG,
         Bit_Pos   => MPU9250_INTCFG_I2C_BYPASS_EN_BIT,
         Bit_Value => Value);
   end MPU9250_Set_I2C_Bypass_Enabled;

   procedure MPU9250_Set_Int_Enabled (Value : Boolean) is
   begin
      --  Full register byte for all interrupts, for quick reading.
      --  Each bit should be set 0 for disabled, 1 for enabled.
      if Value then
         MPU9250_Write_Byte_At_Register
           (Reg_Addr => MPU9250_RA_INT_ENABLE,
            Data     => 16#FF#);
      else
         MPU9250_Write_Byte_At_Register
           (Reg_Addr => MPU9250_RA_INT_ENABLE,
            Data     => 16#00#);
      end if;
   end MPU9250_Set_Int_Enabled;

   procedure MPU9250_Set_Rate (Rate_Div : Byte) is
   begin
      MPU9250_Write_Byte_At_Register
        (Reg_Addr => MPU9250_RA_SMPLRT_DIV,
         Data     => Rate_Div);
   end MPU9250_Set_Rate;


   procedure MPU9250_Set_Sleep_Enabled (Value : Boolean) is
   begin
      MPU9250_Write_Bit_At_Register
        (Reg_Addr  => MPU9250_RA_PWR_MGMT_1,
         Bit_Pos   => MPU9250_PWR1_SLEEP_BIT,
         Bit_Value => Value);
   end MPU9250_Set_Sleep_Enabled;

   procedure MPU9250_Set_Temp_Sensor_Enabled (Value : Boolean) is
   begin
      --  True value for this bit actually disables it.
      MPU9250_Write_Bit_At_Register
        (Reg_Addr  => MPU9250_RA_PWR_MGMT_1,
         Bit_Pos   => MPU9250_PWR1_TEMP_DIS_BIT,
         Bit_Value => not Value);
   end MPU9250_Set_Temp_Sensor_Enabled;

   function MPU9250_Get_Temp_Sensor_Enabled return Boolean is
   begin
      --  False value for this bit means that it is enabled
      return not MPU9250_Read_Bit_At_Register
        (Reg_Addr  => MPU9250_RA_PWR_MGMT_1,
         Bit_Pos   => MPU9250_PWR1_TEMP_DIS_BIT);
   end MPU9250_Get_Temp_Sensor_Enabled;

   --  Private procedures and functions

   function MPU9250_Evaluate_Self_Test
     (Low          : Float;
      High         : Float;
      Value        : Float;
      Debug_String : String) return Boolean is
      Has_Succeed : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      if Value not in Low .. High then
         if Console_Test then
            Console_Put_Line
              ("Self test " & Debug_String & "[FAIL]" & ASCII.LF,
               Has_Succeed);
         end if;
         return False;
      end if;

      return True;
   end MPU9250_Evaluate_Self_Test;

   procedure MPU9250_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data) is
   begin
      Start (MPU9250_I2C_PORT,
             Device_Address,
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);

      Start (MPU9250_I2C_PORT,
             Device_Address,
             Receiver);

      for I in Data'Range loop
         if I = Data'Last then
            Data (I) := Read_Nack (MPU9250_I2C_PORT);
         else
            Data (I) := Read_Ack (MPU9250_I2C_PORT);
         end if;
      end loop;
   end MPU9250_Read_Register;

   procedure MPU9250_Read_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : out Byte) is
   begin
      Start (MPU9250_I2C_PORT,
             Device_Address,
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);

      Start (MPU9250_I2C_PORT,
             Device_Address,
             Receiver);

      Data := Read_Nack (MPU9250_I2C_PORT);
   end MPU9250_Read_Byte_At_Register;

   function MPU9250_Read_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : T_Bit_Pos_8) return Boolean is
      Register_Value : Byte;
   begin
      MPU9250_Read_Byte_At_Register (Reg_Addr, Register_Value);
      return (if (Register_Value and Shift_Left (1, Bit_Pos)) /= 0 then
                 True
              else
                 False);
   end MPU9250_Read_Bit_At_Register;

   procedure MPU9250_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data) is
   begin
      Start (MPU9250_I2C_PORT,
             Device_Address,
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);

      for Data_Byte of Data loop
         Write (MPU9250_I2C_PORT, Data_Byte);
      end loop;

      Stop (MPU9250_I2C_PORT);
   end MPU9250_Write_Register;

   procedure MPU9250_Write_Byte_At_Register
     (Reg_Addr : Byte;
      Data     : Byte) is
   begin
      Start (MPU9250_I2C_PORT,
             Device_Address,
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);
      Write (MPU9250_I2C_PORT, Data);
      Stop (MPU9250_I2C_PORT);
   end MPU9250_Write_Byte_At_Register;

   procedure MPU9250_Write_Bit_At_Register
     (Reg_Addr  : Byte;
      Bit_Pos   : T_Bit_Pos_8;
      Bit_Value : Boolean) is
      Register_Value : Byte;
   begin
      MPU9250_Read_Byte_At_Register (Reg_Addr, Register_Value);

      Register_Value := (if Bit_Value then
                            Register_Value or (Shift_Left (1, Bit_Pos))
                         else
                            Register_Value and not (Shift_Left (1, Bit_Pos)));

      MPU9250_Write_Byte_At_Register (Reg_Addr, Register_Value);
   end MPU9250_Write_Bit_At_Register;

   procedure MPU9250_Write_Bits_At_Register
     (Reg_Addr      : Byte;
      Start_Bit_Pos : T_Bit_Pos_8;
      Data          : Byte;
      Length        : T_Bit_Pos_8) is
      Register_Value : Byte;
      Mask           : Byte;
      Data_Aux       : Byte := Data;
   begin
      MPU9250_Read_Byte_At_Register (Reg_Addr, Register_Value);

      Mask := Shift_Left
        ((Shift_Left (1, Length) - 1), Start_Bit_Pos - Length + 1);
      Data_Aux := Shift_Left
        (Data_Aux, Start_Bit_Pos - Length + 1);
      Data_Aux := Data_Aux and Mask;
      Register_Value := Register_Value and not Mask;
      Register_Value := Register_Value or Data_Aux;

      MPU9250_Write_Byte_At_Register (Reg_Addr, Register_Value);
   end MPU9250_Write_Bits_At_Register;

   function Fuse_Low_And_High_Register_Parts
     (High : Byte;
      Low  : Byte) return T_Int16 is
      function T_Uint16_To_T_Int16 is new Ada.Unchecked_Conversion
        (T_Uint16, T_Int16);
      Register : T_Uint16;
   begin
      Register := Shift_Left (T_Uint16 (High), 8);
      Register := Register or T_Uint16 (Low);

      return T_Uint16_To_T_Int16 (Register);
   end Fuse_Low_And_High_Register_Parts;

end MPU9250_Pack;
