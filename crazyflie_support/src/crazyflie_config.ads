------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2017, AdaCore                     --
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

with System;

with MPU9250;       use MPU9250;

package Crazyflie_Config is

   --  Constants used to configure the Crazyflie support

   --  Interrupt priorities (see drivers/src/nvicconf.h)
   LOW_INTERRUPT_PRIORITY     : constant System.Interrupt_Priority
     := System.Interrupt_Priority'First + 2;
   MID_INTERRUPT_PRIORITY     : constant System.Interrupt_Priority
     := System.Interrupt_Priority'First + 5;
   HIGH_INTERRUPT_PRIORITY    : constant System.Interrupt_Priority
     := System.Interrupt_Priority'First + 8;
   TOP_INTERRUPT_PRIORITY     : constant System.Interrupt_Priority
     := System.Interrupt_Priority'Last;

   DMA_INTERRUPT_PRIORITY : constant System.Interrupt_Priority
     := HIGH_INTERRUPT_PRIORITY;
   DMA_FLOW_CONTROL_INTERRUPT_PRIORITY : constant System.Interrupt_Priority
     := TOP_INTERRUPT_PRIORITY;
   SYSLINK_INTERRUPT_PRIORITY : constant System.Interrupt_Priority
     := TOP_INTERRUPT_PRIORITY;

   --  Link layers implemented to communicate via the CRTP protocol
   type Link_Layer is (RADIO_LINK, USB_LINK, ESKY_LINK);
   LINK_LAYER_TYPE : constant Link_Layer := RADIO_LINK;

   --  Radio configuration
   RADIO_CHANNEL       : constant := 80;
   --  This should be with the radio ..
   type RADIO_RATE is
     (RADIO_RATE_250K,
      RADIO_RATE_1M,
      RADIO_RATE_2M);
   RADIO_DATARATE      : constant := RADIO_RATE'Pos (RADIO_RATE_2M);
   RADIO_ADDRESS       : constant := 16#e7e7e7e7e7#;

   --  IMU configuration
   IMU_GYRO_FS_CONFIG  : constant MPU9250_FS_Gyro_Range
     := MPU9250_Gyro_FS_2000;
   IMU_ACCEL_FS_CONFIG : constant MPU9250_FS_Accel_Range
     := MPU9250_Accel_FS_8;

end Crazyflie_Config;
