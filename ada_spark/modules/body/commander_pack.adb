with Crtp_Pack; use Crtp_Pack;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;
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
      Has_Succeed : Boolean;
      Commands    : Commander_Crtp_Values := (0.0, 0.0, 0.0, 0);

      type Four_Bytes_Array is array (1 .. 4) of T_Uint8;
      type Two_Bytes_Array is array (1 .. 2) of T_Uint8;
      function Four_Bytes_Array_To_Float is new Ada.Unchecked_Conversion
        (Four_Bytes_Array, T_Degrees);
      function Two_Bytes_Array_To_T_Uint16 is new Ada.Unchecked_Conversion
        (Two_Bytes_Array, T_Uint16);
   begin
      Crtp_Receive_Packet
        (Packet, CRTP_PORT_COMMANDER, Has_Succeed, Seconds (2));
      if Has_Succeed then
         Commands.Roll := Four_Bytes_Array_To_Float
           (Four_Bytes_Array (Packet.Data_1 (1 .. 4)));
         Commands.Pitch := Four_Bytes_Array_To_Float
           (Four_Bytes_Array (Packet.Data_1 (5 .. 8)));
         Commands.Yaw := Four_Bytes_Array_To_Float
           (Four_Bytes_Array (Packet.Data_1 (9 .. 12)));
         Commands.Thrust := Two_Bytes_Array_To_T_Uint16
           (Two_Bytes_Array (Packet.Data_1 (13 .. 14)));
      end if;
      Put_Line ("Roll: " & Float'Image (Commands.Roll));
      Put_Line ("Pitch: " & Float'Image (Commands.Pitch));
      Put_Line ("Yaw: " & Float'Image (Commands.Yaw));
      Put_Line ("Thrust: " & T_Uint16'Image (Commands.Thrust));
   end Print_Command;

end Commander_Pack;
