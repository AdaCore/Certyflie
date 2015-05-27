with Crtp_Pack; use Crtp_Pack;

package CRTP_Service_Pack is

   --  Types

   type CRTP_Service_Command is (Link_Echo,
                                 Link_Source,
                                 Link_Sink,
                                 Link_Other);

   for CRTP_Service_Command use (Link_Echo   => 16#00#,
                                 Link_Source => 16#01#,
                                 Link_Sink   => 16#02#,
                                 Link_Other  => 16#03#);
   for CRTP_Service_Command'Size use 2;

   --  Procedures and functions

   --  Initialize CRTP Service module
   procedure CRTP_Service_Init;

   --  Handler called when a CRTP packet is received in the CRTP Service
   --  port queue
   procedure CRTP_Service_Handler (Packet : Crtp_Packet);

private

   --  Global variable and constants

   Is_Init             : Boolean := False;

end CRTP_Service_Pack;
