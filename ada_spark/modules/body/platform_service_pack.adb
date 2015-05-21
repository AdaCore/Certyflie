with Syslink_Pack; use Syslink_Pack;

package body Platform_Service_Pack is

   procedure Platform_Service_Init is
   begin
      if Is_Init then
         return;
      end if;

      Crtp_Register_Callback (CRTP_PORT_PLATFORM,
                              Platform_Service_Handler'Access);

      Is_Init := True;
   end Platform_Service_Init;


   function Platform_Service_Test return Boolean is
   begin
      return Is_Init;
   end Platform_Service_Test;

   procedure Platform_Service_Handler (Packet : Crtp_Packet) is
      Has_Succeed : Boolean;
   begin
      case Packet.Channel is
         when Platform_Channel'Enum_Rep (PLAT_COMMAND) =>
            Platform_Command_Process
              (Packet.Data_1 (1), Packet.Data_1 (2 .. Packet.Data_1'Last));
            Crtp_Send_Packet (Packet, Has_Succeed);
         when others =>
            null;
      end case;
   end Platform_Service_Handler;

   procedure Platform_Command_Process
     (Command : T_Uint8;
      Data    : T_Uint8_Array) is
      Sl_Packet : Syslink_Packet;
   begin
      case Command is
         when Platform_Command'Enum_Rep (SET_CONTINUOUS_WAVE) =>
            Sl_Packet.Slp_Type := SYSLINK_RADIO_CONTWAVE;
            Sl_Packet.Length := 1;
            Sl_Packet.Data (1) := Data (Data'First);
            Syslink_Send_Packet (Sl_Packet);
         when others =>
            null;
      end case;
   end Platform_Command_Process;

   end Platform_Service_Pack;
