with System;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

generic
   type T_Element is private;

package Generic_Queue_Pack is

   type T_Queue (Length : Positive) is private;

   procedure Enqueue
     (Queue : in out T_Queue;
      Item  : T_Element);

   procedure Dequeue
     (Queue : in out T_Queue;
      Item  : out T_Element);

   function Is_Empty (Queue : in T_Queue) return Boolean;

   function Is_Full (Queue : in T_Queue) return Boolean;

   protected type Protected_Queue
     (Ceiling    : System.Any_Priority;
      Queue_Size : Positive)is

      procedure Enqueue_Item
        (Item         : T_Element;
         Has_Succeed  : out Boolean);

      entry Dequeue_Item
        (Item : out T_Element;
         Has_Succeed  : out Boolean);

      procedure Timeout (E : in out Timing_Event);

      procedure Set_Timeout (Timeout_Span : Time_Span);

   private
      pragma Priority (Ceiling);

      Data_Available : Boolean := False;
      Timedout       : Boolean := False;
      Queue          : T_Queue (Queue_Size);
      Timeout_Event  : Timing_Event;
      Timeout_Handler_Accces : Timing_Event_Handler := Timeout'Access;

   end Protected_Queue;

private
   type Element_Array is array (Positive range <>) of T_Element;

   type T_Queue (Length : Positive) is record
      Container : Element_Array (1 .. Length);
      Count     : Natural := 0;
      Front     : Positive := 1;
      Rear      : Positive := 1;
   end record;

end Generic_Queue_Pack;
