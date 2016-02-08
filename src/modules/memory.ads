--  Memory module.
--  Handles one - wire and eeprom memory functions over crtp link.

with CRTP; use CRTP;

package Memory is

   --  Types

   --  Type represening all the memory module CRTP channels.
   type Memory_Channel is
     (MEM_SETTINGS_CH,
      MEM_READ_CH,
      MEM_WRITE_CH);
   for Memory_Channel use
     (MEM_SETTINGS_CH => 0,
      MEM_READ_CH     => 1,
      MEM_WRITE_CH    => 2);
   for Memory_Channel'Size use 2;

   --  Type representing all the avalaible memory commands.
   type Memory_Command is
     (MEM_CMD_GET_NBR,
      MEM_CMD_GET_INFO);
   for Memory_Command use
     (MEM_CMD_GET_NBR  => 1,
      MEM_CMD_GET_INFO => 2);
   for Memory_Command'Size use 8;

   --  Procedures and functions

   --  Initialize the memory module.
   procedure Memory_Init;

   --  Test if the memory module is initialized.
   function Memory_Test return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

   --  Procedures and functions

   --  Handler called when a CRTP packet is received in the memory
   --  port.
   procedure Memory_CRTP_Handler (Packet : CRTP_Packet);

   --  Process a command related to memory modules settings.
   procedure Memory_Settings_Process (Packet : CRTP_Packet);

end Memory;
