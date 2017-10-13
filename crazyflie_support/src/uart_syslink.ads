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

with Ada.Unchecked_Conversion;
with Ada.Interrupts.Names;     use Ada.Interrupts.Names;
with Ada.Real_Time;            use Ada.Real_Time;

with STM32;                    use STM32;
with STM32.Device;             use STM32.Device;
with STM32.DMA;                use STM32.DMA;
with STM32.USARTs;             use STM32.USARTs;

with Types;                    use Types;
with Generic_Queue;

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

private

   package T_Uint8_Queue is new Generic_Queue (T_Uint8);
   use T_Uint8_Queue;

   --  Global variables and constants

   Controller : DMA_Controller renames DMA_2;

   Tx_Channel : constant DMA_Channel_Selector := Channel_5;
   Tx_Stream : constant DMA_Stream_Selector := Stream_6;

   DMA_Tx_IRQ : constant Ada.Interrupts.Interrupt_ID := DMA2_Stream6_Interrupt;
   --  must match that of the selected controller and stream number!!!!

   UART_RX_QUEUE_SIZE   : constant := 40;
   UART_DATA_TIMEOUT_MS : constant Time_Span :=  Milliseconds (1_000);

   --  Procedures and functions

   --  Initialize the STM32F4 USART controller.
   procedure Initialize_USART;

   --  Configure the STM32F4 USART controller.
   procedure Configure_USART;

   --  Initialize the STM32F4 DMA controller.
   procedure Initialize_DMA;

   --  Enable USART interrupts in reception.
   procedure Enable_USART_Rx_Interrupts;

   --  Finalize Tx DMA transmissions.
   procedure Finalize_DMA_Transmission (Transceiver : in out USART);

   --  Tasks and protected objects

   --  DMA Interrupt Handler for transmission.
   protected Tx_IRQ_Handler is
      pragma Interrupt_Priority;

      entry Await_Transfer_Complete;

   private

      Event_Occurred    : Boolean := False;
      Transfer_Complete : Boolean := False;
      Event_Kind        : DMA_Interrupt;

      procedure IRQ_Handler;
      pragma Attach_Handler (IRQ_Handler, DMA_Tx_IRQ);
   end Tx_IRQ_Handler;

   --  Interrupt Handler for reception (DMA not used here).
   protected Rx_IRQ_Handler is
      pragma Interrupt_Priority;

      entry Await_Byte_Reception (Rx_Byte : out T_Uint8);

   private

      Byte_Avalaible  : Boolean := False;
      Rx_Queue        : T_Queue (UART_RX_QUEUE_SIZE);

      procedure IRQ_Handler;
      pragma Attach_Handler (IRQ_Handler, USART6_Interrupt);
   end Rx_IRQ_Handler;

end UART_Syslink;
