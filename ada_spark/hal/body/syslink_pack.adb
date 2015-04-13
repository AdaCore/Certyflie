with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with UART_Syslink; use UART_Syslink;
pragma Elaborate (UART_Syslink);
with Radiolink_Pack; use Radiolink_Pack;

package body Syslink_Pack is

   procedure Syslink_Init is
   begin
      --  TODO
      null;
   end Syslink_Init;

   function Syslink_Test return BOol Is
   begin
      -- TODO
      return 1;
   end Syslink_Test;

   procedure Syslink_Send_Packet (Sl_Packet : Syslink_Packet) is
      subtype Sl_Data_String is
        String (Syslink_Data'First .. Syslink_Data'Last);
      function Sl_Data_To_String is new Ada.Unchecked_Conversion
        (Source => Syslink_Data,
         Target => Sl_Data_String);
   begin
      --  For testing purpose, just print teh packet data
      Put_Line ("Packet.Length: " & T_Uint8'Image (Sl_Packet.Length));
      Put_Line ("Packet.Header: " & T_Uint8'Image (Sl_Packet.Data (1)));
      Put_Line ("Paket.Data: " & Sl_Data_To_String (Sl_Packet.Data));
   end Syslink_Send_Packet;

   procedure Syslink_Route_Incoming_Packet (Rx_Sl_Packet : Syslink_Packet) is
      Group_Type : Syslink_Packet_Group_Type;

   begin
      Group_Type := Syslink_Packet_Group_Type'Val
                       (Syslink_Packet_Type'Enum_Rep (Rx_Sl_Packet.Slp_Type)
                        and SYSLINK_GROUP_MASK);
      case Group_Type is
         when SYSLINK_RADIO_GROUP =>
            Radiolink_Syslink_Disptach (Rx_Sl_Packet);
            --  TODO: Dispatch the syslink packets to teh other modules
            --  when they will be implemented
         when others =>
            null;
      end case;
   end Syslink_Route_Incoming_Packet;


   task body Syslink_Task is
      Rx_State : Syslink_Rx_State := WAIT_FOR_FIRST_START;
      Rx_Sl_Packet : Syslink_Packet;
      Rx_Byte   : T_Uint8;
      Data_Index : Positive := 1;
      Chk_Sum     : array (1 .. 2) of T_Uint8;
      Has_Succeed : Boolean;
   begin
      loop
         UART_Get_Data_With_Timeout (Rx_Byte, Has_Succeed);
         case Rx_State is
            when WAIT_FOR_FIRST_START =>
               Rx_State := (if Rx_Byte = SYSLINK_START_BYTE1 then
                               WAIT_FOR_SECOND_START
                            else
                               WAIT_FOR_FIRST_START);
            when WAIT_FOR_SECOND_START =>
               Rx_State := (if Rx_Byte = SYSLINK_START_BYTE1 then
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
               if T_Uint8 (Data_Index) > Rx_Sl_Packet.Length then
                  Rx_State := WAIT_FOR_CHKSUM_1;
               end if;
            when WAIT_FOR_CHKSUM_1 =>
               Rx_State := (if Chk_Sum (1) = Rx_Byte then
                               WAIT_FOR_CHKSUM_2
                            else
                               WAIT_FOR_FIRST_START);
            when WAIT_FOR_CHKSUM_2 =>
               if Chk_Sum (2) = Rx_Byte then
                  --  TODO: route the packet
                  null;
               end if;
               Rx_State := WAIT_FOR_FIRST_START;
         end case;
      end loop;
   end Syslink_Task;

end Syslink_Pack;
