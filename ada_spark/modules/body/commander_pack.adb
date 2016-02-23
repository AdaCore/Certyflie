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

package body Commander_Pack is

   -----------------------
   -- Commander_Get_RPY --
   -----------------------

   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : in out T_Degrees;
      Euler_Pitch_Desired : in out T_Degrees;
      Euler_Yaw_Desired   : in out T_Degrees)
   is
      -------------------------------
      -- Commander_Get_RPY_Wrapper --
      -------------------------------

      procedure Commander_Get_RPY_Wrapper
        (Euler_Roll_Desired  : in out Float;
         Euler_Pitch_Desired : in out Float;
         Euler_Yaw_Desired   : in out Float);
      pragma Import (C, Commander_Get_RPY_Wrapper, "commanderGetRPY");
   begin
      Commander_Get_RPY_Wrapper
        (Euler_Roll_Desired,
         Euler_Pitch_Desired,
         Euler_Yaw_Desired);
      --  TODO: Smooth commands to have a better control
   end Commander_Get_RPY;

end Commander_Pack;
