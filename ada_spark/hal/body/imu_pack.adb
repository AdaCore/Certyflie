package body IMU_Pack is

   function IMU_6_Calibrated return Boolean is
      function IMU_6_Calibrated_Wrapper return Integer;
      pragma Import (C, IMU_6_Calibrated_Wrapper, "imu6IsCalibrated");
   begin
      return IMU_6_Calibrated_Wrapper /= 0;
   end IMU_6_Calibrated;

end IMU_Pack;
