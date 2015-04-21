with Types; use Types;
with Crtp_Pack; use Crtp_Pack;

package Platform_Service_Pack is

   --  Types

   --  Type enumerating all the channels for  the Platform service module
   type Platform_Channel is (PLAT_COMMAND);
   for Platform_Channel'Size use 2;
   for Platform_Channel use (PLAT_COMMAND => 2#00#);

   --  Type enumerating all the possible commands
   type Platform_Command is (SET_CONTINUOUS_WAVE);
   for Platform_Command'Size use 8;
   for Platform_Command use (SET_CONTINUOUS_WAVE => 16#00#);

   --  Procedures and functions

   --  Initialize the platform service module
   procedure Platform_Service_Init;

   --  Test if the platform service is initialized
   function Platform_Service_Test return Boolean;

   --  Handler called when a CRTP packet is received in the
   --  platform service port
   procedure Platform_Service_Handler (Packet : Crtp_Packet);

   --  Process a given command by sending a CRTP packet
   procedure Platform_Command_Process
     (Command : T_Uint8;
      Data    : T_Uint8_Array);

private

   Is_Init : Boolean := False;

end Platform_Service_Pack;
