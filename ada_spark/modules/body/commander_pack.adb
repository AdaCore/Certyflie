with Protected_IO_Pack; use Protected_IO_Pack;
with Ada.Unchecked_Conversion;

package body Commander_Pack is

   procedure Commander_Init is
   begin
      if Is_Init then
         return;
      end if;

      Crtp_Register_Callback
        (CRTP_PORT_COMMANDER, Commander_Crtp_Handler'Access);
   end Commander_Init;

   function Commander_Test return Boolean is
   begin
      return Is_Init;
   end Commander_Test;

   procedure Commander_Crtp_Handler (Packet : Crtp_Packet) is
   begin
      Side := not Side;
      Target_Val (Side) := Get_Commands_From_Packet (Packet);

      if Target_Val (Side).Thrust = 0 then
         Thrust_Locked := False;
      end if;

      --  TODO: reset the watchdog and remove this test function
      Print_Commands (Target_Val (Side));
   end Commander_Crtp_Handler;

   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : in out T_Degrees;
      Euler_Pitch_Desired : in out T_Degrees;
      Euler_Yaw_Desired   : in out T_Degrees) is
      procedure Commander_Get_RPY_Wrapper
        (Euler_Roll_Desired  : in out Float;
         Euler_Pitch_Desired : in out Float;
         Euler_Yaw_Desired   : in out Float);
      pragma Import (C, Commander_Get_RPY_Wrapper, "commanderGetRPY");
   begin
      Commander_Get_RPY_Wrapper
        (Euler_Roll_Desired,
         Euler_Pitch_Desired,
         Euler_Yaw_Desired);
      --  TODO: Smooth commands to have a better control
   end Commander_Get_RPY;

   function Get_Commands_From_Packet
     (Packet : Crtp_Packet) return Commander_Crtp_Values is
      Commands     : Commander_Crtp_Values := (0.0, 0.0, 0.0, 0);
      Handler      : Crtp_Packet_Handler;
      Has_Succeed  : Boolean;
   begin
      Handler := Crtp_Get_Handler_From_Packet (Packet);

      Crtp_Get_Float_Data (Handler, 1, Commands.Roll, Has_Succeed);
      Crtp_Get_Float_Data (Handler, 5, Commands.Pitch, Has_Succeed);
      Crtp_Get_Float_Data (Handler, 9, Commands.Yaw, Has_Succeed);
      Crtp_Get_T_Uint16_Data (Handler, 13, Commands.Thrust, Has_Succeed);

      return Commands;
   end Get_Commands_From_Packet;

   procedure Print_Commands (Commands : Commander_Crtp_Values) is

   begin
      X_Put_Line ("Roll: " & Float'Image (Commands.Roll));
      X_Put_Line ("Pitch: " & Float'Image (Commands.Pitch));
      X_Put_Line ("Yaw: " & Float'Image (Commands.Yaw));
      X_Put_Line ("Thrust: " & T_Uint16'Image (Commands.Thrust));
   end Print_Commands;

end Commander_Pack;
