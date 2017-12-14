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

with System.Address_To_Access_Conversions;

package body Generic_Vectors is

   function Length (This : Vector) return Natural
     is (This.Last);

   procedure Append
     (To : in out Vector;
      Item : Element_Type) is
   begin
      To.Last := To.Last + 1;
      To.Elements (To.Last) := Item;
   end Append;

   function Element (This : Vector; Index : Natural) return Element_Type
     is (This.Elements (Index + 1));

   --  Messing because "non-local pointer cannot point to local object".
   package Conversions
     is new System.Address_To_Access_Conversions (Element_Type);

   function Element_Access (This : in out Vector; Index : Natural)
                           return not null access Element_Type
   is
   begin
      return Conversions.To_Pointer (This.Elements (Index + 1)'Address);
   end Element_Access;

   procedure Act_On
     (This : in out Vector;
      Taking : not null Action) is
   begin
      for J in 1 .. This.Last loop
         Taking (This.Elements (J));
      end loop;
   end Act_On;

   procedure Act_On
     (This : in out Vector;
      Index : Natural;
      Taking : not null Action) is
   begin
      Taking (This.Elements (Index + 1));
   end Act_On;

   procedure Clear (This : in out Vector; Taking : Action := null) is
   begin
      if Taking /= null then
         for J in 1 .. This.Last loop
            Taking (This.Elements (J));
         end loop;
      end if;

      This.Elements (1 .. This.Last) := (others => <>);
      This.Last := 0;
   end Clear;

end Generic_Vectors;
