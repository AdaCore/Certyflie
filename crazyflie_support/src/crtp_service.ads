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

with CRTP; use CRTP;

package CRTP_Service is

   --  Types

   --  Type representing all the available commands for
   --  CRTP service module.
   type CRTP_Service_Command is (Link_Echo,
                                 Link_Source,
                                 Link_Sink,
                                 Link_Other);
   for CRTP_Service_Command use (Link_Echo   => 16#00#,
                                 Link_Source => 16#01#,
                                 Link_Sink   => 16#02#,
                                 Link_Other  => 16#03#);
   for CRTP_Service_Command'Size use 2;

   --  Procedures and functions

   --  Initialize CRTP Service module.
   procedure CRTP_Service_Init;

   --  Handler called when a CRTP packet is received in the CRTP Service
   --  port queue.
   procedure CRTP_Service_Handler (Packet : CRTP_Packet);

private

   --  Global variable and constants

   Is_Init             : Boolean := False;

end CRTP_Service;
