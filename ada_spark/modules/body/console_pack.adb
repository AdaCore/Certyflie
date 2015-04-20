with Types; use Types;

package body Console_Pack is

   procedure Console_Init is
   begin
      if Is_Init then
         return;
      end if;

      Set_True (Console_Access);
      Message_To_Print := Crtp_Create_Packet (CRTP_PORT_CONSOLE, 0);

      Is_Init := True;
   end Console_Init;

   function Console_Test return Boolean is
   begin
      return Is_Init;
   end Console_Test;

   procedure Console_Send_Message (Has_Succeed : out Boolean) is
   begin
      Crtp_Send_Packet
        (Crtp_Get_Packet_From_Handler (Message_To_Print), Has_Succeed);

      --  Reset the CRTP packet data contained in the handler
      if Has_Succeed then
         Crtp_Reset_Handler (Message_To_Print);
      end if;
   end Console_Send_Message;

   procedure Console_Flush (Has_Succeed : out Boolean) is
   begin
      Suspend_Until_True (Console_Access);
      Console_Send_Message (Has_Succeed);
      Set_True (Console_Access);
   end Console_Flush;

   procedure Console_Put_Char (C : Character; Has_Succeed : out Boolean) is
      procedure Crtp_Append_Character_Data is new Crtp_Append_Data (Character);
      Size_Of_Message : T_Uint8;
   begin
      Suspend_Until_True (Console_Access);
      Size_Of_Message := Crtp_Get_Packet_Size (Message_To_Print);
      if Size_Of_Message < CRTP_MAX_DATA_SIZE then
         Crtp_Append_Character_Data (Message_To_Print, C, Has_Succeed);
      end if;

      if C = ASCII.CR or Size_Of_Message >= CRTP_MAX_DATA_SIZE then
         Console_Send_Message (Has_Succeed);
      end if;

      Set_True (Console_Access);
   end Console_Put_Char;

   procedure Console_Put_String
     (Message     : String;
      Has_Succeed : out Boolean) is
   begin
      for C of Message loop
        Console_Put_Char (C, Has_Succeed);
      end loop;
   end Console_Put_String;

end Console_Pack;
