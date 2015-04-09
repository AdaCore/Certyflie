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
                  "012345678901234567890123456789";
      Packet  : Crtp_Packet;
      subtype String_30 is String (1 .. Packet.Data'Length);
      function String_To_Data is new Ada.Unchecked_Conversion
        (String_30, Crtp_Data);
      Has_Succeed : Boolean;
      pragma Unreferenced (Has_Succeed);

   begin
      Packet.Size := 30;
      Packet.Channel := 0;
      Packet.Reserved := 0;
      Packet.Port := CRTP_PORT_CONSOLE;
      Packet.Data := String_To_Data (Message);

      Has_Succeed := RadiolInk_Send_Packet (Packet);
   end Radio_Link_Test;

end Test_Pack;
