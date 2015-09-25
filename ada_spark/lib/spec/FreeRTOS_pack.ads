with System; use System;
with Types; use Types;

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
