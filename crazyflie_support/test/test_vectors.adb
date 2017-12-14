pragma Assertion_Policy (Check);

with Generic_Vectors;
with Ada.Assertions;

procedure Test_Vectors is
   package Vectors is new Generic_Vectors (Integer);
   subtype Vector is Vectors.Vector (Capacity => 10);
   V : Vector;
begin
   pragma Assert (V.Length = 0, "initial length not 0");
   V.Append (42);
   pragma Assert (V.Length = 1, "length not 1");
   pragma Assert (V.Element (0) = 42, "element (0) not 42");
   pragma Assert (V.Element_Access (0).all = 42, "element_access (0) not 42");
   declare
      Value : Integer := 0;
   begin
      Value := V.Element (1);
      pragma Assert (False, "element (1) should have failed");
   exception
      when Ada.Assertions.Assertion_Error => null;
   end;
   declare
      Value : Integer := 0;
   begin
      Value := V.Element_Access (1).all;
      pragma Assert (False, "element_access (1) should have failed");
   exception
      when Ada.Assertions.Assertion_Error => null;
   end;
   V.Clear;
   pragma Assert (V.Length = 0, "cleared length not 0");
   for J in 1 .. V.Capacity loop
      V.Append (J);
   end loop;
   pragma Assert (V.Length = V.Capacity, "full length not capacity");
   begin
      V.Append (42);
      pragma Assert (False, "append when full should have failed");
   exception
      when Ada.Assertions.Assertion_Error => null;
   end;
   for J in 1 .. V.Capacity loop
      null;
      pragma Assert (V.Element (J - 1) = J,
                     "element (j - 1) /= j");
      pragma Assert (V.Element_Access (J - 1).all = J,
                     "element_access (j - 1) /= j");
   end loop;
end Test_Vectors;
