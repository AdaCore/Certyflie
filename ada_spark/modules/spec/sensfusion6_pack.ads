with Types; use Types;

package SensFusion6_Pack
with SPARK_Mode
is
   --  Global variables and constants

   Q0 : T_Quaternion := 1.0;
   Q1 : T_Quaternion := 0.0;
   Q2 : T_Quaternion := 0.0;
   --  quaternion of sensor frame relative to auxiliary frame
   Q3 : T_Quaternion := 0.0;

   Is_Init : Boolean := False;


   --  Procedures and functions

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

   procedure SensFusion6_Get_Euler_RPY
     (Euler_Roll_Actual  : out T_Angle;
      Euler_Pitch_Actual : out T_Angle;
      Euler_Yaw_Actual   : out T_Angle);


   function SensFusion6_Get_AccZ_Without_Gravity
     (Ax : Float;
      Ay : Float;
      Az : Float) return Float;


end SensFusion6_Pack;
