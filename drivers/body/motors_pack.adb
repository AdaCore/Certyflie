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

with Ada.Real_Time;         use Ada.Real_Time;

with Power_Management_Pack; use Power_Management_Pack;
with Safety_Pack;           use Safety_Pack;

package body Motors_Pack is

   -----------------
   -- Motors_Init --
   -----------------

   procedure Motors_Init is
   begin
      --  Initialize the pwm modulators
      Initialise_PWM_Modulator
        (This                   => M1_Modulator,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => MOTORS_TIMER_M1'Access,
         PWM_AF                 => MOTORS_GPIO_AF_M1,
         Enable_PWM_Timer_Clock => MOTORS_TIM_ENABLE_M1);

      Initialise_PWM_Modulator
        (This                   => M2_Modulator,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => MOTORS_TIMER_M2'Access,
         PWM_AF                 => MOTORS_GPIO_AF_M2,
         Enable_PWM_Timer_Clock => MOTORS_TIM_ENABLE_M2);

      Initialise_PWM_Modulator
        (This                   => M3_Modulator,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => MOTORS_TIMER_M3'Access,
         PWM_AF                 => MOTORS_GPIO_AF_M3,
         Enable_PWM_Timer_Clock => MOTORS_TIM_ENABLE_M3);

      Initialise_PWM_Modulator
        (This                   => M4_Modulator,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => MOTORS_TIMER_M4'Access,
         PWM_AF                 => MOTORS_GPIO_AF_M4,
         Enable_PWM_Timer_Clock => MOTORS_TIM_ENABLE_M4);

      --  Attach the PWM modulators to the corresponding channels
      Attach_PWM_Channel (This                   => M1_Modulator,
                          Channel                => MOTORS_TIM_CHANNEL_M1,
                          Point                  => MOTORS_GPIO_M1_POINT,
                          Enable_GPIO_Port_Clock => MOTORS_GPIO_ENABLE_M1);

      Attach_PWM_Channel (This                   => M2_Modulator,
                          Channel                => MOTORS_TIM_CHANNEL_M2,
                          Point                  => MOTORS_GPIO_M2_POINT,
                          Enable_GPIO_Port_Clock => MOTORS_GPIO_ENABLE_M2);

      Attach_PWM_Channel (This                   => M3_Modulator,
                          Channel                => MOTORS_TIM_CHANNEL_M3,
                          Point                  => MOTORS_GPIO_M3_POINT,
                          Enable_GPIO_Port_Clock => MOTORS_GPIO_ENABLE_M3);

      Attach_PWM_Channel (This                   => M4_Modulator,
                          Channel                => MOTORS_TIM_CHANNEL_M4,
                          Point                  => MOTORS_GPIO_M4_POINT,
                          Enable_GPIO_Port_Clock => MOTORS_GPIO_ENABLE_M4);

      --  Reset all the motors power to zero
      Motors_Reset;
   end Motors_Init;

   ---------------------
   -- Motor_Set_Power --
   ---------------------

   procedure Motor_Set_Power
     (ID : Motor_ID;
      Motor_Power : T_Uint16)
   is
      Power_Percentage_F : Float;
      Power_Percentage   : Percentage;
   begin
      Power_Percentage_F :=
        Saturate ((Float (Motor_Power) / Float (T_Uint16'Last)) * 100.0,
                  0.0,
                  100.0);
      Power_Percentage := Percentage (Power_Percentage_F);

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (This     => M1_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M1,
                            Value    => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (This     => M2_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M2,
                            Value    => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (This     => M3_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M3,
                            Value    => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (This     => M4_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M4,
                            Value    => Power_Percentage);
      end case;
   end Motor_Set_Power;

   -------------------------------------------
   -- Motor_Set_Power_With_Bat_Compensation --
   -------------------------------------------

   procedure Motor_Set_Power_With_Bat_Compensation
     (ID : Motor_ID;
      Motor_Power : T_Uint16)
   is
      Tmp_Thrust         : Float
        := (Float (Motor_Power) / Float (T_Uint16'Last)) * 60.0;
      Volts              : Float
        := -0.0006239 * Tmp_Thrust * Tmp_Thrust + 0.088 * Tmp_Thrust;
      Supply_Voltage     : Float;
      Power_Percentage_F : Float;
      Power_Percentage   : Percentage;
   begin
      Supply_Voltage := Power_Management_Get_Battery_Voltage;
      Power_Percentage_F := (Volts / Supply_Voltage) * 100.0;
      Power_Percentage_F :=
        Saturate (Power_Percentage_F, 0.0, 100.0);
      Power_Percentage := Percentage (Power_Percentage_F);

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (This     => M1_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M1,
                            Value    => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (This     => M2_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M2,
                            Value    => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (This     => M3_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M3,
                            Value    => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (This     => M4_Modulator,
                            Channel  => MOTORS_TIM_CHANNEL_M4,
                            Value    => Power_Percentage);
      end case;
   end Motor_Set_Power_With_Bat_Compensation;

   -----------------
   -- Motors_Test --
   -----------------

   function Motors_Test return Boolean
   is
      Next_Period_1 : Time;
      Next_Period_2 : Time;
   begin
      for Motor in Motor_ID loop
         Next_Period_1 := Clock + Milliseconds (MOTORS_TEST_ON_TIME_MS);
         Motor_Set_Power (Motor, 10_000);
         delay until (Next_Period_1);
         Next_Period_2 := Clock + Milliseconds (MOTORS_TEST_DELAY_TIME_MS);
         Motor_Set_Power (Motor, 0);
         delay until (Next_Period_2);
      end loop;

      return True;
   end Motors_Test;

   ------------------
   -- Motors_Reset --
   ------------------

   procedure Motors_Reset is
   begin
      for Motor in Motor_ID loop
         Motor_Set_Power (Motor, 0);
      end loop;
   end Motors_Reset;

end Motors_Pack;
