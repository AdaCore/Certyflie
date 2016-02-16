with Types; use Types;
with STM32.Device; use STM32.Device;
with STM32.GPIO; use STM32.GPIO;
with STM32; use STM32;
with STM32.Timers; use STM32.Timers;
with STM32.PWM; use STM32.PWM;

package Motors is

   --  Types

   type Motor_ID is (MOTOR_M1, MOTOR_M2, MOTOR_M3, MOTOR_M4);

   subtype Duty_Percentage is Percentage;

   --  Procedures and functions

   --  Initialize the motors.
   procedure Motors_Init;

   --  Apply a power percentage to the given motor.
   procedure Motor_Set_Ratio
     (ID               : Motor_ID;
      Power_Percentage : Duty_Percentage);

   --  Apply an absolute power to the given motor.
   procedure Motor_Set_Power
     (ID : Motor_ID;
      Motor_Power : T_Uint16);

   --  Apply power to the given motor with a compensation
   --  according to the battery level.
   procedure Motor_Set_Power_With_Bat_Compensation
     (ID : Motor_ID;
      Motor_Power : T_Uint16);

   --  Test all the Crazyflie motors.
   function Motors_Test return Boolean;

private
   --  Global variables and constants

   Timer_2_PWM : PWM_Modulator;
   Timer_4_PWM : PWM_Modulator;

   --  Constants used to configure PWM.
   MOTORS_PWM_FREQUENCY : constant := 328_000.0; --  328 KHz
   MOTORS_PWM_PERIOD    : constant := 1.0 / MOTORS_PWM_FREQUENCY;
   MOTORS_PWM_PRESCALE  : constant := 0;

   --  Constants used for testing.
   MOTORS_TEST_RATIO         : constant := 13_000;
   MOTORS_TEST_ON_TIME_MS    : constant := 50;
   MOTORS_TEST_DELAY_TIME_MS : constant := 150;

   --  Constants used to configure the proper GPIO Ports and pins
   --  to communicate with the motors.
   MOTORS_GPIO_M1_PORT   : GPIO_Port renames GPIO_A;
   MOTORS_GPIO_M1_PIN    : GPIO_Pin  renames Pin_1;
   MOTORS_GPIO_POINT_M1  : GPIO_Point renames PA1;
   MOTORS_GPIO_AF_M1     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M1       : PWM_Modulator renames Timer_2_PWM;
   MOTORS_TIM_CHANNEL_M1 : constant Timer_Channel := Channel_2;

   MOTORS_GPIO_M2_PORT   : GPIO_Port renames GPIO_B;
   MOTORS_GPIO_M2_PIN    : GPIO_Pin  renames Pin_11;
   MOTORS_GPIO_POINT_M2  : GPIO_Point renames PB11;
   MOTORS_GPIO_AF_M2     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M2       : PWM_Modulator renames Timer_2_PWM;
   MOTORS_TIM_CHANNEL_M2 : constant Timer_Channel := Channel_4;

   MOTORS_GPIO_M3_PORT   : GPIO_Port renames GPIO_A;
   MOTORS_GPIO_M3_PIN    : GPIO_Pin  renames Pin_15;
   MOTORS_GPIO_POINT_M3  : GPIO_Point renames PA15;
   MOTORS_GPIO_AF_M3     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIMER_M3       : PWM_Modulator renames Timer_2_PWM;
   MOTORS_TIM_CHANNEL_M3 : constant Timer_Channel := Channel_1;

   MOTORS_GPIO_M4_PORT   : GPIO_Port renames GPIO_B;
   MOTORS_GPIO_M4_PIN    : GPIO_Pin  renames Pin_9;
   MOTORS_GPIO_POINT_M4  : GPIO_Point renames PB9;
   MOTORS_GPIO_AF_M4     : constant GPIO_Alternate_Function := GPIO_AF_TIM4;
   MOTORS_TIMER_M4       : PWM_Modulator renames Timer_4_PWM;
   MOTORS_TIM_CHANNEL_M4 : constant Timer_Channel := Channel_4;

   --  Procedures and constants

   --  Set the power of all the motors to zero.
   procedure Motors_Reset;

end Motors;
