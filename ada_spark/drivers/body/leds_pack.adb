package body LEDS_Pack is

   procedure LEDS_Init is
      Configuration : GPIO_Port_Configuration;
   begin
      Enable_Clock (GPIO_D);
      Enable_Clock (GPIO_C);

      Configuration.Mode        := Mode_Out;
      Configuration.Output_Type := Push_Pull;
      Configuration.Speed       := Speed_100MHz;
      Configuration.Resistors   := Floating;

      Configure_IO (Port => GPIO_D,
                    Pin  => LEDs_Pins (LED_Blue_L),
                    Config => Configuration);
      Configure_IO (Port => GPIO_C,
                    Pins => Red_And_Green_LEDs_Pins,
                    Config => Configuration);

      for LED in Crazyflie_LED loop
         Set_LED (LED, False);
      end loop;
   end LEDS_Init;

   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean) is
      Set_Value : constant Boolean
        := (if LEDS_Polarity (Led) then Value else not Value);
   begin
      if Set_Value then
         if LED = LED_Blue_L then
            Set (GPIO_D, LEDs_Pins (LED));
         else
            Set (GPIO_C, LEDs_Pins (LED));
         end if;
      else
         if LED = LED_Blue_L then
            Clear (GPIO_D, LEDs_Pins (LED));
         else
            Clear (GPIO_C, LEDs_Pins (LED));
         end if;
      end if;
   end Set_LED;

end LEDS_Pack;
