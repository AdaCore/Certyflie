with Ada.Real_Time; use Ada.Real_Time;

with LEDS; use LEDS;
with IMU; use IMU;
with Motors; use Motors;
with Power_Management; use Power_Management;
with Communication; use Communication;
with Commander; use Commander;
with Stabilizer; use Stabilizer;
with Memory; use Memory;
with Types; use Types;

package body CF_System is

   procedure System_Init is
   begin
      if Is_Init then
         return;
      end if;
      --  Module initialization.

      --  Initialize LEDs, power management, sensors and actuators.
      LEDS_Init;
      Motors_Init;
      IMU_Init;

      --  Initialize communication related modules.
      Communication_Init;

      --  Initialize power management module.
      Power_Management_Init;

      --  Inialize memory module.
      Memory_Init;

      --  Initialize high level modules.
      Commander_Init;
      Stabilizer_Init;

      Is_Init := True;
   end System_Init;

   function System_Self_Test return Boolean is
      Self_Test_Passed : Boolean;
   begin
      Self_Test_Passed := LEDS_Test;
      Self_Test_Passed := Self_Test_Passed and Motors_Test;
      Self_Test_Passed := Self_Test_Passed and IMU_Test;
      Self_Test_Passed := Self_Test_Passed and Communication_Test;
      Self_Test_Passed := Self_Test_Passed and Memory_Test;
      Self_Test_Passed := Self_Test_Passed and Commander_Test;
      Self_Test_Passed := Self_Test_Passed and Stabilizer_Test;

      if Self_Test_Passed and Get_Current_LED_Status /= Charging_Battery then
         Enable_LED_Status (Ready_To_Fly);
      elsif not Self_Test_Passed then
         Enable_LED_Status (Self_Test_Fail);
      end if;

      return Self_Test_Passed;
   end System_Self_Test;

   procedure System_Loop is
      Attitude_Update_Counter : T_Uint32 := 0;
      Alt_Hold_Update_Counter : T_Uint32 := 0;
      Next_Period             : Time;
   begin
      Next_Period := Clock + IMU_UPDATE_DT_MS;

      loop
         delay until Next_Period;
         Stabilizer_Control_Loop (Attitude_Update_Counter,
                                  Alt_Hold_Update_Counter);

         Next_Period := Next_Period + IMU_UPDATE_DT_MS;
      end loop;
   end System_Loop;

end CF_System;
