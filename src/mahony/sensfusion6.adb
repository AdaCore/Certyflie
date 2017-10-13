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

with Ada.Numerics; use Ada.Numerics;

with Maths;        use Maths;
with Safety;       use Safety;

package body SensFusion6
with SPARK_Mode,
  Refined_State => (SensFusion6_State => (Is_Init,
                                          Q0,
                                          Q1,
                                          Q2,
                                          Q3,
                                          Two_Kp,
                                          Two_Ki,
                                          Integral_FBx,
                                          Integral_FBy,
                                          Integral_FBz))
is

   Two_Kp : constant Float := 2.0 * 0.4;
   --  2 * proportional gain (Kp)
   Two_Ki : constant Float := 2.0 * 0.001;
   --  2 * integral gain (Ki)

   --  Integral error terms scaled by Ki.
   Integral_FBx : Float range -MAX_INTEGRAL_ERROR .. MAX_INTEGRAL_ERROR := 0.0;
   Integral_FBy : Float range -MAX_INTEGRAL_ERROR .. MAX_INTEGRAL_ERROR := 0.0;
   Integral_FBz : Float range -MAX_INTEGRAL_ERROR .. MAX_INTEGRAL_ERROR := 0.0;

   --  Subtypes used to help SPARK proving absence of runtime errors
   --  in the Mahony algorithm

   subtype T_Norm_Acc is T_Acc range -1.0 .. 1.0;
   subtype T_Norm_Mag is T_Mag range -1.0 .. 1.0;
   subtype T_Float_1  is Float range -3.0 .. 3.0;
   subtype T_Float_2  is Float range -7.0 .. 7.0;
   subtype T_Float_3  is
     Float range -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE;
   subtype T_Float_4  is Float range -MAX_RATE_CHANGE .. MAX_RATE_CHANGE;
   subtype T_Float_5  is Float range T_Rate_Rad'First - MAX_INTEGRAL_ERROR
     .. T_Rate_Rad'Last + MAX_INTEGRAL_ERROR;

   procedure Mahony_Update_Q
     (Gx, Gy, Gz : T_Rate_Rad;
      Ax, Ay, Az : T_Acc;
      Mx, My, Mz : T_Mag;
      Dt         : T_Delta_Time)
     with Inline_Always;

   procedure Mahony_Update_Q
     (Gx, Gy, Gz : T_Rate_Rad;
      Ax, Ay, Az : T_Acc;
      Dt         : T_Delta_Time)
     with Inline_Always;

   ----------------------
   -- SensFusion6_Init --
   ----------------------

   procedure SensFusion6_Init is
   begin
      if Is_Init then
         return;
      end if;

      Is_Init := True;
   end SensFusion6_Init;

   ----------------------
   -- SensFusion6_Test --
   ----------------------

   function SensFusion6_Test return Boolean is
   begin
      return Is_Init;
   end SensFusion6_Test;

   ---------------------
   -- Mahony_Update_Q --
   ---------------------

   procedure Mahony_Update_Q
     (Gx : T_Rate_Rad;
      Gy : T_Rate_Rad;
      Gz : T_Rate_Rad;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Mx : T_Mag;
      My : T_Mag;
      Mz : T_Mag;
      Dt : T_Delta_Time)
   is
      Length     : Float;
      Recip_Norm : Float;
      Norm_Ax    : T_Norm_Acc;
      Norm_Ay    : T_Norm_Acc;
      Norm_Az    : T_Norm_Acc;
      Norm_Mx    : T_Norm_Mag;
      Norm_My    : T_Norm_Mag;
      Norm_Mz    : T_Norm_Mag;
      N_Gx       : T_Rate_Rad := Gx;
      N_Gy       : T_Rate_Rad := Gy;
      N_Gz       : T_Rate_Rad := Gz;
      Q0_Q0      : Float;
      Q0_Q1      : Float;
      Q0_Q2      : Float;
      Q0_Q3      : Float;
      Q1_Q1      : Float;
      Q1_Q2      : Float;
      Q1_Q3      : Float;
      Q2_Q2      : Float;
      Q2_Q3      : Float;
      Q3_Q3      : Float;
      Hx, Hy     : Float;
      Bx, Bz     : Float;
      Half_Vx    : Float;
      Half_Vy    : Float;
      Half_Vz    : Float;
      Half_Wx    : Float;
      Half_Wy    : Float;
      Half_Wz    : Float;
      Half_Ex    : Float;
      Half_Ey    : Float;
      Half_Ez    : Float;
      Q0_Tmp     : T_Float_3;
      Q1_Tmp     : T_Float_3;
      Q2_Tmp     : T_Float_3;
      Q3_Tmp     : T_Float_3;

   begin
      Length := Sqrtf (Mx * Mx + My * My + Mz * Mz);

      --  Use IMU algorighm if magnitometer measurement is invalid
      if Length = 0.0 then
         Mahony_Update_Q (Gx, Gy, Gz, Ax, Ay, Az, Dt);

         return;
      end if;

      --  Normalize the Magnetometer measurement
      Norm_Mx := Saturate (Mx / Length, -1.0, 1.0);
      Norm_My := Saturate (My / Length, -1.0, 1.0);
      Norm_Mz := Saturate (Mz / Length, -1.0, 1.0);

      Length := Sqrtf (Ax * Ax + Ay * Ay + Az * Az);

      if Length /= 0.0 then
         --  Normalize accelerometer measurment
         Norm_Ax := Saturate (Ax / Length, -1.0, 1.0);
         Norm_Ay := Saturate (Ay / Length, -1.0, 1.0);
         Norm_Az := Saturate (Az / Length, -1.0, 1.0);

         --  Auxiliary Variables to avoid repeated arithmetic
         Q0_Q0 := Q0 * Q0;
         Q0_Q1 := Q0 * Q1;
         Q0_Q2 := Q0 * Q2;
         Q0_Q3 := Q0 * Q3;
         Q1_Q1 := Q1 * Q1;
         Q1_Q2 := Q1 * Q2;
         Q1_Q3 := Q1 * Q3;
         Q2_Q2 := Q2 * Q2;
         Q2_Q3 := Q2 * Q3;
         Q3_Q3 := Q3 * Q3;

         --  Reference direction of Earth's magnetic field
         Hx := 2.0 * (Norm_Mx * (0.5 - Q2_Q2 - Q3_Q3) +
                        Norm_My * (Q1_Q2 - Q0_Q3) + Norm_Mz * (Q1_Q3 + Q0_Q2));
         Hy := 2.0 * (Norm_Mx * (Q1_Q2 + Q0_Q3) +
                        Norm_My * (0.5 - Q1_Q1 - Q3_Q3) +
                        Norm_Mz * (Q2_Q3 - Q0_Q1));
         Bx := Sqrtf (Hx * Hx + Hy * Hy);
         Bz := 2.0 * (Norm_Mx * (Q1_Q3 - Q0_Q2) + Norm_My * (Q2_Q3 + Q0_Q1) +
                        Norm_Mz * (0.5 - Q1_Q1 - Q2_Q2));

         --  Estimated direction of gravity and magnetic field
         Half_Vx := Q1_Q3 - Q0_Q2;
         Half_Vy := Q0_Q1 + Q2_Q3;
         Half_Vz := Q0_Q0 - 0.5 + Q3_Q3;
         Half_Wx := Bx * (0.5 - Q2_Q2 - Q3_Q3) + Bz * (Q1_Q3 - Q0_Q2);
         Half_Wy := Bx * (Q1_Q2 - Q0_Q3) + Bz * (Q0_Q1 + Q2_Q3);
         Half_Wz := Bx * (Q0_Q2 + Q1_Q3) + Bz * (0.5 - Q1_Q1 - Q2_Q2);

         --  Error is sum of cross product between estimated direction and
         --  measured direction of field vectors
         Half_Ex := (Norm_Ay * Half_Vz - Norm_Az * Half_Vy) +
                    (Norm_My * Half_Wz - Norm_Mz * Half_Wy);
         Half_Ey := (Norm_Az * Half_Vx - Norm_Ax * Half_Vz) +
                    (Norm_Mz * Half_Wx - Norm_Mx * Half_Wz);
         Half_Ez := (Norm_Ax * Half_Vy - Norm_Ay * Half_Vx) +
                    (Norm_Mx * Half_Wy - Norm_My * Half_Wx);

         --  Compute and apply integral feedback if enabled
