with CRC;
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

procedure CRC.Test is
   package Unsigned_32_IO is new Modular_IO (Interfaces.Unsigned_32);
   Check_String : constant String := "123456789";
   subtype Checkable_String is String (Check_String'Range);
   function For_Integer is new CRC.Make (Integer);
   function For_String is new CRC.Make (Checkable_String);
begin
   Unsigned_32_IO.Put (For_Integer (16#12345678#), Base => 16);
   Put_Line (", expected 16#AF6D87D2#");
   Unsigned_32_IO.Put (For_String (Check_String), Base => 16);
   Put_Line (", expected 16#CBF43926#");
end CRC.Test;
