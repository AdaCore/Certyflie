------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                        Copyright (C) 2017, AdaCore                       --
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

with Ada.Streams;
with GNAT.CRC32;

package body CRC is

   function Make (Data : Data_Kind) return Interfaces.Unsigned_32 is
      use type Ada.Streams.Stream_Element_Offset;

      subtype Stream_Element_Array
        is Ada.Streams.Stream_Element_Array (1 .. (Data_Kind'Size + 7) / 8);

      As_Stream_Elements : Stream_Element_Array
      with
        Import,
        Convention => Ada,
        Address    => Data'Address;
      --  We can't use Unchecked_Conversion here, because that makes a
      --  copy!

      CRC32              : GNAT.CRC32.CRC32;
   begin
      GNAT.CRC32.Initialize (CRC32);
      GNAT.CRC32.Update (CRC32, As_Stream_Elements);
      return GNAT.CRC32.Get_Value (CRC32);
   end Make;

end CRC;
