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

   procedure C_SensFusion6_Update_Q
     (Gx : Float;
      Gy : Float;
      GZ : Float;
      Ax : Float;
      Ay : Float;
      Az : Float;
      Dt : Float)
     with
       Global => null;
   pragma Import (C, C_SensFusion6_Update_Q, "sensfusion6UpdateQ");

   procedure C_SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Angle;
      Euler_Pitch_Actual : out T_Angle;
      Euler_Yaw_Actual   : out T_Angle)
     with
       Global => null;
   pragma Import (C, C_SensFusion6_Get_Euler_RPY, "sensfusion6GetEulerRPY");

   function C_SensFusion6_Get_AccZ_Without_Gravity
     (Ax : Float;
      Ay : Float;
      Az : Float) return Float
     with
       Global => null;
   pragma Import (C,
                  C_SensFusion6_Get_AccZ_Without_Gravity,
                  "sensfusion6GetAccZWithoutGravity");

   procedure SensFusion6_Update_Q
     (Gx : T_Rate;
      Gy : T_Rate;
      Gz : T_Rate;
      Ax : T_Acc;
      Ay : T_Acc;
      Az : T_Acc;
      Dt : T_Delta_Time);

   procedure SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Angle;
      Euler_Pitch_Actual : out T_Angle;
      Euler_Yaw_Actual   : out T_Angle);


   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : Float;
      Ay : Float;
      Az : Float) return Float;


end SensFusion6_Pack;
