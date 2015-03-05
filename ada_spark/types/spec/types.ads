with IMU_Pack; use IMU_Pack;

package Types is

   --  General types
   subtype Positive_Float is Float range 0.0 .. Float'Last;

   --  Allowed delta time range
   subtype T_Delta_Time   is Float range IMU_UPDATE_DT .. 1.0;

   --  Angle range type, in degrees.
   subtype T_Angle        is Float range -360.0 .. 360.0;

   --  Allowed speed range, in m/s
   subtype T_Speed        is Float range -2000.0 .. 2000.0;

end Types;
