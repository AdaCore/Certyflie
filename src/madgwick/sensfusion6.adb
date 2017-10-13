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

with Config;       use Config;
with Maths;        use Maths;
with Safety;       use Safety;

package body SensFusion6
with SPARK_Mode,
  Refined_State => (SensFusion6_State => (Is_Init,
                                          Q0,
                                          Q1,
                                          Q2,
                                          Q3))
is

   --  Needed for Madgwick algorithm.
   Beta : constant T_Alpha := 0.08;

   --  Subtypes used to help SPARK proving absence of runtime errors
   --  in the Mahony algorithm

   subtype T_Norm_Acc is T_Acc range -1.0 .. 1.0;
   subtype T_Norm_Mag is T_Mag range -1.0 .. 1.0;
   subtype T_Float_3  is
     Float range -4.0 * MAX_RATE_CHANGE .. 4.0 * MAX_RATE_CHANGE;

   procedure Madgwick_Update_Q
     (Gx, Gy, Gz : T_Rate_Rad;
      Ax, Ay, Az : T_Acc;
      Mx, My, Mz : T_Mag;
      Dt : T_Delta_Time);
   --  Madgwick sensorfusion algorithm implementation.
   --  9 sensors fusion version (IMU + magnetometer);

   procedure Madgwick_Update_Q
     (Gx, Gy, Gz : T_Rate_Rad;
      Ax, Ay, Az : T_Acc;
      Dt : T_Delta_Time);
   --  Madgwick sensorfusion algorithm implementation.
   --  IMU version of the algorithm (without magnetometer);

   -----------------------
   -- Madgwick_Update_Q --
   -----------------------

   procedure Madgwick_Update_Q
     (Gx, Gy, Gz : T_Rate_Rad;
      Ax, Ay, Az : T_Acc;
      Mx, My, Mz : T_Mag;
      Dt         : T_Delta_Time)
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
      Q0_Mx_X2   : Float;
      Q0_My_X2   : Float;
      Q0_Mz_X2   : Float;
      Q1_Mx_X2   : Float;
      Q0_X2      : Float;
      Q1_X2      : Float;
      Q2_X2      : Float;
      Q3_X2      : Float;
      Q0_Q2_X2   : Float;
      Q2_Q3_X2   : Float;
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
      Q_Dot1     : Float;
      Q_Dot2     : Float;
      Q_Dot3     : Float;
      Q_Dot4     : Float;
      Hx, Hy     : Float;
      Bx2, Bz2   : Float;
      Bx4, Bz4   : Float;
      S0         : Float;
      S1         : Float;
      S2         : Float;
      S3         : Float;
      Q0_Tmp     : T_Float_3;
      Q1_Tmp     : T_Float_3;
      Q2_Tmp     : T_Float_3;
      Q3_Tmp     : T_Float_3;

   begin
      Length := Sqrtf (Mx * Mx + My * My + Mz * Mz);

      --  Use IMU algorithm if magnetometer measurement is invalid
      if Length = 0.0 then
         Madgwick_Update_Q (Gx, Gy, Gz, Ax, Ay, Az, Dt);

         return;
      end if;

      --  Rate of change of quaternion from gyroscope
      Q_Dot1 := 0.5 * (-Q1 * Gx - Q2 * Gy - Q3 * Gz);
      Q_Dot2 := 0.5 * (Q0 * Gx + Q2 * Gz - Q3 * Gy);
      Q_Dot3 := 0.5 * (Q0 * Gy - Q1 * Gz + Q3 * Gx);
      Q_Dot4 := 0.5 * (Q0 * Gz + Q1 * Gy - Q2 * Gx);

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
         Q0_Mx_X2 := 2.0 * Q0 * Mx;
         Q0_My_X2 := 2.0 * Q0 * My;
         Q0_Mz_X2 := 2.0 * Q0 * Mz;
         Q1_Mx_X2 := 2.0 * Q1 * Mx;
         Q0_X2    := 2.0 * Q0;
         Q1_X2    := 2.0 * Q1;
         Q2_X2    := 2.0 * Q2;
         Q3_X2    := 2.0 * Q3;
         Q0_Q2_X2 := 2.0 * Q0 * Q2;
         Q2_Q3_X2 := 2.0 * Q2 * Q3;
         Q0_Q0    := Q0 * Q0;
         Q0_Q1    := Q0 * Q1;
         Q0_Q2    := Q0 * Q2;
         Q0_Q3    := Q0 * Q3;
         Q1_Q1    := Q1 * Q1;
         Q1_Q2    := Q1 * Q2;
         Q1_Q3    := Q1 * Q3;
         Q2_Q2    := Q2 * Q2;
         Q2_Q3    := Q2 * Q3;
         Q3_Q3    := Q3 * Q3;

         --  Reference direction of Earth's magnetic field
         Hx := Norm_Mx * Q0_Q0 - Q0_My_X2 * Q3 + Q0_Mz_X2 * Q2 +
           Norm_Mx * Q1_Q1 + Q1_X2 * Norm_My * Q2 + Q1_X2 * Norm_Mz * Q3 -
             Norm_Mx * Q2_Q2 - Norm_Mx * Q3_Q3;
         Hy := Q0_Mx_X2 * Q3 + Norm_My * Q0_Q0 - Q0_My_X2 * Q1 +
           Q1_Mx_X2 * Q2 - Norm_My * Q1_Q1 + Norm_My * Q2_Q2 +
             Q2_X2 * Norm_Mz * Q3 - Norm_My * Q3_Q3;

         Bx2 := Sqrtf (Hx ** 2 + Hy ** 2);
         Bz2 := -Q0_Mx_X2 * Q2 + Q0_My_X2 * Q1 + Norm_Mz * Q0_Q0 +
           Q1_Mx_X2 * Q3 - Norm_Mz * Q1_Q1 + Q2_X2 * Norm_My * Q3 -
             Norm_Mz * Q2_Q2 + Mz * Q3_Q3;
         Bx4 := 2.0 * Bx2;
         Bz4 := 2.0 * Bz2;

         --  Gradient descent algorithm corrective step
         S0 := -Q2_X2 * (2.0 * Q1_Q3 - Q0_Q2_X2 - Norm_Ax) +
           Q1_X2 * (2.0 * Q0_Q1 + Q2_Q3_X2 - Norm_Ay) -
           Bz2 * Q2 * (Bx2 * (0.5 - Q2_Q2 - Q3_Q3) +
                           Bz2 * (Q1_Q3 - Q0_Q2) - Norm_Mx) +
           (-Bx2 * Q3 + Bz2 * Q1) *
           (Bx2 * (Q1_Q2 - Q0_Q3) + Bz2 * (Q0_Q1 + Q2_Q3) - Norm_My) +
           Bx2 * Q2 * (Bx2 * (Q0_Q2 + Q1_Q3) +
                             Bz2 * (0.5 - Q1_Q1 - Q2_Q2) - Norm_Mz);

         S1 := Q3_X2 * (2.0 * Q1_Q3 - Q0_Q2_X2 - Norm_Ax) +
           Q0_X2 * (2.0 * Q0_Q1 + Q2_Q3_X2 - Norm_Ay) -
           4.0 * Q1 * (1.0 - 2.0 * Q1_Q1 - 2.0 * Q2_Q2 - Norm_Az) +
           Bz2 * Q3 * (Bx2 * (0.5 - Q2_Q2 - Q3_Q3) +
                           Bz2 * (Q1_Q3 - Q0_Q2) - Norm_Mx) +
           (Bx2 * Q2 + Bz2 * Q0) * (Bx2 * (Q1_Q2 - Q0_Q3) +
                                      Bz2 * (Q0_Q1 + Q2_Q3) - Norm_My) +
           (Bx2 * Q3 - Bz4 * Q1) * (Bx2 * (Q0_Q2 + Q1_Q3) +
                                      Bz2 * (0.5 - Q1_Q1 - Q2_Q2) - Norm_Mz);

         S2 := -Q0_X2 * (2.0 * Q1_Q3 - Q0_Q2_X2 - Norm_Ax) +
           Q3_X2 * (2.0 * Q0_Q1 + Q2_Q3_X2 - Norm_Ay) -
           4.0 * Q2 * (1.0 - 2.0 * Q1_Q1 - 2.0 * Q2_Q2 - Norm_Az) +
           (-Bx4 * Q2 - Bz2 * Q0) * (Bx2 * (0.5 - Q2_Q2 - Q3_Q3) +
                                       Bz2 * (Q1_Q3 - Q0_Q2) - Norm_Mx) +
           (Bx2 * Q1 + Bz2 * Q3) * (Bx2 * (Q1_Q2 - Q0_Q3) +
                                      Bz2 * (Q0_Q1 + Q2_Q3) - Norm_My) +
           (Bx2 * Q0 - Bz4 * Q2) * (Bx2 * (Q0_Q2 + Q1_Q3) +
                                      Bz2 * (0.5 - Q1_Q1 - Q2_Q2) - Norm_Mz);

         S3 := Q1_X2 * (2.0 * Q1_Q3 - Q0_Q2_X2 - Norm_Ax) +
           Q2_X2 * (2.0 * Q0_Q1 + Q2_Q3_X2 - Norm_Ay) +
           (-Bx4 * Q3 + Bz2 * Q1) * (Bx2 * (0.5 - Q2_Q2 - Q3_Q3) +
                                       Bz2 * (Q1_Q3 - Q0_Q2) - Norm_Mx) +
           (-Bx2 * Q0 + Bz2 * Q2) * (Bx2 * (Q1_Q2 - Q0_Q3) +
                                       Bz2 * (Q0_Q1 + Q2_Q3) - Norm_My) +
           Bx2 * Q1 * (Bx2 * (Q0_Q2 + Q1_Q3) +
                           Bz2 * (0.5 - Q1_Q1 - Q2_Q2) - Norm_Mz);

         --  Normalize step magnitudes
         Recip_Norm := Inv_Sqrt (S0 * S0 + S1 * S1 + S2 * S2 + S3 * S3);
         S0 := S0 * Recip_Norm;
         S1 := S1 * Recip_Norm;
         S2 := S2 * Recip_Norm;
         S3 := S3 * Recip_Norm;

         --  Apply feedback step
         Q_Dot1 := Q_Dot1 - Beta * S0;
         Q_Dot2 := Q_Dot2 - Beta * S1;
         Q_Dot3 := Q_Dot3 - Beta * S2;
         Q_Dot4 := Q_Dot4 - Beta * S3;
      end if;

      --  Integrate rate of change of quaternion to yield quaternion
      Q0_Tmp := Q0 + Q_Dot1 * Dt;
      Q1_Tmp := Q1 + Q_Dot2 * Dt;
      Q2_Tmp := Q2 + Q_Dot3 * Dt;
      Q3_Tmp := Q3 + Q_Dot4 * Dt;

      --  Normalize quaternion
      Recip_Norm :=
        Inv_Sqrt (Q0_Tmp ** 2 + Q1_Tmp ** 2 + Q2_Tmp ** 2 + Q3_Tmp ** 2);
      Q0 :=
        Saturate (Q0_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q1 :=
        Saturate (Q1_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q2 :=
        Saturate (Q2_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q3 :=
        Saturate (Q3_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
   end Madgwick_Update_Q;

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

   -----------------------
   -- Madgwick_Update_Q --
   -----------------------

   procedure Madgwick_Update_Q
     (Gx : T_Rate_Rad;
      Gy : T_Rate_Rad;
      Gz : T_Rate_Rad;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time)
   is
      Recip_Norm    : Float;
      S0            : Float;
      S1            : Float;
      S2            : Float;
      S3            : Float;
      Q_Dot1        : Float;
      Q_Dot2        : Float;
      Q_Dot3        : Float;
      Q_Dot4        : Float;
      Q0_X2         : Float;
      Q1_X2         : Float;
      Q2_X2         : Float;
      Q3_X2         : Float;
      Q0_X4         : Float;
      Q1_X4         : Float;
      Q2_X4         : Float;
      Q1_X8         : Float;
      Q2_X8         : Float;
      Q0_Q0         : Float;
      Q1_Q1         : Float;
      Q2_Q2         : Float;
      Q3_Q3         : Float;
      Norm_Ax       : T_Acc;
      Norm_Ay       : T_Acc;
      Norm_Az       : T_Acc;
      Q0_Tmp        : Float;
      Q1_Tmp        : Float;
      Q2_Tmp        : Float;
      Q3_Tmp        : Float;

   begin
      --  Rate of change of quaternion from gyroscope
      Q_Dot1 := 0.5 * (-Q1 * Gx - Q2 * Gy - Q3 * Gz);
      Q_Dot2 := 0.5 * (Q0 * Gx + Q2 * Gz - Q3 * Gy);
      Q_Dot3 := 0.5 * (Q0 * Gy - Q1 * Gz + Q3 * Gx);
      Q_Dot4 := 0.5 * (Q0 * Gz + Q1 * Gy - Q2 * Gx);

      --  Compute feedback only if accelerometer measurement valid
      --  (avoids NaN in accelerometer normalisation)

      Recip_Norm := Sqrtf (Ax * Ax + Ay * Ay + Az * Az);

      if Recip_Norm /= 0.0 then
         --  Normalize accelerometer measurement
         Norm_Ax := Saturate (Ax / Recip_Norm, -1.0, 1.0);
         Norm_Ay := Saturate (Ay / Recip_Norm, -1.0, 1.0);
         Norm_Az := Saturate (Az / Recip_Norm, -1.0, 1.0);

         --  Auxiliary variables to avoid repeated arithmetic
         Q0_X2 := 2.0 * Q0;
         Q1_X2 := 2.0 * Q1;
         Q2_X2 := 2.0 * Q2;
         Q3_X2 := 2.0 * Q3;
         Q0_X4 := 4.0 * Q0;
         Q1_X4 := 4.0 * Q1;
         Q2_X4 := 4.0 * Q2;
         Q1_X8 := 8.0 * Q1;
         Q2_X8 := 8.0 * Q2;
         Q0_Q0 := Q0 * Q0;
         Q1_Q1 := Q1 * Q1;
         Q2_Q2 := Q2 * Q2;
         Q3_Q3 := Q3 * Q3;

         --  Gradient descent algorithm corrective step
         S0 := Q0_X4 * Q2_Q2 + Q2_X2 * Norm_Ax +
           Q0_X4 * Q1_Q1 - Q1_X2 * Norm_Ay;
         S1 := Q1_X4 * Q3_Q3 - Q3_X2 * Norm_Ax + 4.0 * Q0_Q0 * Q1 -
           Q0_X2 * Norm_Ay - Q1_X4 + Q1_X8 * Q1_Q1 +
             Q1_X8 * Q2_Q2 + Q1_X4 * Norm_Az;
         S2 := 4.0 * Q0_Q0 * Q2 + Q0_X2 * Norm_Ax + Q2_X4 * Q3_Q3 -
           Q3_X2 * Norm_Ay - Q2_X4 + Q2_X8 * Q1_Q1 +
             Q2_X8 * Q2_Q2 + Q2_X4 * Norm_Az;
         S3 := 4.0 * Q1_Q1 * Q3 - Q1_X2 * Norm_Ax +
           4.0 * Q2_Q2 * Q3 - Q2_X2 * Norm_Ay;

         --  Normalize step magnitudes
         Recip_Norm := Inv_Sqrt (S0 * S0 + S1 * S1 + S2 * S2 + S3 * S3);
         S0 := S0 * Recip_Norm;
         S1 := S1 * Recip_Norm;
         S2 := S2 * Recip_Norm;
         S3 := S3 * Recip_Norm;

         --  Apply feedback step
         Q_Dot1 := Q_Dot1 - Beta * S0;
         Q_Dot2 := Q_Dot2 - Beta * S1;
         Q_Dot3 := Q_Dot3 - Beta * S2;
         Q_Dot4 := Q_Dot4 - Beta * S3;
      end if;

      --  Integrate rate of change of quaternion to yield quaternion
      Q0_Tmp := Q0 + Q_Dot1 * Dt;
      Q1_Tmp := Q1 + Q_Dot2 * Dt;
      Q2_Tmp := Q2 + Q_Dot3 * Dt;
      Q3_Tmp := Q3 + Q_Dot4 * Dt;

      --  Normalize quaternion
      Recip_Norm :=
        Inv_Sqrt (Q0_Tmp ** 2 + Q1_Tmp ** 2 + Q2_Tmp ** 2 + Q3_Tmp ** 2);
      Q0 :=
        Saturate (Q0_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q1 :=
        Saturate (Q1_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q2 :=
        Saturate (Q2_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
      Q3 :=
        Saturate (Q3_Tmp * Recip_Norm, T_Quaternion'First, T_Quaternion'Last);
   end Madgwick_Update_Q;

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
      Madgwick_Update_Q
        (Rad_Gx, Rad_Gy, Rad_Gz,
         Ax, Ay, Az,
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
