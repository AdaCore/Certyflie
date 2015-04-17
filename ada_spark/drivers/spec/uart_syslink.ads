with Types; use Types;

package UART_Syslink is

   --  Types

   subtype UART_TX_Buffer is T_Uint8_Array (1 .. 64);

   --  Procedures and functions

   --  Get data from UART controller
   procedure UART_Get_Data_With_Timeout
     (Rx_Byte      : out T_Uint8;
      Has_Suceed   : out Boolean);

   procedure UART_Send_Data_DMA_Blocking
     (Data_Size : T_Uint32;
      Data      : UART_TX_Buffer);

private

   --  For testing purpose
   Counter : Positive := 1;

   function Get_Current_Byte (Counter : Positive) return T_Uint8;

end UART_Syslink;
