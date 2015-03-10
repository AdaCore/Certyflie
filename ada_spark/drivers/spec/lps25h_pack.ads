with Interfaces.C.Extensions; use Interfaces.C.Extensions;

--  Package wrapping functions from the lps25h pressure sensor driver

package LPS25h_pack is

   --  Types

   subtype T_Pressure is Float range 450.0 .. 1100.0;  --  in mBar
   subtype T_Temperature is Float range -20.0 .. 80.0; --  in degree Celcius
   subtype T_Altitude is Float range -700.0 .. 8000.0;

   --  Procedures and functions

   function LPS25h_Get_Data (Pressure    : out T_Pressure;
                             Temperature : out T_Temperature;
                             Asl         : out T_Altitude) return bool;
   pragma Import (C, LPS25h_Get_Data, "lps25hGetData");



end LPS25h_pack;
