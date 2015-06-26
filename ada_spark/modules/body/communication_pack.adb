with Link_Interface_Pack; use Link_Interface_Pack;
with CRTP_Service_Pack; use CRTP_Service_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;
with Console_Pack; use Console_Pack;
with Log_Pack; use Log_Pack;

package body Communication_Pack is

   procedure Communication_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  Initialize the link layer (Radiolink by default in Config.ads)
      Link_Init;

      --  Initialize low and high level services
      CRTP_Service_Init;
      Platform_Service_Init;

      --  Initialize the console module
      Console_Init;

      --  initialize the log module.
      Log_Init;

      Is_Init := True;
   end Communication_Init;

   function Communication_Test return Boolean is
   begin
      return Is_Init;
   end Communication_Test;

end Communication_Pack;
