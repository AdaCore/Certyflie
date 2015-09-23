
with Ada.Real_Time; use Ada.Real_Time;

with Types; use Types;
with Config; use Config;
with Syslink_Pack; use Syslink_Pack;
with LEDS_Pack; use LEDS_Pack;

package Power_Management_Pack is

   --  Types

   --  Type reperesenting the current power state.
   type Power_State is (Battery, Charging, Charged, Low_Power, Shut_Down);

   --  Type representing the current charge state.
   type Power_Charge_State is (Charge_100_MA, Charge_500_MA, Charge_MAX);

   --  Types used for Syslink packet translation.
   type Power_Syslink_Info_Repr is (Normal, Flags_Detailed);

   --  Type representing a syslink packet containing power information.
   type Power_Syslink_Info (Repr : Power_Syslink_Info_Repr := Normal) is record
      case Repr is
         when Normal =>
            Flags            : T_Uint8;
            V_Bat_1          : Float;
            Current_Charge_1 : Float;
         when Flags_Detailed =>
            Pgood            : Boolean;
            Charging         : Boolean;
            Unused           : T_Uint6;
            V_Bat_2          : Float;
            Current_Charge_2 : Float;
      end case;
   end record;

   pragma Unchecked_Union (Power_Syslink_Info);
   for Power_Syslink_Info'Size use 72;
   pragma Pack (Power_Syslink_Info);

   --  Procedures and functions

   --  Initialize the power management module.
   procedure Power_Management_Init;

   --  Update the power state information.
   procedure Power_Management_Syslink_Update (Sl_Packet : Syslink_Packet);

   --  Return True is the Crazyflie is discharging, False when it's charging.
   function Power_Management_Is_Discharging return Boolean;

   --  Get the current battery voltage.
   function Power_Management_Get_Battery_Voltage return Float;

private

   --  Global variables and constants

   --  Current power information received from nrf51
   --  and current power state.
   Current_Power_Info  : Power_Syslink_Info;
   Current_Power_State : Power_State;

   --  Current battery voltage, and it's min and max values.
   Battery_Voltage          : Float;
   Battery_Voltage_Min      : Float := 6.0;
   Battery_Voltage_Max      : Float := 0.0;
   Battery_Low_Time_Stamp   : Time;

   --  LEDs to switch on according power state.
   Charging_LED  : constant Crazyflie_LED := LED_Blue_L;
   Charged_LED   : constant Crazyflie_LED := LED_Green_L;
   Low_Power_Led : constant Crazyflie_LED := LED_Red_L;

   --  Constants used to detect when the battery is low.
   PM_BAT_LOW_VOLTAGE : constant := 3.2;
   PM_BAT_LOW_TIMEOUT : constant Time_Span := Seconds (5);

   --  Constants used to know the charge percentage of the battery.
   Bat_671723HS25C : constant array (1 .. 10) of Float :=
                       (
                        3.00, --   00%
                        3.78, --   10%
                        3.83, --   20%
                        3.87, --   30%
                        3.89, --   40%
                        3.92, --   50%
                        3.96, --   60%
                        4.00, --   70%
                        4.04, --   80%
                        4.10  --   90%
                       );

   --  Procedures and functions

   --  Set the battery voltage and its min and max values.
   procedure Power_Management_Set_Battery_Voltage (Voltage : Float);

   --  Return a number From 0 To 9 Where 0 is completely Discharged
   --  and 9 is 90% charged.
   function Power_Management_Get_Charge_From_Voltage
     (Voltage : Float) return Integer;

   --  Get the power state for the given power information received from
   --  the nrf51.
   function Power_Management_Get_State
     (Power_Info : Power_Syslink_Info) return Power_State;

   --  Switch on/off the power related leds according to power state.
   procedure Set_Power_LEDs (State : Power_State);

   --  Tasks and protected objects

   task Power_Management_Task is
      pragma Priority (PM_TASK_PRIORITY);
   end Power_Management_Task;

end Power_Management_Pack;
