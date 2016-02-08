with Ada.Real_Time; use Ada.Real_Time;
with Safety; use Safety;
with Power_Management; use Power_Management;
with STM32F4.RCC; use STM32F4.RCC;

package body Motors is

   procedure Motors_Init is
   begin

      Initialise_PWM_Modulator
        (Timer_2_PWM,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => Timer_2'Access,
         PWM_AF                 => GPIO_AF_TIM2,
         Enable_PWM_Timer_Clock => TIM2_Clock_Enable'Access);

      Initialise_PWM_Modulator
        (Timer_4_PWM,
         Requested_Frequency    => MOTORS_PWM_FREQUENCY,
         PWM_Timer              => Timer_4'Access,
         PWM_AF                 => GPIO_AF_TIM4,
         Enable_PWM_Timer_Clock => TIM4_Clock_Enable'Access);

      Attach_PWM_Channel
        (MOTORS_TIMER_M1,
         MOTORS_TIM_CHANNEL_M1,
         (MOTORS_GPIO_M1_PORT'Access, MOTORS_GPIO_M1_PIN),
         GPIOA_Clock_Enable'Access);

      Attach_PWM_Channel
        (MOTORS_TIMER_M2,
         MOTORS_TIM_CHANNEL_M2,
         (MOTORS_GPIO_M2_PORT'Access, MOTORS_GPIO_M2_PIN),
         GPIOB_Clock_Enable'Access);

      Attach_PWM_Channel
        (MOTORS_TIMER_M3,
         MOTORS_TIM_CHANNEL_M3,
         (MOTORS_GPIO_M3_PORT'Access, MOTORS_GPIO_M3_PIN),
         GPIOA_Clock_Enable'Access);

      Attach_PWM_Channel
        (MOTORS_TIMER_M4,
         MOTORS_TIM_CHANNEL_M4,
         (MOTORS_GPIO_M4_PORT'Access, MOTORS_GPIO_M4_PIN),
         GPIOB_Clock_Enable'Access);

      --  Reset all the motors power to zero
      Motors_Reset;

      Enable_PWM_Channel (MOTORS_TIMER_M1, MOTORS_TIM_CHANNEL_M1);
      Enable_PWM_Channel (MOTORS_TIMER_M2, MOTORS_TIM_CHANNEL_M2);
      Enable_PWM_Channel (MOTORS_TIMER_M3, MOTORS_TIM_CHANNEL_M3);
      Enable_PWM_Channel (MOTORS_TIMER_M4, MOTORS_TIM_CHANNEL_M4);
   end Motors_Init;

   procedure Motor_Set_Ratio
     (ID               : Motor_ID;
      Power_Percentage : Duty_Percentage) is
   begin
      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M1,
                            Channel => MOTORS_TIM_CHANNEL_M1,
                            Value   => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (This     => MOTORS_TIMER_M2,
                            Channel => MOTORS_TIM_CHANNEL_M2,
                            Value   => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M3,
                            Channel => MOTORS_TIM_CHANNEL_M3,
                            Value   => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M4,
                            Channel => MOTORS_TIM_CHANNEL_M4,
                            Value   => Power_Percentage);
      end case;
   end Motor_Set_Ratio;

   procedure Motor_Set_Power
     (ID : Motor_ID;
      Motor_Power : T_Uint16) is
      Power_Percentage_F : Float;
      Power_Percentage : Duty_Percentage;
   begin
      Power_Percentage_F :=
        Saturate ((Float (Motor_Power) / Float (T_Uint16'Last)) * 100.0,
                  0.0,
                  100.0);
      Power_Percentage := Duty_Percentage (Power_Percentage_F);

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M1,
                            Channel => MOTORS_TIM_CHANNEL_M1,
                            Value   => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M2,
                            Channel => MOTORS_TIM_CHANNEL_M2,
                            Value   => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M3,
                            Channel => MOTORS_TIM_CHANNEL_M3,
                            Value   => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M4,
                            Channel => MOTORS_TIM_CHANNEL_M4,
                            Value   => Power_Percentage);
      end case;
   end Motor_Set_Power;

   procedure Motor_Set_Power_With_Bat_Compensation
     (ID : Motor_ID;
      Motor_Power : T_Uint16) is
      Tmp_Thrust         : constant Float
        := (Float (Motor_Power) / Float (T_Uint16'Last)) * 60.0;
      Volts              : constant Float
        := -0.0006239 * Tmp_Thrust * Tmp_Thrust + 0.088 * Tmp_Thrust;
      Supply_Voltage     : Float;
      Power_Percentage_F : Float;
      Power_Percentage   : Duty_Percentage;
   begin
      Supply_Voltage := Power_Management_Get_Battery_Voltage;
      Power_Percentage_F := (Volts / Supply_Voltage) * 100.0;
      Power_Percentage_F :=
        Saturate (Power_Percentage_F, 0.0, 100.0);
      Power_Percentage := Duty_Percentage (Power_Percentage_F);

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M1,
                            Channel => MOTORS_TIM_CHANNEL_M1,
                            Value   => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M2,
                            Channel => MOTORS_TIM_CHANNEL_M2,
                            Value   => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M3,
                            Channel => MOTORS_TIM_CHANNEL_M3,
                            Value   => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (This    => MOTORS_TIMER_M4,
                            Channel => MOTORS_TIM_CHANNEL_M4,
                            Value   => Power_Percentage);
      end case;
   end Motor_Set_Power_With_Bat_Compensation;

   function Motors_Test return Boolean is
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

   procedure Motors_Reset is
   begin
      for Motor in Motor_ID loop
         Motor_Set_Power (Motor, 0);
      end loop;
   end Motors_Reset;

end Motors;
