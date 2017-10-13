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

with Ada.Unchecked_Conversion;

package body CRTP_Service is

   -----------------------
   -- CRTP_Service_Init --
   -----------------------

   procedure CRTP_Service_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_LINK,
                              CRTP_Service_Handler'Access);

      Is_Init := True;
   end CRTP_Service_Init;

   --------------------------
   -- CRTP_Service_Handler --
   --------------------------

   procedure CRTP_Service_Handler (Packet : CRTP_Packet)
   is
      Command     : CRTP_Service_Command;
      Tx_Packet   : CRTP_Packet := Packet;
      Has_Succeed : Boolean;

      ------------------------------------------
      -- CRTP_Channel_To_CRTP_Service_Command --
      ------------------------------------------

      function CRTP_Channel_To_CRTP_Service_Command is
        new Ada.Unchecked_Conversion (CRTP_Channel, CRTP_Service_Command);
   begin
      Command := CRTP_Channel_To_CRTP_Service_Command (Packet.Channel);

      case Command is
         when Link_Echo =>
            CRTP_Send_Packet (Tx_Packet, Has_Succeed);
         when Link_Source =>
            Tx_Packet.Size := CRTP_MAX_DATA_SIZE;
            CRTP_Send_Packet (Tx_Packet, Has_Succeed);
         when others =>
            --  Null packets
            null;
      end case;
   end CRTP_Service_Handler;

end CRTP_Service;
