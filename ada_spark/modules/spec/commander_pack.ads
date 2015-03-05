with Interfaces.C; use Interfaces.C;

package Commander_Pack
  with SPARK_Mode
is

   --  Types
   type RPY_Type is (RATE, ANGLE);
   for RPY_Type use (RATE => 0, ANGLE => 1);
   for RPY_Type'Size use Interfaces.C.int'Size;

   --  Procedures and functions
   procedure Commander_Get_RPY (Euler_Roll_Desired  : in out Float;
                                Euler_Pitch_Desired : in out Float;
                                Euler_Yaw_Desired   : in out Float)
     with
       Global => null;
   pragma Import (C, Commander_Get_RPY, "commanderGetRPY");

   procedure Commander_Get_RPY_Type (Roll_Type  : in out RPY_Type;
                                     Pitch_Type : in out RPY_Type;
                                     Yaw_Type   : in out RPY_Type)
     with
       Global => null;
   pragma Import (C, Commander_Get_RPY_Type, "commanderGetRPYType");

end Commander_Pack;
