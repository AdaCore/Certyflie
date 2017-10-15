------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2017, AdaCore                     --
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

with System;

package Parameter is

   --  Type representing all the types that be used as parameters.

   type Parameter_Size is (One_Byte, Two_Bytes, Four_Bytes, Eight_Bytes);
   type Reserved_4_5 is range 0 .. 0;
   type Reserved_7_7 is range 0 .. 0;

   type Parameter_Variable_Type is record
      Size       : Parameter_Size;
      Floating   : Boolean;
      Signed     : Boolean;
      Unused_4_5 : Reserved_4_5 := 0;
      Read_Only  : Boolean;
      Unused_7_7 : Reserved_7_7 := 0;
   end record;
   for Parameter_Variable_Type use record
      Size       at 0 range 0 .. 1;
      Floating   at 0 range 2 .. 2;
      Signed     at 0 range 3 .. 3;
      Unused_4_5 at 0 range 4 .. 5;
      Read_Only  at 0 range 6 .. 6;
      Unused_7_7 at 0 range 7 .. 7;
   end record;
   for Parameter_Variable_Type'Size use 8;

   --  Global variables and constants

   --  Limitation of the variable/group name size.
   MAX_PARAM_VARIABLE_NAME_LENGTH : constant := 14;

   --  Procedures and functions

   --  Initialize the parameter subystem.
   procedure Parameter_Init;

   --  Test if the parameter subsystem is initialized.
   function Parameter_Test return Boolean;

   --  Create a parameter group if there is any space left and if the name
   --  is not too long.
   procedure Create_Parameter_Group
     (Name        : String;
      Group_ID    : out Natural;
      Has_Succeed : out Boolean)
   with Pre => Name'Length <= MAX_PARAM_VARIABLE_NAME_LENGTH;

   --  Append a variable to a parameter group.
   procedure Append_Parameter_Variable_To_Group
     (Group_ID       : Natural;
      Name           : String;
      Parameter_Type : Parameter_Variable_Type;
      Variable       : System.Address;
      Has_Succeed    : out Boolean)
   with Pre => Name'Length <= MAX_PARAM_VARIABLE_NAME_LENGTH;

end Parameter;
