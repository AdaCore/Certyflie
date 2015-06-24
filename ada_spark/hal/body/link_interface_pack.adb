with Config; use Config;
with Radiolink_Pack; use Radiolink_Pack;

package body Link_Interface_Pack is

   procedure Link_Init is
   begin
      if Is_Init then
         return;
      end if;

      case LINK_LAYER_TYPE is
         when RADIO_LINK =>
            Radiolink_Init;
         when others =>
            --  Other link layers not implemented yet
            null;
      end case;

      Is_Init := True;
   end Link_Init;

   function Link_Send_Packet (Packet : CRTP_Packet) return Boolean is
   begin
      case Link_Layer_Type is
         when RADIO_LINK =>
            return Radiolink_Send_Packet (Packet);
         when others =>
            --  Other link layers not implemented yet
            return False;
      end case;
   end Link_Send_Packet;

   procedure Link_Receive_Packet_Blocking (Packet : out CRTP_Packet) is
   begin
      case Link_Layer_Type is
         when RADIO_LINK =>
            Radiolink_Receive_Packet_Blocking (Packet);
         when others =>
            --  Other link layers not implemented yet
            null;
      end case;
   end Link_Receive_Packet_Blocking;

end Link_Interface_Pack;
