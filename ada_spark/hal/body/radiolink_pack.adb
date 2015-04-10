with Types; use Types;
with Ada.Unchecked_Conversion;
with Ada.Real_Time; use Ada.Real_Time;

package body Radiolink_Pack is

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

end Radiolink_Pack;
