with Ada.Unchecked_Conversion;
with Types; use Types;

package body Memory_Pack is

   --  Public procedures and functions

   procedure Memory_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_MEM, Memory_CRTP_Handler'Access);

      Is_Init := True;
   end Memory_Init;

   function Memory_Test return Boolean is
   begin
      return Is_Init;
   end Memory_Test;

   --  Private procedures and functions

   procedure Memory_CRTP_Handler (Packet : CRTP_Packet) is
      function CRTP_Channel_To_Memory_Channel is new Ada.Unchecked_Conversion
        (CRTP_Channel, Memory_Channel);
      Channel : Memory_Channel;
   begin
      Channel := CRTP_Channel_To_Memory_Channel (Packet.Channel);

      case Channel is
         when MEM_SETTINGS_CH =>
            Memory_Settings_Process (Packet);
         when MEM_READ_CH =>
            null;
         when MEM_WRITE_CH =>
            null;
      end case;
   end Memory_CRTP_Handler;

   procedure Memory_Settings_Process (Packet : CRTP_Packet) is
      function T_Uint8_To_Memory_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Memory_Command);
      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);

      Command        : Memory_Command;
      Packet_Handler : CRTP_Packet_Handler;
      Has_Succeed    : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Memory_Command (Packet.Data_1 (1));

      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_MEM, Memory_Channel'Enum_Rep(MEM_SETTINGS_CH));
      CRTP_Append_T_Uint8_Data
        (Packet_Handler,
         Memory_Command'Enum_Rep (Command),
         Has_Succeed);

      case Command is
         when MEM_CMD_GET_NBR =>
            --  TODO: for now we just send 0 instead of the real number
            --  of One Wire memories + EEPROM memory.
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               0,
               Has_Succeed);
         when MEM_CMD_GET_INFO =>
            null;
      end case;

      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Packet_Handler),
         Has_Succeed);
   end Memory_Settings_Process;

end Memory_Pack;
