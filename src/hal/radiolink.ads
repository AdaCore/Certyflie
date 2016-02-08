with System;
with Generic_Queue;
with Syslink; use Syslink;
with CRTP; use CRTP;
with Types; use Types;

package Radiolink is

   --  Constants

   --  Size of transmission/receptions queues.
   RADIOLINK_TX_QUEUE_SIZE : constant := 1;
   RADIOLINK_RX_QUEUE_SIZE : constant := 5;

   --  Procedures and functions

   --  Initialize the Radiolink layer.
   procedure Radiolink_Init;

   --  Set the radio channel.
   procedure Radiolink_Set_Channel (Channel : T_Uint8);

   --  Set the radio data rate.
   procedure Radiolink_Set_Data_Rate (Data_Rate : T_Uint8);

   --  Send a packet to Radiolink layer.
   function Radiolink_Send_Packet (Packet : CRTP_Packet) return Boolean;

   --  Receive a packet from Radiolink layer.
   --  Putting the task calling it in sleep mode until a packet is received.
   procedure Radiolink_Receive_Packet_Blocking (Packet : out CRTP_Packet);

   --  Enqueue a packet in the Radiolink RX_Queue and send one packet
   --  to Syslink if one has been received.
   procedure Radiolink_Syslink_Dispatch (Rx_Sl_Packet : Syslink_Packet);

private

   package Syslink_Queue is new Generic_Queue (Syslink_Packet);
   package CRTP_Queue is new Generic_Queue (CRTP_Packet);

   --  Global variables and constants

   Is_Init : Boolean := False;
   RSSI    : T_Uint8;

   --  Tasks and protected objects

   --  Protected object queue used for transmission.
   Tx_Queue : Syslink_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, RADIOLINK_TX_QUEUE_SIZE);

   --  Protected object queue used for reception.
   Rx_Queue : CRTP_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, RADIOLINK_RX_QUEUE_SIZE);

end Radiolink;