--           if Two_Ki > 0.0 then
--              Integral_FBx := Integral_FBx + Two_Ki * Half_Ex * Dt;
--              Integral_FBy := Integral_FBy + Two_Ki * Half_Ey * Dt;
--              Integral_FBz := Integral_FBz + Two_Ki * Half_Ez * Dt;
--              N_Gx := N_Gx + Integral_FBx;
--              N_Gy := N_Gy + Integral_FBy;
--              N_Gz := N_Gz + Integral_FBz;
--           else
--              Integral_FBx := 0.0;
--              Integral_FBy := 0.0;
--              Integral_FBz := 0.0;
--           end if;

         --  Apply proportional feedback
         N_Gx := N_Gx + Two_Kp * Half_Ex;
         N_Gy := N_Gy + Two_Kp * Half_Ey;
         N_Gz := N_Gz + Two_Kp * Half_Ez;
      end if;

      --  Integrate rate of change of quaternion
      N_Gx := N_Gx * (0.5 * Dt);
      N_Gy := N_Gy * (0.5 * Dt);
      N_Gz := N_Gz * (0.5 * Dt);

      Q0_Tmp := Q0 - Q1 * N_Gx - Q2 * N_Gy - Q3 * N_Gz;
      Q1_Tmp := Q1 + Q0 * N_Gx + Q2 * N_Gz - Q3 * N_Gy;
      Q2_Tmp := Q2 + Q0 * N_Gy - Q1 * N_Gz + Q3 * N_Gx;
      Q3_Tmp := Q3 + Q0 * N_Gz + Q1 * N_Gy - Q2 * N_Gx;

      --  Normalize quaternions
      Recip_Norm := Inv_Sqrt (Q0_Tmp * Q0_Tmp + Q1_Tmp * Q1_Tmp +
                                Q2_Tmp * Q2_Tmp + Q3_Tmp * Q3_Tmp);
      Q0 := Saturate (Q0_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q1 := Saturate (Q1_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q2 := Saturate (Q2_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q3 := Saturate (Q3_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
   end Mahony_Update_Q;

   ---------------------
   -- Mahony_Update_Q --
   ---------------------

   procedure Mahony_Update_Q
     (Gx : T_Rate_Rad;
      Gy : T_Rate_Rad;
      Gz : T_Rate_Rad;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time)
   is
      Recip_Norm      : Float;
      Norm_Ax         : T_Norm_Acc;
      Norm_Ay         : T_Norm_Acc;
      Norm_Az         : T_Norm_Acc;
      --  Estimated direction of gravity and vector perpendicular
      --  to magnetic flux
      Half_Vx         : constant T_Float_1 := Q1 * Q3 - Q0 * Q2;
      Half_Vy         : constant T_Float_1 := Q0 * Q1 + Q2 * Q3;
      Half_Vz         : constant T_Float_1 := Q0 * Q0 - 0.5 + Q3 * Q3;
      Half_Ex         : T_Float_2;
      Half_Ey         : T_Float_2;
      Half_Ez         : T_Float_2;
      Q0_Tmp          : T_Float_3;
      Q1_Tmp          : T_Float_3;
      Q2_Tmp          : T_Float_3;
      Q3_Tmp          : T_Float_3;
      Qa              : constant T_Quaternion := Q0;
      Qb              : constant T_Quaternion := Q1;
      Qc              : constant T_Quaternion := Q2;
      Ax_Lifted       : T_Acc_Lifted;
      Ay_Lifted       : T_Acc_Lifted;
      Az_Lifted       : T_Acc_Lifted;
      Square_Sum      : Natural_Float;
      Rate_Change_Gx  : T_Float_4 := Gx;
      Rate_Change_Gy  : T_Float_4 := Gy;
      Rate_Change_Gz  : T_Float_4 := Gy;
      Integ_FB_Gx     : T_Float_5 := Gx;
      Integ_FB_Gy     : T_Float_5 := Gy;
      Integ_FB_Gz     : T_Float_5 := Gz;

   begin
      if not ((Ax = 0.0) and (Ay = 0.0) and (Az = 0.0)) then
         --  Normalize accelerometer measurement
         Ax_Lifted := Lift_Away_From_Zero (Ax);
         Ay_Lifted := Lift_Away_From_Zero (Ay);
         Az_Lifted := Lift_Away_From_Zero (Az);
         Square_Sum := Ax_Lifted * Ax_Lifted +
           Ay_Lifted * Ay_Lifted + Az_Lifted * Az_Lifted;
         --  We ensured that Ax_Tmp, Ay_Tmp, Az_Tmp are sufficiently far away
         --  from zero with 'Lift_Away_From_Zero' function
         --  so that the Square_Sum calculation results in a value
         --  diferent from 0.0 and positive.
         Recip_Norm := Inv_Sqrt (Square_Sum);
         --  These asserts are only needed to help SPARK
         pragma Assert (Recip_Norm in 0.0 .. 2.7E+22);
         pragma Assert (Ax in -16.0 .. 16.0);
         pragma Assert (Ay in -16.0 .. 16.0);
         pragma Assert (Az in -16.0 .. 16.0);
         Norm_Ax := Saturate (Ax * Recip_Norm, -1.0, 1.0);
         Norm_Ay := Saturate (Ay * Recip_Norm, -1.0, 1.0);
         Norm_Az := Saturate (Az * Recip_Norm, -1.0, 1.0);

         --  Error is sum of cross product between estimated
         --  and measured direction of gravity
         Half_Ex := (Norm_Ay * Half_Vz - Norm_Az * Half_Vy);
         Half_Ey := (Norm_Az * Half_Vx - Norm_Ax * Half_Vz);
         Half_Ez := (Norm_Ax * Half_Vy - Norm_Ay * Half_Vx);

         --  Compute and apply integral feedback if enabled
         pragma Warnings (Off, "*condition is always*");
         if Two_Ki > 0.0 then
            Integral_FBx := Saturate (Integral_FBx + Two_Ki * Half_Ex * Dt,
                                      -MAX_INTEGRAL_ERROR,
                                      MAX_INTEGRAL_ERROR);
            Integral_FBy := Saturate (Integral_FBy + Two_Ki * Half_Ey * Dt,
                                      -MAX_INTEGRAL_ERROR,
                                      MAX_INTEGRAL_ERROR);
            Integral_FBz := Saturate (Integral_FBz + Two_Ki * Half_Ez * Dt,
                                      -MAX_INTEGRAL_ERROR,
                                      MAX_INTEGRAL_ERROR);
            --  Apply integral feedback
            Integ_FB_Gx := Gx + Integral_FBx;
            Integ_FB_Gy := Gy + Integral_FBy;
            Integ_FB_Gz := Gz + Integral_FBz;

         else
            Integral_FBx := 0.0;
            Integral_FBy := 0.0;
            Integral_FBz := 0.0;
         end if;
         pragma Warnings (On, "*condition is always*");

         --  Apply proportional feedback
         Rate_Change_Gx := Integ_FB_Gx + Two_Kp * Half_Ex;
         Rate_Change_Gy := Integ_FB_Gy + Two_Kp * Half_Ey;
         Rate_Change_Gz := Integ_FB_Gz + Two_Kp * Half_Ez;
      end if;

      --  Integrate rate of change of quaternion
      Rate_Change_Gx := Rate_Change_Gx * (0.5 * Dt);
      Rate_Change_Gy := Rate_Change_Gy * (0.5 * Dt);
      Rate_Change_Gz := Rate_Change_Gz * (0.5 * Dt);

      Q0_Tmp := Q0 +
        (-Qb * Rate_Change_Gx - Qc * Rate_Change_Gy - Q3 * Rate_Change_Gz);
      Q1_Tmp := Q1 +
        (Qa * Rate_Change_Gx + Qc * Rate_Change_Gz - Q3 * Rate_Change_Gy);
      Q2_Tmp := Q2 +
        (Qa * Rate_Change_Gy - Qb * Rate_Change_Gz + Q3 * Rate_Change_Gx);
      Q3_Tmp := Q3 +
        (Qa * Rate_Change_Gz + Qb * Rate_Change_Gy - Qc * Rate_Change_Gx);

      --  These asserts are only needed to help SPARK
      pragma Assert
        (Q0_Tmp in -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE);
      pragma Assert
        (Q1_Tmp in -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE);
      pragma Assert
        (Q2_Tmp in -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE);
      pragma Assert
        (Q3_Tmp in -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE);

      --  Normalize quaternions
      Recip_Norm := Inv_Sqrt (Q0_Tmp * Q0_Tmp + Q1_Tmp * Q1_Tmp +
                                Q2_Tmp * Q2_Tmp + Q3_Tmp * Q3_Tmp);
      Q0 := Saturate (Q0_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q1 := Saturate (Q1_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q2 := Saturate (Q2_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
      Q3 := Saturate (Q3_Tmp * Recip_Norm,
                      T_Quaternion'First,
                      T_Quaternion'Last);
   end Mahony_Update_Q;

   --------------------------
   -- SensFusion6_Update_Q --
   --------------------------

   procedure SensFusion6_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Mx : T_Mag;
      My : T_Mag;
      Mz : T_Mag;
      Dt : T_Delta_Time)
   is
      --  Translate rates in degree to radians
      Rad_Gx : constant T_Rate_Rad := Gx * Pi / 180.0;
      Rad_Gy : constant T_Rate_Rad := Gy * Pi / 180.0;
      Rad_Gz : constant T_Rate_Rad := Gz * Pi / 180.0;

   begin
      Mahony_Update_Q
        (Rad_Gx, Rad_Gy, Rad_Gz,
         Ax, Ay, Az,
         Mx, My, Mz,
         Dt);
   end SensFusion6_Update_Q;

   -------------------------------
   -- SensFusion6_Get_Euler_RPY --
   -------------------------------

   procedure SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Degrees;
      Euler_Pitch_Actual : out T_Degrees;
      Euler_Yaw_Actual   : out T_Degrees)
   is
      Grav_X : Float;
      Grav_Y : Float;
      Grav_Z : Float;
   begin
      --  Estimated gravity direction
      Grav_X := 2.0 * (Q1 * Q3 - Q0 * Q2);
      Grav_Y := 2.0 * (Q0 * Q1 + Q2 * Q3);
      Grav_Z := Q0 * Q0 - Q1 * Q1 - Q2 * Q2 + Q3 * Q3;

      Grav_X := Saturate (Grav_X, -1.0, 1.0);

      Euler_Yaw_Actual :=
        Atan (2.0 * (Q0 * Q3 + Q1 * Q2),
              Q0 * Q0 + Q1 * Q1 - Q2 * Q2 - Q3 * Q3) * 180.0 / Pi;
      --  Pitch seems to be inverted
      Euler_Pitch_Actual := Asin (Grav_X) * 180.0 / Pi;
      Euler_Roll_Actual := Atan (Grav_Y, Grav_Z) * 180.0 / Pi;
   end SensFusion6_Get_Euler_RPY;

   ------------------------------------------
   -- SensFusion6_Get_AccZ_Without_Gravity --
   ------------------------------------------

   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc) return Float
   is
      Grav_X : Float range -4.0 .. 4.0;
      Grav_Y : Float range -4.0 .. 4.0;
      Grav_Z : Float range -4.0 .. 4.0;
   begin
      --  Estimated gravity direction

      Grav_X := 2.0 * (Q1 * Q3 - Q0 * Q2);

      Grav_Y := 2.0 * (Q0 * Q1 + Q2 * Q3);

      Grav_Z := Q0 * Q0 - Q1 * Q1 - Q2 * Q2 + Q3 * Q3;

      --  Return vertical acceleration without gravity
      --  (A dot G) / |G| - 1G (|G| = 1) -> (A dot G) - 1G
      return (Ax * Grav_X + Ay * Grav_Y + Az * Grav_Z) - 1.0;
   end SensFusion6_Get_AccZ_Without_Gravity;

end SensFusion6;
