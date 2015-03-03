with Interfaces; use Interfaces;
with Utils; use Utils;
with Debug_Pack; use Debug_Pack;

package body Worker_Pack
with SPARK_Mode
is
   procedure Worker_Init is
   begin
      if Worker_Queue = System.Null_Address then
         Worker_Queue := XQueue_Create (Unsigned_32 (WORKER_QUEUE_LENGTH),
                                        Worker_Work'Size / 8);
      end if;
   end Worker_Init;

   function Worker_Test return Integer is
   begin
      if Worker_Queue /= System.Null_Address then
         return 1;
      else
         return 0;
      end if;
   end Worker_Test;

   procedure Worker_Loop
   is
      Work : Worker_Work := (None, System.Null_Address);
      Res : Integer := 0;
   begin
      if Worker_Queue /= System.Null_Address then
         loop
            Res := XQueue_Receive (Worker_Queue, Work'Address, PORT_MAX_DELAY);

            exit when Res = -1;

            case Work.Func is
               when Log_Run =>
                  Log_Run_Worker (Work.Arg);
               when Neo_Pixel_Ring =>
                  Neo_Pixel_Ring_Worker (Work.Arg);
               when others =>
                  null;
            end case;
         end loop;
      end if;
   end Worker_Loop;

   function Worker_Schedule (Func_ID : Integer;
                             Arg     : Pvoid) return Integer is
      Work : Worker_Work := (None, System.Null_Address);
      Res : Integer := 0;
   begin
      Work.Func := Action'Val (Func_ID);

      Work.Arg := Arg;
      Res := XQueue_Send (Worker_Queue, Work'Address, 0);

      if Res = -1 then
         return 12; -- ENOMEM
      end if;

      return 0;
   end Worker_Schedule;

   procedure Log_Run_Worker (Arg : Pvoid) is
      procedure Worker_Function (Arg : Pvoid);
      pragma Import (C, Worker_Function, "logRunBlock");
   begin
      Worker_Function (Arg);
   end Log_Run_Worker;

   procedure Neo_Pixel_Ring_Worker (Arg : Pvoid) is
      procedure Worker_Function (Arg : Pvoid);
      pragma Import (C, Worker_Function, "neopixelringWorker");
   begin
      Worker_Function (Arg);
   end Neo_Pixel_Ring_Worker;

end Worker_Pack;
