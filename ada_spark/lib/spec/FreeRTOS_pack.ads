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

with System; use System;
with Types;  use Types;

package FreeRTOS_Pack
  with SPARK_Mode
is
   --  Types
   subtype Pvoid is System.Address;

   --  Constants
   PORT_MAX_DELAY  : constant T_Uint32 := 16#ffffffff#;
   TICK_RATE_HZ    : constant T_Uint16 := 1000;

   --  Functions and procedures
   function XQueue_Create
     (QueueLength : T_Uint32;
      ItemSize    : T_Uint32) return Pvoid
     with
       Global => null;
   pragma Import (C, XQueue_Create, "w_xQueueCreate");

   function XQueue_Receive
     (XQueue        : Pvoid;
      Buffer        : Pvoid;
      Ticks_To_wait : T_Uint32) return Integer
     with
       Global => null;
   pragma Import (C, XQueue_Receive, "w_xQueueReceive");

   function XQueue_Send
     (XQueue        : Pvoid;
      Item_To_Queue : Pvoid;
      Ticks_To_wait : T_Uint32) return Integer
     with
       Global => null;
   pragma Import (C, XQueue_Send, "w_xQueueSend");

   function XTask_Get_Tick_Count return T_Uint16
     with Global => null;
   pragma Import (C, XTask_Get_Tick_Count, "xTaskGetTickCount");

   function Milliseconds_To_Ticks (Time_In_Milli : T_Uint16) return T_Uint16
   is (Time_In_Milli * (TICK_RATE_HZ / 1000));


end FreeRTOS_Pack;
