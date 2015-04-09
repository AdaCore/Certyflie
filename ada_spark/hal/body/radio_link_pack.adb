with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;

package body Radio_Link_Pack is

   function Radio_Link_Send_Packet (Packet : Crtp_Packet) return Boolean is
      subtype String_Of_Data_Length is String (1 .. Packet.Data'Length);
      function Data_To_String is new Ada.Unchecked_Conversion
        (Crtp_Data, String_Of_Data_Length);
   begin
      --  For testing purpose, we just print teh message we want to send
      --  on the console.
      Put_Line (Data_To_String (Packet.Data));
      return True;
   end Radio_Link_Send_Packet;

end Radio_Link_Pack;
