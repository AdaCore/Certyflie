------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2017, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Ada.Real_Time;               use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

with STM32.Board;                 use STM32.Board;

package LEDS is

   subtype Crazyflie_LED is User_LED;
   LED_Blue_L  : Crazyflie_LED renames STM32.Board.LED_Blue_L;
   LED_Green_L : Crazyflie_LED renames STM32.Board.LED_Green_L;
   LED_Green_R : Crazyflie_LED renames STM32.Board.LED_Green_R;
   LED_Red_L   : Crazyflie_LED renames STM32.Board.LED_Red_L;
   LED_Red_R   : Crazyflie_LED renames STM32.Board.LED_Red_R;

   type Battery_State is
     (Initial_State,
      On_Battery,
      Low_Power,
      Charging,
      Charged);

   type System_State is
     (Initial_State,
      Self_Test,
      Calibrating,
      Failure,
      Ready,
      Connected);

   type Link_State is
     (Initial_State,
      Not_Connected,
      Connected);

   subtype Valid_System_State is System_State range Self_Test .. Connected;
   subtype Valid_Battery_State is Battery_State range On_Battery .. Charged;
   subtype Valid_Link_State is Link_State range Not_Connected .. Connected;

   --  Initialize the Crazyflie LEDs.
   procedure LEDS_Init;

   --  Test if the LEDs are initialized.
   function LEDS_Test return Boolean;

   --  Enables the LED if Value = True, disables if Value = False.
   procedure Set_LED (LED : in out Crazyflie_LED; Value : Boolean);

   --  Whether the LED is lid or off
   function LED_Set (LED : Crazyflie_LED) return Boolean
     renames STM32.Board.Is_On;

   procedure Toggle_LED (LED : in out Crazyflie_LED)
                         renames STM32.Board.Toggle_LED;

   --  Switch off all the Crazyflie LEDs.
   procedure Reset_All_LEDs;

   procedure Set_System_State (State : Valid_System_State);
   procedure Set_Battery_State (State : Valid_Battery_State);
   procedure Set_Battery_Level (Level : Natural);
   procedure Set_Link_State (State : Valid_Link_State);

   function Get_System_State return System_State;
   function Get_Battery_State return Battery_State;

   --  Support flashing an LED (for example, to indicate that a
   --  packet has been received from the controller).

   type Flasher (The_LED : not null access Crazyflie_LED)
     is tagged limited private;

   procedure Set (The_Flasher : in out Flasher);
   --  Lights the associated LED for 5 ms.

private

   Is_Initialized : Boolean := False;

   --  An LED animation targets a specific LED and switches it on/off according
   --  to its blink period.
   type LED_Animation is new Timing_Event with record
      LED          : Crazyflie_LED;
      Blink_Period : Duration;
   end record;

   --  The individual LED animations corresponding to the various individual
   --  values of Crazyflie_LED_Status. A period of zero represents constant
   --  "on" rather than blinking.
   System_Animations : array (Valid_System_State) of LED_Animation :=
                         (Self_Test   => (Timing_Event with LED_Red_R, 0.1),
                          Calibrating => (Timing_Event with LED_Green_R, 0.1),
                          Failure     => (Timing_Event with LED_Red_R, 0.0),
                          Ready       => (Timing_Event with LED_Green_R, 0.5),
                          Connected   => (Timing_Event with LED_Green_R, 0.0));

   Battery_Animations : array (Valid_Battery_State) of LED_Animation :=
                          (On_Battery => (Timing_Event with LED_Blue_L, 3.0),
                           Low_Power  => (Timing_Event with LED_Red_L, 0.5),
                           Charging   => (Timing_Event with LED_Blue_L, 0.5),
                           Charged    => (Timing_Event with LED_Blue_L, 0.0));

   --  The package global for the status that determines which LEDs are active.
   --  Controlled by procedure Enable_LED_Status.
   Current_System_Status  : System_State := Initial_State;
   Current_Battery_Status : Battery_State := Initial_State;
   Current_Link_Status    : Link_State := Initial_State;

   --  The PO containing the handler for blinking the LEDs corresponding to the
   --  value of Current_LED_Status. The handler is passed an LED_Animation
   --  value that is derived from type Timing_Event.
   protected LED_Status_Event_Handler is
      pragma Interrupt_Priority;

      --  Toggles the animation's LED and sets itself as the handler for
      --  the next expiration occurrence. We must use this formal parameter
      --  type (the "base class") for the sake of compatibility with the
      --  Timing_Event_Handler procedure pointer, but the object passed will be
      --  of type LED_Animation, derived from Timing_Event and thus compatible
      --  as an actual parameter.
      procedure Toggle_LED_Status (Event : in out Timing_Event);

   end LED_Status_Event_Handler;

   type Flasher (The_LED : not null access Crazyflie_LED)
     is new Ada.Real_Time.Timing_Events.Timing_Event with null record;

end LEDS;
