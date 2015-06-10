with STM32F4.RCC; use STM32F4.RCC;

package body MPU6500_Pack is

   procedure MPU6500_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  Wait for MPU6500 startup
      while (Clock < MPU6500_STARTUP_TIME_MS) loop
         null;
      end loop;

      MPU6500_Init_Control_Lines;
      MPU6500_Configure_I2C;

   end MPU6500_Init;

   procedure MPU6500_Init_Control_Lines is
      GPIO_Conf : GPIO_Port_Configuration;
   begin
      Enable_Clock (MPU6500_SDA_GPIO);
      Enable_Clock (MPU6500_SCL_GPIO);

      Enable_Clock (MPU6500_I2C_PORT);

      Reset (MPU6500_I2C_PORT);

      Enable_Clock (MPU6500_I2C_PORT);

      Configure_Alternate_Function
        (MPU6500_SCL_GPIO, MPU6500_SCL_Pin, MPU6500_SCL_AF);
      Configure_Alternate_Function
        (MPU6500_SDA_GPIO, MPU6500_SDA_Pin, MPU6500_SDA_AF);

      GPIO_Conf.Speed       := Speed_25MHz;
      GPIO_Conf.Mode        := Mode_AF;
      GPIO_Conf.Output_Type := Open_Drain;
      GPIO_Conf.Resistors   := Pull_Up;
      GPIO_Conf.Locked      := True;
      Configure_IO (MPU6500_SCL_GPIO, MPU6500_SCL_Pin, GPIO_Conf);
      Configure_IO (MPU6500_SDA_GPIO, MPU6500_SDA_Pin, GPIO_Conf);
   end MPU6500_Init_Control_Lines;

   procedure MPU6500_Configure_I2C is
   begin
      Enable_Clock (MPU6500_I2C_PORT);
      Reset (MPU6500_I2C_PORT);
      Enable_Clock (MPU6500_I2C_PORT);

      I2C3_Force_Reset;
      I2C3_Release_Reset;

      Configure
        (Port        => MPU6500_I2C_PORT,
         Mode        => I2C_Mode,
         Duty_Cycle  => DutyCycle_2,
         Own_Address => MPU6500_I2C_OWN_ADDR,
         Ack         => Ack_Enable,
         Ack_Address => AcknowledgedAddress_7bit,
         Clock_Speed => 1_000);

      Set_State (MPU6500_I2C_PORT, Enabled);
   end MPU6500_Configure_I2C;

   function MPU6500_Test return Boolean is
   begin
      return Is_Init;
   end MPU6500_Test;

   function MPU6500_Test_Connection return Boolean is
      Who_Am_I : I2C_Data (1 .. 1);
   Begin
      MPU6500_Read_Register (Reg_Addr => MPU6500_RA_WHO_AM_I,
                             Data     => Who_Am_I);
      return Who_Am_I (1) /= 0;
   end MPU6500_Test_Connection;

   procedure MPU6500_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data) is
   begin
      Start (MPU6500_I2C_PORT, MPU6500_DEFAULT_ADDRESS, Transmitter);
      Write (MPU6500_I2C_PORT, Reg_Addr);

      for Data_Byte of Data loop
         Write (MPU6500_I2C_PORT, Data_Byte);
      end loop;

      Stop (MPU6500_I2C_PORT);
   end MPU6500_Write_Register;

   procedure MPU6500_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data) is
   begin
      Start (MPU6500_I2C_PORT, MPU6500_DEFAULT_ADDRESS, Transmitter);
      Write (MPU6500_I2C_PORT, Reg_Addr);
      Stop (MPU6500_I2C_PORT);

      Start (MPU6500_I2C_PORT, MPU6500_DEFAULT_ADDRESS, Receiver);

      for I in Data'Range loop
         if I = Data'Last then
            Data (I) := Read_Nack (MPU6500_I2C_PORT);
         else
            Data (I) := Read_Ack (MPU6500_I2C_PORT);
         end if;
      end loop;
   end MPU6500_Read_Register;

end MPU6500_Pack;
