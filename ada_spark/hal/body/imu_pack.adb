with Filter_Pack; use Filter_Pack;

package body IMU_Pack is

   function IMU_6_Calibrated return Boolean is
   begin
      return True;
   end IMU_6_Calibrated;


   function IMU_Has_Barometer return Boolean is
   begin
      return True;
   end IMU_Has_Barometer;

end IMU_Pack;
