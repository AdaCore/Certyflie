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

with CRTP;  use CRTP;
with Types; use Types;

package Platform_Service is

   --  Types

   --  Type enumerating all the channels for the Platform service module.
   type Platform_Channel is (PLAT_COMMAND);
   for Platform_Channel'Size use 2;
   for Platform_Channel use (PLAT_COMMAND => 2#00#);

   --  Type enumerating all the possible commands.
   type Platform_Command is (SET_CONTINUOUS_WAVE);
   for Platform_Command'Size use 8;
   for Platform_Command use (SET_CONTINUOUS_WAVE => 16#00#);

   --  Procedures and functions

   --  Initialize the platform service module.
   procedure Platform_Service_Init;

   --  Test if the platform service is initialized.
   function Platform_Service_Test return Boolean;

   --  Handler called when a CRTP packet is received in the
   --  platform service port.
   procedure Platform_Service_Handler (Packet : CRTP_Packet);

   --  Process a given command by sending a CRTP packet.
   procedure Platform_Command_Process
     (Command : T_Uint8;
      Data    : T_Uint8_Array);

private

   Is_Init : Boolean := False;

end Platform_Service;
