with Interfaces.C.Extensions; use Interfaces.C.Extensions;

--  Package wrapping functions from Power Management HAL

package PM_Pack is

   --  Procedures and functions

   function PM_Is_Discharging return bool;
   pragma Import (C, PM_Is_Discharging, "pmIsDischarging");

end PM_Pack;
