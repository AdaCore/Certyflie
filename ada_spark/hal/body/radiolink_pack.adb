with Ada.Unchecked_Conversion;

with Config; use Config;

package body Radiolink_Pack is

   procedure Radiolink_Init is
   begin
      if Is_Init then
         return;
      end if;

      Syslink_Init;

      Radiolink_Set_Channel (RADIO_CHANNEL);
      Radiolink_Set_Data_Rate (RADIO_DATARATE);

      Is_Init := True;
   end Radiolink_Init;

   procedure Radiolink_Set_Data_Rate (Data_Rate : T_Uint8) is
      Sl_Packet : Syslink_Packet;
   begin
      Sl_Packet.Slp_Type := SYSLINK_RADIO_DATARATE;
      Sl_Packet.Length := 1;
      Sl_Packet.Data (1) := Data_Rate;
      Syslink_Send_Packet (Sl_Packet);
   end Radiolink_Set_Data_Rate;

   procedure Radiolink_Set_Channel (Channel : T_Uint8) is
      Sl_Packet : Syslink_Packet;
   begin
      Sl_Packet.Slp_Type := SYSLINK_RADIO_CHANNEL;
      Sl_Packet.Length := 1;
      Sl_Packet.Data (1) := Channel;
      Syslink_Send_Packet (Sl_Packet);
   end Radiolink_Set_Channel;

   procedure Radiolink_Receive_Packet_Blocking (Packet : out CRTP_Packet) is
   begin
      Rx_Queue.Await_Item_To_Dequeue (Packet);
   end Radiolink_Receive_Packet_Blocking;

   function Radiolink_Send_Packet (Packet : CRTP_Packet) return Boolean is
      Sl_Packet : Syslink_Packet;
      Has_Succeed : Boolean;
      function CRTP_Raw_To_Syslink_Data is new Ada.Unchecked_Conversion
        (CRTP_Raw, Syslink_Data);
   begin
      Sl_Packet.Length := Packet.Size + 1;
      Sl_Packet.Slp_Type := SYSLINK_RADIO_RAW;
      Sl_Packet.Data := CRTP_Raw_To_Syslink_Data (Packet.Raw);

      --  Try to enqueue the Syslink packet
      Tx_Queue.Enqueue_Item (Sl_Packet, Has_Succeed);

      return Has_Succeed;
   end Radiolink_Send_Packet;

   procedure Radiolink_Syslink_Dispatch (Rx_Sl_Packet : Syslink_Packet) is
      Tx_Sl_Packet   : Syslink_Packet;
      Rx_CRTP_Packet : CRTP_Packet;
      Has_Succeed    : Boolean;
   begin
      if Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RAW then
         Rx_CRTP_Packet.Size := Rx_Sl_Packet.Length - 1;
         Rx_CRTP_Packet.Header := Rx_Sl_Packet.Data (1);
         Rx_CRTP_Packet.Data_2 :=
           CRTP_Data (Rx_Sl_Packet.Data (2 .. Rx_Sl_Packet.Data'Length));

         --  Enqueue the received packet
         Rx_Queue.Enqueue_Item (Rx_CRTP_Packet, Has_Succeed);
         -- TODO: led blink

         -- If a radio packet is received, one can be sent
         Tx_Queue.Dequeue_Item (Tx_Sl_Packet, Has_Succeed);

         if Has_Succeed then
            -- TODO: led blink
            Syslink_Send_Packet (Tx_Sl_Packet);
         end if;
      elsif Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RSSI then
         --  Extract RSSI sample sent from Radio
         RSSI := Rx_Sl_Packet.Data (1);
      end if ;
   end Radiolink_Syslink_Dispatch;

end Radiolink_Pack;
