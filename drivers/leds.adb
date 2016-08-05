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

package body LEDS is

   ---------------
   -- LEDS_Init --
   ---------------

   procedure LEDS_Init is
   begin
      STM32.Board.Initialize_LEDs;
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

   procedure Set_LED (LED : Crazyflie_LED; Value : Boolean)
   is
   begin
      if Value then
         Turn_On (LED);
      else
         Turn_Off (LED);
      end if;
   end Set_LED;

   ----------------
   -- Toggle_LED --
   ----------------

   procedure Toggle_LED (LED : Crazyflie_LED) renames STM32.Board.Toggle_LED;

   --------------------
   -- Reset_All_LEDs --
   --------------------

   procedure Reset_All_LEDs renames All_LEDs_Off;

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
      for Animation of LED_Animations (Current_LED_Status).all loop
         if Animation.Blink_Period > Time_Span_Zero then
            Animation.Cancel_Handler (Cancelled);
         else
            Set_LED (Animation.LED, False);
         end if;
      end loop;

      Current_LED_Status := LED_Status;

      for Animation of LED_Animations (Current_LED_Status).all loop
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
