with Ada.Unchecked_Conversion;

package body UART_Syslink is

   procedure UART_Get_Data_With_Timeout
     (Rx_Byte      : out T_Uint8;
      Has_Suceed   : out Boolean) is
   begin
      Rx_Byte := Get_Current_Byte (Counter);
      Counter := Counter + 1;
      if Counter >= 16 then
         COunter := 5;
      end if;
   end UART_Get_Data_With_Timeout;

   function Get_Current_Byte (Counter : Positive) return T_Uint8 is
      Message_To_Send : constant String := "Hello World!";
   begin
      case Counter is
         when 1 =>
            return SYSLINK_START_BYTE1;
         when 2 =>
            return SYSLINK_START_BYTE2;
         when 3 =>
            return Syslink_Packet_Type'Enum_Rep (SYSLINK_RADIO_RAW);
         when 4 =>
            return Message_To_Send'Length;
         when others =>
            return Character'Enum_Rep (Message_To_Send (Counter - 4));
      end case;
   end Get_Current_Byte;

end UART_Syslink;
