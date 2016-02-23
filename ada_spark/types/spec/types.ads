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

with Interfaces;
with Interfaces.C.Extensions;

with IMU_Pack; use IMU_Pack;

package Types is

   --  General types used for C Interfacing.

   type T_Int8   is new Interfaces.Integer_8;
   type T_Int16  is new Interfaces.Integer_16;
   type T_Int32  is new Interfaces.Integer_32;
   type T_Uint8  is new Interfaces.Unsigned_8;
   type T_Uint16 is new Interfaces.Unsigned_16;
   type T_Uint32 is new Interfaces.Unsigned_32;

   subtype Natural_Float is Float range 0.0 .. Float'Last;

   --  Types used by the stabilization system

   --  Allowed delta time range.
   subtype T_Delta_Time   is Float range IMU_UPDATE_DT .. 1.0;

   --  Smoothing terms. Used for barycentric expressions.
   subtype T_Alpha        is Float range 0.0 .. 1.0;

   --  Angle range type, in degrees.
   --  This range is deduced from the MPU9150 Datasheet.
   subtype T_Degrees        is Float range -360.0 .. 360.0;

   --  Allowed speed range, in m/s.
   --  This range is deduced from the MPU9150 Datasheet.
   subtype T_Speed        is Float range -2000.0 .. 2000.0;

   --  Allowed sensitivity for target altitude change in Alt Hold mode.
   subtype T_Sensitivity  is Float range 100.0 .. 300.0;

   --  Allowed factor to relate Altitude with Thrust command for motors.
   subtype T_Motor_Fac    is Float range 10_000.0 .. 15_000.0;

   --  Types used for the implementation of Mahony and Madgwick algorithms

   subtype T_Quaternion is Float range -1.0 .. 1.0;

end Types;
