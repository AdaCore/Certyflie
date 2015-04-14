with Types; use Types;
with Generic_Queue_Pack;
with System;

package Crtp_Pack is
   --  Constants

   CRTP_MAX_DATA_SIZE : constant := 30;
   CRTP_TX_QUEUE_SIZE : constant := 60;

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
   type Crtp_Data is array (1 .. CRTP_MAX_DATA_SIZE) of T_Uint8;

   type Crtp_Raw is array (1 .. CRTP_MAX_DATA_SIZE + 1) of T_Uint8;

   type Crpt_Packet_Representation is (DETAILED, HEADER_DATA, RAW);
   --  Type for CRTP packets
   type Crtp_Packet (Repr : Crpt_Packet_Representation := DETAILED) is record
      Size     : T_Uint8;

      case Repr is
         when DETAILED =>
            Channel  : Crtp_Channel;
            Reserved : Crtp_Reserved;
            Port     : Crtp_Port;
            Data_1     : Crtp_Data;
         when HEADER_DATA =>
            Header   : T_Uint8;
            Data_2     : Crtp_Data;
         when RAW =>
            Raw     : Crtp_Raw;
      end case;
   end record;

   pragma Unchecked_Union (Crtp_Packet);
   for Crtp_Packet'Size use 256;
   pragma Pack (Crtp_Packet);

private
   package Crtp_Queue is new Generic_Queue_Pack (Crtp_Packet);

   --  Tasks and protected objects

   --  Protected object queue for transmission
   Tx_Queue : Crtp_Queue.Protected_Queue
     (System.Priority'Last, CRTP_TX_QUEUE_SIZE);

   --  Task in charge of transmitting the messages in the Tx Queue
   --  to the link layer.
   task Crtp_Tx_Task is
      pragma Priority (System.Priority'Last - 1);
   end;

end Crtp_Pack;
