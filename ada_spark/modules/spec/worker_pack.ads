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

with System;                  use System;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

with FreeRTOS_Pack;           use FreeRTOS_Pack;
with Types;                   use Types;

package Worker_Pack
with SPARK_Mode,
  Initializes => Worker_Queue
is
   --  Types

   --  Worker functions currently supported.
   type Action is (Log_Run, Neo_Pixel_Ring, None);

   --  Element type of the worker queue. 'Action' refers to a worker function
   --  and 'Arg' to its argument.
   type Worker_Work is record
      Func : Action;
      Arg  : Pvoid;
   end record;

   --  Constants and Global Variables

   WORKER_QUEUE_LENGTH : constant T_Uint32 := 5;

   Worker_Queue : Pvoid := System.Null_Address;

   --  Procedures and Functions

   --  Initialize the worker queue.
   procedure Worker_Init
     with
       Global => (In_Out => Worker_Queue);
   pragma Export (C, Worker_Init, "ada_workerInit");

   --  Test if the worker queue is valid.
   function Worker_Test return bool
     with
       Global => (Input => Worker_Queue);
   pragma Export (C, Worker_Test, "ada_workerTest");

   --  Main loop calling all teh worker functions in the worker queue.
   procedure Worker_Loop
     with
       Global => (Input => Worker_Queue);
   pragma Export (C, Worker_Loop, "ada_workerLoop");

   --  Add a worker function to the worker queue.
   function Worker_Schedule
     (Func_ID : Integer;
      Arg     : Pvoid) return Integer;
   pragma Export (C, Worker_Schedule, "ada_workerSchedule");

   --  Worker function to send log data.
   procedure Log_Run_Worker (Arg : Pvoid)
     with
       Global => null;

   --  Worker function to begin a LED sequence of Neo Pixel Ring.
   procedure Neo_Pixel_Ring_Worker (Arg : Pvoid)
     with
       Global => null;

end Worker_Pack;
