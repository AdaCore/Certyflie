with Protected_IO_Pack; use Protected_IO_Pack;

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
      X_Put_Line ("Console Send message has succeed: " & Boolean'Image (Has_Succeed));
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

   procedure Console_Put_Line
     (Message     : String;
      Has_Succeed : out Boolean) is
      Free_Bytes_In_Packet : Boolean := True;
      procedure Crtp_Append_Character_Data is new Crtp_Append_Data (Character);
   begin
      for C of Message loop
         Crtp_Append_Character_Data
           (Message_To_Print, C, Free_Bytes_In_Packet);

         if not Free_Bytes_In_Packet then
            Console_Send_Message (Has_Succeed);
         end if;
      end loop;

      Console_Send_Message (Has_Succeed);
   end Console_Put_Line;

end Console_Pack;
