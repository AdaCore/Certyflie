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

--  Package defining an asbtract interface for the link layer used by
--  the CRTP Communication protocol.
with CRTP; use CRTP;

package Link_Interface is

   --  Procedures and functions

   --  Initialize the selected link layer.
   --  The selected link layer is specified in 'config.ads'.
   procedure Link_Init;

   --  Send a CRTP packet using the link layer specified in
   --  the 'Config' package.
   --  Return 'True' if the packet is correctly sent, 'False'
   --  ortherwise.
   function Link_Send_Packet (Packet : CRTP_Packet) return Boolean;

   --  Receive a CRTP packet using the link layer specified in
   --  the 'Config' package.
   --  Put the task calling it in sleep mode until a packet is received.
   procedure Link_Receive_Packet_Blocking (Packet : out CRTP_Packet);

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end Link_Interface;
