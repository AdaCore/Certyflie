with System; use System;

package Worker_Pack
  with SPARK_Mode
is
   -- Types
   subtype Pvoid is System.Address;

   type Action is (Log_Run, Neo_Pixel_Ring);

   type Worker_Work is record
      Func : Action;
      Arg  : Pvoid;
   end record;

   -- Constants and Global Variables
   WORKER_QUEUE_LENGTH : constant Natural := 5;

   Worker_Queue : Pvoid := System.Null_Address;

   -- Procedures and Functions
   procedure Worker_Init;

   function Worker_Test return Boolean;

   procedure Worker_Loop;

   function Worker_Schedule(Func_Name : String; Arg : Pvoid) return Integer;

   procedure Log_Run_Worker (Arg : Pvoid);

   procedure Neo_Pixel_Ring_Worker (Arg : Pvoid);



end Worker_Pack;
