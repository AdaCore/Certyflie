--  Package initializing all the modules of the Crazyflie

package System_Pack is

   --  Procedures and functions

   --  Initialize all the low/high level modules
   procedure System_Init;

   --  Self test function, used to check if all the modules
   --  are working correctly
   function System_Self_Test return Boolean;

   --  Main loop of the system
   procedure System_Loop;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end System_Pack;
