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
with Types;                    use Types;

package body Memory is

   --  Public procedures and functions

   -----------------
   -- Memory_Init --
   -----------------

   procedure Memory_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_MEM, Memory_CRTP_Handler'Access);

      Is_Init := True;
   end Memory_Init;

   -----------------
   -- Memory_Test --
   -----------------

   function Memory_Test return Boolean is
   begin
      return Is_Init;
   end Memory_Test;

   --  Private procedures and functions

   -------------------------
   -- Memory_CRTP_Handler --
   -------------------------

   procedure Memory_CRTP_Handler (Packet : CRTP_Packet)
   is
      ------------------------------------
      -- CRTP_Channel_To_Memory_Channel --
      ------------------------------------

      function CRTP_Channel_To_Memory_Channel is new Ada.Unchecked_Conversion
        (CRTP_Channel, Memory_Channel);
      Channel : Memory_Channel;
   begin
      Channel := CRTP_Channel_To_Memory_Channel (Packet.Channel);

      case Channel is
         when MEM_SETTINGS_CH =>
            Memory_Settings_Process (Packet);
         when MEM_READ_CH =>
            null;
         when MEM_WRITE_CH =>
            null;
      end case;
   end Memory_CRTP_Handler;

   -----------------------------
   -- Memory_Settings_Process --
   -----------------------------

   procedure Memory_Settings_Process (Packet : CRTP_Packet)
   is
      -------------------------------
      -- T_Uint8_To_Memory_Command --
      -------------------------------

      function T_Uint8_To_Memory_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Memory_Command);

      ------------------------------
      -- CRTP_Append_T_Uint8_Data --
      ------------------------------

      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);

      Command        : Memory_Command;
      Packet_Handler : CRTP_Packet_Handler;
      Has_Succeed    : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Memory_Command (Packet.Data_1 (1));

      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_MEM, Memory_Channel'Enum_Rep (MEM_SETTINGS_CH));
      CRTP_Append_T_Uint8_Data
        (Packet_Handler,
         Memory_Command'Enum_Rep (Command),
         Has_Succeed);

      case Command is
         when MEM_CMD_GET_NBR =>
            --  TODO: for now we just send 0 instead of the real number
            --  of One Wire memories + EEPROM memory.
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               0,
               Has_Succeed);
            CRTP_Send_Packet
              (CRTP_Get_Packet_From_Handler (Packet_Handler),
               Has_Succeed);
         when MEM_CMD_GET_INFO =>
            null;
      end case;
   end Memory_Settings_Process;

end Memory;
