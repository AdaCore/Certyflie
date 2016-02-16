package body Last_Chance_Handler is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Error : Exception_Occurrence) is
      pragma Unreferenced (Error);
   begin
      loop
         null;
      end loop;
   end Last_Chance_Handler;

end Last_Chance_Handler;
