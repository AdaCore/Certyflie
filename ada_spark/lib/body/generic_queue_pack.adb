package body Generic_Queue_Pack is

   procedure Enqueue
     (Queue : in out T_Queue;
      Item  : T_Element) is
   begin
      if Queue.Count = Queue.Container'Length then
         return;
      end if;

      Queue.Container (Queue.Rear) := Item;
      Queue.Rear := (if Queue.Rear = Queue.Container'Length then
                        1
                     else
                        Queue.Rear + 1);

      Queue.Count := Queue.Count + 1;
   end Enqueue;

   procedure Dequeue
     (Queue : in out T_Queue;
      Item  : out T_Element) is
   begin
      if Queue.Count = 0 then
         return;
      end if;

      Item := Queue.Container (Queue.Front);
      Queue.Front := (if Queue.Front = Queue.Container'Length then
                         1
                      else
                         Queue.Front + 1);
      Queue.Count := Queue.Count - 1;
   end Dequeue;

   function Is_Empty (Queue : in T_Queue) return Boolean is
   begin
      return Queue.Count = 0;
   end Is_Empty;

   function Is_Full (Queue : in T_Queue) return Boolean is
   begin
      return Queue.Count = Queue.Container'Length;
   end Is_Full;

   protected body Protected_Queue is
      procedure Enqueue_Item
        (Item         : T_Element;
         Has_Succeed  : out Boolean;
         Time_To_Wait : Time_Span := Milliseconds (0)) is
         Timeout_Time : Time;
      begin
         Timeout_Time := Clock + Time_To_Wait;

         while Is_Full (Queue) loop
            if Clock >= Timeout_Time then
               Has_Succeed := False;
               return;
            end if;
         end loop;

         if not Is_Full (Queue) then
            Has_Succeed := True;
            Enqueue (Queue, Item);
         else
            Has_Succeed := False;
         end if;
      end Enqueue_Item;

      procedure Dequeue_Item
        (Item : out T_Element;
         Has_Succeed   : out Boolean;
         Time_To_Wait  : Time_Span := Milliseconds (0)) is
         Timeout_Time : Time;
      begin
         Timeout_Time := Clock + Time_To_Wait;

         while Is_Empty (Queue) loop
            if Clock >= Timeout_Time then
               Has_Succeed := False;
               return;
            end if;
         end loop;

         if not Is_Empty (Queue) then
            Has_Succeed := True;
            Dequeue (Queue, Item);
         else
            Has_Succeed := False;
         end if;
      end Dequeue_Item;
   end Protected_Queue;

end Generic_Queue_Pack;
