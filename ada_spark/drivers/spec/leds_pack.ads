with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F4_Discovery; use STM32F4_Discovery;

package LEDS_Pack is

   --  Type indexing all the Crazyflie leds
   type Crazyflie_LED is
     (LED_Blue_L, LED_Green_L, LED_Green_R, LED_Red_L, LED_Red_R);

   --  Initizalize the Crazyflie leds
   procedure LEDS_Init;

   --  Test if the leds are initialized
   function LEDS_Test return Boolean;

   -- Set the led if Value = True, clear if Value = False
   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean);

private
   --  Global variables and constants

   Is_Init : Boolean := False;

   --  Mapping to get the proper pin of a given led
   LEDs_Pins : constant array (Crazyflie_LED) of GPIO_Pin
     := (LED_Blue_L  => Pin_2,
         LED_Green_L => Pin_1,
         LED_Green_R => Pin_2,
         LED_Red_L   => Pin_0,
         LED_Red_R   => Pin_3);


   --  Mapping to the proper polarity of a given led
   LEDS_Polarity : constant array (Crazyflie_LED) of Boolean
     := (LED_Blue_L  => True,
         LED_Green_L => False,
         LED_Green_R => False,
         LED_Red_L   => False,
         LED_Red_R   => False);

   --  Used to configure all leds a the same time
   Red_And_Green_LEDs_Pins : constant GPIO_Pins
     := LEDs_Pins (LED_Green_L) & LEDs_Pins (LED_Green_R) &
                               LEDs_Pins (LED_Red_L) & LEDs_Pins (LED_Red_R);
end LEDS_Pack;
