
with Ada.Unchecked_Conversion;
with Ada.Interrupts.Names; use Ada.Interrupts.Names;
with STM32F4; use STM32F4;
with STM32F4.DMA; use STM32F4.DMA;
with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F4.USARTs; use STM32F4.USARTs;
with STM32F4_Discovery; use STM32F4_Discovery;
with Ada.Real_Time; use Ada.Real_Time;

with Types; use Types;

package UART_Syslink is

   --  Types

   subtype DMA_Data is T_Uint8_Array (1 .. 64);

   type USART_Error is
     (No_Err, Parity_Err, Framing_Err, Noise_Err, Overrun_Err);

   --  Procedures and functions

   --  Initialize the UART Syslink interface
   procedure UART_Syslink_Init;

   --  Get one byte of data from UART, with a defined timeout
   procedure UART_Get_Data_Blocking (Rx_Byte : out T_Uint8);

   --  Send data to DMA
   procedure UART_Send_DMA_Data_Blocking
     (Data_Size : Natural;
      Data      : DMA_Data);

private

   --  Global variables and constants

   IO_Port : GPIO_Port renames GPIO_C;

   Transceiver : USART renames USART_6;
   Transceiver_AF : constant GPIO_Alternate_Function := GPIO_AF_USART6;

   TX_Pin : constant GPIO_Pin := Pin_6;
   RX_Pin : constant GPIO_Pin := Pin_7;

   Controller : DMA_Controller renames DMA_2;

   Tx_Channel : constant DMA_Channel_Selector := Channel_5;
   Tx_Stream : constant DMA_Stream_Selector := Stream_6;

   DMA_Tx_IRQ : constant Ada.Interrupts.Interrupt_Id := DMA2_Stream6_Interrupt;
   -- must match that of the selected controller and stream number!!!!

   Bytes_To_Transfer : constant := DMA_Data'Length;

   Source_Block  : aliased DMA_Data := (others => 0);

   Event_Kind : DMA_Interrupt;

   UART_RX_QUEUE_SIZE : constant := 40;
   UART_DATA_TIMEOUT_MS : constant Time_Span :=  Milliseconds (1_000);

   --  Procedures and functions

   --  Convert 16-Bit word to T_Uint8
   function Half_Word_To_T_Uint8 is
     new Ada.Unchecked_Conversion (Half_Word, T_Uint8);

   --  Convert T_Uint8 to 16-Bit words
   function T_Uint8_To_Half_Word is
     new Ada.Unchecked_Conversion (T_Uint8, Half_Word);

   --  Initialize the STM32F4 USART controller
   procedure Initialize_USART;

   --  Configure the STM32F4 USART controller
   procedure Configure_USART;

   --  Initialize the STM32F4 DMA controller
   procedure Initialize_DMA;

   --  Enable USART interrupts in reception
   procedure Enable_USART_Rx_Interrupts;

   --  Tasks and protected objects

   --  DMA Interrupt Handler for transmission
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

   --  Interrupt Handler for reception (DMA not used here)
   protected Rx_IRQ_Handler is
      pragma Interrupt_Priority;

      entry Await_Byte_Reception (Rx_Byte : out T_Uint8);

   private

      Byte_Avalaible : Boolean := False;
      Received_Byte  : T_Uint8;

      procedure IRQ_Handler;
      pragma Attach_Handler (IRQ_Handler, USART6_Interrupt);
   end Rx_IRQ_Handler;

end UART_Syslink;
