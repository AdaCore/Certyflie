with System;
with Generic_Queue_Pack;
with Syslink_Pack; use Syslink_Pack;
with Crtp_Pack; use Crtp_Pack;
with Types; use Types;

package Radiolink_Pack is

   --  Constants

   RADIOLINK_TX_QUEUE_SIZE : constant := 1;
   RADIOLINK_RX_QUEUE_SIZE : constant := 5;

   --  Procedures and functions

   --  Initialize the Radiolink layer
   procedure Radiolink_Init;

   --  Set the radio channel
   procedure Radiolink_Set_Channel (Channel : T_Uint8);

   --  Set the radio data rate
   procedure Radiolink_Set_Data_Rate (Data_Rate : T_Uint8);

   --  Send a packet to Radiolink layer
   function Radiolink_Send_Packet (Packet : Crtp_Packet) return Boolean;

   --  Recieve a packet from Radiolink layer
   procedure Radiolink_Receive_Packet
     (Packet : out Crtp_Packet;
      Has_Suceed : out Boolean);

   --  Enqueue a packet in the Radiolink RX_Queue and send one packet
   --  to Syslink if one has been received
   procedure Radiolink_Syslink_Dispatch (Rx_Sl_Packet : Syslink_Packet);

private

   package Syslink_Queue is new Generic_Queue_Pack (Syslink_Packet);
   package Crtp_Queue is new Generic_Queue_Pack (Crtp_Packet);

   --  Global variables and constants

   Is_Init : Boolean := False;
   RSSI    : T_Uint8;

   --  Tasks and protected objects

   --  Protected object queue for transmission
   Tx_Queue : Syslink_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, RADIOLINK_TX_QUEUE_SIZE);

   --  Protected object queue for reception
   Rx_Queue : Crtp_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, RADIOLINK_RX_QUEUE_SIZE);

end RadiolInk_Pack;
