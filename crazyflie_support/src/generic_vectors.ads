------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                       Copyright (C) 2017, AdaCore                        --
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

generic
   type Element_Type is private;
package Generic_Vectors is

   --  A Vector corresponds conceptually to a zero-indexed array.
   type Vector (Capacity : Positive) is tagged private;

   function Length (This : Vector) return Natural;

   procedure Append (To : in out Vector; Item : Element_Type)
     with Pre => Length (To) < To.Capacity;

   function Element (This : Vector; Index : Natural)
                     return Element_Type
     with Pre => Index < Length (This);

   function Element_Access (This : in out Vector; Index : Natural)
                           return not null access Element_Type
     with Pre => Index < Length (This);

   type Action is access procedure (On : in out Element_Type);

   procedure Act_On (This : in out Vector;
                     Taking : not null Action);

   procedure Act_On (This : in out Vector;
                     Index : Natural;
                     Taking : not null Action)
     with Pre => Index < Length (This);

   procedure Clear (This : in out Vector; Taking : Action := null);

private

   type Components is array (Natural range <>) of Element_Type;

   type Vector (Capacity : Positive) is tagged
      record
         Last : Natural := 0;
         Elements : Components (1 .. Capacity) := (others => <>);
      end record;

end Generic_Vectors;
