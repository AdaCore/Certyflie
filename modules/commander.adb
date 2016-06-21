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

with Ada.Unchecked_Conversion;

with Safety;                   use Safety;

package body Commander
with SPARK_Mode,
  Refined_State => (Commander_State  => (Is_Init,
                                         Is_Inactive,
                                         Alt_Hold_Mode,
                                         Alt_Hold_Mode_Old,
                                         Thrust_Locked,
                                         Side,
                                         Target_Val,
                                         Last_Update))
is
   --  Private procedures and functions

   ------------------------------
   -- Commander_Watchdog_Reset --
   ------------------------------

   procedure Commander_Watchdog_Reset is
   begin
      CRTP_Set_Is_Connected (True);

      Last_Update := Clock;
   end Commander_Watchdog_Reset;

   -----------------------------------
   -- Commander_Get_Inactivity_Time --
   -----------------------------------

   function Commander_Get_Inactivity_Time return Time_Span
   is
      Current_Time : constant Time := Clock;
   begin
      return Current_Time - Last_Update;
   end Commander_Get_Inactivity_Time;

   ------------------------
   -- Commander_Watchdog --
   ------------------------

   procedure Commander_Watchdog is
      Used_Side : Boolean;
      Time_Since_Last_Update : Time_Span;
   begin
      --  To prevent the change of Side value when this is called
      Used_Side := Side;

      Time_Since_Last_Update := Commander_Get_Inactivity_Time;

      if Time_Since_Last_Update > COMMANDER_WDT_TIMEOUT_STABILIZE then
         CRTP_Set_Is_Connected (False);

         Target_Val (Used_Side).Roll := 0.0;
         Target_Val (Used_Side).Pitch := 0.0;
         Target_Val (Used_Side).Yaw := 0.0;
      end if;

      if Time_Since_Last_Update > COMMANDER_WDT_TIMEOUT_SHUTDOWN then
         Target_Val (Used_Side).Thrust := 0;
         --  TODO: set the alt hold mode variable to false
         Alt_Hold_Mode := False;
         Is_Inactive := True;
         Thrust_Locked := True;
      else
         Is_Inactive := False;
      end if;
   end Commander_Watchdog;

   --  Public procedures and functions

   --------------------
   -- Commander_Init --
   --------------------

   procedure Commander_Init
     with SPARK_Mode => Off
   is
   begin
      if Is_Init then
         return;
      end if;

      Last_Update := Clock;
      CRTP_Register_Callback
        (CRTP_PORT_COMMANDER, Commander_CRTP_Handler'Access);

      Is_Init := True;
   end Commander_Init;

   --------------------
   -- Commander_Test --
   --------------------

   function Commander_Test return Boolean is
   begin
      return Is_Init;
   end Commander_Test;

   ------------------------------
   -- Get_Commands_From_Packet --
   ------------------------------

   function Get_Commands_From_Packet
     (Packet : CRTP_Packet) return Commander_CRTP_Values
   is
      Commands     : Commander_CRTP_Values;
      Handler      : CRTP_Packet_Handler;
      Has_Succeed  : Boolean;
   begin
      Handler := CRTP_Get_Handler_From_Packet (Packet);

      pragma Warnings (Off, "unused assignment",
                       Reason => "Has_Succeed can't be equal to false here");
      CRTP_Get_Float_Data (Handler, 1, Commands.Roll, Has_Succeed);
      CRTP_Get_Float_Data (Handler, 5, Commands.Pitch, Has_Succeed);
      CRTP_Get_Float_Data (Handler, 9, Commands.Yaw, Has_Succeed);
      CRTP_Get_T_Uint16_Data (Handler, 13, Commands.Thrust, Has_Succeed);
      pragma Warnings (On, "unused assignment");

      return Commands;
   end Get_Commands_From_Packet;

   ----------------------------
   -- Commander_CRTP_Handler --
   ----------------------------

   procedure Commander_CRTP_Handler (Packet : CRTP_Packet) is
   begin
      Side := not Side;
      Target_Val (Side) := Get_Commands_From_Packet (Packet);

      if Target_Val (Side).Thrust = 0 then
         Thrust_Locked := False;
      end if;

      Commander_Watchdog_Reset;
   end Commander_CRTP_Handler;

   -----------------------
   -- Commander_Get_RPY --
   -----------------------

   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : out T_Degrees;
      Euler_Pitch_Desired : out T_Degrees;
      Euler_Yaw_Desired   : out T_Degrees)
   is
      Used_Side : Boolean;
   begin
      --  To prevent the change of Side value when this is called
      Used_Side := Side;

      Euler_Roll_Desired := Target_Val (Used_Side).Roll;
      Euler_Pitch_Desired := Target_Val (Used_Side).Pitch;
      Euler_Yaw_Desired := Target_Val (Used_Side).Yaw;
   end Commander_Get_RPY;

   ----------------------------
   -- Commander_Get_RPY_Type --
   ----------------------------

   procedure Commander_Get_RPY_Type
     (Roll_Type  : out RPY_Type;
      Pitch_Type : out RPY_Type;
      Yaw_Type   : out RPY_Type) is
   begin
      Roll_Type := ANGLE;
      Pitch_Type := ANGLE;
      Yaw_Type := RATE;
   end Commander_Get_RPY_Type;

   --------------------------
   -- Commander_Get_Thrust --
   --------------------------

   procedure Commander_Get_Thrust (Thrust : out T_Uint16) is
      Raw_Thrust : T_Uint16;
   begin
      Raw_Thrust := Target_Val (Side).Thrust;

      if Thrust_Locked then
         Thrust := 0;
      else
         Thrust := Saturate (Raw_Thrust, 0, MAX_THRUST);
      end if;

      Commander_Watchdog;
   end Commander_Get_Thrust;

   ----------------------------
   -- Commander_Get_Alt_Hold --
   ----------------------------

   procedure Commander_Get_Alt_Hold
     (Alt_Hold        : out Boolean;
      Set_Alt_Hold    : out Boolean;
      Alt_Hold_Change : out Float) is
   begin
      Alt_Hold := Alt_Hold_Mode;
      Set_Alt_Hold := Alt_Hold_Mode and not Alt_Hold_Mode_Old;
      Alt_Hold_Change :=
        (if Alt_Hold_Mode then
           (Float (Target_Val (Side).Thrust) - ALT_HOLD_THRUST_F)
           / ALT_HOLD_THRUST_F
         else
            0.0);
      Alt_Hold_Mode_Old := Alt_Hold_Mode;
   end Commander_Get_Alt_Hold;

end Commander;
