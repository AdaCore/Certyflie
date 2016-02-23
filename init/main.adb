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

pragma Profile (Ravenscar);

with Ada.Real_Time;       use Ada.Real_Time;
with Last_Chance_Handler; pragma Unreferenced (Last_Chance_Handler);

with Config;              use Config;
with System_Pack;         use System_Pack;

----------
-- Main --
----------

procedure Main is
   pragma Priority (MAIN_TASK_PRIORITY);
   Self_Test_Passed : Boolean;
begin
   --  System initialization
   System_Init;

   --  See if we pass the self test
   Self_Test_Passed := System_Self_Test;

   --  Start the main loop if the self test passed
   if Self_Test_Passed then
      System_Loop;
   else
      delay until Time_Last;
   end if;
end Main;
