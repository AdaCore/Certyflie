with System; use System;

package Worker_Pack
  with SPARK_Mode
is
   -- Types
   subtype Pvoid is System.Address;

   type Worker_Work is record
      FuncName : String (1 .. 32);
      Arg : Pvoid;
   end record;

   -- Constants and Global Variables
   WORKER_QUEUE_LENGTH : constant Natural := 5;

   WorkerQueue : Pvoid := System.Null_Address;

   -- Procedures and Functions
   procedure WorkerInit;

   function WorkerTest return Boolean;

   procedure WorkerLoop;

   function WorkerSchedule(FuncName : String; Arg : Pvoid) return Integer;

   -- Imported C functions


end Worker_Pack;
