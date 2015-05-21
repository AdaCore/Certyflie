pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Syslink_Pack; use Syslink_Pack;
with Console_Pack; use Console_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Last_Chance_Handler;
with System;
with LEDS_Pack; use LEDS_Pack;
with Motors_Pack; use Motors_Pack;

procedure Main is
   pragma Priority (System.Priority'Last);
begin
   --  Module initialization
   LEDS_Init;

   Motors_Init;
   --Motors_Test;

   Syslink_Init;
   Platform_Service_Init;
   Commander_Init;
   Console_Init;
   delay until (Time_Last);
end Main;
