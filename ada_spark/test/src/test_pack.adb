with Ada.Text_IO; use Ada.Text_IO;
with Generic_Queue_Pack;

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

end Test_Pack;
