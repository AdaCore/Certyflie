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

with CRTP;      use CRTP;
with Types;     use Types;

package Parameter is

   --  Types

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

   --  Type representing all the available parameter module CRTP channels.
   type Parameter_Channel is
     (PARAM_TOC_CH,
      PARAM_READ_CH,
      PARAM_WRITE_CH);
   for Parameter_Channel use
     (PARAM_TOC_CH   => 0,
      PARAM_READ_CH  => 1,
      PARAM_WRITE_CH => 2);
   for Parameter_Channel'Size use 2;

   --  Type representing all the param commands.
   --  PARAM_CMD_GET_INFO is requested at connexion to fetch the TOC.
   --  PARAM_CMD_GET_ITEM is requested whenever the client wants to
   --  fetch the newest variable data.
   type Parameter_TOC_Command is
     (PARAM_CMD_GET_ITEM,
      PARAM_CMD_GET_INFO);
   for Parameter_TOC_Command use
     (PARAM_CMD_GET_ITEM => 0,
      PARAM_CMD_GET_INFO => 1);
   for Parameter_TOC_Command'Size use 8;

   --  Type representing all the available parameter control commands.
   type Parameter_Control_Command is
     (PARAM_CMD_RESET,
      PARAM_CMD_GET_NEXT,
      PARAM_CMD_GET_CRC);
   for Parameter_Control_Command use
     (PARAM_CMD_RESET    => 0,
      PARAM_CMD_GET_NEXT => 1,
      PARAM_CMD_GET_CRC  => 2);
   for Parameter_Control_Command'Size use 8;

   --  Global variables and constants

   --  Limitation of the variable/group name size.
   MAX_PARAM_VARIABLE_NAME_LENGTH : constant := 14;

   --  Maximum number of groups we can log.
   MAX_PARAM_NUMBER_OF_GROUPS          : constant := 8;
   --  Maximum number of variables we can log inside a group.
   MAX_PARAM_NUMBER_OF_VARIABLES       : constant := 4;

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
      Has_Succeed : out Boolean);

   --  Append a variable to a parameter group.
   procedure Append_Parameter_Variable_To_Group
     (Group_ID       : Natural;
      Name           : String;
      Storage_Type   : Parameter_Variable_Type;
      Parameter_Type : Parameter_Variable_Type;
      Variable       : System.Address;
      Has_Succeed    : out Boolean);

private

   --  Types

   subtype Parameter_Name is String (1 .. MAX_PARAM_VARIABLE_NAME_LENGTH);

   --  Type representing a parameter variable. Parameter variables
   --  can be chained together inside a same block.
   type Parameter_Variable is record
      Group_ID       : Natural;
      Name           : Parameter_Name;
      Name_Length    : Natural;
      Storage_Type   : Parameter_Variable_Type;
      Parameter_Type : Parameter_Variable_Type;
      Variable       : System.Address := System.Null_Address;
   end record;

   type Parameter_Group_Variable_Array is
     array (0 .. MAX_PARAM_NUMBER_OF_VARIABLES - 1) of
     aliased Parameter_Variable;

   type Parameter_Variable_Array is
     array (0 ..
              MAX_PARAM_NUMBER_OF_VARIABLES * MAX_PARAM_NUMBER_OF_GROUPS - 1)
     of access Parameter_Variable;

   --  Type representing a log group.
   --  Parameter groups can contain several log variables.
   type Parameter_Group is record
      Name                      : Parameter_Name;
      Name_Length               : Natural;
      Parameter_Variables       : Parameter_Group_Variable_Array;
      Parameter_Variables_Index : Natural := 0;
   end record;

   type Parameter_Group_Array is
     array (0 .. MAX_PARAM_NUMBER_OF_GROUPS - 1) of Parameter_Group;

   type Parameter_Data_Base is record
      Parameter_Groups          : Parameter_Group_Array;
      Parameter_Variables       : Parameter_Variable_Array := (others => null);
      Parameter_Groups_Index    : Natural := 0;
      Parameter_Variables_Count : T_Uint8 := 0;
   end record;

   --  Global variables and constants

   Is_Init : Boolean := False;

   --  Head of the parameter groups list.
   Parameter_Data : aliased Parameter_Data_Base;

   --  Procedures and functions

   --  Handler called when a CRTP packet is received in the param
   --  port.
   procedure Parameter_CRTP_Handler (Packet : CRTP_Packet);

   --  Process a command related to TOC demands from the python client.
   procedure Parameter_TOC_Process (Packet : CRTP_Packet);

   --  Convert an unbounded string to a Log_Name, with a fixed size.
   function String_To_Parameter_Name (Name : String) return Parameter_Name;
   pragma Inline (String_To_Parameter_Name);

   --  Append raw data from the variable and group name.
   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Variable       : Parameter_Variable;
      Group          : Parameter_Group;
      Packet_Handler : in out CRTP_Packet_Handler;
      Has_Succeed    : out Boolean);

end Parameter;
