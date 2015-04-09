with Types; use Types;

package body Radiolink_Pack is

   protected body Radiolink_Tx_Queue is
      procedure Enqueue_Packet
        (Packet      : Syslink_Packet;
         Has_Succeed : out Boolean) is
      begin
         if Is_Full (Queue) then
            Has_Succeed := False;
            return;
         end if;

         Enqueue (Queue, Packet);
         Has_Succeed := True;
      end Enqueue_Packet;

      entry Dequeue_Packet (Packet : out Syslink_Packet)
        when Is_Not_Empty
      is
      begin
         Dequeue (Queue, Packet);
         Is_Not_Empty := not Is_Empty (Queue);
      end Dequeue_Packet;
   end Radiolink_Tx_Queue;

   function Radiolink_Send_Packet (Packet : Crtp_Packet) return Boolean is
      Sl_Packet : Syslink_Packet;
   begin
      Sl_Packet.Length := Packet.Size + 1;
      Sl_Packet.Slp_Type := SYSLINK_RADIO_RAW;
      --  TODO: Find  hint to copy Packet.Size + 1 Bytes at the
      --  Packet.Header address...
      Sl_Packet.Data := Packet.Data;
      return True;
   end Radiolink_Send_Packet;



end Radiolink_Pack;
