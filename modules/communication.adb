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

with Console;          use Console;
with CRTP_Service;     use CRTP_Service;
with Platform_Service; use Platform_Service;
with Link_Interface;   use Link_Interface;

package body Communication is

   ------------------------
   -- Communication_Init --
   ------------------------

   procedure Communication_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  Initialize the link layer (Radiolink by default in Config.ads).
      Link_Init;

      --  Initialize low and high level services.
      CRTP_Service_Init;
      Platform_Service_Init;

      --  Initialize the console module.
      Console_Init;

      Is_Init := True;
   end Communication_Init;

   ------------------------
   -- Communication_Test --
   ------------------------

   function Communication_Test return Boolean is
   begin
      return Is_Init;
   end Communication_Test;

end Communication;
