with Syslink_Pack; use Syslink_Pack;
with Types; use Types;

package UART_Syslink is

   --  Procedures and functions

   procedure UART_Get_Data_With_Timeout
     (Rx_Byte      : out T_Uint8;
      Has_Suceed   : out Boolean);

private

   --  For testing purpose
   Counter : Positive := 1;

   function Get_Current_Byte (Counter : Positive) return T_Uint8;

end UART_Syslink;
