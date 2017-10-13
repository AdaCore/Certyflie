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

with Crazyflie_Config;    use Crazyflie_Config;
with Radiolink; use Radiolink;

package body Link_Interface is

   ---------------
   -- Link_Init --
   ---------------

   procedure Link_Init is
   begin
      if Is_Init then
         return;
      end if;

      case LINK_LAYER_TYPE is
         when RADIO_LINK =>
            Radiolink_Init;
         when others =>
            --  Other link layers not implemented yet.
            null;
      end case;

      Is_Init := True;
   end Link_Init;

   ----------------------
   -- Link_Send_Packet --
   ----------------------

   function Link_Send_Packet (Packet : CRTP_Packet) return Boolean is
   begin
      case LINK_LAYER_TYPE is
         when RADIO_LINK =>
            return Radiolink_Send_Packet (Packet);
         when others =>
            --  Other link layers not implemented yet.
            return False;
      end case;
   end Link_Send_Packet;

   ----------------------------------
   -- Link_Receive_Packet_Blocking --
   ----------------------------------

   procedure Link_Receive_Packet_Blocking (Packet : out CRTP_Packet) is
   begin
      case LINK_LAYER_TYPE is
         when RADIO_LINK =>
            Radiolink_Receive_Packet_Blocking (Packet);
         when others =>
            --  Other link layers not implemented yet.
            null;
      end case;
   end Link_Receive_Packet_Blocking;

end Link_Interface;
