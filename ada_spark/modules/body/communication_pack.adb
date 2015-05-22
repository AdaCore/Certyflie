with Link_Interface_Pack; use Link_Interface_Pack;
with CRTP_Service_Pack; use CRTP_Service_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;
with Console_Pack; use Console_Pack;

package body Communication_Pack is

   procedure Communication_Init is
      Has_Succeed : Boolean;
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

      --  Test
      Console_Put_Line ("Hello, I'm the Crazyflie!", Has_Succeed);

      Is_Init := True;
   end Communication_Init;

end Communication_Pack;
