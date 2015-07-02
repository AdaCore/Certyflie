package body LEDS_Pack is

   procedure LEDS_Init is
      Configuration : GPIO_Port_Configuration;
   begin
      if Is_Init then
         return;
      end if;

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

      Reset_All_LEDs;

      Is_Init := True;
   end LEDS_Init;

   function LEDS_Test return Boolean is
   begin
      return Is_Init;
   end LEDS_Test;

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

   procedure Toggle_LED (LED : Crazyflie_LED) is
   begin
      if LED = LED_Blue_L then
         Toggle (GPIO_D, LEDs_Pins (LED));
      else
         Toggle (GPIO_C, LEDs_Pins (LED));
      end if;
   end Toggle_LED;

   procedure Reset_All_LEDs is
   begin
      for LED in Crazyflie_LED loop
         Set_LED (LED, False);
      end loop;
   end Reset_All_LEDs;

   procedure Enable_LED_Status (LED_Status : Crazyflie_LED_Status) is
      Cancelled            : Boolean;
      Status_LED_Animation : LED_Animation;
      pragma Unreferenced (Cancelled);
   begin
      Reset_All_LEDs;

      Current_LED_Status := LED_Status;
      Cancel_Handler (Current_LED_Status_Event, Cancelled);
      Status_LED_Animation := LED_Animations (Current_LED_Status);

      if Status_LED_Animation.Blink_Period > Milliseconds (0) then
         Set_Handler (Current_LED_Status_Event,
                      Clock + Status_LED_Animation.Blink_Period,
                      Current_LED_Status_Event_Handler);
      else
         Set_LED (Status_LED_Animation.LED, True);
      end if;
   end Enable_LED_Status;

   function Get_Current_LED_Status return Crazyflie_LED_Status is
   begin
      return Current_LED_Status;
   end Get_Current_LED_Status;

   protected body LED_Status_Event_Handler is
      procedure Toggle_LED_Status (Event : in out Timing_Event) is
         Cancelled            : Boolean;
         Status_LED_Animation : constant LED_Animation
           := LED_Animations (Current_LED_Status);
         pragma Unreferenced (Event);
         pragma Unreferenced (Cancelled);
      begin
         Toggle_LED (Status_LED_Animation.LED);
         Set_Handler (Current_LED_Status_Event,
                      Clock + Status_LED_Animation.Blink_Period,
                      Current_LED_Status_Event_Handler);
      end Toggle_LED_Status;
   end LED_Status_Event_Handler;

end LEDS_Pack;
