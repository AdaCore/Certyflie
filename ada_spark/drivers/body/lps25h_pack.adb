package body LPS25h_pack is

   ---------------------
   -- LPS25h_Get_Data --
   ---------------------

   procedure LPS25h_Get_Data
     (Pressure    : out T_Pressure;
      Temperature : out T_Temperature;
      Asl         : out T_Altitude;
      Status      : out Boolean)
   is
      -----------------------------
      -- LPS25h_Get_Data_Wrapper --
      -----------------------------

      function LPS25h_Get_Data_Wrapper
        (Pressure    : out T_Pressure;
         Temperature : out T_Temperature;
         Asl         : out T_Altitude) return bool;
      pragma Import (C, LPS25h_Get_Data_Wrapper, "lps25hGetData");

      Res : bool;
   begin
      Res := LPS25h_Get_Data_Wrapper (Pressure,
                                      Temperature,
                                      Asl);
      if Res = 0 then
         Status := False;
      else
         Status := True;
      end if;
   end LPS25h_Get_Data;

end LPS25h_pack;
