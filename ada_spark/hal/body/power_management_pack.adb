with Ada.Unchecked_Conversion;

package body Power_Management_Pack is

   procedure Power_Management_Init is
   begin
      null;
   end Power_Management_Init;

   procedure Power_Management_Syslink_Update (Sl_Packet : Syslink_Packet) is
      subtype Power_Data is T_Uint8_Array (1 .. 9);
      function Syslink_Data_To_Power_Syslink_Info is
         new Ada.Unchecked_Conversion (Power_Data, Power_Syslink_Info);
   begin
      Current_Power_Info :=
        Syslink_Data_To_Power_Syslink_Info (Sl_Packet.Data (1 .. 9));

      --  Set the Power LEDs accordingly
      Set_Power_LEDs (Power_Management_Get_State);
   end Power_Management_Syslink_Update;

   function Power_Management_Get_State return Power_State is
      Current_State : Power_State;
      Is_Charging   : Boolean;
      Is_Pgood      : Boolean;
   begin
      Is_Charging := Current_Power_Info.Charging;
      Is_Pgood := Current_Power_Info.Pgood;

      if Is_Pgood and Is_Charging then
         Current_State := Charged;
      elsif Is_Charging then
         Current_State := Charging;
      else
         Current_State := Battery;
      end if;

      -- TODO: add the restant cases..
      return Current_State;
   end Power_Management_Get_State;

   procedure Set_Power_LEDs (State : Power_State) is
   begin
      case State is
         when Charging =>
            Set_LED (Charging_LED, True);
            Set_LED (Charged_LED, False);
         when Charged =>
            Set_LED (Charged_LED, True);
            Set_LED (Charging_LED, False);
         when Battery =>
            Set_LED (Charged_LED, False);
            Set_LED (Charging_LED, False);
         when others =>
            null;
      end case;
      --  TODO: find other led feedback for the other power states
   end Set_Power_LEDs;

   function Power_Management_Is_Discharging return Boolean is
      State : Power_State;
   begin
      State := Power_Management_Get_State;

      return State = Battery;
   end Power_Management_Is_Discharging;

end Power_Management_Pack;
