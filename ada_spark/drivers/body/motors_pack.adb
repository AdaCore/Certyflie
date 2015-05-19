with Ada.Real_Time; use Ada.Real_Time;
with STM32F4.PWM; use STM32F4.PWM;

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
      Timer_Configuration := (Prescaler => 0,
                              Period => MOTORS_PWM_PERIOD);

      Config_Timer (Tim  => TIM2,
                    Conf => Timer_Configuration);
      Config_Timer (Tim =>  TIM4,
                    Conf => Timer_Configuration);

      --  Configure the channels
      Channel_Configuration := (Mode => Output);

      Config_Channel (Tim  => TIM2,
                      Ch   => CH2,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => TIM2,
                      Ch   => CH4,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => TIM2,
                      Ch   => CH1,
                      Conf => Channel_Configuration);
      Config_Channel (Tim  => TIM4,
                      Ch   => CH4,
                      Conf => Channel_Configuration);

      --  Enable the channels
      Set_Channel_State (Tim   => TIM2,
                         Ch    => CH2,
                         State => Enabled);
      Set_Channel_State (Tim   => TIM2,
                         Ch    => CH4,
                         State => Enabled);
      Set_Channel_State (Tim   => TIM2,
                         Ch    => CH1,
                         State => Enabled);
      Set_Channel_State (Tim   => TIM4,
                         Ch    => CH4,
                         State => Enabled);
      --  TODO: enable halt debug
   end Motors_Init;

   procedure Motor_Set_Ratio
     (ID          : Motor_ID;
      Motor_Power : Duty_Percentage) is
   begin

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Percentage (Tim     => TIM2,
                                 Ch      => CH2,
                                 Percent => Motor_Power);
         when MOTOR_M2 =>
            Set_Duty_Percentage (Tim     => TIM2,
                                 Ch      => CH4,
                                 Percent => Motor_Power);
         when MOTOR_M3 =>
            Set_Duty_Percentage (Tim     => TIM2,
                                 Ch      => CH1,
                                 Percent => Motor_Power);
         when MOTOR_M4 =>
            Set_Duty_Percentage (Tim     => TIM4,
                                 Ch      => CH4,
                                 Percent => Motor_Power);
      end case;
   end Motor_Set_Ratio;

   procedure Motors_Test is
      Next_Period_1 : Time;
      Next_Period_2 : Time;
   begin
      for Motor in Motor_ID loop
         Next_Period_1 := Clock + Milliseconds (MOTORS_TEST_ON_TIME_MS);
         Motor_Set_Ratio (Motor, 20);
         delay until (Next_Period_1);
         Next_Period_2 := Clock + Milliseconds (MOTORS_TEST_DELAY_TIME_MS);
         Motor_Set_Ratio (Motor, 1);
         delay until (Next_Period_2);
      end loop;
   end Motors_Test;

   function C_16_To_Bits (Ratio : T_Uint16) return Word is
   begin
      --  TODO
      return Word (Ratio);
   end C_16_To_Bits;


end Motors_Pack;
