pragma Profile (Ravenscar);

with Ada.Real_Time; use Ada.Real_Time;
with Last_Chance_Handler;
with System;
with LEDS_Pack; use LEDS_Pack;
with Motors_Pack; use Motors_Pack;
with Communication_Pack; use Communication_Pack;
with Commander_Pack; use Commander_Pack;

procedure Main is
   pragma Priority (System.Priority'Last);
begin
   --  Module initialization

   --  Initialize LEDs, sensors and actuators
   LEDS_Init;
   Motors_Init;
   Motors_Test;

   --  Initialize communication related modules
   Communication_Init;

   --  Initialize high level modules
   Commander_Init;

   delay until (Time_Last);
end Main;
