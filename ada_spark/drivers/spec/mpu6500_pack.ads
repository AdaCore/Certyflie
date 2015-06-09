--  MPU6500 I2C device class package

with Ada.Real_Time; use Ada.Real_Time;

with STM32F4.I2C; use STM32F4.I2C;
with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F429_Discovery;  use STM32F429_Discovery;
with STM32F4; use STM32F4;

package MPU6500_Pack is

   --  Types and subtypes

   type I2C_Data is array (Positive range <>) of Byte;

   --  Procedures and functions

   --  Initialize the MPU6500 Device via I2C
   procedure MPU6500_Init;

   function MPU6500_Test return Boolean;

   function MPU6500_Test_Connection return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

   MPU6500_I2C_PORT : I2C_Port renames I2C_3;
   MPU6500_I2C_OWN_ADDR : constant := 16#74#;

   MPU6500_SCL_GPIO : GPIO_Port renames GPIO_A;
   MPU6500_SCL_Pin  : constant GPIO_Pin := Pin_8;
   MPU6500_SCL_AF   : GPIO_Alternate_Function := GPIO_AF_I2C3;

   MPU6500_SDA_GPIO : GPIO_Port renames GPIO_C;
   MPU6500_SDA_Pin  : constant GPIO_Pin := Pin_9;
   MPU6500_SDA_AF   : constant GPIO_Alternate_Function := GPIO_AF_I2C3;

   --  Address pin low (GND), default for InvenSense evaluation board
   MPU6500_ADDRESS_AD0_LOW  : constant := 16#68#;
   --  Address pin high (VCC)
   MPU6500_ADDRESS_AD0_HIGH : constant := 16#69#;
   --  Defaul address (low)
   MPU6500_DEFAULT_ADDRESS  : constant := MPU6500_ADDRESS_AD0_LOW;

   MPU6500_STARTUP_TIME_MS : constant Time
     := Time_First + Milliseconds (1_000);

   --  MPU6500 register adresses

   MPU6500_RA_WHO_AM_I : constant := 16#75#;

   --  Procedures and functions

   --  Initialize the GPIO pins of the I2C control lines
   procedure MPU6500_Init_Control_Lines;

   --  Configure I2C for MPU6500
   procedure MPU6500_Configure_I2C;

   --  Write data to the specified MPU6500 register
   procedure MPU6500_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data);

   --  Read data to the specified MPU6500 register
   procedure MPU6500_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data);

end MPU6500_Pack;
