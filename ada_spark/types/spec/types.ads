package Types is

   --  Types

   subtype Allowed_Floats is Float range -100_000.0 .. 100_000.0;
   subtype Delta_Time     is Float range 0.001 .. 0.999;

   --  Angle range type, in degrees.
   subtype T_Angle        is Float range -360.0 .. 360.0;

   --  These ranges are deduced from the MPU9150 specification.
   --  It corresponds to the maximum range of values that can be output
   --  by the IMU.
   subtype T_Rate is Float range -2_000.0  .. 2_000.0;
   subtype T_Acc  is Float range -16_000.0 .. 16_000.0;
   subtype T_Mag  is Float range -4_800.0  .. 4_800.0;

end Types;
