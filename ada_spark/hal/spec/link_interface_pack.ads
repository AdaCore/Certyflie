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
   --  Put the task calling it in sleep mode until a packet is received.
   procedure Link_Receive_Packet_Blocking (Packet : out Crtp_Packet);

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end Link_Interface_Pack;
