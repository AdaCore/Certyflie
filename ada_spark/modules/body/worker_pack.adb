------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

package body Worker_Pack
  with SPARK_Mode
is
   -----------------
   -- Worker_Init --
   -----------------

   procedure Worker_Init is
   begin
      if Worker_Queue = System.Null_Address then
         Worker_Queue := XQueue_Create (WORKER_QUEUE_LENGTH,
                                        Worker_Work'Size / 8);
      end if;
   end Worker_Init;

   -----------------
   -- Worker_Test --
   -----------------

   function Worker_Test return bool is
   begin
      if Worker_Queue /= System.Null_Address then
         return 1;
      else
         return 0;
      end if;
   end Worker_Test;

   -----------------
   -- Worker_Loop --
   -----------------

   procedure Worker_Loop
   is
      Work : Worker_Work := (None, System.Null_Address);
      Res : Integer;
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

   ---------------------
   -- Worker_Schedule --
   ---------------------

   function Worker_Schedule
     (Func_ID : Integer;
      Arg     : Pvoid) return Integer
   is
      Work : Worker_Work;
      Res : Integer;
   begin
      --  No worker function registered for this ID
      if Func_ID not in Action'Pos (Action'First) .. Action'Pos (Action'Last)
      then
         return 1;
      end if;
      Work.Func := Action'Val (Func_ID);
      Work.Arg := Arg;

      Res := XQueue_Send (Worker_Queue, Work'Address, 0);

      if Res = -1 then
         return 12; -- ENOMEM
      end if;

      return 0;
   end Worker_Schedule;

   --------------------
   -- Log_Run_Worker --
   --------------------

   procedure Log_Run_Worker (Arg : Pvoid)
   is
      ---------------------
      -- Worker_Function --
      ---------------------

      procedure Worker_Function (Arg : Pvoid)
        with
          Global => null;
      pragma Import (C, Worker_Function, "logRunBlock");
   begin
      Worker_Function (Arg);
   end Log_Run_Worker;

   ---------------------------
   -- Neo_Pixel_Ring_Worker --
   ---------------------------

   procedure Neo_Pixel_Ring_Worker (Arg : Pvoid)
   is
      ---------------------
      -- Worker_Function --
      ---------------------

      procedure Worker_Function (Arg : Pvoid)
     with
       Global => null;
      pragma Import (C, Worker_Function, "neopixelringWorker");
   begin
      Worker_Function (Arg);
   end Neo_Pixel_Ring_Worker;

end Worker_Pack;
