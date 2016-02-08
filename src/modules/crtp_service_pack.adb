with Ada.Unchecked_Conversion;

package body CRTP_Service_Pack is

   procedure CRTP_Service_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_LINK,
                              CRTP_Service_Handler'Access);

      Is_Init := True;
   end CRTP_Service_Init;

   procedure CRTP_Service_Handler (Packet : CRTP_Packet) is
      Command     : CRTP_Service_Command;
      Tx_Packet   : CRTP_Packet := Packet;
      Has_Succeed : Boolean;
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

end CRTP_Service_Pack;
