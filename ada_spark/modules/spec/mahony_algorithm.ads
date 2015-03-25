with Types; use Types;
with IMU_Pack; use IMU_Pack;
with SensFusion6_Pack; use SensFusion6_Pack;

--  MAHONY_QUATERNION_IMU
--  Madgwick's implementation of Mayhony's AHRS algorithm.
--  See: http:-- www.x-io.co.uk/open-source-ahrs-with-x-imu
--
--  Date     Author      Notes
--  29/09/2011 SOH Madgwick    Initial release
--  02/10/2011 SOH Madgwick  Optimised for reduced CPU load

package Mahony_Algorithm
  with SPARK_Mode
is

   --  Global variables and constants

   TWO_KP_DEF  : constant Float := (2.0 * 0.4);   --  2 * proportional gain
   TWO_KI_DEF  : constant Float := (2.0 * 0.001); --  2 * integral gain

   Two_Kp       : Float := TWO_KP_DEF; --  2 * proportional gain (Kp)
   Two_Ki       : Float := TWO_KI_DEF; --  2 * integral gain (Ki)
   Integral_FBx : Float := 0.0;
   Integral_FBy : Float := 0.0;
   Integral_FBz : Float := 0.0; --  integral error terms scaled by Ki

   --  Procedures and functions

   procedure Mahony_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time);


end Mahony_Algorithm;
