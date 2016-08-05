------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
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

   --  This type is used to represent the possible Crazyflie states for the
   --  on-board LEDs to indicate. Each status has at least one corresponding
   --  LED. A given state's LEDs are animated, in that they can either blink
   --  or be constantly enabled. The current animations cease when the status
   --  changes, and new animations are then enabled for the new status.
   type Crazyflie_LED_Status is
     (Ready_To_Fly,
      Calibrating,
      Charging_Battery,
      Low_Power_Battery,
      Self_Test_Fail);

   --  Initialize the Crazyflie LEDs.
   procedure LEDS_Init;

   --  Test if the LEDs are initialized.
   function LEDS_Test return Boolean;

   --  Enables the LED if Value = True, disables if Value = False.
   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean);

   procedure Toggle_LED (LED : Crazyflie_LED);

   --  Switch off all the Crazyflie LEDs.
   procedure Reset_All_LEDs;

   --  Sets the specified Crazyflie LED status and activates the LED (or
   --  LEDs) corresponding to this new status. All LEDs for the previous status
   --  become disabled.
   procedure Enable_LED_Status (LED_Status : Crazyflie_LED_Status);

   function Get_Current_LED_Status return Crazyflie_LED_Status;

private

   Is_Initialized : Boolean := False;

   --  An LED animation targets a specific LED and switches it on/off according
   --  to its blink period.
   type LED_Animation is new Timing_Event with record
      LED          : Crazyflie_LED;
      Blink_Period : Time_Span;
   end record;

   --  A representation for a collection or "group" of animations, so that a
   --  given Crazyflie_LED_Status value can involve multiple LEDs if desired.
   type LED_Animation_Group is array (Positive range <>) of LED_Animation;

   --  The individual LED animations corresponding to the various individual
   --  values of Crazyflie_LED_Status. A period of zero represents constant
   --  "on" rather than blinking.

   Ready_To_Fly_Group : aliased LED_Animation_Group :=
                          (1 => LED_Animation'(Timing_Event with LED_Green_R,
                           Blink_Period => Milliseconds (500)),
                           2 => LED_Animation'(Timing_Event with LED_Blue_L,
                           Blink_Period => Time_Span_Zero));

   Calibrating_Group  : aliased LED_Animation_Group :=
                          (1 => LED_Animation'(Timing_Event with LED_Red_R,
                           Blink_Period => Milliseconds (250)),
                           2 => LED_Animation'(Timing_Event with LED_Blue_L,
                             Blink_Period => Time_Span_Zero));

   Charging_Battery_Group : aliased LED_Animation_Group :=
                              (1 => LED_Animation'(Timing_Event
                                 with LED_Blue_L,
                               Blink_Period => Milliseconds (500)));

   Low_Power_Battery_Group : aliased LED_Animation_Group :=
                               (1 => LED_Animation'(Timing_Event
                                  with LED_Red_L,
                                Blink_Period => Time_Span_Zero));

   Self_Test_Fail_Group : aliased LED_Animation_Group :=
                            (1 => LED_Animation'(Timing_Event
                               with LED_Red_L,
                             Blink_Period => Milliseconds (500)));

   --  The collection of all LED animations, mapping Crazyflie_LED_Status
   --  values to their corresponding animations.
   LED_Animations : constant array (Crazyflie_LED_Status) of
     access LED_Animation_Group :=
       (Ready_To_Fly      => Ready_To_Fly_Group'Access,
        Calibrating       => Calibrating_Group'Access,
        Charging_Battery  => Charging_Battery_Group'Access,
        Low_Power_Battery => Low_Power_Battery_Group'Access,
        Self_Test_Fail    => Self_Test_Fail_Group'Access);

   --  The package global for the status that determines which LEDs are active.
   --  Controlled by procedure Enable_LED_Status.
   Current_LED_Status : Crazyflie_LED_Status := Ready_To_Fly;

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

end LEDS;
