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

package body Console is

   ------------------
   -- Console_Init --
   ------------------

   procedure Console_Init is
   begin
      if Is_Init then
         return;
      end if;

      Set_True (Console_Access);
      Message_To_Print := CRTP_Create_Packet (CRTP_PORT_CONSOLE, 0);

      Is_Init := True;
   end Console_Init;

   function Console_Test return Boolean is
   begin
      return Is_Init;
   end Console_Test;

   --------------------------
   -- Console_Send_Message --
   --------------------------

   procedure Console_Send_Message (Has_Succeed : out Boolean) is
   begin
      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Message_To_Print), Has_Succeed);

      --  Reset the CRTP packet data contained in the handler
      CRTP_Reset_Handler (Message_To_Print);
   end Console_Send_Message;

   -------------------
   -- Console_Flush --
   -------------------

   procedure Console_Flush (Has_Succeed : out Boolean) is
   begin
      Suspend_Until_True (Console_Access);
      Console_Send_Message (Has_Succeed);
      Set_True (Console_Access);
   end Console_Flush;

   ----------------------
   -- Console_Put_Line --
   ----------------------

   procedure Console_Put_Line
     (Message     : String;
      Has_Succeed : out Boolean)
   is
      Free_Bytes_In_Packet : Boolean := True;

      --------------------------------
      -- CRTP_Append_Character_Data --
      --------------------------------

      procedure CRTP_Append_Character_Data is new CRTP_Append_Data (Character);

   begin
      for C of Message loop
         CRTP_Append_Character_Data
           (Message_To_Print, C, Free_Bytes_In_Packet);

         if not Free_Bytes_In_Packet then
            Console_Send_Message (Has_Succeed);
         end if;
      end loop;

      Console_Send_Message (Has_Succeed);
   end Console_Put_Line;

end Console;
