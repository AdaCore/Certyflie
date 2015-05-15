with STM32F4; use STM32F4;
with Ada.Real_Time; use Ada.Real_Time;

package body Motors_Pack is

   procedure Motors_Init is
      GPIO_Configuration : GPIO_Port_Configuration;
   begin
      --  Enable GPIOs
      Enable_Clock (MOTORS_GPIO_M1_PORT);
      Enable_Clock (MOTORS_GPIO_M2_PORT);
      Enable_Clock (MOTORS_GPIO_M3_PORT);
      Enable_Clock (MOTORS_GPIO_M4_PORT);

      --  Enable timers
      Enable_Clock (MOTORS_TIMER_M1);
      Enable_Clock (MOTORS_TIMER_M2);
      Enable_Clock (MOTORS_TIMER_M3);
      Enable_Clock (MOTORS_TIMER_M4);

      --  Configure GPIOs
      GPIO_Configuration.Mode := Mode_AF;
      GPIO_Configuration.Speed := Speed_25MHz;
      GPIO_Configuration.Output_Type := Push_Pull;
      GPIO_Configuration.Resistors := Pull_Down;

      Configure_IO (Port => MOTORS_GPIO_M1_PORT,
                    Pin  => MOTORS_GPIO_M1_PIN,
                    Config => GPIO_Configuration);
      Configure_IO (Port => MOTORS_GPIO_M2_PORT,
                    Pin  => MOTORS_GPIO_M2_PIN,
                    Config => GPIO_Configuration);
      Configure_IO (Port => MOTORS_GPIO_M3_PORT,
                    Pin  => MOTORS_GPIO_M3_PIN,
                    Config => GPIO_Configuration);
      Configure_IO (Port => MOTORS_GPIO_M4_PORT,
                    Pin  => MOTORS_GPIO_M4_PIN,
                    Config => GPIO_Configuration);

      Configure_Alternate_Function
        (Port => MOTORS_GPIO_M1_PORT,
         Pin => MOTORS_GPIO_M1_PIN,
         AF   => MOTORS_GPIO_AF_M1);
      Configure_Alternate_Function
        (Port => MOTORS_GPIO_M2_PORT,
         Pin => MOTORS_GPIO_M2_PIN,
         AF   => MOTORS_GPIO_AF_M2);
      Configure_Alternate_Function
        (Port => MOTORS_GPIO_M3_PORT,
         Pin => MOTORS_GPIO_M3_PIN,
         AF   => MOTORS_GPIO_AF_M3);
      Configure_Alternate_Function
        (Port => MOTORS_GPIO_M4_PORT,
         Pin => MOTORS_GPIO_M4_PIN,
         AF   => MOTORS_GPIO_AF_M4);

      --  Configure the timers
      Configure
        (This => MOTORS_TIMER_M1,
         Prescaler => MOTORS_PWM_PRESCALE,
         Period => MOTORS_PWM_PERIOD,
         Clock_Divisor => Div1,
         Counter_Mode  => Up,
         Repetitions  => 0);
      Configure
        (This => MOTORS_TIMER_M2,
         Prescaler => MOTORS_PWM_PRESCALE,
         Period => MOTORS_PWM_PERIOD,
         Clock_Divisor => Div1,
         Counter_Mode  => Up,
         Repetitions  => 0);
      Configure
        (This => MOTORS_TIMER_M3,
         Prescaler => MOTORS_PWM_PRESCALE,
         Period => MOTORS_PWM_PERIOD,
         Clock_Divisor => Div1,
         Counter_Mode  => Up,
         Repetitions  => 0);
      Configure
        (This => MOTORS_TIMER_M4,
         Prescaler => MOTORS_PWM_PRESCALE,
         Period => MOTORS_PWM_PERIOD,
         Clock_Divisor => Div1,
         Counter_Mode  => Up,
         Repetitions  => 0);

      --  PWM channels configuration
      Configure_Channel_Output
        (This     => MOTORS_TIMER_M1,
         Channel  => Channel_2,
         Mode     => PWM1,
         State    => Enable,
         Pulse    => 0,
         Polarity => High);
      Set_Output_Preload_Enable
        (This    => MOTORS_TIMER_M1,
         Channel => Channel_2,
         Enabled => True);

      Configure_Channel_Output
        (This     => MOTORS_TIMER_M2,
         Channel  => Channel_4,
         Mode     => PWM1,
         State    => Enable,
         Pulse    => 0,
         Polarity => High);
      Set_Output_Preload_Enable
        (This    => MOTORS_TIMER_M2,
         Channel => Channel_4,
         Enabled => True);

      Configure_Channel_Output
        (This     => MOTORS_TIMER_M3,
         Channel  => Channel_1,
         Mode     => PWM1,
         State    => Enable,
         Pulse    => 0,
         Polarity => High);
      Set_Output_Preload_Enable
        (This    => MOTORS_TIMER_M3,
         Channel => Channel_1,
         Enabled => True);

      Configure_Channel_Output
        (This     => MOTORS_TIMER_M4,
         Channel  => Channel_4,
         Mode     => PWM1,
         State    => Enable,
         Pulse    => 0,
         Polarity => High);
      Set_Output_Preload_Enable
        (This    => MOTORS_TIMER_M4,
         Channel => Channel_4,
         Enabled => True);

      --  TODO: enable sync

      --  Enable the timer PWM outputs
      Enable_Main_Output (MOTORS_TIMER_M1);
      Enable_Main_Output (MOTORS_TIMER_M2);
      Enable_Main_Output (MOTORS_TIMER_M3);
      Enable_Main_Output (MOTORS_TIMER_M4);

      --  Test...
      Enable (MOTORS_TIMER_M1);
      Enable (MOTORS_TIMER_M2);
      Enable (MOTORS_TIMER_M3);
      Enable (MOTORS_TIMER_M4);

      --  TODO: enable halt debug

   end Motors_Init;

   procedure Motor_Set_Ratio
     (ID          : Motor_ID;
      Motor_Power : T_Uint16) is
   begin
      case ID is
         when MOTOR_M1 =>
            Set_Compare_Value (This       => MOTORS_TIMER_M1,
                               Channel    => Channel_2,
                               Word_Value => Word (Motor_Power));
         when MOTOR_M2 =>
            Set_Compare_Value (This       => MOTORS_TIMER_M2,
                               Channel    => Channel_1,
                               Word_Value => Word (Motor_Power));
         when MOTOR_M3 =>
            Set_Compare_Value (This       => MOTORS_TIMER_M3,
                               Channel    => Channel_4,
                               Word_Value => Word (Motor_Power));
         when MOTOR_M4 =>
            Set_Compare_Value (This       => MOTORS_TIMER_M4,
                               Channel    => Channel_4,
                               Word_Value => Word (Motor_Power));
      end case;
   end Motor_Set_Ratio;

   procedure Motors_Test is
      Next_Period_1 : Time;
      Next_Period_2 : Time;
   begin
      for Motor in Motor_ID loop
         Next_Period_1 := Clock + Milliseconds (MOTORS_TEST_ON_TIME_MS);
         Motor_Set_Ratio (Motor, MOTORS_TEST_RATIO);
         delay until (Next_Period_1);
         Next_Period_2 := Clock + Milliseconds (MOTORS_TEST_DELAY_TIME_MS);
         Motor_Set_Ratio (Motor, 0);
         delay until (Next_Period_2);
      end loop;
   end Motors_Test;

end Motors_Pack;
