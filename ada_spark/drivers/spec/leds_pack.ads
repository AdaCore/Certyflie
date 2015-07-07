with Ada.Real_Time; use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;

with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F4_Discovery; use STM32F4_Discovery;

package LEDS_Pack is

   --  Type indexing all the Crazyflie leds.
   type Crazyflie_LED is
     (LED_Blue_L, LED_Green_L, LED_Green_R, LED_Red_L, LED_Red_R);

   --  Type enumerating possible crazyflie LED status.
   --  This type is used to activate a led animation according
   --  to a specific status.
   type Crazyflie_LED_Status is
     (Ready_To_Fly,
      Charging_Battery,
      Low_Power_Battery,
      Self_Test_Fail);

   --  Initizalize the Crazyflie leds.
   procedure LEDS_Init;

   --  Test if the leds are initialized.
   function LEDS_Test return Boolean;

   --  Set the led if Value = True, clear if Value = False.
   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean);

   --  Toggle the selected led.
   procedure Toggle_LED (LED : Crazyflie_LED);

   --  Switch off all the crazyflie leds.
   procedure Reset_All_LEDs;

   --  Enable the specified Crazyflie led status.
   procedure Enable_LED_Status (LED_Status : Crazyflie_LED_Status);

   --  Get the current LED status.
   function Get_Current_LED_Status return Crazyflie_LED_Status;

private
   --  Global variables and constants

   Is_Init : Boolean := False;

   --  Mapping to get the proper pin of a given led.
   LEDs_Pins : constant array (Crazyflie_LED) of GPIO_Pin
     := (LED_Blue_L  => Pin_2,
         LED_Green_L => Pin_1,
         LED_Green_R => Pin_2,
         LED_Red_L   => Pin_0,
         LED_Red_R   => Pin_3);

   --  Mapping to the proper polarity of a given led.
   LEDS_Polarity : constant array (Crazyflie_LED) of Boolean
     := (LED_Blue_L  => True,
         LED_Green_L => False,
         LED_Green_R => False,
         LED_Red_L   => False,
         LED_Red_R   => False);

   --  Used to configure all leds a the same time.
   Red_And_Green_LEDs_Pins : constant GPIO_Pins
     := LEDs_Pins (LED_Green_L) & LEDs_Pins (LED_Green_R) &
                               LEDs_Pins (LED_Red_L) & LEDs_Pins (LED_Red_R);
   --  Type representing a led animation. A led animation targets
   --  a specific LED and switch it on/off according to
   --  its blink period.
   type LED_Animation is record
      LED          : Crazyflie_LED := LED_Blue_L;
      Blink_Period : Time_Span := Milliseconds (0);
   end record;

   --  Predefined led animations, each one corresponding to a specific
   --  LED status.
   LED_Animations          : constant array (Crazyflie_LED_Status)
     of LED_Animation
     := (Ready_To_Fly      => (LED          => LED_Green_R,
                               Blink_Period => Milliseconds (500)),
         Charging_Battery  => (LED          => LED_Blue_L,
                               Blink_Period => Milliseconds (500)),
         Low_Power_Battery => (LED          => LED_Red_L,
                               Blink_Period => Milliseconds (0)),
         Self_Test_Fail    => (LED          => LED_Red_L,
                               Blink_Period => Milliseconds (500)));

   --  Current led status.
   Current_LED_Status       : Crazyflie_LED_Status := Ready_To_Fly;
   --  Timing event associated to the current led status animation,
   --  if the animation link period is superior from 0.
   Current_LED_Status_Event : Timing_Event;

   --  Procedures and functions

   --  Handler called when the LED_Status_Event timer expires.
   --  Toggle the state of the cuurent LED status animation.
   protected LED_Status_Event_Handler is
      pragma Interrupt_Priority;

      procedure Toggle_LED_Status (Event : in out Timing_Event);
   end LED_Status_Event_Handler;

   --  Access to the current status timing event handler.
   Current_LED_Status_Event_Handler : constant Timing_Event_Handler
     := LED_Status_Event_Handler.Toggle_LED_Status'Access;

end LEDS_Pack;
