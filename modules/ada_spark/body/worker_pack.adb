with Interfaces; use Interfaces;

package body Worker_Pack is

   procedure WorkerInit is
      function XQueueCreate(QueueLength : Unsigned_32; ItemSize : Unsigned_32) return Pvoid;
      pragma Import(C, XQueueCreate, "w_xQueueCreate");
   begin
      if WorkerQueue /= System.Null_Address then
         WorkerQueue := XQueueCreate(Unsigned_32(WORKER_QUEUE_LENGTH), Unsigned_32(Worker_Work'Size / 8));
      end if;
   end WorkerInit;

   function WorkerTest return Boolean is
   begin
      return True;
   end WorkerTest;

   procedure WorkerLoop is
   begin
      null;
   end WorkerLoop;

   function WorkerSchedule(FuncName : String; Arg : Pvoid) return Integer is
   begin
      return 0;
   end WorkerSchedule;

end Worker_Pack;
