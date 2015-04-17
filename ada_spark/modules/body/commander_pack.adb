with Crtp_Pack; use Crtp_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Protected_IO_Pack; use Protected_IO_Pack;
with Ada.Unchecked_Conversion;

package body Commander_Pack is

   task body Get_Command_Task is
   begin
      loop
         Print_Command;
      end loop;
   end Get_Command_Task;

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

   procedure Print_Command is
      Packet      : Crtp_Packet;
      Handler     : Crtp_Packet_Handler;
      Has_Succeed : Boolean;
      Commands    : Commander_Crtp_Values := (0.0, 0.0, 0.0, 0);
      procedure Crtp_Get_Float_Data is new Crtp_Get_Data (Float);
      procedure Crtp_Get_T_Uint16_Data is new Crtp_Get_Data (T_Uint16);
   begin
      Crtp_Receive_Packet
        (Packet, CRTP_PORT_COMMANDER, Has_Succeed, Milliseconds (100));

      if Has_Succeed then
         Handler := Crtp_Get_Handler (Packet);
         Crtp_Get_Float_Data (Handler, 1, Commands.Roll, Has_Succeed);
         Crtp_Get_Float_Data (Handler, 5, Commands.Pitch, Has_Succeed);
         Crtp_Get_Float_Data (Handler, 9, Commands.Yaw, Has_Succeed);
         Crtp_Get_T_Uint16_Data (Handler, 13, Commands.Thrust, Has_Succeed);

         X_Put_Line ("Roll: " & Float'Image (Commands.Roll));
         X_Put_Line ("Pitch: " & Float'Image (Commands.Pitch));
         X_Put_Line ("Yaw: " & Float'Image (Commands.Yaw));
         X_Put_Line ("Thrust: " & T_Uint16'Image (Commands.Thrust));
      end if;
   end Print_Command;

end Commander_Pack;
