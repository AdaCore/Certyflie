--  MPU9250 I2C device class package

with Ada.Real_Time; use Ada.Real_Time;

with STM32F4.I2C; use STM32F4.I2C;
with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F429_Discovery;  use STM32F429_Discovery;
with STM32F4; use STM32F4;

package MPU9250_Pack is

   --  Types and subtypes

   type I2C_Data is array (Positive range <>) of Byte;

   --  Procedures and functions

   --  Initialize the MPU9250 Device via I2C
   procedure MPU9250_Init;

   function MPU9250_Test return Boolean;

   function MPU9250_Test_Connection return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

   MPU9250_I2C_PORT : I2C_Port renames I2C_3;
   MPU9250_I2C_OWN_ADDR : constant := 16#0074#;

   MPU9250_SCL_GPIO : GPIO_Port renames GPIO_A;
   MPU9250_SCL_Pin  : constant GPIO_Pin := Pin_8;
   MPU9250_SCL_AF   : GPIO_Alternate_Function := GPIO_AF_I2C3;

   MPU9250_SDA_GPIO : GPIO_Port renames GPIO_C;
   MPU9250_SDA_Pin  : constant GPIO_Pin := Pin_9;
   MPU9250_SDA_AF   : constant GPIO_Alternate_Function := GPIO_AF_I2C3;

   --  MPU9250 Device ID. Use to test if we are connected via I2C
   MPU9250_DEVICE_ID        : constant := 16#71#;
   --  Address pin low (GND), default for InvenSense evaluation board
   MPU9250_ADDRESS_AD0_LOW  : constant := 16#68#;
   --  Address pin high (VCC)
   MPU9250_ADDRESS_AD0_HIGH : constant := 16#69#;
   --  Default address (low)
   MPU9250_DEFAULT_ADDRESS  : constant := MPU9250_ADDRESS_AD0_HIGH;

   MPU9250_STARTUP_TIME_MS : constant Time
     := Time_First + Milliseconds (1_000);

   --  MPU9250 register adresses

   MPU9250_RA_WHO_AM_I : constant := 16#75#;

   --  Procedures and functions

   --  Initialize the GPIO pins of the I2C control lines
   procedure MPU9250_Init_Control_Lines;

   --  Configure I2C for MPU9250
   procedure MPU9250_Configure_I2C;

   --  Write data to the specified MPU9250 register
   procedure MPU9250_Write_Register
     (Reg_Addr    : Byte;
      Data        : I2C_Data);

   --  Read data to the specified MPU9250 register
   procedure MPU9250_Read_Register
     (Reg_Addr    : Byte;
      Data        : in out I2C_Data);

end MPU9250_Pack;
