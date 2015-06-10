with STM32F4.RCC; use STM32F4.RCC;

package body MPU9250_Pack is

   procedure MPU9250_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  Wait for MPU9250 startup
      while (Clock < MPU9250_STARTUP_TIME_MS) loop
         null;
      end loop;

      MPU9250_Init_Control_Lines;
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
         Clock_Speed => 1_000);

      Set_State (MPU9250_I2C_PORT, Enabled);
   end MPU9250_Configure_I2C;

   function MPU9250_Test return Boolean is
   begin
      return Is_Init;
   end MPU9250_Test;

   function MPU9250_Test_Connection return Boolean is
      Who_Am_I : I2C_Data (1 .. 1);
   Begin
      MPU9250_Read_Register (Reg_Addr => MPU9250_RA_WHO_AM_I,
                             Data     => Who_Am_I);
      return Who_Am_I (1) = MPU9250_DEVICE_ID;
   end MPU9250_Test_Connection;

   procedure MPU9250_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data) is
   begin
      Start (MPU9250_I2C_PORT,
             Shift_Left (MPU9250_DEFAULT_ADDRESS, 1),
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);

      for Data_Byte of Data loop
         Write (MPU9250_I2C_PORT, Data_Byte);
      end loop;

      Stop (MPU9250_I2C_PORT);
   end MPU9250_Write_Register;

   procedure MPU9250_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data) is
   begin
      Start (MPU9250_I2C_PORT,
             Shift_Left (MPU9250_DEFAULT_ADDRESS, 1),
             Transmitter);
      Write (MPU9250_I2C_PORT, Reg_Addr);
      Stop (MPU9250_I2C_PORT);

      Start (MPU9250_I2C_PORT,
             Shift_Left (MPU9250_DEFAULT_ADDRESS, 1),
             Receiver);

      for I in Data'Range loop
         if I = Data'Last then
            Data (I) := Read_Nack (MPU9250_I2C_PORT);
         else
            Data (I) := Read_Ack (MPU9250_I2C_PORT);
         end if;
      end loop;
   end MPU9250_Read_Register;

end MPU9250_Pack;
