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

with Ada.Real_Time; use Ada.Real_Time;
with System;

with Types;         use Types;
with MPU9250;       use MPU9250;

package Crazyflie_Config is

   --  Constants used to configure the Crazyflie support

   --  Link layers implemented to communicate via the CRTP protocol
   type Link_Layer is (RADIO_LINK, USB_LINK, ESKY_LINK);
   LINK_LAYER_TYPE : constant Link_Layer := RADIO_LINK;

   --  Radio configuration
   RADIO_CHANNEL       : constant := 80;
   RADIO_DATARATE      : constant := 0;

   --  IMU configuration
   IMU_GYRO_FS_CONFIG  : constant MPU9250_FS_Gyro_Range
     := MPU9250_Gyro_FS_2000;
   IMU_ACCEL_FS_CONFIG : constant MPU9250_FS_Accel_Range
     := MPU9250_Accel_FS_8;

end Crazyflie_Config;
