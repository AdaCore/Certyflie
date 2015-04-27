pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Protected_IO_Pack;
with Syslink_Pack; use Syslink_Pack;
with Console_Pack; use Console_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Last_Chance_Handler;
with System;

procedure Main is
   pragma Priority (System.Priority'Last);
begin
   --  Use for thread safe printing
   Protected_IO_Pack.Initialize;

   --  Module initialization
   Syslink_Init;
   Platform_Service_Init;
   Commander_Init;
   Console_Init;
   delay until (Time_Last);
end Main;
