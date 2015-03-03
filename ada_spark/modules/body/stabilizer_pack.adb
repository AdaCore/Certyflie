package body Stabilizer_Pack is

   procedure Modif_Variables is
   begin
      Gyro.X := 12.0;
      Acc.Y  := 13.0;
      Mag.Z  := 14.0;
      Pid_Init(Alt_Hold_PID, 10.0, 1.0, 2.0, 3.0, 0.1);
   end Modif_Variables;

end Stabilizer_Pack;
