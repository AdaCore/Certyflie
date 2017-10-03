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

with Types;                    use Types;

package UART_Syslink is

   --  Types

   subtype DMA_Data is T_Uint8_Array (1 .. 64);

   type USART_Error is
     (No_Err, Parity_Err, Framing_Err, Noise_Err, Overrun_Err);

   --  Procedures and functions

   --  Initialize the UART Syslink interface.
   procedure UART_Syslink_Init;

   --  Get one byte of data from UART, with a defined timeout.
   procedure UART_Get_Data_Blocking (Rx_Byte : out T_Uint8);

   --  Send data to DMA.
   procedure UART_Send_DMA_Data_Blocking
     (Data_Size : Natural;
      Data      : DMA_Data);

end UART_Syslink;
