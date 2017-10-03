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

   --  Type representing all the available memory commands.
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
