with Types; use Types;

package Filter_Pack is

   --  Procedures and functions

   --  IIR filter the samples.
   function IIR_LP_Filter_Single
     (Input       : T_Uint32;
      Attenuation : T_Uint32;
      Filter      : in out T_Uint32) return T_Uint32;

private

   --  Global variables and constants

   IIR_SHIFT : constant := 8;

end Filter_Pack;
