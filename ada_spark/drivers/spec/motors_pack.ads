with Types; use Types;
with STM32F4_Discovery; use STM32F4_Discovery;
with STM32F4.GPIO; use STM32F4.GPIO;
with STM32F4.Timers; use STM32F4.Timers;

package Motors_Pack is

   --  Types

   type Motor_ID is (MOTOR_M1, MOTOR_M2, MOTOR_M3, MOTOR_M4);

   --  Procedures and functions

   --  Initialize the motors
   procedure Motors_Init;

   --  Apply power to the given motor
   procedure Motor_Set_Ratio
     (ID          : Motor_ID;
      Motor_Power : T_Uint16);

   --  Test all the Crazyflie motors
   procedure Motors_Test;

private
   --  Global variables and constants

   --  Constants used to configure PWM
   MOTOR_PWM_BITS       : constant := 8;
   MOTORS_PWM_PERIOD    : constant := 255;
   MOTORS_PWM_PRESCALE : constant := 0;

   --  Constants used for testing
   MOTORS_TEST_RATIO         : constant := 13_000;
   MOTORS_TEST_ON_TIME_MS    : constant := 50;
   MOTORS_TEST_DELAY_TIME_MS : constant := 150;

   --  Constants used to configure the proper GPIO Ports and pins
   --  to communicate with the motors
   MOTORS_GPIO_M1_PORT : GPIO_Port renames GPIO_A;
   MOTORS_GPIO_M1_PIN  : GPIO_Pin  renames Pin_1;
   MOTORS_GPIO_AF_M1   : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M1     : Timer renames Timer_2;

   MOTORS_GPIO_M2_PORT : GPIO_Port renames GPIO_B;
   MOTORS_GPIO_M2_PIN  : GPIO_Pin  renames Pin_11;
   MOTORS_GPIO_AF_M2   : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M2     : Timer renames Timer_2;

   MOTORS_GPIO_M3_PORT : GPIO_Port renames GPIO_A;
   MOTORS_GPIO_M3_PIN  : GPIO_Pin  renames Pin_15;
   MOTORS_GPIO_AF_M3   : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M3     : Timer renames Timer_2;

   MOTORS_GPIO_M4_PORT : GPIO_Port renames GPIO_B;
   MOTORS_GPIO_M4_PIN  : GPIO_Pin  renames Pin_9;
   MOTORS_GPIO_AF_M4   : constant GPIO_Alternate_Function := GPIO_AF_TIM4;
   MOTORS_TIMER_M4     : Timer renames Timer_4;

end Motors_Pack;
