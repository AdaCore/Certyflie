with CRTP_Pack; use CRTP_Pack;

package body Parameter_Pack is

   --  Public procedures and functions

   procedure Parameter_Init is
   begin
      if Is_Init then
         return;
      end if;

      Is_Init := False;
   end Parameter_Init;

   function Parameter_Test return Boolean is
   begin
      return Is_Init;
   end Parameter_Test;

   --  Private procedures and functions

   procedure Parameter_CRTP_Handler (Packet : CRTP_Packet) is
      function CRTP_Channel_To_Parameter_Channel is
        new Ada.Unchecked_Conversion (CRTP_Channel, Parameter_Channel);

      Channel : Log_Channel;
   begin
      Channel := CRTP_Channel_To_Parameter_Channel (Packet.Channel);

      case Channel is
         when PARAM_TOC_CH =>
            null;
         when PARAM_READ_CH =>
            null;
         when PARAM_WRITE_CH =>
            null;
      end case;
   end Parameter_CRTP_Handler;

end Parameter_Pack;
