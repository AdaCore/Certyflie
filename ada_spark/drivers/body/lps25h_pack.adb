package body LPS25h_pack is

   procedure LPS25h_Get_Data
     (Pressure    : out T_Pressure;
      Temperature : out T_Temperature;
      Asl         : out T_Altitude;
      Status      : out Boolean) is
   begin
      --  TODO: implement the real function when drivers will be done
      Pressure := T_Pressure'First;
      Temperature := 0.0;
      Asl := 0.0;
      Status := False;
   end LPS25h_Get_Data;

end LPS25h_pack;
