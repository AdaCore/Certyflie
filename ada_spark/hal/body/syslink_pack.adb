with Ada.Unchecked_Conversion;
with UART_Syslink; use UART_Syslink;
pragma Elaborate (UART_Syslink);
with Radiolink_Pack; use Radiolink_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Protected_IO_Pack; use Protected_IO_Pack;

package body Syslink_Pack is

   --  TODO: Move this variable in the private part of the package
   --  when the with clause for Syslink_Pack won't be needed in the
   --  UART_Syslink_Pack
   Tx_Buffer : UART_TX_Buffer;

   procedure Syslink_Init is
   begin
      if Is_Init then
         return;
      end if;

      Set_True (Syslink_Access);
   end Syslink_Init;

   function Syslink_Test return Bool is
   begin
      return (if Is_Init then 1 else 0);
   end Syslink_Test;

   procedure Syslink_Send_Packet (Sl_Packet : Syslink_Packet) is
      Data_Size : Integer range Tx_Buffer'First .. Tx_Buffer'Last;
      Chk_Sum      : array (1 .. 2) of T_Uint8 := (others => 0);
   begin
      Suspend_Until_True (Syslink_Access);

      Tx_Buffer (1) := SYSLINK_START_BYTE1;
      Tx_Buffer (2) := SYSLINK_START_BYTE2;
      Tx_Buffer (3) := Syslink_Packet_Type'Enum_Rep (Sl_Packet.Slp_Type);
      Tx_Buffer (4) := Sl_Packet.Length;

      Data_Size := Integer (Sl_Packet.Length + 6);

      for I in 3 .. Data_Size - 2 loop
         Chk_Sum (1) := Chk_Sum (1) + Tx_Buffer (I);
         Chk_Sum (2) := Chk_Sum (2) + Chk_Sum (1);
      end loop;

      Tx_Buffer (Data_Size - 1) := Chk_Sum (1);
      Tx_Buffer (Data_Size) := Chk_Sum (2);

      --  TODO: call UART_Send_Data_DMA_Blocking
      Set_True (Syslink_Access);
   end Syslink_Send_Packet;

   procedure Syslink_Route_Incoming_Packet (Rx_Sl_Packet : Syslink_Packet) is
      Group_Type : Syslink_Packet_Group_Type;

   begin
      Group_Type := Syslink_Packet_Group_Type'Val
        (Syslink_Packet_Type'Enum_Rep (Rx_Sl_Packet.Slp_Type)
         and SYSLINK_GROUP_MASK);

      case Group_Type is
         when SYSLINK_RADIO_GROUP =>
            X_Put_Line ("Packet sent to RadioLink");
            Radiolink_Syslink_Dispatch (Rx_Sl_Packet);
            --  TODO: Dispatch the syslink packets to teh other modules
            --  when they will be implemented
         when others =>
            null;
      end case;
   end Syslink_Route_Incoming_Packet;

   task body Syslink_Task is
      Rx_State     : Syslink_Rx_State := WAIT_FOR_FIRST_START;
      Rx_Sl_Packet : Syslink_Packet;
      Rx_Byte      : T_Uint8;
      Data_Index   : Positive := 1;
      Chk_Sum      : array (1 .. 2) of T_Uint8;
      Has_Succeed  : Boolean;
      Next_Period  : Time := Clock + Seconds (1);
   begin
      loop
         delay until Next_Period;
         UART_Get_Data_With_Timeout (Rx_Byte, Has_Succeed);
         X_Put_Line ("Rx_Byte: " & T_Uint8'Image (Rx_Byte));
         case Rx_State is
            when WAIT_FOR_FIRST_START =>

               Rx_State := (if Rx_Byte = SYSLINK_START_BYTE1 then
                               WAIT_FOR_SECOND_START
                            else
                               WAIT_FOR_FIRST_START);
            when WAIT_FOR_SECOND_START =>
               Rx_State := (if Rx_Byte = SYSLINK_START_BYTE2 then
                               WAIT_FOR_TYPE
                            else
                               WAIT_FOR_FIRST_START);
            when WAIT_FOR_TYPE =>
               Chk_Sum (1) := Rx_Byte;
               Chk_Sum (2) := Rx_Byte;
               Rx_Sl_Packet.Slp_Type := Syslink_Packet_Type'Val (Rx_Byte);
               Rx_State := WAIT_FOR_LENGTH;
            when WAIT_FOR_LENGTH =>
               if Rx_Byte <= SYSLINK_MTU then
                  Rx_Sl_Packet.Length := Rx_Byte;
                  Chk_Sum (1) := Chk_Sum (1) + Rx_Byte;
                  Chk_Sum (2) := Chk_Sum (2) + Chk_Sum (1);
                  Data_Index := 1;
                  Rx_State := (if Rx_Byte > 0 then
                                  WAIT_FOR_DATA
                               else
                                  WAIT_FOR_CHKSUM_1);
               else
                  Rx_State := WAIT_FOR_FIRST_START;
               end if;
            when WAIT_FOR_DATA =>
               Rx_Sl_Packet.Data (Data_Index) := Rx_Byte;
               Chk_Sum (1) := Chk_Sum (1) + Rx_Byte;
               Chk_Sum (2) := Chk_Sum (2) + Chk_Sum (1);
               Data_Index := Data_Index + 1;
               if T_Uint8 (Data_Index) >= Rx_Sl_Packet.Length then
                  --  TODO: remove this.. Only for testing purpose
                  Syslink_Route_Incoming_Packet (Rx_Sl_Packet);
                  Rx_State := WAIT_FOR_FIRST_START;
                  --Rx_State := WAIT_FOR_CHKSUM_1;
               end if;
            when WAIT_FOR_CHKSUM_1 =>
               Rx_State := (if Chk_Sum (1) = Rx_Byte then
                               WAIT_FOR_CHKSUM_2
                            else
                               WAIT_FOR_FIRST_START);
            when WAIT_FOR_CHKSUM_2 =>
               if Chk_Sum (2) = Rx_Byte then
                  Syslink_Route_Incoming_Packet (Rx_Sl_Packet);
               end if;
               Rx_State := WAIT_FOR_FIRST_START;
         end case;
         Next_Period := Next_Period + Seconds (1);
      end loop;
   end Syslink_Task;

end Syslink_Pack;
