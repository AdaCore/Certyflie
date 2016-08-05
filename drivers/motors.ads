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

with Types;             use Types;

with STM32.GPIO;      use STM32.GPIO;
with STM32;           use STM32;
with STM32.PWM;       use STM32.PWM;
with STM32.Timers;    use STM32.Timers;
with STM32.Device;    use STM32.Device;

package Motors
   with Abstract_State => Motors_State
is

   --  Types

   type Motor_ID is (MOTOR_M1, MOTOR_M2, MOTOR_M3, MOTOR_M4);

   --  Procedures and functions

   --  Initialize the motors.
   procedure Motors_Init
     with
     Global => (In_Out => Motors_State);

   --  Apply an absolute power to the given motor.
   procedure Motor_Set_Power
     (ID    : Motor_ID;
      Power : T_Uint16)
     with
       Global => (In_Out => Motors_State);

   --  Apply power to the given motor with a compensation
   --  according to the battery level.
   procedure Motor_Set_Power_With_Bat_Compensation
     (ID    : Motor_ID;
      Power : T_Uint16)
     with
       Global => (In_Out => Motors_State);

   --  Test all the Crazyflie motors.
   function Motors_Test return Boolean
     with
       Global => (Input => Motors_State);

   --  Set the power of all the motors to zero.
   procedure Motors_Reset
     with
       Global => (In_Out => Motors_State);

private
   --  Global variables and constants

   --  Constants used to configure PWM.
   MOTORS_PWM_FREQUENCY : constant := 328_000.0; --  328 KHz
   MOTORS_PWM_PRESCALE  : constant := 0;

   --  Constants used for testing.
   MOTORS_TEST_RATIO         : constant := 13_000;
   MOTORS_TEST_ON_TIME_MS    : constant := 50;
   MOTORS_TEST_DELAY_TIME_MS : constant := 150;

   PWM_TIMER_M1_M2_M3        : aliased PWM_Timer (Timer_2'Access);
   PWM_TIMER_M4              : aliased PWM_Timer (Timer_4'Access);

   --  Constants used to configure the proper GPIO Ports and pins
   --  to communicate with the motors.
   MOTORS_GPIO_M1_POINT  : constant GPIO_Point := PA1;
   MOTORS_GPIO_AF_M1     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIM_CHANNEL_M1 : constant Timer_Channel := Channel_2;

   MOTORS_GPIO_M2_POINT  : constant GPIO_Point := PB11;
   MOTORS_GPIO_AF_M2     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIM_CHANNEL_M2 : constant Timer_Channel := Channel_4;

   MOTORS_GPIO_M3_POINT  : constant GPIO_Point := PA15;
   MOTORS_GPIO_AF_M3     : constant GPIO_Alternate_Function := GPIO_AF_TIM2;
   MOTORS_TIM_CHANNEL_M3 : constant Timer_Channel := Channel_1;

   MOTORS_GPIO_M4_POINT  : constant GPIO_Point := PB9;
   MOTORS_GPIO_AF_M4     : constant GPIO_Alternate_Function := GPIO_AF_TIM4;
   MOTORS_TIM_CHANNEL_M4 : constant Timer_Channel := Channel_4;

   --  PWM modulators
   M1_Modulator          : PWM_Modulator
     with
       Part_Of => Motors_State;
   M2_Modulator          : PWM_Modulator
     with
       Part_Of => Motors_State;
   M3_Modulator          : PWM_Modulator
     with
       Part_Of => Motors_State;
   M4_Modulator          : PWM_Modulator
     with
       Part_Of => Motors_State;

end Motors;
