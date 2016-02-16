with Ada.Exceptions; use Ada.Exceptions;

package Last_Chance_Handler is

   procedure Last_Chance_Handler (Error : Exception_Occurrence);
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");
   pragma No_Return (Last_Chance_Handler);

end Last_Chance_Handler;
