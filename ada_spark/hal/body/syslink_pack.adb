with Text_IO; use Text_IO;
with Ada.Unchecked_Conversion;

package body Syslink_Pack is

   procedure Syslink_Init is
   begin
      null;
   end Syslink_Init;

   function Syslink_Test return BOol Is
   begin
      return 1;
   end Syslink_Test;

   procedure Syslink_Send_Packet (Sl_Packet : Syslink_Packet) is
      subtype Sl_Data_String is
        String (Syslink_Data'First .. Syslink_Data'Last);
      function Sl_Data_To_String is new Ada.Unchecked_Conversion
        (Source => Syslink_Data,
         Target => Sl_Data_String);
   begin
      --  For testing purpose, just print teh packet data
      Put_Line ("Packet.Length: " & T_Uint8'Image (Sl_Packet.Length));
      Put_Line ("Packet.Header: " & T_Uint8'Image (Sl_Packet.Data (1)));
      Put_Line ("Paket.Data: " & Sl_Data_To_String (Sl_Packet.Data));
   end Syslink_Send_Packet;

end Syslink_Pack;
