with System;

package Worker_Pack
  with SPARK_Mode
is
   -- Types
   subtype Pvoid is System.Address;

   type Worker_Work (Func_Name_Size : Natural) is record
      Func_Name : String (1 .. Func_Name_Size);
      Arg : Pvoid;
   end record;

   -- Constants and Global Variables
   WORKER_QUEUE_LENGTH : constant Natural := 5;

   XQueueHandle : Pvoid;

   -- Procedures and Functions
   procedure WorkerInit;

   function WorkerTest return Boolean;

   procedure WorkerLoop;

   function WorkerSchedule(Func_Name : String; Arg : Pvoid) return Integer;

   -- Imported C functions


end Worker_Pack;
