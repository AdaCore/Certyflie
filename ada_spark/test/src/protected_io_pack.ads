with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

package Protected_IO_Pack is

   --  Used for testing only
   procedure Initialize;
   procedure X_Put_Line (Line : String);

private
   Nobody_Printing : Suspension_Object;

end Protected_IO_Pack;
