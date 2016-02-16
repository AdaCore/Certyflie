with STM32; use STM32;
with STM32.Device; use STM32.Device;

package body LEDS is

   ---------------
   -- LEDS_Init --
   ---------------

   procedure LEDS_Init is
      Configuration : GPIO_Port_Configuration;
   begin
      if Is_Initialized then
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

      Is_Initialized := True;
   end LEDS_Init;

   ---------------
   -- LEDS_Test --
   ---------------

   function LEDS_Test return Boolean is
   begin
      return Is_Initialized;
   end LEDS_Test;

   -------------
   -- Set_LED --
   -------------

   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean) is
      Set_Value : constant Boolean
        := (if LEDS_Polarity (LED) then Value else not Value);
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

   ----------------
   -- Toggle_LED --
   ----------------

   procedure Toggle_LED (LED : Crazyflie_LED) is
   begin
      if LED = LED_Blue_L then
         Toggle (GPIO_D, LEDs_Pins (LED));
      else
         Toggle (GPIO_C, LEDs_Pins (LED));
      end if;
   end Toggle_LED;

   --------------------
   -- Reset_All_LEDs --
   --------------------

   procedure Reset_All_LEDs is
   begin
      for LED in Crazyflie_LED loop
         Set_LED (LED, False);
      end loop;
   end Reset_All_LEDs;

   -----------------------
   -- Enable_LED_Status --
   -----------------------

   procedure Enable_LED_Status (LED_Status : Crazyflie_LED_Status) is
      Cancelled : Boolean;
      pragma Unreferenced (Cancelled);
   begin
      Reset_All_LEDs;
      --  This reset is in a race with the events' occurrences, but is OK since
      --  we're about to cancel all of the current live events anyway, and
      --  there is no corruption to worry about.

      Current_LED_Status := LED_Status;

      for Animation of LED_Animations (Current_LED_Status).all loop
         Animation.Cancel_Handler (Cancelled);
         if Animation.Blink_Period > Time_Span_Zero then
            Animation.Set_Handler
              (Clock + Animation.Blink_Period,
               LED_Status_Event_Handler.Toggle_LED_Status'Access);
         else
            Set_LED (Animation.LED, True);
         end if;
      end loop;
   end Enable_LED_Status;

   ------------------------------
   -- LED_Status_Event_Handler --
   ------------------------------

   protected body LED_Status_Event_Handler is

      procedure Toggle_LED_Status (Event : in out Timing_Event) is
         Animation : LED_Animation renames
                       LED_Animation (Timing_Event'Class (Event));
         --  We "know" we have an LED_Animation value for the actual parameter
         --  but the formal gives a view of type Timing_Event, so we convert
         --  to the subclass to change the view. (The inner conversion to
         --  the classwide base type is required.) Changing the view allows
         --  reference to the LED and Blink_Period components within Event.
      begin
         Toggle_LED (Animation.LED);

         --  Set this procedure as the handler for the next occurrence for
         --  Event, too.
         Animation.Set_Handler
           (Clock + Animation.Blink_Period,
            Toggle_LED_Status'Access);
      end Toggle_LED_Status;

   end LED_Status_Event_Handler;

   ----------------------------
   -- Get_Current_LED_Status --
   ----------------------------

   function Get_Current_LED_Status return Crazyflie_LED_Status is
   begin
      return Current_LED_Status;
   end Get_Current_LED_Status;

end LEDS;
