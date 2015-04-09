with System;
with Generic_Queue_Pack;
with Syslink_Pack; use Syslink_Pack;
with Crtp_Pack; use Crtp_Pack;

package Radiolink_Pack is

   --  Constants

   RADIOLINK_TX_QUEUE_SIZE : constant := 1;

   --  Procedures and functions

   function Radiolink_Send_Packet (Packet : Crtp_Packet) return Boolean;

private

   package Syslink_Queue is new Generic_Queue_Pack (Syslink_Packet);
   use Syslink_Queue;

   --  Tasks and protected objects

   --  Protected object ensuring that nobody tries to enqueue
   --  a message at the same time
   protected Radiolink_Tx_Queue is
      procedure Enqueue_Packet
        (Packet      : Syslink_Packet;
         Has_Succeed : out Boolean);
      entry Dequeue_Packet (Packet : out Syslink_Packet);
   private
      pragma Priority (System.Priority'Last);
      Queue           : T_Queue (RADIOLINK_TX_QUEUE_SIZE);
      Is_Not_Empty    : Boolean := False;
   end Radiolink_Tx_Queue;

end RadiolInk_Pack;
