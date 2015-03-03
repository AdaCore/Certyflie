with Types; use Types;

package IMU_Pack is

   --  Constants
   IMU_UPDATE_FREQ : constant Allowed_Floats := 500.0;
   IMU_UPDATE_DT   : constant Allowed_Floats := 1.0 / IMU_UPDATE_FREQ;

end IMU_Pack;
