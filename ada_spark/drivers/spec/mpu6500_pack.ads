--  MPU6500 I2C device class package

package MPU6500_Pack is

   --  Procedures and functions

   --  Initialize the MPU6500 Device via I2C
   procedure MPU6500_Init;

   function MPU6500_Test return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end MPU6500_Pack;
