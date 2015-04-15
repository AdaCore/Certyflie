with Ada.Unchecked_Conversion;
with Syslink_Pack; use Syslink_Pack;
with Crtp_Pack; use Crtp_Pack;

package body UART_Syslink is

   procedure UART_Get_Data_With_Timeout
     (Rx_Byte      : out T_Uint8;
      Has_Suceed   : out Boolean) is
   begin
      Rx_Byte := Get_Current_Byte (Counter);
      Counter := Counter + 1;
      if Counter >= 19 then
         Counter := 1;
      end if;
      Has_Suceed := True;
   end UART_Get_Data_With_Timeout;

   function Get_Current_Byte (Counter : Positive) return T_Uint8 is
      Roll   : constant Float := 20.0;
      Pitch  : constant Float := 30.0;
      Yaw    : constant Float := 40.0;
      Thrust : constant T_Uint16 := 30;
      Handler : Crtp_Packet_Handler;
      Packet  : Crtp_Packet;
      Has_Succeed : Boolean;
      procedure Crtp_Append_Float_Data is new Crtp_Append_Data (Float);
      procedure Crtp_Append_T_Uint16_Data is new Crtp_Append_Data (T_Uint16);
   begin
      Handler := Crtp_Create_Packet (CRTP_PORT_COMMANDER, 0);
      Crtp_Append_Float_Data (Handler, Roll, Has_Succeed);
      Crtp_Append_Float_Data (Handler, Pitch, Has_Succeed);
      Crtp_Append_Float_Data (Handler, Yaw, Has_Succeed);
      Crtp_Append_T_Uint16_Data (Handler, Thrust, Has_Succeed);
      Packet := Crtp_Get_Packet_From_Handler (Handler);

      case Counter is
         when 1 =>
            return SYSLINK_START_BYTE1;
         when 2 =>
            return SYSLINK_START_BYTE2;
         when 3 =>
            return Syslink_Packet_Type'Enum_Rep (SYSLINK_RADIO_RAW);
         when 4 =>
            return Packet.Size + 1;
         when 5 =>
            return Packet.Header;
         when others =>
            return Packet.Data_1 (Counter - 5);
      end case;
   end Get_Current_Byte;

end UART_Syslink;
