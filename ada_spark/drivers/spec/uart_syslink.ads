with Types; use Types;
with STM32F4_Discovery; use STM32F4_Discovery;
with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F4.USARTs; use STM32F4.USARTs;
with STM32F4; use STM32F4;
with Ada.Unchecked_Conversion;

package UART_Syslink is

   --  Types

   subtype UART_TX_Buffer is T_Uint8_Array (1 .. 64);

   --  Procedures and functions

   --  Initialize the GPIO port for UART
   procedure Init_IO;

   --  Initialize the UART controller
   procedure Init_UART;

   --  Get data from UART controller
   procedure UART_Get_Data
     (Rx_Byte      : out T_Uint8;
      Has_Succeed   : out Boolean);

   procedure UART_Send_Data
     (Data_Size : Natural;
      Data      : UART_TX_Buffer);

private

   --  Global variables and constants

   UART_Port      : USART renames STM32F4_Discovery.USART_6;
   UART_GPIO_Port : GPIO_Port renames STM32F4_Discovery.GPIO_C;
   Tx_GPIO_Pin : constant GPIO_Pin := Pin_6;
   Rx_GPIO_Pin : constant GPIO_Pin := Pin_7;
   UART_AF     : constant GPIO_Alternate_Function := GPIO_AF_USART6;

   Mask : constant := 16#FF#;

   --  Procedures and functions

   --  Convert 16-Bit word to T_Uint8
   function Half_Word_To_T_Uint8 is
     new Ada.Unchecked_Conversion (Half_Word, T_Uint8);

   --  Convert T_Uint8 to 16-Bit words
   function T_Uint8_To_Half_Word is
     new Ada.Unchecked_Conversion (T_Uint8, Half_Word);

   --  For testing purpose
   Counter : Positive := 1;

   function Get_Current_Byte (Counter : Positive) return T_Uint8;

end UART_Syslink;
