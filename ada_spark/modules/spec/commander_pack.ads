with Types; use Types;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with Crtp_Pack; use Crtp_Pack;
pragma Elaborate_All (Crtp_Pack);

package Commander_Pack
with SPARK_Mode
is

   --  Types

   --  Type of the commands given by the pilot.
   --  Can be an angle rate, or an angle.
   type RPY_Type is (RATE, ANGLE);
   for RPY_Type use (RATE => 0, ANGLE => 1);
   for RPY_Type'Size use Interfaces.C.int'Size;

   type Commander_Crtp_Values is record
      Roll   : T_Degrees;
      Pitch  : T_Degrees;
      Yaw    : T_Degrees;
      Thrust : T_Uint16;
   end record;
   pragma Pack (Commander_Crtp_Values);

   --  Procedures and functions

   --  Initizalize the Commander module
   procedure Commander_Init;

   --  Test if the Commander module is initialized
   function Commander_Test return Boolean;

   --  Handler called when a CRTP packet is received in the commander
   --  port queue
   procedure Commander_Crtp_Handler (Packet : Crtp_Packet);

   --  Get the commands from the pilot.
   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : in out T_Degrees;
      Euler_Pitch_Desired : in out T_Degrees;
      Euler_Yaw_Desired   : in out T_Degrees)
     with
       Global => null;

   --  Get the commands types by default or from the client.
   procedure Commander_Get_RPY_Type
     (Roll_Type  : in out RPY_Type;
      Pitch_Type : in out RPY_Type;
      Yaw_Type   : in out RPY_Type)
     with
       Global => null;
   pragma Import (C, Commander_Get_RPY_Type, "commanderGetRPYType");

   --  Check if the pilot is inactive or if the radio signal is lost.
   procedure Commander_Watchdog
     with
       Global => null;
   pragma Import (C, Commander_Watchdog, "commanderWatchdog");

   --  Get the thrust from the pilot.
   procedure Commander_Get_Thrust (Thrust : out T_Uint16)
     with
       Global => null;
   pragma Import (C, Commander_Get_Thrust, "commanderGetThrust");

   --  Get Alt Hold Mode parameters from the pilot.
   procedure Commander_Get_Alt_Hold
     (Alt_Hold        : out bool;
      Set_Alt_Hold    : out bool;
      Alt_Hold_Change : out Float)
     with
       Global => null;
   pragma Import (C, Commander_Get_Alt_Hold, "commanderGetAltHold");

private

   --  Global variables

   Is_Init       : Boolean := False;
   Is_Inactive   : Boolean := True;
   Thrust_Locked : Boolean := True;
   Side          : Boolean := False;

   --  Container for the commander values received via CRTP
   Target_Val : array (Boolean) of Commander_Crtp_Values;

   --  Procedures and functions

   --  Get target values from a received CRTP packet
   function Get_Commands_From_Packet
     (Packet : Crtp_Packet) return Commander_Crtp_Values;

   --  Get Float data from a CRTP Packet
   procedure Crtp_Get_Float_Data is new Crtp_Get_Data (Float);

   --  Get T_Uint16 data from a CRTP Packet
   procedure Crtp_Get_T_Uint16_Data is new Crtp_Get_Data (T_Uint16);

   --  Test function used to test the CRTP Protocol implementation
   --  using Ravenscar
   procedure Print_Commands (Commands : Commander_Crtp_Values);

end Commander_Pack;
