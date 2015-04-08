package body Crtp_Pack is

   protected body Tx_Queue is
      entry Enqueue_Packet (Packet : Crtp_Packet)
        when Is_Not_Full is
      begin
         Enqueue (Queue, Packet);
         Is_Not_Full := not Is_Full (Queue);
      end Enqueue_Packet;
   end Tx_Queue;

end Crtp_Pack;
