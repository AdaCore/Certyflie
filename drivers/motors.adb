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

with Ada.Real_Time;    use Ada.Real_Time;

with STM32.GPIO;       use STM32.GPIO;
with STM32.Timers;     use STM32.Timers;
with STM32.Board;     use STM32.Board;

with Power_Management; use Power_Management;
with Safety;           use Safety;

package body Motors
with Refined_State => (Motors_State => (M1_Modulator,
                                        M2_Modulator,
                                        M3_Modulator,
                                        M4_Modulator))
is

   -----------------
   -- Motors_Init --
   -----------------

   procedure Motors_Init is
   begin
      --  Initialize the pwm generators

      --  Note that the first call to Initialize_PWM_Modulator will configure
      --  the underlying timer (because Configure_Generator is True), but since
      --  this timer is shared among three motors, the next two calls should
      --  not configure the timer (hence Configure_Generator is False).

      Initialize_PWM_Modulator
        (M1_Modulator,
         Generator           => MOTOR_123_Timer'Access,
         Frequency           => MOTORS_PWM_FREQUENCY,
         Configure_Generator => True);

      Initialize_PWM_Modulator
        (M2_Modulator,
         Generator           => MOTOR_123_Timer'Access,
         Frequency           => MOTORS_PWM_FREQUENCY,
         Configure_Generator => False);

      Initialize_PWM_Modulator
        (M3_Modulator,
         Generator           => MOTOR_123_Timer'Access,
         Frequency           => MOTORS_PWM_FREQUENCY,
         Configure_Generator => False);

      Initialize_PWM_Modulator
        (M4_Modulator,
         Generator           => MOTOR_4_Timer'Access,
         Frequency           => MOTORS_PWM_FREQUENCY,
         Configure_Generator => True);

      --  Attach the PWM modulators to the corresponding channels

      Attach_PWM_Channel
        (M1_Modulator,
         Channel => MOTOR_1_Channel,
         Point   => MOTOR_1,
         PWM_AF  => MOTOR_1_AF);

      Attach_PWM_Channel
        (M2_Modulator,
         Channel => MOTOR_2_Channel,
         Point   => MOTOR_2,
         PWM_AF  => MOTOR_2_AF);

      Attach_PWM_Channel
        (M3_Modulator,
         Channel => MOTOR_3_Channel,
         Point   => MOTOR_3,
         PWM_AF  => MOTOR_3_AF);

      Attach_PWM_Channel
        (M4_Modulator,
         Channel => MOTOR_4_Channel,
         Point   => MOTOR_4,
         PWM_AF  => MOTOR_4_AF);

      --  And then enable the channels
      Enable_PWM (M1_Modulator);
      Enable_PWM (M2_Modulator);
      Enable_PWM (M3_Modulator);
      Enable_PWM (M4_Modulator);

      --  Reset all the motors power to zero
      Motors_Reset;
   end Motors_Init;

   ---------------------
   -- Motor_Set_Power --
   ---------------------

   procedure Motor_Set_Power
     (ID    : Motor_ID;
      Power : T_Uint16)
   is
      Power_Percentage_F : Float;
      Power_Percentage   : Percentage;
   begin
      Power_Percentage_F :=
        Saturate ((Float (Power) / Float (T_Uint16'Last)) * 100.0,
                  0.0,
                  100.0);
      Power_Percentage := Percentage (Power_Percentage_F);

      case ID is
         when MOTOR_M1 =>
            Set_Duty_Cycle (M1_Modulator, Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (M2_Modulator, Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (M3_Modulator, Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (M4_Modulator, Power_Percentage);
      end case;
   end Motor_Set_Power;

   -------------------------------------------
   -- Motor_Set_Power_With_Bat_Compensation --
   -------------------------------------------

   procedure Motor_Set_Power_With_Bat_Compensation
     (ID    : Motor_ID;
      Power : T_Uint16)
   is
      Tmp_Thrust         : constant Float :=
                             (Float (Power) / Float (T_Uint16'Last)) * 60.0;
      Volts              : constant Float :=
                   -0.0006239 * Tmp_Thrust * Tmp_Thrust + 0.088 * Tmp_Thrust;
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
            Set_Duty_Cycle (M1_Modulator, Power_Percentage);
         when MOTOR_M2 =>
            Set_Duty_Cycle (M2_Modulator, Power_Percentage);
         when MOTOR_M3 =>
            Set_Duty_Cycle (M3_Modulator, Power_Percentage);
         when MOTOR_M4 =>
            Set_Duty_Cycle (M4_Modulator, Power_Percentage);
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

end Motors;
