--  Package defining an asbtract interface for the link layer used by
--  the CRTP Communication protocol.
with Crtp_Pack; use Crtp_Pack;

package Link_Interface_Pack is

   --  Initialize the selected link layer
   procedure Link_Init;

   --  Send a CRTP packet using the link layer specified in
   --  the 'Config' package.
   --  Return 'True' if the packet is correctly sent, 'False'
   --  ortherwise.
   function Link_Send_Packet (Packet : Crtp_Packet) return Boolean;

   --  Receive a CRTP packet using the link layer specified in
   --  the 'Config' package.
   --  'Packet_Received' is set to 'True' if a packet has been received,
   --  set to 'False' otherwise.
   procedure Link_Receive_Packet
     (Packet          : out Crtp_Packet;
      Has_Succeed     : out Boolean);

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end Link_Interface_Pack;
