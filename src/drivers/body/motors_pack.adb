with Ada.Real_Time; use Ada.Real_Time;
with Safety_Pack; use Safety_Pack;
with Power_Management_Pack; use Power_Management_Pack;

package body Motors_Pack is

   procedure Motors_Init is
      GPIO_Configuration    : GPIO_Port_Configuration;
      Timer_Configuration   : Timer_Config;
      Channel_Configuration : Channel_Config;
   begin
      --  Enable GPIOs
      Enable_Clock (MOTORS_GPIO_M1_PORT);
      Enable_Clock (MOTORS_GPIO_M2_PORT);
      Enable_Clock (MOTORS_GPIO_M3_PORT);
      Enable_Clock (MOTORS_GPIO_M4_PORT);

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
      Timer_Configuration := (Prescaler => MOTORS_PWM_PRESCALE,
                              Period => MOTORS_PWM_PERIOD);

      Config_Timer (Tim  => MOTORS_TIMER_M1,
                    Conf => Timer_Configuration);
      Config_Timer (Tim  => MOTORS_TIMER_M2,
                    Conf => Timer_Configuration);
      Config_Timer (Tim  => MOTORS_TIMER_M3,
                    Conf => Timer_Configuration);
      Config_Timer (Tim =>  MOTORS_TIMER_M4,
                    Conf => Timer_Configuration);

      --  Configure the channels
      Channel_Configuration := (Mode => Output);

      Config_Channel (Tim  => MOTORS_TIMER_M1,
                      Ch   => MOTORS_TIM_CHANNEL_M1,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => MOTORS_TIMER_M2,
                      Ch   => MOTORS_TIM_CHANNEL_M2,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => MOTORS_TIMER_M3,
                      Ch   => MOTORS_TIM_CHANNEL_M3,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => MOTORS_TIMER_M4,
                      Ch   => MOTORS_TIM_CHANNEL_M4,
                      Conf => Channel_Configuration);

      --  Reset all the motors power to zero
      Motors_Reset;

      --  Enable the channels
      Set_Channel_State (Tim   => MOTORS_TIMER_M1,
                         Ch    => MOTORS_TIM_CHANNEL_M1,
                         State => Enabled);
      Set_Channel_State (Tim   => MOTORS_TIMER_M2,
                         Ch    => MOTORS_TIM_CHANNEL_M2,
                         State => Enabled);
      Set_Channel_State (Tim   => MOTORS_TIMER_M3,
                         Ch    => MOTORS_TIM_CHANNEL_M3,
                         State => Enabled);
      Set_Channel_State (Tim   => MOTORS_TIMER_M4,
                         Ch    => MOTORS_TIM_CHANNEL_M4,
                         State => Enabled);
   end Motors_Init;

   procedure Motor_Set_Ratio
     (ID               : Motor_ID;
      Power_Percentage : Duty_Percentage) is
   begin
      case ID is
         when MOTOR_M1 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M1,
                                 Ch      => MOTORS_TIM_CHANNEL_M1,
                                 Percent => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M2,
                                 Ch      => MOTORS_TIM_CHANNEL_M2,
                                 Percent => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M3,
                                 Ch      => MOTORS_TIM_CHANNEL_M3,
                                 Percent => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M4,
                                 Ch      => MOTORS_TIM_CHANNEL_M4,
                                 Percent => Power_Percentage);
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
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M1,
                                 Ch      => MOTORS_TIM_CHANNEL_M1,
                                 Percent => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M2,
                                 Ch      => MOTORS_TIM_CHANNEL_M2,
                                 Percent => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M3,
                                 Ch      => MOTORS_TIM_CHANNEL_M3,
                                 Percent => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M4,
                                 Ch      => MOTORS_TIM_CHANNEL_M4,
                                 Percent => Power_Percentage);
      end case;
   end Motor_Set_Power;

   procedure Motor_Set_Power_With_Bat_Compensation
     (ID : Motor_ID;
      Motor_Power : T_Uint16) is
      Tmp_Thrust         : Float
        := (Float (Motor_Power) / Float (T_Uint16'Last)) * 60.0;
      Volts              : Float
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
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M1,
                                 Ch      => MOTORS_TIM_CHANNEL_M1,
                                 Percent => Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M2,
                                 Ch      => MOTORS_TIM_CHANNEL_M2,
                                 Percent => Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M3,
                                 Ch      => MOTORS_TIM_CHANNEL_M3,
                                 Percent => Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Percentage (Tim     => MOTORS_TIMER_M4,
                                 Ch      => MOTORS_TIM_CHANNEL_M4,
                                 Percent => Power_Percentage);
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

end Motors_Pack;
