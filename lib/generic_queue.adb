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

package body Generic_Queue is

   -------------
   -- Enqueue --
   -------------

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

   -------------
   -- Dequeue --
   -------------

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

   -----------
   -- Reset --
   -----------

   procedure Reset (Queue : in out T_Queue) is
   begin
      Queue.Count := 0;
   end Reset;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Queue : T_Queue) return Boolean is
   begin
      return Queue.Count = 0;
   end Is_Empty;

   -------------
   -- Is_Full --
   -------------

   function Is_Full (Queue : T_Queue) return Boolean is
   begin
      return Queue.Count = Queue.Container'Length;
   end Is_Full;

   ---------------------
   -- Protected_Queue --
   ---------------------

   protected body Protected_Queue is

      ------------------
      -- Enqueue_Item --
      ------------------

      procedure Enqueue_Item
        (Item         : T_Element;
         Has_Succeed  : out Boolean) is
      begin
         if not Is_Full (Queue) then
            Has_Succeed := True;
            Enqueue (Queue, Item);
            Data_Available := True;
         else
            Has_Succeed := False;
         end if;

      end Enqueue_Item;

      procedure Dequeue_Item
        (Item        : out T_Element;
         Has_Succeed : out Boolean) is
      begin
         if not Is_Empty (Queue) then
            Has_Succeed := True;
            Dequeue (Queue, Item);
            Data_Available := not Is_Empty (Queue);
         else
            Has_Succeed := False;
         end if;
      end Dequeue_Item;

      procedure Reset_Queue is
      begin
         Reset (Queue);
      end Reset_Queue;

      entry Await_Item_To_Dequeue
        (Item : out T_Element) when Data_Available is
      begin
         Dequeue (Queue, Item);
         Data_Available := not Is_Empty (Queue);
      end Await_Item_To_Dequeue;

   end Protected_Queue;

end Generic_Queue;
