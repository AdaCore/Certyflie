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

package Pid_Parameters is

   --  Constants
   PID_ROLL_RATE_KP                : constant := 250.0;
   PID_ROLL_RATE_KI                : constant := 500.0;
   PID_ROLL_RATE_KD                : constant := 2.5;
   PID_ROLL_RATE_INTEGRATION_LIMIT : constant := 33.3;

   PID_PITCH_RATE_KP                : constant := 250.0;
   PID_PITCH_RATE_KI                : constant := 500.0;
   PID_PITCH_RATE_KD                : constant := 2.5;
   PID_PITCH_RATE_INTEGRATION_LIMIT : constant := 33.3;

   PID_YAW_RATE_KP                : constant := 70.0;
   PID_YAW_RATE_KI                : constant := 16.7;
   PID_YAW_RATE_KD                : constant := 0.0;
   PID_YAW_RATE_INTEGRATION_LIMIT : constant := 166.7;

   PID_ROLL_KP                : constant := 10.0;
   PID_ROLL_KI                : constant := 4.0;
   PID_ROLL_KD                : constant := 0.0;
   PID_ROLL_INTEGRATION_LIMIT : constant := 20.0;

   PID_PITCH_KP                : constant := 10.0;
   PID_PITCH_KI                : constant := 4.0;
   PID_PITCH_KD                : constant := 0.0;
   PID_PITCH_INTEGRATION_LIMIT : constant := 20.0;

   PID_YAW_KP                : constant := 10.0;
   PID_YAW_KI                : constant := 1.0;
   PID_YAW_KD                : constant := 0.35;
   PID_YAW_INTEGRATION_LIMIT : constant := 360.0;

   --  Default limit for the integral term in PID.
   DEFAULT_PID_INTEGRATION_LIMIT : constant := 5000.0;

   --  Default min and max values for coefficients in PID.
   MIN_ATTITUDE_COEFF                : constant := 0.0;
   MAX_ATTITUDE_COEFF                : constant := 10.0;
   MIN_RATE_COEFF                    : constant := 0.0;
   MAX_RATE_COEFF                    : constant := 500.0;
   MIN_ALTITUDE_COEFF                : constant := 0.0;
   MAX_ALTITUDE_COEFF                : constant := 2.0;

end Pid_Parameters;
