with Ada.Real_Time; use Ada.Real_Time;

with LEDS_Pack; use LEDS_Pack;
with IMU_Pack; use IMU_Pack;
with Motors_Pack; use Motors_Pack;
with Power_Management_Pack; use Power_Management_Pack;
with Communication_Pack; use Communication_Pack;
with Commander_Pack; use Commander_Pack;
with Stabilizer_Pack; use Stabilizer_Pack;
with Types; use Types;

package body System_Pack is

   procedure System_Init is
   begin
      if Is_Init then
         return;
      end if;
      --  Module initialization

      --  Initialize LEDs, power management, sensors and actuators
      LEDS_Init;
      Motors_Init;
      IMU_Init;
      Power_Management_Init;

      --  Initialize communication related modules
      Communication_Init;

      --  Initialize high level modules
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
      Self_Test_Passed := Self_Test_Passed and Commander_Test;
      Self_Test_Passed := Self_Test_Passed and Stabilizer_Test;

      if not Self_Test_Passed then
         Set_LED (LED   => LED_Red_R,
                  Value => True);
      else
         Set_LED (LED   => LED_Green_R,
                  Value => True);
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

end System_Pack;
