package body Platform_Service_Pack is

   procedure Platform_Service_Init is
   begin
      if Is_Init then
         return;
      end if;
      Is_Init := True;
   end Platform_Service_Init;


   function Platform_Service_Test return Boolean is
   begin
      return Is_Init;
   end Platform_Service_Test;

end Platform_Service_Pack;
