package body IMU_Pack is

   function IMU_6_Calibrated return Boolean is
   begin
      return True;
   end IMU_6_Calibrated;


   function IMU_Has_Barometer return Boolean is
   begin
      return True;
   end IMU_Has_Barometer;

   procedure IMU_9_Read
     (Gyro : in out Gyroscope_Data;
      Acc  : in out Accelerometer_Data;
      Mag  : in out Magnetometer_Data) is
   begin
      --  TODO: implement the real function when drivers will be done
      Gyro.X := 0.0;
      Gyro.Y := 0.0;
      Gyro.Z := 0.0;

      Acc.X := 0.0;
      Acc.Y := 0.0;
      Acc.Z := 0.0;

      Mag.X := 0.0;
      Mag.Y := 0.0;
      Mag.Z := 0.0;
   end IMU_9_Read;
end IMU_Pack;
