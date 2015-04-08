package body Generic_Queue_Pack is

   function Enqueue
     (Queue : in out T_Queue;
      Item  : T_Element) return Boolean is
   begin
      if Queue.Count = Queue.Container'Length then
         return False;
      end if;

      Queue.Container (Queue.Rear) := Item;
      Queue.Rear := (if Queue.Rear + 1 = Queue.Container'Length then
                        0
                     else
                        Queue.Rear + 1);

      Queue.Count := Queue.Count + 1;
      return True;
   end Enqueue;

   function Dequeue
     (Queue : in out T_Queue;
      Item  : out T_Element) return Boolean is
   begin
      if Queue.Count = 0 then
         return False;
      end if;

      Item := Queue.Container (Queue.Front);
      Queue.Front := (if Queue.Front + 1 = Queue.Container'Length then
                         0
                      else
                         Queue.Front + 1);
      Queue.Count := Queue.Count - 1;
      return True;
   end Dequeue;

   function Is_Empty (Queue : in T_Queue) return Boolean is
   begin
      return Queue.Count = 0;
   end Is_Empty;

end Generic_Queue_Pack;
