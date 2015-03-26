with Maths_Pack; use Maths_Pack;
with Safety_Pack; use Safety_Pack;
with Mahony_Algorithm; use Mahony_Algorithm;
with Config; use Config;

with Interfaces.C; use Interfaces.C;

package body SensFusion6_Pack
with SPARK_Mode
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
     (Euler_Roll_Actual  : out T_Angle;
      Euler_Pitch_Actual : out T_Angle;
      Euler_Yaw_Actual   : out T_Angle) is
      Grav_X : Float;
      Grav_Y : Float;
      Grav_Z : Float;
   begin
      --  Estimated gravity direction
      Grav_X := 2.0 * (Q1 * Q3 - Q0 * Q2);
      Grav_Y := 2.0 * (Q0 * Q1 + Q2 * Q3);
      Grav_Z := Q0 * Q0 - Q1 * Q1 - Q2 * Q2 + Q3 * Q3;

      Grav_X := Constrain (Grav_X, -1.0, 1.0);

      Euler_Yaw_Actual :=
        Atan_2 (2.0 * (Q0 * Q3 + Q1 * Q2),
                Q0 * Q0 + Q1 * Q1 - Q2 * Q2 - Q3 * Q3) * 180.0 / PI;
      --  Pitch seems to be inverted
      Euler_Pitch_Actual := Asin (Grav_X) * 180.0 / PI;
      Euler_Roll_Actual := Atan_2 (Grav_Y, Grav_Z) * 180.0 / PI;
   end SensFusion6_Get_Euler_RPY;

   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : Float;
      Ay : Float;
      Az : Float) return Float is
      Grav_X : Float;
      Grav_Y : Float;
      Grav_Z : Float;
   begin
      --  Estimated gravity direction
      Grav_X := 2.0 * (Q1 * Q3 - Q0 * Q2);
      Grav_Y := 2.0 * (Q0 * Q1 + Q2 * Q3);
      Grav_Z := Q0 * Q0 - Q1 * Q1 - Q2 * Q2 + Q3 * Q3;

      --  Feturn vertical acceleration without gravity
      --  (A dot G) / |G| - 1G (|G| = 1) -> (A dot G) - 1G
      return (Ax * Grav_X + Ay * Grav_Y + Az * Grav_Z) - 1.0;
   end SensFusion6_Get_AccZ_Without_Gravity;


end SensFusion6_Pack;
