with Types; use Types;

package SensFusion6_Pack
with SPARK_Mode
is

   --  Procedures and functions
   procedure SensFusion6_Update_Q (Gx : Float;
                                   Gy : Float;
                                   GZ : Float;
                                   Ax : Float;
                                   Ay : Float;
                                   Az : Float;
                                   Dt : Float)
     with
       Global => null;
   pragma Import (C, SensFusion6_Update_Q, "sensfusion6UpdateQ");

   procedure SensFusion6_Get_Euler_RPY (Euler_Roll_Actual  : out T_Angle;
                                        Euler_Pitch_Actual : out T_Angle;
                                        Euler_Yaw_Actual   : out T_Angle)
     with
       Global => null;
   pragma Import (C, SensFusion6_Get_Euler_RPY, "sensfusion6GetEulerRPY");

   function SensFusion6_Get_AccZ_Without_Gravity (Ax : Float;
                                                  Ay : Float;
                                                  AZ : Float) return Float
     with
       Global => null;
   pragma Import (C,
                  SensFusion6_Get_AccZ_Without_Gravity,
                  "sensfusion6GetAccZWithoutGravity");

end SensFusion6_Pack;
