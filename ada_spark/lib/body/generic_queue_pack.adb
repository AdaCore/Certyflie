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
         Has_Succeed  : out Boolean) is
         Cancelled : Boolean;
         pragma Unreferenced (Cancelled);
      begin
         Cancel_Handler (Timeout_Event, Cancelled);

         if not Is_Full (Queue) then
            Has_Succeed := True;
            Enqueue (Queue, Item);
            Data_Available := True;
         else
            Has_Succeed := False;
         end if;

         Timedout := False;
      end Enqueue_Item;

      entry Dequeue_Item
        (Item          : out T_Element;
         Has_Succeed   : out Boolean) when Data_Available is
         Cancelled : Boolean;
         pragma Unreferenced (Cancelled);
      begin
         Cancel_Handler (Timeout_Event, Cancelled);
         Dequeue (Queue, Item);
         Data_Available := not Is_Empty (Queue);
         Has_Succeed := not Timedout;
         Timedout := False;
      end Dequeue_Item;

      procedure Timeout (E : in out Timing_Event) is
         pragma Unreferenced (E);
      begin
         Data_Available := True;
         Timedout := True;
      end Timeout;

      procedure Set_Timeout (Timeout_Span : Time_Span) is
      begin
         Set_Handler
           (Timeout_Event, Clock + Timeout_Span, Timeout_Handler_Accces);
      end Set_Timeout;

   end Protected_Queue;

end Generic_Queue_Pack;
