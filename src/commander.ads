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

with Ada.Real_Time; use Ada.Real_Time;

with CRTP;          use CRTP;
with Types;         use Types;
pragma Elaborate_All (CRTP);

package Commander
with SPARK_Mode,
  Abstract_State => Commander_State
is

   --  Types

   --  Type of the commands given by the pilot.
   --  Can be an angle rate, or an angle.
   type RPY_Type is (RATE, ANGLE);
   for RPY_Type use (RATE => 0, ANGLE => 1);
   for RPY_Type'Size use Integer'Size;

   --  Type used to represent different commands
   --  received in a CRTP packet sent from the client.
   type Commander_CRTP_Values is record
      Roll   : T_Degrees := 0.0;
      Pitch  : T_Degrees := 0.0;
      Yaw    : T_Degrees := 0.0;
      Thrust : T_Uint16 := 0;
   end record;
   pragma Pack (Commander_CRTP_Values);

   --  Procedures and functions

   --  Initizalize the Commander module.
   procedure Commander_Init;

   --  Test if the Commander module is initialized.
   function Commander_Test return Boolean;

   --  Handler called when a CRTP packet is received in the commander
   --  port queue.
   procedure Commander_CRTP_Handler (Packet : CRTP_Packet);

   --  Get the commands from the pilot.
   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : out T_Degrees;
      Euler_Pitch_Desired : out T_Degrees;
      Euler_Yaw_Desired   : out T_Degrees)
     with
       Global => (Input => Commander_State);

   --  Get the commands types by default or from the client..
   procedure Commander_Get_RPY_Type
     (Roll_Type  : out RPY_Type;
      Pitch_Type : out RPY_Type;
      Yaw_Type   : out RPY_Type)
     with
       Global => null;

   --  Get the thrust from the pilot.
   procedure Commander_Get_Thrust (Thrust : out T_Uint16)
     with
       Global => (Input  => Clock_Time,
                  In_Out => (CRTP_State,
                             Commander_State));

   --  Get Alt Hold Mode parameters from the pilot..
   procedure Commander_Get_Alt_Hold
     (Alt_Hold        : out Boolean;
      Set_Alt_Hold    : out Boolean;
      Alt_Hold_Change : out Float);

   --  Cut the trust when inactivity time has been during for too long.
   procedure Commander_Watchdog
     with
       Global => (Input  => Clock_Time,
                  In_Out => (CRTP_State,
                             Commander_State));

private

   --  Global variables and constants

   COMMANDER_WDT_TIMEOUT_STABILIZE : constant Time_Span
     := Milliseconds (500);
   COMMANDER_WDT_TIMEOUT_SHUTDOWN  : constant Time_Span
     := Milliseconds (1000);

   MIN_THRUST        : constant := 1000;
   MAX_THRUST        : constant := 60_000;
   ALT_HOLD_THRUST_F : constant := 32_767.0;

   Is_Init           : Boolean := False
     with
       Part_Of => Commander_State;
   Is_Inactive       : Boolean := True
     with
       Part_Of => Commander_State;
   Alt_Hold_Mode     : Boolean := False
     with
       Part_Of => Commander_State;
   Alt_Hold_Mode_Old : Boolean := False
     with
       Part_Of => Commander_State;
   Thrust_Locked     : Boolean := True
     with
       Part_Of => Commander_State;
   Side              : Boolean := False
     with
       Part_Of => Commander_State;

   --  Container for the commander values received via CRTP.
   Target_Val : array (Boolean) of Commander_CRTP_Values
     with
       Part_Of => Commander_State;

   Last_Update : Time
     with
       Part_Of => Commander_State;

   --  Procedures and functions

   --  Reset the watchdog by assigning the Clock current value to Last_Update
   --  variable.
   procedure Commander_Watchdog_Reset;
   pragma Inline (Commander_Watchdog_Reset);

   --  Get inactivity time since last update.
   function Commander_Get_Inactivity_Time return Time_Span
     with
       Volatile_Function;
   pragma Inline (Commander_Get_Inactivity_Time);

   --  Get target values from a received CRTP packet
   function Get_Commands_From_Packet
     (Packet : CRTP_Packet) return Commander_CRTP_Values;

   --  Get Float data from a CRTP Packet.
   procedure CRTP_Get_Float_Data is new CRTP_Get_Data (Float);

   --  Get T_Uint16 data from a CRTP Packet.
   procedure CRTP_Get_T_Uint16_Data is new CRTP_Get_Data (T_Uint16);

end Commander;
