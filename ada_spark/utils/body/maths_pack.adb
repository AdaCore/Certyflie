------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

with Safety_Pack;                       use Safety_Pack;

package body Maths_Pack
  with SPARK_Mode
is

   --------------
   -- Inv_Sqrt --
   --------------

   function Inv_Sqrt (X : Float) return Float
   is
      -----------
      -- Sqrtf --
      -----------

      function Sqrtf (X : Float) return Float with
        Global => null,
        Pre    => X >= Float'Succ (0.0),
        Post   => Sqrtf'Result in 3.745E-23 .. 1.85E+19,
        Import, Convention => Intrinsic, External_Name => "__builtin_sqrtf";
   begin
      return 1.0 / Sqrtf (X);
   end Inv_Sqrt;

   ----------
   -- Atan --
   ----------

   function Atan (Y :  Float; X : Float) return T_Radians is
   begin
      --  We constrain the return value accordingly to
      --  the Ada RM specification for Arctan
      --  (A.5.1 Elementary Functions)
      return Saturate (Arctan (Y, X), -Pi, Pi);
   end Atan;

   ----------
   -- Asin --
   ----------

   function Asin (X : Float) return T_Radians is
   begin
      --  We constrain the return value accordingly to
      --  the Ada RM specification for Arcsin
      --  (A.5.1 Elementary Functions)
      return Saturate (Arcsin (X), -Pi / 2.0, Pi / 2.0);
   end Asin;

end Maths_Pack;
