------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2017, AdaCore                     --
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

with Ada.Real_Time;    use Ada.Real_Time;

with Communication;    use Communication;
with Commander;        use Commander;
with IMU;              use IMU;
with LEDS;             use LEDS;
with Log;              use Log;
with Memory;           use Memory;
with Motors;           use Motors;
with Parameter;        use Parameter;
with Power_Management; use Power_Management;
with Stabilizer;       use Stabilizer;
with Types;            use Types;

package body Crazyflie_System is

   procedure Initialize_System_Parameter_Logging;
   procedure Self_Test_Status (OK : Boolean) with Inline;

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
      IMU_Init (Use_Mag    => True,
                DLPF_256Hz => False);

      --  Initialize communication related modules.
      Communication_Init;

      --  Initialize power management module.
      Power_Management_Init;

      --  Initialize memory module.
      Memory_Init;

      --  Initialize logging.
      Log_Init;

      --  Initialize parameters.
      Parameter_Init;
      Initialize_System_Parameter_Logging;

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
      Set_System_State (Self_Test);
      Self_Test_Passed := LEDS_Test;
      Self_Test_Passed := Self_Test_Passed and Motors_Test;
      Self_Test_Passed := Self_Test_Passed and IMU_Test;
      Self_Test_Passed := Self_Test_Passed and Communication_Test;
      Self_Test_Passed := Self_Test_Passed and Memory_Test;
      Self_Test_Passed := Self_Test_Passed and Commander_Test;
      Self_Test_Passed := Self_Test_Passed and Stabilizer_Test;

      if Self_Test_Passed then
         Set_System_State (Calibrating);

         if IMU_6_Calibrate then
            Set_System_State (Ready);
         else
            Set_System_State (Failure);
         end if;

      elsif not Self_Test_Passed then
         Set_System_State (Failure);
      end if;

      Self_Test_Status (OK => Self_Test_Passed);

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

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Error : Exception_Occurrence)
   is
      pragma Unreferenced (Error);
   begin
      Motors_Reset;
      Reset_All_LEDs;

      --  No-return procedure...
      loop
         Toggle_LED (LED_Red_L);
         delay until Clock + Milliseconds (1_000);
      end loop;
   end Last_Chance_Handler;

   ------------------------------
   -- System Parameter Logging --
   ------------------------------

   System_Group_ID : Natural := 0;
   System_Group_Created : Boolean;

   Self_Test_Passed : Boolean := True
   with Convention => C;

   pragma Assert (Self_Test_Passed'Size = 8);

   procedure Initialize_System_Parameter_Logging is
   begin
      Parameter.Create_Parameter_Group (Name        => "system",
                                        Group_ID    => System_Group_ID,
                                        Has_Succeed => System_Group_Created);

      if System_Group_Created then
         declare
            Dummy          : Boolean;
            Parameter_Type : constant Parameter.Parameter_Variable_Type
              := (Size      => One_Byte,
                  Floating  => False,
                  Signed    => False,
                  Read_Only => True,
                  others    => <>);
         begin
            Parameter.Append_Parameter_Variable_To_Group
              (System_Group_ID,
               Name           => "selftestPassed",
               Parameter_Type => Parameter_Type,
               Variable       => Self_Test_Passed'Address,
               Has_Succeed    => Dummy);
         end;
      end if;
   end Initialize_System_Parameter_Logging;

   procedure Self_Test_Status (OK : Boolean) is
   begin
      Self_Test_Passed := OK;
   end Self_Test_Status;

end Crazyflie_System;
