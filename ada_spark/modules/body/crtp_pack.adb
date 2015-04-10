with Link_Interface_Pack; use Link_Interface_Pack;
pragma Elaborate (Link_Interface_Pack);

package body Crtp_Pack is

   task body Crtp_Tx_Task is
      Packet : Crtp_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Tx_Queue.Dequeue_Item (Packet);
         Has_Succeed := Link_Send_Packet (Packet);

         --  Keep testing, if the link change sto USB it will go through
         while not Has_Succeed loop
            Has_Succeed := Link_Send_Packet (Packet);
         end loop;
      end loop;
   end Crtp_Tx_Task;

end Crtp_Pack;
