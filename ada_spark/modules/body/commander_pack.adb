with Safety_Pack; use Safety_Pack;
with Ada.Unchecked_Conversion;

package body Commander_Pack is

   --  Public procedures and functions

   procedure Commander_Init is
   begin
      if Is_Init then
         return;
      end if;

      Last_Update := Clock;
      CRTP_Register_Callback
        (CRTP_PORT_COMMANDER, Commander_CRTP_Handler'Access);

      Is_Init := True;
   end Commander_Init;

   function Commander_Test return Boolean is
   begin
      return Is_Init;
   end Commander_Test;

   procedure Commander_CRTP_Handler (Packet : CRTP_Packet) is
      Has_Succeed : Boolean;
      Tx_Packet   : CRTP_Packet;
      pragma Unreferenced (Has_Succeed);
   begin
      Side := not Side;
      Target_Val (Side) := Get_Commands_From_Packet (Packet);

      if Target_Val (Side).Thrust = 0 then
         Thrust_Locked := False;
      end if;

      Commander_Watchdog_Reset;
   end Commander_CRTP_Handler;

   procedure Commander_Get_RPY
     (Euler_Roll_Desired  : in out T_Degrees;
      Euler_Pitch_Desired : in out T_Degrees;
      Euler_Yaw_Desired   : in out T_Degrees) is
      Used_Side : Boolean;
   begin
      --  To prevent the change of Side value when this is called
      Used_Side := Side;

      Euler_Roll_Desired := Target_Val (Used_Side).Roll;
      Euler_Pitch_Desired := Target_Val (Used_Side).Pitch;
      Euler_Yaw_Desired := Target_Val (Used_Side).Yaw;
   end Commander_Get_RPY;

   procedure Commander_Get_RPY_Type
     (Roll_Type  : in out RPY_Type;
      Pitch_Type : in out RPY_Type;
      Yaw_Type   : in out RPY_Type) is
   begin
      Roll_Type := ANGLE;
      Pitch_Type := ANGLE;
      Yaw_Type := RATE;
   end Commander_Get_RPY_Type;

   procedure Commander_Get_Thrust (Thrust : out T_Uint16) is
      Raw_Thrust : T_Uint16;
   begin
      Raw_Thrust := Target_Val (Side).Thrust;

      if Thrust_Locked then
         Thrust := 0;
      else
         Thrust := Saturate (Raw_Thrust, 0, MAX_THRUST);
      end if;

      Commander_Watchdog;
   end Commander_Get_Thrust;

   procedure Commander_Get_Alt_Hold
     (Alt_Hold        : out bool;
      Set_Alt_Hold    : out Bool;
      Alt_Hold_Change : out Float) is
   begin
      Alt_Hold := Boolean'Enum_Rep (Alt_Hold_Mode);
      Set_Alt_Hold :=
        Boolean'Enum_Rep (Alt_Hold_Mode and not Alt_Hold_Mode_Old);
      Alt_Hold_Change :=
        (if Alt_Hold_Mode then
           (Float (Target_Val (Side).Thrust) - ALT_HOLD_THRUST_F)
           / ALT_HOLD_THRUST_F
         else
            0.0);
      Alt_Hold_Mode_Old := Alt_Hold_Mode;
   end Commander_Get_Alt_Hold;

   --  Private procedures and functions

   procedure Commander_Watchdog_Reset is
   begin
      Last_Update := Clock;
   end Commander_Watchdog_Reset;

   procedure Commander_Watchdog is
      Used_Side : Boolean;
      Time_Since_Last_Update : Time_Span;
   begin
      --  To prevent the change of Side value when this is called
      Used_Side := Side;

      Time_Since_Last_Update := Commander_Get_Inactivity_Time;

      if Time_Since_Last_Update > COMMANDER_WDT_TIMEOUT_STABILIZE then
         Target_Val (Used_Side).Roll := 0.0;
         Target_Val (Used_Side).Pitch := 0.0;
         Target_Val (Used_Side).Yaw := 0.0;
      end if;

      if Time_Since_Last_Update > COMMANDER_WDT_TIMEOUT_SHUTDOWN then
         Target_Val (Used_Side).Thrust := 0;
         -- TODO: set the alt hold mode variable to false
         Alt_Hold_Mode := False;
         Is_Inactive := True;
         Thrust_Locked := True;
      else
         Is_Inactive := False;
      end if;
   end Commander_Watchdog;

   function Get_Commands_From_Packet
     (Packet : CRTP_Packet) return Commander_CRTP_Values is
      Commands     : Commander_CRTP_Values := (0.0, 0.0, 0.0, 0);
      Handler      : CRTP_Packet_Handler;
      Has_Succeed  : Boolean;
   begin
      Handler := CRTP_Get_Handler_From_Packet (Packet);

      CRTP_Get_Float_Data (Handler, 1, Commands.Roll, Has_Succeed);
      CRTP_Get_Float_Data (Handler, 5, Commands.Pitch, Has_Succeed);
      CRTP_Get_Float_Data (Handler, 9, Commands.Yaw, Has_Succeed);
      CRTP_Get_T_Uint16_Data (Handler, 13, Commands.Thrust, Has_Succeed);

      return Commands;
   end Get_Commands_From_Packet;

end Commander_Pack;
