with Ada.Text_IO; use Ada.Text_IO;

procedure Main is

   function Test (A : Integer) return Integer is
   begin
      return 10 / A;
   end Test;
begin
   Put_Line ("Dummy project to test build infrastructure...");

   --  Division by zero that will trigger some errors in codepeer
   Put_Line ("Test (0) :" & Test (0)'Img);
end Main;
