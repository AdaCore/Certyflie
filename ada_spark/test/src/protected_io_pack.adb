with Ada.Text_IO; use Ada.Text_IO;

package body Protected_IO_Pack is

   procedure Initialize is
   begin
      Set_True (Nobody_Printing);
   end Initialize;

   procedure X_Put_Line (Line : String) is
   begin
      Suspend_Until_True (Nobody_Printing);
      Put_Line (Line);
      Set_True (Nobody_Printing);
   end X_Put_Line;

end Protected_IO_Pack;
