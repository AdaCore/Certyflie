with Types; use Types;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with CRTP_Pack; use CRTP_Pack;
pragma Elaborate_All (CRTP_Pack);
with Ada.Real_Time; use Ada.Real_Time;

package Commander_Pack
with SPARK_Mode
is

   --  Types

   --  Type of the commands given by the pilot.
   --  Can be an angle rate, or an angle.
   type RPY_Type is (RATE, ANGLE);
   for RPY_Type use (RATE => 0, ANGLE => 1);
   for RPY_Type'Size use Interfaces.C.int'Size;

   type Commander_CRTP_Values is record
      Roll   : T_Degrees := 0.0;
      Pitch  : T_Degrees := 0.0;
      Yaw    : T_Degrees := 0.0;
      Thrust : T_Uint16 := 0;
   end record;
   pragma Pack (Commander_CRTP_Values);

   --  Procedures and functions

   --  Initizalize the Commander module
   procedure Commander_Init;

   --  Test if the Commander module is initialized
   function Commander_Test return Boolean;

   --  Handler called when a CRTP packet is received in the commander
   --  port queue
   procedure Commander_CRTP_Handler (Packet : CRTP_Packet);

   --  Get the commands from the pilot.
   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : in out T_Degrees;
      Euler_Pitch_Desired : in out T_Degrees;
      Euler_Yaw_Desired   : in out T_Degrees);

   --  Get the commands types by default or from the client.
   procedure Commander_Get_RPY_Type
     (Roll_Type  : in out RPY_Type;
      Pitch_Type : in out RPY_Type;
      Yaw_Type   : in out RPY_Type);

   --  Get the thrust from the pilot.
   procedure Commander_Get_Thrust (Thrust : out T_Uint16);

   --  Get Alt Hold Mode parameters from the pilot.
   procedure Commander_Get_Alt_Hold
     (Alt_Hold        : out bool;
      Set_Alt_Hold    : out bool;
      Alt_Hold_Change : out Float);

   --  Cut the trust when inactivity time has been during for too long
   procedure Commander_Watchdog;

private

   --  Global variables and constants

   COMMANDER_WDT_TIMEOUT_STABILIZE : constant Time_Span
     := Milliseconds (500);
   COMMANDER_WDT_TIMEOUT_SHUTDOWN  : constant Time_Span
     := Milliseconds (1000);

   MIN_THRUST        : constant := 1000;
   MAX_THRUST        : constant := 60_000;
   ALT_HOLD_THRUST_F : constant := 32_767.0;

   Is_Init           : Boolean := False;
   Is_Inactive       : Boolean := True;
   Alt_Hold_Mode     : Boolean := False;
   Alt_Hold_Mode_Old : Boolean := False;
   Thrust_Locked     : Boolean := True;
   Side              : Boolean := False;

   --  Container for the commander values received via CRTP
   Target_Val : array (Boolean) of Commander_CRTP_Values;

   Last_Update : Time;

   --  Procedures and functions

   --  Reset the watchdog by assigning the Clock current value to Last_Update
   --  variable
   procedure Commander_Watchdog_Reset;
   pragma Inline (Commander_Watchdog_Reset);

   --  Get inactivity time since last update
   function Commander_Get_Inactivity_Time return Time_Span is
      (Clock - Last_Update);
   pragma Inline (Commander_Get_Inactivity_Time);

   --  Get target values from a received CRTP packet
   function Get_Commands_From_Packet
     (Packet : CRTP_Packet) return Commander_CRTP_Values;

   --  Get Float data from a CRTP Packet
   procedure CRTP_Get_Float_Data is new CRTP_Get_Data (Float);

   --  Get T_Uint16 data from a CRTP Packet
   procedure CRTP_Get_T_Uint16_Data is new CRTP_Get_Data (T_Uint16);

end Commander_Pack;
