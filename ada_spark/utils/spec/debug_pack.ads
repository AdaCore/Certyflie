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

with Interfaces.C;            use Interfaces.C;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

package Debug_Pack is

   --  Functions and procedures

   procedure Debug_Print (Str : String);

   --  Wrapper for the 'consolePuts' function
   --  declared in 'utils/interface/debug.h'
   function C_ConsolePuts (Str : char_array) return Integer;
   pragma Import (C, C_ConsolePuts, "consolePuts");

   --  Wrapper for the 'consolePutchar' function
   --  declared in 'utils/interface/debug.h'
   function C_ConsolePutchar (Ch : Integer) return Integer;
   pragma Import (C, C_ConsolePutchar, "consolePutchar");

private

   function To_C   (Item : Character) return char;

   function To_C
     (Item       : String;
      Append_Nul : Boolean := True) return char_array;


end Debug_Pack;
