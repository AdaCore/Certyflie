with Ada.Unchecked_Conversion;
with Syslink_Pack; use Syslink_Pack;
with Crtp_Pack; use Crtp_Pack;
with Protected_IO_Pack; use Protected_IO_Pack;

package body UART_Syslink is

   procedure Init_IO is
      GPIO_Conf : GPIO_Port_Configuration;
   begin
      Enable_Clock (UART_GPIO_Port);

      --  Rx/Tx pins
      Configure_Alternate_Function (UART_GPIO_Port, (Rx_GPIO_Pin, Tx_GPIO_Pin),
                                    UART_AF);
      GPIO_Conf.Speed       := Speed_25MHz;
      GPIO_Conf.Mode        := Mode_AF;
      GPIO_Conf.Output_Type := Push_Pull;
      GPIO_Conf.Resistors   := Pull_Up;
      GPIO_Conf.Locked      := True;
      Configure_IO (UART_GPIO_Port, (Rx_GPIO_Pin, Tx_GPIO_Pin), GPIO_Conf);

      --  Controll flow pin
      --  GPIO_Conf.Mode := Mode_In;
      --  Configure_IO (CF_GPIO_Port, CF_GPIO_Pin, GPIO_Conf);
   end Init_IO;

   procedure Init_UART is
   begin
      Enable_Clock (UART_Port);

      --  TODO: set to Crazyflie spec: 1_000_000
      Set_Baud_Rate (UART_Port, 115_200);

      --  Crazyflie has CTS flow control
      --  Set_Flow_Control (UART_Port, CTS_Flow_Control);
      Set_Flow_Control (UART_Port, No_Flow_Control);
      Set_Mode (UART_Port, Tx_Rx_Mode);
      Set_Parity (UART_Port, No_Parity);
      Set_Stop_Bits (UART_Port, Stopbits_1);
      Set_Word_Length (UART_Port, Word_Length_8);
      Enable (UART_Port);
   end Init_UART;

   procedure UART_Get_Data
     (Rx_Byte      : out T_Uint8;
      Has_Suceed   : out Boolean) is
   begin
      while not Rx_Ready (UART_Port) loop
         null;
      end loop;

      Receive (UART_Port, Rx_Byte);
   end UART_Get_Data;

   procedure UART_Send_Data
     (Data_Size : T_Uint32;
      Data      : UART_TX_Buffer) is
   begin
      for I in 1 .. Data_Size loop
         while not Tx_Ready (UART_Port) loop
            null;
         end loop;
         Transmit (UART_Port, Data (I));
      end loop;
   end UART_Send_Data;

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
