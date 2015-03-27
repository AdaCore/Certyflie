with Maths_Pack; use Maths_Pack;
with Safety_Pack; use Safety_Pack;
with Config; use Config;

with Interfaces.C; use Interfaces.C;

package body SensFusion6_Pack
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
   procedure SensFusion6_Init is
   begin
      if Is_Init = 1 then
         return;
      end if;

      Is_Init := 1;
   end SensFusion6_Init;

   function SensFusion6_Test return bool is
   begin
      return Is_Init;
   end SensFusion6_Test;

   procedure SensFusion6_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time) is
   begin
      case SENSOR_FUSION_ALGORITHM is
         when MAHONY => Mahony_Update_Q (Gx,
                                         Gy,
                                         Gz,
                                         Ax,
                                         Ay,
                                         Az,
                                         Dt);
         when others => Mahony_Update_Q (Gx,
                                         Gy,
                                         Gz,
                                         Ax,
                                         Ay,
                                         Az,
                                         Dt);
      end case;
   end SensFusion6_Update_Q;

   procedure SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Degrees;
      Euler_Pitch_Actual : out T_Degrees;
      Euler_Yaw_Actual   : out T_Degrees) is
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
        Atan_2 (2.0 * (Q0 * Q3 + Q1 * Q2),
                Q0 * Q0 + Q1 * Q1 - Q2 * Q2 - Q3 * Q3) * 180.0 / PI;
      --  Pitch seems to be inverted
      Euler_Pitch_Actual := Asin (Grav_X) * 180.0 / PI;
      Euler_Roll_Actual := Atan_2 (Grav_Y, Grav_Z) * 180.0 / PI;
   end SensFusion6_Get_Euler_RPY;

   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc) return Float is
      Grav_X : Float range -4.0 .. 4.0;
      Grav_Y : Float range -4.0 .. 4.0;
      Grav_Z : Float range -4.0 .. 4.0;
   begin
      --  Estimated gravity direction

      Grav_X := 2.0 * (Q1 * Q3 - Q0 * Q2);

      Grav_Y := 2.0 * (Q0 * Q1 + Q2 * Q3);

      Grav_Z := Q0 * Q0 - Q1 * Q1 - Q2 * Q2 + Q3 * Q3;

      --  Feturn vertical acceleration without gravity
      --  (A dot G) / |G| - 1G (|G| = 1) -> (A dot G) - 1G
      return (Ax * Grav_X + Ay * Grav_Y + Az * Grav_Z) - 1.0;
   end SensFusion6_Get_AccZ_Without_Gravity;

   procedure Mahony_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time) is
      Recip_Norm    : Float;
      Norm_Ax       : T_Acc;
      Norm_Ay       : T_Acc;
      Norm_Az       : T_Acc;
      --  Conversion from degrees/s to rad/s
      Rad_Gx        : Float := Gx * PI / 180.0;
      Rad_Gy        : Float := Gy * PI / 180.0;
      Rad_Gz        : Float := Gz * PI / 180.0;
      --  Estimated direction of gravity and vector perpendicular
      --  to magnetic flux
      Half_Vx       : Float := Q1 * Q3 - Q0 * Q2;
      Half_Vy       : Float := Q0 * Q1 + Q2 * Q3;
      Half_Vz       : Float := Q0 * Q0 - 0.5 + Q3 * Q3;
      Half_Ex       : Float;
      Half_Ey       : Float;
      Half_Ez       : Float;
      Q0_Tmp        : Float;
      Q1_Tmp        : Float;
      Q2_Tmp        : Float;
      Q3_Tmp        : Float;
      Qa            : T_Quaternion := Q0;
      Qb            : T_Quaternion := Q1;
      Qc            : T_Quaternion := Q2;

   begin
      --  Compute feedback only if accelerometer measurement valid
      --  (avoids NaN in accelerometer normalisation)
      if (not ((Ax = 0.0) and (Ay = 0.0) and (Az = 0.0))) then
         --  Normalize accelerometer measurement
         Recip_Norm := Inv_Sqrt (Ax * Ax + Ay * Ay + Az * Az);
         Norm_Ax := Ax * Recip_Norm;
         Norm_Ay := Ay * Recip_Norm;
         Norm_Az := Az * Recip_Norm;

         --  Error is sum of cross product between estimated
         --  and measured direction of gravity
         Half_Ex := (Norm_Ay * Half_Vz - Norm_Az * Half_Vy);
         Half_Ey := (Norm_Az * Half_Vx - Norm_Ax * Half_Vz);
         Half_Ez := (Norm_Ax * Half_Vy - Norm_Ay * Half_Vx);

         --  Compute and apply integral feedback if enabled
         if Two_Ki > 0.0 then
            Integral_FBx := Integral_FBx + Two_Ki * Half_Ex * Dt;
            Integral_FBy := Integral_FBy + Two_Ki * Half_Ey * Dt;
            Integral_FBz := Integral_FBz + Two_Ki * Half_Ez * Dt;
            Rad_Gx := Rad_Gx + Integral_FBx;
            Rad_Gy := Rad_Gy + Integral_FBy;
            Rad_Gz := Rad_Gz + Integral_FBz;
         else
            Integral_FBx := 0.0;
            Integral_FBy := 0.0;
            Integral_FBz := 0.0;
         end if;

         --  Apply proportional feedback
         Rad_Gx := Rad_Gx + Two_Kp * Half_Ex;
         Rad_Gy := Rad_Gy + Two_Kp * Half_Ey;
         Rad_Gz := Rad_Gz + Two_Kp * Half_Ez;
      end if;

      --  Integrate rate of change of quaternion
      Rad_Gx := Rad_Gx * (0.5 * Dt);
      Rad_Gy := Rad_Gy * (0.5 * Dt);
      Rad_Gz := Rad_Gz * (0.5 * Dt);

      Q0_Tmp := Q0 + (-Qb * Rad_Gx - Qc * Rad_Gy - Q3 * Rad_Gz);
      Q1_Tmp := Q1 + (Qa * Rad_Gx + Qc * Rad_Gz - Q3 * Rad_Gy);
      Q2_Tmp := Q2 + (Qa * Rad_Gy - Qb * Rad_Gz + Q3 * Rad_Gx);
      Q3_Tmp := Q3 + (Qa * Rad_Gz + Qb * Rad_Gy - Qc * Rad_Gx);

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

end SensFusion6_Pack;
