pragma Profile (Ravenscar);

with Last_Chance_Handler;
with Ada.Real_Time; use Ada.Real_Time;

with System_Pack; use System_Pack;
with Config; use Config;

pragma Unreferenced (Last_Chance_Handler);

procedure Main is
   pragma Priority (MAIN_TASK_PRIORITY);
   Self_Test_Passed : Boolean;
begin
   --  System initialization
   System_Init;

   --  See if we pass the self test
   Self_Test_Passed := System_Self_Test;

   --  Start the main loop if the self test passed
   if Self_Test_Passed then
      System_Loop;
   else
      delay until Time_Last;
   end if;
end Main;
