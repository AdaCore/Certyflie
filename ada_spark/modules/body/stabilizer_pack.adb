package body Stabilizer_Pack is

   --  For testing purpose
   procedure Modif_Variables is
   begin
      Gyro.X := 12.0;
      Acc.Y  := 13.0;
      Mag.Z  := 14.0;
   end Modif_Variables;

end Stabilizer_Pack;
