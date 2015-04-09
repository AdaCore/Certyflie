with Types; use Types;
with Generic_Queue_Pack;

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

   type Crtp_Packet is record
      Size     : T_Uint8;
      Channel  : Crtp_Channel;
      Reserved : Crtp_Reserved;
      Port     : Crtp_Port;
      Data     : Crtp_Data;
   end record;
   for Crtp_Packet'Size use 256;
   pragma Pack (Crtp_Packet);

   package Crtp_Queue is new Generic_Queue_Pack (Crtp_Packet);
   use Crtp_Queue;

   --  Tasks and protected objects

   --  Protected object ensuring that nobody tries to enqueue
   --  a message at the same time
   protected type Tx_Queue is
      entry Enqueue_Packet (Packet : Crtp_Packet);
   private
      Queue       : T_Queue (CRTP_TX_QUEUE_SIZE);
      Is_Not_Full : Boolean := False;
   end Tx_Queue;

end Crtp_Pack;
