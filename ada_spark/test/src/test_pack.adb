with Ada.Text_IO; use Ada.Text_IO;
with Generic_Queue_Pack;
with Crtp_Pack; use Crtp_Pack;
with RadiolInk_Pack; use RadiolInk_Pack;
with Ada.Unchecked_Conversion;

package body Test_Pack is

   procedure Queue_Test is
      package Integer_Queue_Pack is new Generic_Queue_Pack (Integer);
      use Integer_Queue_Pack;
      Queue : T_Queue (5);
      Item : Integer;
   begin
      --  Enqueue Elements first...
      Enqueue (Queue, 1);
      Enqueue (Queue, 2);
      Enqueue (Queue, 3);
      Enqueue (Queue, 5);

      --  And see what's happening...
      Dequeue (Queue, Item);
      Put_Line ("1st dequeue: " & Integer'Image (Item));
      Dequeue (Queue, Item);
      Put_Line ("2nd dequeue: " & Integer'Image (Item));
   end Queue_Test;

   procedure Radio_Link_Test is
      Message : constant String (1 .. CRTP_MAX_DATA_SIZE) :=
                  "Hello Syslink!0000000000000000";
      Packet  : Crtp_Packet;
      subtype Data_String is String (1 .. Packet.Data_1'Length);
      function String_To_Data is new Ada.Unchecked_Conversion
        (Data_String, Crtp_Data);
      Has_Succeed : Boolean;
      pragma Unreferenced (Has_Succeed);

   begin
      Packet.Size := 12;
      Packet.Channel := 0;
      Packet.Reserved := 0;
      Packet.Port := CRTP_PORT_CONSOLE;
      Packet.Data_1 := String_To_Data (Message);

      Has_Succeed := Radiolink_Send_Packet (Packet);
   end Radio_Link_Test;

   procedure Packet_Handler_Test is
      Handler : Crtp_Packet_Handler;
      Has_Succeed : Boolean;
      procedure Crtp_Append_Float_Data is new Crtp_Append_Data (Float);
      procedure Crtp_Get_Float_Data is new Crtp_Get_Data (Float);
      Data : Float;
   begin
      Handler := Crtp_Create_Packet (CRTP_PORT_COMMANDER, 0);
      Crtp_Append_Float_Data (Handler, 12.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 13.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 14.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 15.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 16.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 17.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 18.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 19.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 20.0, Has_Succeed);
      Crtp_Append_Float_Data (Handler, 21.0, Has_Succeed);

      Crtp_Get_Float_Data (Handler, 25, Data, Has_Succeed);
      Put_Line ("Float data: " & Float'Image (Data));
   end Packet_Handler_Test;

end Test_Pack;
