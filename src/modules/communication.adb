with Link_Interface; use Link_Interface;
with CRTP_Service; use CRTP_Service;
with Platform_Service; use Platform_Service;
with Console; use Console;

package body Communication is

   procedure Communication_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  Initialize the link layer (Radiolink by default in Config.ads).
      Link_Init;

      --  Initialize low and high level services.
      CRTP_Service_Init;
      Platform_Service_Init;

      --  Initialize the console module.
      Console_Init;

      Is_Init := True;
   end Communication_Init;

   function Communication_Test return Boolean is
   begin
      return Is_Init;
   end Communication_Test;

end Communication;
