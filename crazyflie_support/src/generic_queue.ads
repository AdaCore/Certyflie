------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with System;

generic
   type T_Element is private;

package Generic_Queue is

   --  Types

   type T_Queue (Length : Positive) is private;

   --  Procedures and functions

   --  Enqueue an item in the queue, if the queue is not full.
   procedure Enqueue
     (Queue : in out T_Queue;
      Item  : T_Element);

   --  Dequeue an item from the queue, if the queue is not empty.
   procedure Dequeue
     (Queue : in out T_Queue;
      Item  : out T_Element);

   --  Reset the queue by setting the count to 0.
   procedure Reset (Queue : in out T_Queue);

   --  Return True if the queue is empty, False otherwise.
   function Is_Empty (Queue : T_Queue) return Boolean;

   --  Return True if the queue is full, False otherwise.
   function Is_Full (Queue : T_Queue) return Boolean;

   --  Tasks and protected types

   --  Protected type used to access a queue that can be
   --  used by various tasks.
   protected type Protected_Queue
     (Ceiling    : System.Any_Priority;
      Queue_Size : Positive) is

      procedure Enqueue_Item
        (Item         : T_Element;
         Has_Succeed  : out Boolean);

      procedure Dequeue_Item
        (Item        : out T_Element;
         Has_Succeed : out Boolean);

      procedure Reset_Queue;

      entry Await_Item_To_Dequeue (Item : out T_Element);

   private
      pragma Priority (Ceiling);

      Data_Available : Boolean := False;
      Queue          : T_Queue (Queue_Size);

   end Protected_Queue;

private

   --  Types

   --  Type for arrays containing T_Element type items,
   --  T_Element type given as generic parameter.
   type Element_Array is array (Positive range <>) of T_Element;

   --  Type representing a generic queue.
   type T_Queue (Length : Positive) is record
      Container : Element_Array (1 .. Length);
      Count     : Natural := 0;
      Front     : Positive := 1;
      Rear      : Positive := 1;
   end record;

end Generic_Queue;
