with Types; use Types;

package Filter
  with SPARK_Mode
is

   --  Global variables and constants

   IIR_SHIFT : constant := 8;

   --  Procedures and functions

   --  Infinite-impulse-response low-pass filter.
   --  Used to filter IMU measurements.
   procedure IIR_LP_Filter_Single
     (Input       : T_Int32;
      Attenuation : T_Int32;
      Filter      : in out T_Int32;
      Result      : out T_Int32);

end Filter;
