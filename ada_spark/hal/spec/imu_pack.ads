package IMU_Pack is

   --  Constants
   IMU_UPDATE_FREQ : constant := 500.0;
   IMU_UPDATE_DT   : constant := 1.0 / IMU_UPDATE_FREQ;

   --  Procedures and functions
   procedure IMU6_Init;
   pragma Import(C, IMU6_Init, "imu6Init");

end IMU_Pack;
