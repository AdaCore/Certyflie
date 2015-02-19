package body Worker_Pack is

   procedure WorkerInit is
   begin
      null;
   end WorkerInit;

   function WorkerTest return Boolean is
   begin
      return True;
   end WorkerTest;

   procedure WorkerLoop is
   begin
      null;
   end WorkerLoop;

   function WorkerSchedule(Func_Name : String; Arg : Pvoid) return Integer is
   begin
      return 0;
   end WorkerSchedule;

end Worker_Pack;
