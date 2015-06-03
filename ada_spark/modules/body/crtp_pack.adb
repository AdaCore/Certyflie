with Link_Interface_Pack; use Link_Interface_Pack;
pragma Elaborate (Link_Interface_Pack);
with Ada.Unchecked_Conversion;

package body Crtp_Pack is

   task body Crtp_Tx_Task is
      Packet : Crtp_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Tx_Queue.Dequeue_Item
           (Packet, Has_Succeed);

         if Has_Succeed then
            Has_Succeed := Link_Send_Packet (Packet);
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
            Port_Queues (Packet.Port).Enqueue_Item (Packet, Has_Succeed);
            if not Has_Succeed then
               Dropped_Packets := Dropped_Packets + 1;
            end if;

            if Callbacks (Packet.Port) /= null then
               Callbacks (Packet.Port) (Packet);
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

   function Crtp_Get_Handler_From_Packet
     (Packet : Crtp_Packet) return Crtp_Packet_Handler
   is
      Handler : Crtp_Packet_Handler;
   begin
      Handler.Packet := Packet;
      Handler.Index := Integer (Packet.Size);

      return Handler;
   end Crtp_Get_Handler_From_Packet;

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

   procedure Crtp_Reset_Handler (Handler : in out Crtp_Packet_Handler) is
   begin
      Handler.Index := 1;
      Handler.Packet.Size := 0;
      Handler.Packet.Data_1 := (others => 0);
   end Crtp_Reset_Handler;

   function Crtp_Get_Packet_Size
     (Handler : Crtp_Packet_Handler) return T_Uint8 is
   begin
      return Handler.Packet.Size;
   end Crtp_Get_Packet_Size;

   procedure Crtp_Receive_Packet
     (Packet           : out Crtp_Packet;
      Port_ID          : Crtp_Port;
      Has_Succeed      : out Boolean;
      Time_To_Wait     :  Time_Span := Milliseconds (0)) is
      pragma Unreferenced (Time_To_Wait);
   begin
      Port_Queues (Port_ID).Dequeue_Item
        (Packet, Has_Succeed);
   end Crtp_Receive_Packet;

   procedure Crtp_Send_Packet
     (Packet : Crtp_Packet;
      Has_Succeed : out Boolean;
      Time_To_Wait : Time_Span := Milliseconds (0)) is
      pragma Unreferenced (Time_To_Wait);
   begin
      Tx_Queue.Enqueue_Item (Packet, Has_Succeed);
   end Crtp_Send_Packet;

   procedure Crtp_Register_Callback
     (Port_ID  : Crtp_Port;
      Callback : Crtp_Callback) is
   begin
      Callbacks (Port_ID) := Callback;
   end Crtp_Register_Callback;

end Crtp_Pack;
