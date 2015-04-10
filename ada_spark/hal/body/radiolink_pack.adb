with Types; use Types;
with Ada.Unchecked_Conversion;

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
      Has_Suceed : Boolean;
      function Crtp_To_Syslink_Data is new Ada.Unchecked_Conversion
        (Crtp_Packet, Syslink_Data);
   begin
      Sl_Packet.Length := Packet.Size + 1;
      Sl_Packet.Slp_Type := SYSLINK_RADIO_RAW;
      Sl_Packet.Data := Crtp_To_Syslink_Data (Packet);

      --  Try to enqueue the Syslink packet
      Radiolink_Tx_Queue.Enqueue_Packet (Sl_Packet, Has_Suceed);
      return Has_Suceed;
   end Radiolink_Send_Packet;

end Radiolink_Pack;
