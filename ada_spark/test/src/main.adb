with Ada.Text_IO; use Ada.Text_IO;
with Generic_Queue_Pack;
with Crtp_Pack; use Crtp_Pack;

procedure Main is
   package Integer_Queue_Pack is new Generic_Queue_Pack (Integer, 5);
   use Integer_Queue_Pack;
   Queue : T_Queue;
   Has_Succeed : Boolean;
   Item : Integer;
begin
   --  Enqueue Elements first...
   Has_Succeed := Enqueue (Queue, 1);
   Has_Succeed := Enqueue (Queue, 2);
   Has_Succeed := Enqueue (Queue, 3);
   Has_Succeed := Enqueue (Queue, 5);

   --  And see what's happening...
   Has_Succeed := Dequeue (Queue, Item);
   Put_Line ("1st dequeue: " & Integer'Image (Item));
   Has_Succeed := Dequeue (Queue, Item);
   Put_Line ("2nd dequeue: " & Integer'Image (Item));
end Main;
