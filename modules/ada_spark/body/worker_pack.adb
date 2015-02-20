with Interfaces; use Interfaces;

package body Worker_Pack is

   procedure Worker_Init is
      function XQueue_Create(QueueLength : Unsigned_32; ItemSize : Unsigned_32) return Pvoid;
      pragma Import(C, XQueue_Create, "w_xQueueCreate");
   begin
      if Worker_Queue /= System.Null_Address then
         Worker_Queue := XQueue_Create(Unsigned_32(WORKER_QUEUE_LENGTH), Unsigned_32(Worker_Work'Size / 8));
      end if;
   end Worker_Init;

   function Worker_Test return Boolean is
   begin
      return True;
   end Worker_Test;

   procedure Worker_Loop is
   begin
      null;
   end Worker_Loop;

   function Worker_Schedule(Func_Name : String; Arg : Pvoid) return Integer is
   begin
      return 0;
   end Worker_Schedule;

   procedure Log_Run_Worker (Arg : Pvoid) is
      procedure Worker_Function (Arg : Pvoid);
      pragma Import(C, Worker_Function, "logRunBlock");
   begin
      Worker_Function(Arg);
   end Log_Run_Worker;

   procedure Neo_Pixel_Ring_Worker (Arg : Pvoid) is
      procedure Worker_Function (Arg : Pvoid);
      pragma Import(C, Worker_Function, "neopixelringWorker");
   begin
      Worker_Function(Arg);
   end Neo_Pixel_Ring_Worker;

end Worker_Pack;
