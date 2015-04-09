package body Crtp_Pack is

   protected body Tx_Queue is
      procedure Enqueue_Packet
        (Packet      : Crtp_Packet;
         Has_Succeed : out Boolean) is
      begin
         if Is_Full (Queue) then
            Has_Succeed := False;
            return;
         end if;

         Enqueue (Queue, Packet);
         Has_Succeed := True;
      end Enqueue_Packet;

      entry Dequeue (Packet : out Crtp_Packet)
        when Is_Not_Empty
      is
      begin
         Dequeue (Queue, Packet);
         Is_Not_Empty := not Is_Empty (Queue);
      end Dequeue;
   end Tx_Queue;

   task body Tx_Task is
      Packet : Crtp_Packet;
   begin
      loop
         Tx_Queue.Dequeue (Packet);
      end loop;
   end Tx_Task;

end Crtp_Pack;
