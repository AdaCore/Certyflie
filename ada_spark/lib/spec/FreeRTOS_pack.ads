with System; use System;
with Types; use Types;

package FreeRTOS_Pack is
   --  Types
   subtype Pvoid is System.Address;

   --  Constants
   PORT_MAX_DELAY  : constant T_Uint32    := 16#ffffffff#;

   --  Functions and procedures
   function XQueue_Create
     (QueueLength : T_Uint32;
      ItemSize    : Integer) return Pvoid;
   pragma Import (C, XQueue_Create, "w_xQueueCreate");

   function XQueue_Receive
     (XQueue        : Pvoid;
      Buffer        : Pvoid;
      Ticks_To_wait : T_Uint32) return Integer;
   pragma Import (C, XQueue_Receive, "w_xQueueReceive");

   function XQueue_Send
     (XQueue        : Pvoid;
      Item_To_Queue : Pvoid;
      Ticks_To_wait : T_Uint32) return Integer;
   pragma Import (C, XQueue_Send, "w_xQueueSend");

end FreeRTOS_Pack;
