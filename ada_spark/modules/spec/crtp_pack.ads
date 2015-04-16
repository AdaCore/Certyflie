with Types; use Types;
with Generic_Queue_Pack;
with System;
with Ada.Real_Time; use Ada.Real_Time;

package Crtp_Pack is
   --  Constants

   CRTP_MAX_DATA_SIZE : constant := 30;
   CRTP_TX_QUEUE_SIZE : constant := 60;
   CRTP_RX_QUEUE_SIZE : constant := 2;
   CRTP_NBR_OF_PORTS  : constant := 16;

   --  Types

   --  Type used for representing a CRTP channel, which can be seen
   --  as a sub-set for a specific port
   type Crtp_Channel is new T_Uint8 range 0 .. 3;
   for Crtp_Channel'Size use 2;

   --  Enumeration type for CRTP ports. Each port corresponds to
   --  a specific modules
   type Crtp_Port is (CRTP_PORT_CONSOLE,
                      CRTP_PORT_PARAM,
                      CRTP_PORT_COMMANDER,
                      CRTP_PORT_MEM,
                      CRTP_PORT_LOG,
                      CRTP_PORT_PLATFORM,
                      CRTP_PORT_LINK);
   for Crtp_Port use (CRTP_PORT_CONSOLE   => 16#00#,
                      CRTP_PORT_PARAM     => 16#02#,
                      CRTP_PORT_COMMANDER => 16#03#,
                      CRTP_PORT_MEM       => 16#04#,
                      CRTP_PORT_LOG       => 16#05#,
                      CRTP_PORT_PLATFORM  => 16#0D#,
                      CRTP_PORT_LINK      => 16#0F#);
   for Crtp_Port'Size use 4;

   --  Type for representinf teh two reserved bits in a CRTP packet.
   --  These bits are used for the transport layer.
   type Crtp_Reserved is new T_Uint8 range 0 .. 3;
   for Crtp_Reserved'Size use 2;

   --  Type for CRTP packet data
   subtype Crtp_Data is T_Uint8_Array (1 .. CRTP_MAX_DATA_SIZE);

   --  Type used to represenet a raw CRTP Packet (Header + Data)
   type Crtp_Raw is array (1 .. CRTP_MAX_DATA_SIZE + 1) of T_Uint8;

   --  Type listing the different representations for the union type
   --  CRTP Packet
   type Crpt_Packet_Representation is (DETAILED, HEADER_DATA, RAW);

   --  Type for CRTP packets
   type Crtp_Packet (Repr : Crpt_Packet_Representation := DETAILED) is record
      Size     : T_Uint8;

      case Repr is
         when DETAILED =>
            Channel    : Crtp_Channel;
            Reserved   : Crtp_Reserved;
            Port       : Crtp_Port;
            Data_1     : Crtp_Data;
         when HEADER_DATA =>
            Header     : T_Uint8;
            Data_2     : Crtp_Data;
         when RAW =>
            Raw        : Crtp_Raw;
      end case;
   end record;

   pragma Unchecked_Union (Crtp_Packet);
   for Crtp_Packet'Size use 256;
   pragma Pack (Crtp_Packet);

   --  Type used to easily manipulate Crtp packet
   type Crtp_Packet_Handler is private;

   --  Procedures and functions

   --  Create a CRTP Packet handler to append/get data
   function Crtp_Create_Packet
     (Port    : Crtp_Port;
      Channel : Crtp_Channel) return Crtp_Packet_Handler;

   --  Return an handler to easily manipulate the CRTP packet
   function Crtp_Get_Handler (Packet : Crtp_Packet) return Crtp_Packet_Handler;

   --  Return the CRTP Packet contained in the CRTP Packet handler
   function Crtp_Get_Packet_From_Handler
     (Handler : Crtp_Packet_Handler) return Crtp_Packet;

   --  Append data to the CRTP Packet
   generic
      type T_Data is private;
   procedure Crtp_Append_Data
     (Handler        : in out Crtp_Packet_Handler;
      Data           : T_Data;
      Has_Succeed    : out Boolean);

   --  Get data at a specified index of the CRTP Packet data field
   generic
      type T_Data is private;
   procedure Crtp_Get_Data
     (Handler    : Crtp_Packet_Handler;
      Index      : Integer;
      Data       : out T_Data;
      Has_Succeed : out Boolean);

   --  Receive a packet from the port queue, with a given Timeout
   procedure Crtp_Receive_Packet
     (Packet           : out Crtp_Packet;
      Port_ID          : Crtp_Port;
      Has_Succeed      : out Boolean;
      Time_To_Wait     :  Time_Span := Milliseconds (0));

private
   package Crtp_Queue is new Generic_Queue_Pack (Crtp_Packet);

   --  Types
   type Crtp_Packet_Handler is record
      Packet : Crtp_Packet;
      Index  : Positive;
   end record;

   --  Tasks and protected objects

   --  Protected object queue for transmission
   Tx_Queue : Crtp_Queue.Protected_Queue
     (System.Priority'Last, CRTP_TX_QUEUE_SIZE);

   --  Protected object queue for reception
   Rx_Queue : Crtp_Queue.Protected_Queue
     (System.Priority'Last, CRTP_RX_QUEUE_SIZE);

   --  Array of protected object queues, one for each task
   Port_Queues : array (Crtp_Port) of Crtp_Queue.Protected_Queue
     (System.Priority'Last, 1);

   --  Task in charge of transmitting the messages in the Tx Queue
   --  to the link layer.
   task Crtp_Tx_Task is
      pragma Priority (System.Priority'Last - 1);
   end;

   --  Task in charge of dequeuing the messages in teh Rx_queue
   --  to put them in the Port_Queues
   task Crtp_Rx_Task is
      pragma Priority (System.Priority'Last - 1);
   end;

   --  Global variables

   --  Number of dropped packets at reception
   Dropped_Packets : Natural := 0;

end Crtp_Pack;
