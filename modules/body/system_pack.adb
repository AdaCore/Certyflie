------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Ada.Real_Time;         use Ada.Real_Time;

with Communication_Pack;    use Communication_Pack;
with Commander_Pack;        use Commander_Pack;
with IMU_Pack;              use IMU_Pack;
with LEDS_Pack;             use LEDS_Pack;
with Memory_Pack;           use Memory_Pack;
with Motors_Pack;           use Motors_Pack;
with Power_Management_Pack; use Power_Management_Pack;
with Stabilizer_Pack;       use Stabilizer_Pack;
with Types;                 use Types;

package body System_Pack is

   -----------------
   -- System_Init --
   -----------------

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

   ----------------------
   -- System_Self_Test --
   ----------------------

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

   -----------------
   -- System_Loop --
   -----------------

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
