with Types; use Types;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with IMU_Pack; use IMU_Pack;

package SensFusion6_Pack
with SPARK_Mode
is
   --  Global variables and constants

   Q0 : T_Quaternion := 1.0;
   Q1 : T_Quaternion := 0.0;
   Q2 : T_Quaternion := 0.0;
   --  quaternion of sensor frame relative to auxiliary frame
   Q3 : T_Quaternion := 0.0;

   pragma Export (C, Q0, "q0");
   pragma Export (C, Q1, "q1");
   pragma Export (C, Q2, "q2");
   pragma Export (C, Q3, "q3");

   Is_Init : bool := 0;

   --  Procedures and functions

   procedure SensFusion6_Init;

   function SensFusion6_Test return bool;

   procedure SensFusion6_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time);

   procedure SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Degrees;
      Euler_Pitch_Actual : out T_Degrees;
      Euler_Yaw_Actual   : out T_Degrees);


   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc) return Float;


end SensFusion6_Pack;
