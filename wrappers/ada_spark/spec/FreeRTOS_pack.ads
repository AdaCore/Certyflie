with System; use System;
with Interfaces; use Interfaces;
with Interfaces.C; use Interfaces.C;

package FreeRTOS_Pack is
   --  Types
   subtype Pvoid is System.Address;

   --  Functions and procedures
   function XQueue_Create (QueueLength : Unsigned_32;
                           ItemSize    : Integer) return Pvoid;
   pragma Import (C, XQueue_Create, "w_xQueueCreate");

   function XQueue_Receive (XQueue        : Pvoid;
                            Buffer        : Pvoid;
                            Ticks_To_wait : Unsigned_32) return Integer;
   pragma Import (C, XQueue_Receive, "w_xQueueReceive");

   function XQueue_Send (XQueue        : Pvoid;
                         Item_To_Queue : Pvoid;
                         Ticks_To_wait : Unsigned_32) return Integer;
   pragma Import (C, XQueue_Send, "w_xQueueSend");

end FreeRTOS_Pack;
