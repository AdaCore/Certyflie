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

with Syslink; use Syslink;

package body Platform_Service is

   ---------------------------
   -- Platform_Service_Init --
   ---------------------------

   procedure Platform_Service_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_PLATFORM,
                              Platform_Service_Handler'Access);

      Is_Init := True;
   end Platform_Service_Init;

   ---------------------------
   -- Platform_Service_Test --
   ---------------------------

   function Platform_Service_Test return Boolean is
   begin
      return Is_Init;
   end Platform_Service_Test;

   ------------------------------
   -- Platform_Service_Handler --
   ------------------------------

   procedure Platform_Service_Handler (Packet : CRTP_Packet) is
      Has_Succeed : Boolean;
   begin
      case Packet.Channel is
         when Platform_Channel'Enum_Rep (PLAT_COMMAND) =>
            Platform_Command_Process
              (Packet.Data_1 (1), Packet.Data_1 (2 .. Packet.Data_1'Last));
            CRTP_Send_Packet (Packet, Has_Succeed);
         when others =>
            null;
      end case;
   end Platform_Service_Handler;

   ------------------------------
   -- Platform_Command_Process --
   ------------------------------

   procedure Platform_Command_Process
     (Command : T_Uint8;
      Data    : T_Uint8_Array) is
      Sl_Packet : Syslink_Packet;
   begin
      case Command is
         when Platform_Command'Enum_Rep (SET_CONTINUOUS_WAVE) =>
            Sl_Packet.Slp_Type := SYSLINK_RADIO_CONTWAVE;
            Sl_Packet.Length := 1;
            Sl_Packet.Data (1) := Data (Data'First);
            Syslink_Send_Packet (Sl_Packet);
         when others =>
            null;
      end case;
   end Platform_Command_Process;

end Platform_Service;
