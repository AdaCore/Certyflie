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

with HAL;         use HAL;
with STM32.Board; use STM32.Board;
with STM32.GPIO;  use STM32.GPIO;

package body UART_Syslink is

   --  Public procedures and functions

   -----------------------
   -- UART_Syslink_Init --
   -----------------------

   procedure UART_Syslink_Init is
   begin
      Initialize_USART;
      Configure_USART;
      Initialize_DMA;

      Enable (NRF_USART);

      Enable_USART_Rx_Interrupts;
   end UART_Syslink_Init;

   ----------------------------
   -- UART_Get_Data_Blocking --
   ----------------------------

   procedure UART_Get_Data_Blocking (Rx_Byte : out T_Uint8) is
   begin
      Rx_IRQ_Handler.Await_Byte_Reception (Rx_Byte);
   end UART_Get_Data_Blocking;

   ---------------------------------
   -- UART_Send_DMA_Data_Blocking --
   ---------------------------------

   procedure UART_Send_DMA_Data_Blocking
     (Data_Size : Natural;
      Data      : DMA_Data) is
   begin
      Start_Transfer_with_Interrupts
        (Controller,
         Tx_Stream,
         Source      => Data'Address,
         Destination => Data_Register_Address (NRF_USART),
         Data_Count  => UInt16 (Data_Size));
      --  also enables the stream

      Enable_DMA_Transmit_Requests (NRF_USART);

      Tx_IRQ_Handler.Await_Transfer_Complete;
   end UART_Send_DMA_Data_Blocking;

   --  Private procedures and functions

   ----------------------
   -- Initialize_USART --
   ----------------------

   procedure Initialize_USART
   is
      Configuration : GPIO_Port_Configuration;
      USART_Pins    : constant GPIO_Points := NRF_RX & NRF_TX;
   begin
      Enable_Clock (USART_Pins);

      Configuration.Mode := Mode_AF;
      Configuration.Speed := Speed_25MHz;
      Configuration.Output_Type := Push_Pull;
      Configuration.Resistors := Pull_Up;

      Configure_IO
        (Points => USART_Pins,
         Config => Configuration);

      Configure_Alternate_Function
        (Points => USART_Pins,
         AF     => NRF_USART_AF);

      Enable_Clock (NRF_USART);
   end Initialize_USART;

   ---------------------
   -- Configure_USART --
   ---------------------

   procedure Configure_USART is
   begin
      Disable (NRF_USART);

      Set_Baud_Rate    (NRF_USART, 1_000_000);
      Set_Mode         (NRF_USART, Tx_Rx_Mode);
      Set_Stop_Bits    (NRF_USART, Stopbits_1);
      Set_Word_Length  (NRF_USART, Word_Length_8);
      Set_Parity       (NRF_USART, No_Parity);
      Set_Flow_Control (NRF_USART, No_Flow_Control);

      Enable (NRF_USART);
   end Configure_USART;

   --------------------
   -- Initialize_DMA --
   --------------------

   procedure Initialize_DMA is
      Configuration : DMA_Stream_Configuration;
   begin
      Enable_Clock (Controller);

      Configuration.Channel := Tx_Channel;
      Configuration.Direction := Memory_To_Peripheral;
      Configuration.Increment_Peripheral_Address := False;
      Configuration.Increment_Memory_Address := True;
      Configuration.Peripheral_Data_Format := Bytes;
      Configuration.Memory_Data_Format := Bytes;
      Configuration.Operation_Mode := Normal_Mode;
      Configuration.Priority  := Priority_Very_High;
      Configuration.FIFO_Enabled  := True;
      Configuration.FIFO_Threshold := FIFO_Threshold_Full_Configuration;
      Configuration.Memory_Burst_Size := Memory_Burst_Inc4;
      Configuration.Peripheral_Burst_Size := Peripheral_Burst_Inc4;

      Configure (Controller, Tx_Stream, Configuration);
      --  note the controller is disabled by the call to Configure
   end Initialize_DMA;

   --------------------------------
   -- Enable_USART_Rx_Interrupts --
   --------------------------------

   procedure Enable_USART_Rx_Interrupts is
   begin
      Enable_Interrupts (NRF_USART, Source => Received_Data_Not_Empty);
   end Enable_USART_Rx_Interrupts;

   -------------------------------
   -- Finalize_DMA_Transmission --
   -------------------------------

   procedure Finalize_DMA_Transmission (Transceiver : in out USART) is
      --  see static void USART_DMATransmitCplt
   begin
      loop
         exit when Status (Transceiver, Transmission_Complete_Indicated);
      end loop;
      Clear_Status (Transceiver, Transmission_Complete_Indicated);
      Disable_DMA_Transmit_Requests (Transceiver);
   end Finalize_DMA_Transmission;

   --  Tasks and protected objects

   --------------------
   -- Tx_IRQ_Handler --
   --------------------

   protected body Tx_IRQ_Handler is

      -----------------------------
      -- Await_Transfer_Complete --
      -----------------------------

      entry Await_Transfer_Complete when Transfer_Complete is
      begin
         Event_Occurred := False;
         Transfer_Complete := False;
      end Await_Transfer_Complete;

      -----------------
      -- IRQ_Handler --
      -----------------

      procedure IRQ_Handler is
      begin
         --  Transfer Error Interrupt management
         if Status (Controller, Tx_Stream, Transfer_Error_Indicated) then
            if Interrupt_Enabled
              (Controller, Tx_Stream, Transfer_Error_Interrupt)
            then
               Disable_Interrupt
                 (Controller, Tx_Stream, Transfer_Error_Interrupt);
               Clear_Status (Controller, Tx_Stream, Transfer_Error_Indicated);
               Event_Kind := Transfer_Error_Interrupt;
               Event_Occurred := True;
               return;
            end if;
         end if;

         --  FIFO Error Interrupt management.
         if Status (Controller, Tx_Stream, FIFO_Error_Indicated) then
            if Interrupt_Enabled
              (Controller, Tx_Stream, FIFO_Error_Interrupt)
            then
               Disable_Interrupt (Controller, Tx_Stream, FIFO_Error_Interrupt);
               Clear_Status (Controller, Tx_Stream, FIFO_Error_Indicated);
               Event_Kind := FIFO_Error_Interrupt;
               Event_Occurred := True;
               return;
            end if;
         end if;

         --  Direct Mode Error Interrupt management
         if Status (Controller, Tx_Stream, Direct_Mode_Error_Indicated) then
            if Interrupt_Enabled
              (Controller, Tx_Stream, Direct_Mode_Error_Interrupt)
            then
               Disable_Interrupt
                 (Controller, Tx_Stream, Direct_Mode_Error_Interrupt);
               Clear_Status
                 (Controller, Tx_Stream, Direct_Mode_Error_Indicated);
               Event_Kind := Direct_Mode_Error_Interrupt;
               Event_Occurred := True;
               return;
            end if;
         end if;

         --  Half Transfer Complete Interrupt management
         if Status
           (Controller, Tx_Stream, Half_Transfer_Complete_Indicated)
         then
            if Interrupt_Enabled
              (Controller, Tx_Stream, Half_Transfer_Complete_Interrupt)
            then
               if Double_Buffered (Controller, Tx_Stream) then
                  Clear_Status
                    (Controller, Tx_Stream, Half_Transfer_Complete_Indicated);
               else -- not double buffered
                  if not Circular_Mode (Controller, Tx_Stream) then
                     Disable_Interrupt
                       (Controller,
                        Tx_Stream,
                        Half_Transfer_Complete_Interrupt);
                  end if;
                  Clear_Status
                    (Controller, Tx_Stream, Half_Transfer_Complete_Indicated);
               end if;
               Event_Kind := Half_Transfer_Complete_Interrupt;
               Event_Occurred := True;
            end if;
         end if;

         --  Transfer Complete Interrupt management
         if Status (Controller, Tx_Stream, Transfer_Complete_Indicated) then
            if Interrupt_Enabled
              (Controller, Tx_Stream, Transfer_Complete_Interrupt)
            then
               if Double_Buffered
                 (Controller, Tx_Stream)
               then
                  Clear_Status
                    (Controller, Tx_Stream, Transfer_Complete_Indicated);
                  --  TODO: handle the difference between M0 and M1 callbacks
               else
                  if not Circular_Mode (Controller, Tx_Stream) then
                     Disable_Interrupt
                       (Controller, Tx_Stream, Transfer_Complete_Interrupt);
                  end if;
                  Clear_Status
                    (Controller, Tx_Stream, Transfer_Complete_Indicated);
               end if;
               Finalize_DMA_Transmission (NRF_USART);
               Event_Kind := Transfer_Complete_Interrupt;
               Event_Occurred := True;
               Transfer_Complete := True;
            end if;
         end if;
      end IRQ_Handler;

   end Tx_IRQ_Handler;

   --------------------
   -- Rx_IRQ_Handler --
   --------------------

   protected body Rx_IRQ_Handler is

      --------------------------
      -- Await_Byte_Reception --
      --------------------------

      entry Await_Byte_Reception (Rx_Byte : out T_Uint8)
        when Byte_Avalaible is
      begin
         Dequeue (Rx_Queue, Rx_Byte);
         Byte_Avalaible := not Is_Empty (Rx_Queue);
      end Await_Byte_Reception;

      -----------------
      -- IRQ_Handler --
      -----------------

      procedure IRQ_Handler is
         Received_Byte : T_Uint8;
      begin
         if Status (NRF_USART, Read_Data_Register_Not_Empty) then
            Received_Byte := T_Uint8 (Current_Input (NRF_USART) and 16#FF#);
            Clear_Status (NRF_USART, Read_Data_Register_Not_Empty);
            Enqueue (Rx_Queue, Received_Byte);
            Byte_Avalaible := True;
         elsif Status (NRF_USART, Overrun_Error_Indicated) then
            --  RM0090 rev11 top of p 1001: overrun is cleared by
            --  reading SR (which we've already done (twice, now?!)),
            --  then reading DR.
            --
            --  We got here because the DR was empty. The incoming
            --  character (the one that didn't make it from the shift
            --  register to the DR) is discarded. We assume the
            --  missing data can be recovered by higher-level
            --  protocols.
            Received_Byte := T_Uint8 (Current_Input (NRF_USART) and 16#FF#);
            Clear_Status (NRF_USART, Read_Data_Register_Not_Empty);
            Clear_Status (NRF_USART, Overrun_Error_Indicated);
         end if;
      end IRQ_Handler;

   end Rx_IRQ_Handler;

begin
   Disable_Interrupts (NRF_USART, Source => Received_Data_Not_Empty);
   Disable_DMA_Transmit_Requests (NRF_USART);
end UART_Syslink;
