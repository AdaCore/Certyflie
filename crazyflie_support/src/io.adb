with HAL;

with STM32.Board;
with STM32.Device;
with STM32.GPIO;
with STM32.USARTs;

with System;

package body IO
is

   protected Buffer is
      procedure Put (C : Character);
      entry Get (C : out Character);
   private
      Ready : Boolean := False;
      Count : Natural := 0;
      Buf : String (1 .. 256);
      Read_Index : Positive := 1;
      Write_Index : Positive := 1;
   end Buffer;

   --  Uses PC10 (TX), PC11 (RX).
   USART : STM32.USARTs.USART
     renames STM32.Board.EXT_USART1;
   Alternate_Function : STM32.GPIO_Alternate_Function
     renames STM32.Board.EXT_USART1_AF;
   Tx_Point : STM32.GPIO.GPIO_Point
     renames STM32.Board.EXT_USART1_TX;
   Rx_Point : STM32.GPIO.GPIO_Point
     renames STM32.Board.EXT_USART1_RX;

   procedure Put (C : Character) is
   begin
      Buffer.Put (C);
   end Put;

   procedure Put (S : String) is
   begin
      for C of S loop
         Put (C);
      end loop;
   end Put;

   procedure Put_Line (S : String) is
   begin
      for C of S loop
         Put (C);
      end loop;
      New_Line;
   end Put_Line;

   procedure New_Line is
   begin
      Put (ASCII.CR);
      Put (ASCII.LF);
   end New_Line;

   procedure Get (C : out Character) is
   begin
      while not STM32.USARTs.Rx_Ready (USART) loop
         null;
      end loop;
      C := Character'Val (STM32.USARTs.Current_Input (USART));
   end Get;

   protected body Buffer is
      procedure Put (C : Character) is
      begin
         if Count < Buf'Length then
            Buf (Write_Index) := C;
            Write_Index := (if Write_Index = Buf'Last
                            then Buf'First
                            else Write_Index + 1);
            Count := Count + 1;
            Ready := True;
         end if;
      end Put;
      entry Get (C : out Character) when Ready is
      begin
         C := Buf (Read_Index);
         Read_Index := (if Read_Index = Buf'Last
                        then Buf'First
                        else Read_Index + 1);
         Count := Count - 1;
         Ready := Count > 0;
      end Get;
   end Buffer;

   task Output with Priority => System.Priority'First + 1;

   task body Output is
      C : Character;
   begin
      loop
         Buffer.Get (C);
         while not STM32.USARTs.Tx_Ready (USART) loop
            null;
         end loop;
         STM32.USARTs.Transmit (USART, HAL.UInt9 (Character'Pos (C)));
      end loop;
   end Output;

   procedure Initialize_USART;
   procedure Configure_USART;

   procedure Initialize_USART is
      use STM32.GPIO;
   begin
      STM32.Device.Enable_Clock (Rx_Point & Tx_Point);

      Configure_IO (Rx_Point,
                    Config => (Mode => Mode_AF,
                               Output_Type => Open_Drain,
                               Speed => Speed_25MHz,
                               Resistors => Pull_Up));

      Configure_IO (Tx_Point,
                    Config => (Mode => Mode_AF,
                               Output_Type => Push_Pull,
                               Speed => Speed_25MHz,
                               Resistors => Pull_Up));

      Configure_Alternate_Function (Rx_Point & Tx_Point,
                                    AF => Alternate_Function);

      STM32.Device.Enable_Clock (USART);
   end Initialize_USART;

   procedure Configure_USART is
      use STM32.USARTs;
   begin
      Disable (USART);

      Set_Baud_Rate    (USART, 115_200);
      Set_Mode         (USART, Tx_Rx_Mode);
      Set_Stop_Bits    (USART, Stopbits_1);
      Set_Word_Length  (USART, Word_Length_8);
      Set_Parity       (USART, No_Parity);
      Set_Flow_Control (USART, No_Flow_Control);

      Enable (USART);
   end Configure_USART;

begin
   Initialize_USART;
   Configure_USART;
end IO;
