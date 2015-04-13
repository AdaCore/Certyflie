with Ada.Unchecked_Conversion;
with Ada.Real_Time; use Ada.Real_Time;

package body Radiolink_Pack is

   procedure Radiolink_Receive_Packet
     (Packet : out Crtp_Packet;
      Has_Suceed : out Boolean) is
   begin
      Rx_Queue.Dequeue_Item (Packet, Milliseconds (100), Has_Suceed);
   end Radiolink_Receive_Packet;

   function Radiolink_Send_Packet (Packet : Crtp_Packet) return Boolean is
      Sl_Packet : Syslink_Packet;
      Has_Suceed : Boolean;
      function Crtp_To_Syslink_Data is new Ada.Unchecked_Conversion
        (Crtp_Packet, Syslink_Data);
   begin
      Sl_Packet.Length := Packet.Size + 1;
      Sl_Packet.Slp_Type := SYSLINK_RADIO_RAW;
      Sl_Packet.Data := Crtp_To_Syslink_Data (Packet);

      --  Try to enqueue the Syslink packet
      Tx_Queue.Enqueue_Item (Sl_Packet, Milliseconds (100), Has_Suceed);
      return Has_Suceed;
   end Radiolink_Send_Packet;

   procedure Radiolink_Syslink_Disptach (Rx_Sl_Packet : Syslink_Packet) is
      Tx_Sl_Packet : Syslink_Packet;
      Rx_Crtp_Packet : Crtp_Packet;
      Has_Succeed     : Boolean;
   begin
      if Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RAW then
         Rx_Crtp_Packet.Size := Rx_Sl_Packet.Length - 1;
         Rx_Crtp_Packet.Header := Rx_Sl_Packet.Data (1);
         Rx_Crtp_Packet.Data :=
           Crtp_Data (Rx_Sl_Packet.Data (2 .. Rx_Sl_Packet.Data'Length - 1));

         --  Enqueue the received packet
         Rx_Queue.Enqueue_Item (Rx_Crtp_Packet, Milliseconds (0), Has_Succeed);
         -- TODO: led blink

         -- If a radio packet is received, one can be sent
         Tx_Queue.Dequeue_Item (Tx_Sl_Packet, Milliseconds (0), Has_Succeed);
         if Has_Succeed then
            -- TODO: led blink
            Syslink_Send_Packet (Tx_Sl_Packet);
         end if;
      elsif Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RSSI then
         --  Extract RSSI sample sent from Radio
         RSSI := Rx_Sl_Packet.Data (1);
      end if ;
   end Radiolink_Syslink_Disptach;


end Radiolink_Pack;
