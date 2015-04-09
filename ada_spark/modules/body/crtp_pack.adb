with Link_Interface_Pack; use Link_Interface_Pack;
pragma Elaborate (Link_Interface_Pack);

package body Crtp_Pack is

   protected body Crtp_Tx_Queue is
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

      entry Dequeue_Packet (Packet : out Crtp_Packet)
        when Is_Not_Empty
      is
      begin
         Dequeue (Queue, Packet);
         Is_Not_Empty := not Is_Empty (Queue);
      end Dequeue_Packet;
   end Crtp_Tx_Queue;

   task body Crtp_Tx_Task is
      Packet : Crtp_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Crtp_Tx_Queue.Dequeue_Packet (Packet);
         Has_Succeed := Link_Send_Packet (Packet);

         --  Keep testing, if the link change sto USB it will go through
         while not Has_Succeed loop
            Has_Succeed := Link_Send_Packet (Packet);
         end loop;
      end loop;
   end Crtp_Tx_Task;

end Crtp_Pack;
