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

package body Debug_Pack is

   -----------------
   -- Debug_Print --
   -----------------

   procedure Debug_Print (Str : String)
   is
      C_Str : char_array := To_C (Str);
      Res : Integer;
   begin
      Res := C_ConsolePuts (C_Str);
   end Debug_Print;

   ----------
   -- To_C --
   ----------

   function To_C (Item : Character) return char is
   begin
      return char'Val (Character'Pos (Item));
   end To_C;

   ----------
   -- To_C --
   ----------

   function To_C
     (Item       : String;
      Append_Nul : Boolean := True) return char_array
   is
   begin
      if Append_Nul then
         declare
            R : char_array (0 .. Item'Length);

         begin
            for J in Item'Range loop
               R (size_t (J - Item'First)) := To_C (Item (J));
            end loop;

            R (R'Last) := nul;
            return R;
         end;

      --  Append_Nul False

      else
         --  A nasty case, if the string is null, we must return a null
         --  char_array. The lower bound of this array is required to be zero
         --  (RM B.3(50)) but that is of course impossible given that size_t
         --  is unsigned. According to Ada 2005 AI-258, the result is to raise
         --  Constraint_Error. This is also the appropriate behavior in Ada 95,
         --  since nothing else makes sense.

         if Item'Length = 0 then
            raise Constraint_Error;

         --  Normal case

         else
            declare
               R : char_array (0 .. Item'Length - 1);

            begin
               for J in Item'Range loop
                  R (size_t (J - Item'First)) := To_C (Item (J));
               end loop;

               return R;
            end;
         end if;
      end if;
   end To_C;

end Debug_Pack;
