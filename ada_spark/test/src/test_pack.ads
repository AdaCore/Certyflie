with System;

package Test_Pack is

   procedure Queue_Test;

   procedure Radio_Link_Test;

   procedure Packet_Handler_Test;

   --  Used for testing only
   protected Printer is
      procedure Printer_Put_Line (Line : String);
      pragma Priority (System.Priority'Last);
   end Printer;

end Test_Pack;
