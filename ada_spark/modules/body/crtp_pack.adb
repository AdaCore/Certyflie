with Config; use Config;
with Link_Interface_Pack; use Link_Interface_Pack;
pragma Elaborate (Link_Interface_Pack);
with Ada.Unchecked_Conversion;
with Ada.Text_IO; use Ada.Text_IO;

package body Crtp_Pack is

   task body Crtp_Tx_Task is
      Packet : Crtp_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Tx_Queue.Dequeue_Item
           (Packet, Has_Succeed, Milliseconds (PORT_MAX_DELAY_TIME));

         if Has_Succeed then
            Has_Succeed := Link_Send_Packet (Packet);

            --  Keep testing, if the link change sto USB it will go through
            while not Has_Succeed loop
               Has_Succeed := Link_Send_Packet (Packet);
            end loop;
         end if;
      end loop;
   end Crtp_Tx_Task;

    task body Crtp_Rx_Task is
      Packet : Crtp_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Link_Receive_Packet (Packet, Has_Succeed);

         if Has_Succeed then
            Put_Line ("Packet received in CRTP");
            Port_Queues (Packet.Port).Enqueue_Item (Packet, Has_Succeed, Milliseconds (100));
            Put_Line ("Packet enqueued in port");
            if not Has_Succeed then
               Put_Line ("Packet dropped");
               Dropped_Packets := Dropped_Packets + 1;
            end if;
         end if;
      end loop;
   end Crtp_Rx_Task;

   function Crtp_Create_Packet
     (Port : Crtp_Port;
      Channel : Crtp_Channel) return Crtp_Packet_Handler is
      Packet : Crtp_Packet;
      Handler : Crtp_Packet_Handler;
   begin
      Packet.Size := 0;
      Packet.Port := Port;
      Packet.Channel := Channel;

      Handler.Index := 1;
      Handler.Packet := Packet;

      return Handler;
   end Crtp_Create_Packet;

   function Crtp_Get_Handler (Packet : Crtp_Packet) return Crtp_Packet_Handler
   is
      Handler : Crtp_Packet_Handler;
   begin
      Handler.Packet := Packet;
      Handler.Index := Integer (Packet.Size);

      return Handler;
   end Crtp_Get_Handler;

   function Crtp_Get_Packet_From_Handler
     (Handler : Crtp_Packet_Handler) return Crtp_Packet is
   begin
      return Handler.Packet;
   end Crtp_Get_Packet_From_Handler;

   procedure Crtp_Get_Data
     (Handler    : Crtp_Packet_Handler;
      Index      : Integer;
      Data       : out T_Data;
      Has_Succeed : out Boolean) is
      Data_Size : constant Natural := T_Data'Size / 8;
      subtype Byte_Array_Data is T_Uint8_Array (1 .. Data_Size);
      function Byte_Array_To_Data is new Ada.Unchecked_Conversion
        (Byte_Array_Data, T_Data);
   begin
      if Index
      in Handler.Packet.Data_1'First .. Handler.Packet.Data_1'Last - Data_Size - 1
      then
         Data := Byte_Array_To_Data
           (Handler.Packet.Data_1 (Index .. Index + Data_Size - 1));
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end Crtp_Get_Data;

   procedure Crtp_Append_Data
     (Handler : in out Crtp_Packet_Handler;
      Data           : T_Data;
      Has_Succeed     : out Boolean) is
      Data_Size : constant Natural := T_Data'Size / 8;
      subtype Byte_Array_Data is T_Uint8_Array (1 .. Data_Size);
      function Data_To_Byte_Array is new Ada.Unchecked_Conversion
        (T_Data, Byte_Array_Data);
   begin
      if Handler.Index + Data_Size - 1 <= Handler.Packet.Data_1'Last then
         Handler.Packet.Data_1
           (Handler.Index .. Handler.Index + Data_Size - 1) :=
           Data_To_Byte_Array (Data);

         Handler.Packet.Size := Handler.Packet.Size + T_Uint8 (Data_Size);
         Handler.Index := Handler.Index + Data_Size;
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end Crtp_Append_Data;

   procedure Crtp_Receive_Packet
     (Packet           : out Crtp_Packet;
      Port_ID          : Crtp_Port;
      Has_Succeed      : out Boolean;
      Time_To_Wait     :  Time_Span := Milliseconds (0)) is
   begin
      Port_Queues (Port_ID).Dequeue_Item
        (Packet, Has_Succeed, Time_To_Wait);
   end Crtp_Receive_Packet;

end Crtp_Pack;
