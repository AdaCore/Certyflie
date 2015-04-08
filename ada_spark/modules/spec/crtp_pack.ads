with Types; use Types;

package Crtp_Pack is

   --  Constants
   CRTP_MAX_DATA_SIZE : constant := 30;

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
   type Crtp_Data is array (Natural range <>) of T_Uint8;

   type Crtp_Packet is record
      Size     : T_Uint8;
      Channel  : Crtp_Channel;
      Reserved : Crtp_Reserved;
      Port     : Crtp_Port;
      Data     : Crtp_Data (0 .. CRTP_MAX_DATA_SIZE - 1);
   end record;
   for Crtp_Packet'Size use 256;
   pragma Pack (Crtp_Packet);

end Crtp_Pack;
