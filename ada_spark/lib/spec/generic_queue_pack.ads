generic
   type T_Element is private;
   Queue_Max_Length : Positive;

package Generic_Queue_Pack is
   type T_Queue is private;

   function Enqueue
     (Queue : in out T_Queue;
      Item  : T_Element) return Boolean;

   function Dequeue
     (Queue : in out T_Queue;
      Item  : out T_Element) return Boolean;

   function Is_Empty (Queue : in T_Queue) return Boolean;

private
   type Element_Array is array (Natural range <>) of T_Element;

   type T_Queue is record
      Container : Element_Array (0 .. Queue_Max_Length - 1);
      Count     : Natural := 0;
      Front     : Natural := 0;
      Rear      : Natural := 0;
   end record;

end Generic_Queue_Pack;
