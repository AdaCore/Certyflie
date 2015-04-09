with Config; use Config;
with Radiolink_Pack; use Radiolink_Pack;

package body Link_Interface_Pack is

   function Link_Send_Packet (Packet : Crtp_Packet) return Boolean is
   begin
      case Link_Layer_Type is
         when RADIO_LINK =>
            return Radiolink_Send_Packet (Packet);
         when others =>
            --  Other link layers not implemented yet
            return False;
      end case;
   end Link_Send_Packet;

   procedure Link_Receive_Packet
     (Packet          : out Crtp_Packet;
      Packet_Received : out Boolean) is
   begin
      null;
   end Link_Receive_Packet;

end Link_Interface_Pack;
