with Ada.Real_Time;               use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

with STM32F4.GPIO;      use STM32F4.GPIO;
with STM32F4_Discovery; use STM32F4_Discovery;

package LEDS_Pack is

   type Crazyflie_LED is
     (LED_Blue_L, LED_Green_L, LED_Green_R, LED_Red_L, LED_Red_R);

   --  This type is used to represent the possible Crazyflie states for the
   --  on-board LEDs to indicate. Each status has at least one corresponding
   --  LED. A given state's LEDs are animated, in that they can either blink
   --  or be constantly enabled. The current animations cease when the status
   --  changes, and new animations are then enabled for the new status.
   type Crazyflie_LED_Status is
     (Ready_To_Fly,
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

   --  Mapping to get the proper pin of a given LED.
   LEDs_Pins : constant array (Crazyflie_LED) of GPIO_Pin
     := (LED_Blue_L  => Pin_2,
         LED_Green_L => Pin_1,
         LED_Green_R => Pin_2,
         LED_Red_L   => Pin_0,
         LED_Red_R   => Pin_3);

   --  Mapping to the proper polarity of a given LED.
   LEDS_Polarity : constant array (Crazyflie_LED) of Boolean
     := (LED_Blue_L  => True,
         LED_Green_L => False,
         LED_Green_R => False,
         LED_Red_L   => False,
         LED_Red_R   => False);

   --  Used to configure all LEDs at the same time.
   Red_And_Green_LEDs_Pins : constant GPIO_Pins
     := LEDs_Pins (LED_Green_L) & LEDs_Pins (LED_Green_R) &
        LEDs_Pins (LED_Red_L)   & LEDs_Pins (LED_Red_R);

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
   LED_Animations : constant array (Crazyflie_LED_Status)
     of access LED_Animation_Group
     := (Ready_To_Fly      => Ready_To_Fly_Group'Access,
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

end LEDS_Pack;
