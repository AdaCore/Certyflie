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

with Ada.Unchecked_Conversion;

with CRTP;      use CRTP;
with Types;     use Types;

with CRC;

package body Parameter is

   --  Types, subprograms previously in private part of spec

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

   --  Error code constants
   ENOENT : constant := 2;
   --  E2BIG  : constant := 7;
   --  ENOMEM : constant := 12;
   --  EEXIST : constant := 17;

   --  Maximum number of groups we can log.
   MAX_PARAM_NUMBER_OF_GROUPS          : constant := 8;
   --  Maximum number of variables we can log inside a group.
   MAX_PARAM_NUMBER_OF_VARIABLES       : constant := 4;

   --  Types, subprograms previously in private part of spec

   subtype Parameter_Name is String (1 .. MAX_PARAM_VARIABLE_NAME_LENGTH);

   --  Type representing a parameter variable.
   type Parameter_Variable is record
      Group_ID       : Natural;
      Name           : Parameter_Name;
      Name_Length    : Natural;
      --  Storage_Type   : Parameter_Variable_Type;
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

   --  Read a parameter.
   procedure Parameter_Read_Process (Packet : CRTP_Packet);

   --  Public procedures and functions

   --------------------
   -- Parameter_Init --
   --------------------

   procedure Parameter_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_PARAM, Parameter_CRTP_Handler'Access);

      Is_Init := True;
   end Parameter_Init;

   --------------------
   -- Parameter_Test --
   --------------------

   function Parameter_Test return Boolean is
   begin
      return Is_Init;
   end Parameter_Test;

   ----------------------------
   -- Create_Parameter_Group --
   ----------------------------

   procedure Create_Parameter_Group
     (Name        : String;
      Group_ID    : out Natural;
      Has_Succeed : out Boolean)
   is
      Parameter_Groups_Index : constant Natural
        := Parameter_Data.Parameter_Groups_Index;
   begin
      if Parameter_Groups_Index > Parameter_Data.Parameter_Groups'Last or
        Name'Length > MAX_PARAM_VARIABLE_NAME_LENGTH
      then
         Has_Succeed := False;
         return;
      end if;

      Parameter_Data.Parameter_Groups (Parameter_Groups_Index).Name :=
        String_To_Parameter_Name (Name);
      Parameter_Data.Parameter_Groups (Parameter_Groups_Index).Name_Length :=
        Name'Length;
      Group_ID := Parameter_Groups_Index;
      Parameter_Data.Parameter_Groups_Index := Parameter_Groups_Index + 1;

      Has_Succeed := True;
   end Create_Parameter_Group;

   ----------------------------------------
   -- Append_Parameter_Variable_To_Group --
   ----------------------------------------

   procedure Append_Parameter_Variable_To_Group
     (Group_ID       : Natural;
      Name           : String;
      Parameter_Type : Parameter_Variable_Type;
      Variable       : System.Address;
      Has_Succeed    : out Boolean)
   is
      Group               : Parameter_Group;
      Parameter_Variables_Index : Natural;
   begin
      Has_Succeed := False;

      --  If group ID doesn't exist.
      if Group_ID not in Parameter_Data.Parameter_Groups'Range then
         return;
      end if;

      Group := Parameter_Data.Parameter_Groups (Group_ID);
      Parameter_Variables_Index := Group.Parameter_Variables_Index;

      if Parameter_Variables_Index > Group.Parameter_Variables'Last or
        Name'Length > MAX_PARAM_VARIABLE_NAME_LENGTH
      then
         return;
      end if;

      Group.Parameter_Variables (Parameter_Variables_Index).Name :=
        String_To_Parameter_Name (Name);
      Group.Parameter_Variables (Parameter_Variables_Index).Group_ID
        := Group_ID;
      Group.Parameter_Variables (Parameter_Variables_Index).Name_Length
        := Name'Length;
      Group.Parameter_Variables (Parameter_Variables_Index).Parameter_Type
        := Parameter_Type;
      Group.Parameter_Variables (Parameter_Variables_Index).Variable
        := Variable;

      Group.Parameter_Variables_Index := Parameter_Variables_Index + 1;

      Parameter_Data.Parameter_Groups (Group_ID) := Group;

      Parameter_Data.Parameter_Variables
        (Integer (Parameter_Data.Parameter_Variables_Count))
        := Parameter_Data.Parameter_Groups
          (Group_ID).Parameter_Variables (Parameter_Variables_Index)'Access;

      Parameter_Data.Parameter_Variables_Count :=
        Parameter_Data.Parameter_Variables_Count + 1;
      Has_Succeed := True;
   end Append_Parameter_Variable_To_Group;

   --  Private procedures and functions

   ----------------------------
   -- Parameter_CRTP_Handler --
   ----------------------------

   procedure Parameter_CRTP_Handler (Packet : CRTP_Packet)
   is
      ---------------------------------------
      -- CRTP_Channel_To_Parameter_Channel --
      ---------------------------------------

      function CRTP_Channel_To_Parameter_Channel is
        new Ada.Unchecked_Conversion (CRTP_Channel, Parameter_Channel);

      Channel : Parameter_Channel;
   begin
      Channel := CRTP_Channel_To_Parameter_Channel (Packet.Channel);

      --  The C code (param.c) has a further case
      --  MISC_CH/MISC_SETBYNAME, not handled here.
      case Channel is
         when PARAM_TOC_CH =>
            Parameter_TOC_Process (Packet);
         when PARAM_READ_CH =>
            Parameter_Read_Process (Packet);
         when PARAM_WRITE_CH =>
            null;
      end case;
   end Parameter_CRTP_Handler;

   ---------------------------
   -- Parameter_TOC_Process --
   ---------------------------

   procedure Parameter_TOC_Process (Packet : CRTP_Packet)
   is
      function T_Uint8_To_Parameter_TOC_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Parameter_TOC_Command);

      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);

      procedure CRTP_Append_Parameter_Variable_Type_Data
      is new CRTP_Append_Data
        (Parameter_Variable_Type);

      procedure CRTP_Append_T_Uint32_Data is new CRTP_Append_Data
        (T_Uint32);

      function Parameter_Database_CRC32 return T_Uint32;
      function Parameter_Database_CRC32 return T_Uint32 is
         --  Note, this doesn't take account of uninitialized
         --  components of Parameter_Data, but since the only use (in
         --  cfclient, anyway) is to determine whether to load new
         --  data this will just add a minor startup load.
         function Parameter_TOC_CRC
         is new CRC.Make (Data_Kind => Parameter_Data_Base);
      begin
         return T_Uint32 (Parameter_TOC_CRC (Parameter_Data));
      end Parameter_Database_CRC32;

      Command        : Parameter_TOC_Command;
      Packet_Handler : CRTP_Packet_Handler;
      Has_Succeed    : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Parameter_TOC_Command (Packet.Data_1 (1));
      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_PARAM, Parameter_Channel'Enum_Rep (PARAM_TOC_CH));
      CRTP_Append_T_Uint8_Data
        (Packet_Handler,
         Parameter_TOC_Command'Enum_Rep (Command),
         Has_Succeed);

      case Command is
         when PARAM_CMD_GET_INFO =>
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               Parameter_Data.Parameter_Variables_Count,
               Has_Succeed);
            CRTP_Append_T_Uint32_Data
              (Packet_Handler,
               Parameter_Database_CRC32,
               Has_Succeed);

         when PARAM_CMD_GET_ITEM =>
            declare
               Var_ID              : constant T_Uint8 := Packet.Data_1 (2);
               Parameter_Var       : Parameter_Variable;
               Parameter_Var_Group : Parameter_Group;
            begin
               if Var_ID < Parameter_Data.Parameter_Variables_Count then
                  CRTP_Append_T_Uint8_Data
                    (Packet_Handler,
                     Var_ID,
                     Has_Succeed);

                  Parameter_Var := Parameter_Data.Parameter_Variables
                    (Integer (Var_ID)).all;
                  Parameter_Var_Group := Parameter_Data.Parameter_Groups
                    (Parameter_Var.Group_ID);

                  CRTP_Append_Parameter_Variable_Type_Data
                    (Packet_Handler,
                     Parameter_Var.Parameter_Type,
                     Has_Succeed);
                  Append_Raw_Data_Variable_Name_To_Packet
                    (Parameter_Var,
                     Parameter_Var_Group,
                     Packet_Handler,
                     Has_Succeed);
               end if;
            end;
      end case;
      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Packet_Handler),
         Has_Succeed);
   end Parameter_TOC_Process;

   ------------------------------
   -- String_To_Parameter_Name --
   ------------------------------

   function String_To_Parameter_Name (Name : String) return Parameter_Name
   is
      Result : Parameter_Name := (others => ASCII.NUL);
   begin
      Result (1 .. Name'Length) := Name;

      return Result;
   end String_To_Parameter_Name;

   ---------------------------------------------
   -- Append_Raw_Data_Variable_Name_To_Packet --
   ---------------------------------------------

   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Variable       : Parameter_Variable;
      Group          : Parameter_Group;
      Packet_Handler : in out CRTP_Packet_Handler;
      Has_Succeed     : out Boolean)
   is
      subtype Parameter_Complete_Name is
        String (1 .. Variable.Name_Length + Group.Name_Length + 2); -- nulls
      subtype Parameter_Complete_Name_Raw is
        T_Uint8_Array (Parameter_Complete_Name'Range);

      ------------------------------------------------------------
      -- Parameter_Complete_Name_To_Parameter_Complete_Name_Raw --
      ------------------------------------------------------------

      function Parameter_Complete_Name_To_Parameter_Complete_Name_Raw is new
        Ada.Unchecked_Conversion (Parameter_Complete_Name,
                                  Parameter_Complete_Name_Raw);

      --------------------------------------------------
      -- CRTP_Append_Parameter_Complete_Name_Raw_Data --
      --------------------------------------------------

      procedure CRTP_Append_Parameter_Complete_Name_Raw_Data is new
        CRTP_Append_Data (Parameter_Complete_Name_Raw);

      Complete_Name : constant Parameter_Complete_Name
        := Group.Name (1 .. Group.Name_Length) & ASCII.NUL
        & Variable.Name (1 .. Variable.Name_Length) & ASCII.NUL;
      Complete_Name_Raw : Parameter_Complete_Name_Raw;
   begin
      Complete_Name_Raw :=
        Parameter_Complete_Name_To_Parameter_Complete_Name_Raw (Complete_Name);
      CRTP_Append_Parameter_Complete_Name_Raw_Data
        (Packet_Handler,
         Complete_Name_Raw,
         Has_Succeed);
   end Append_Raw_Data_Variable_Name_To_Packet;

   ----------------------------
   -- Parameter_Read_Process --
   ----------------------------

   procedure Parameter_Read_Process (Packet : CRTP_Packet) is
      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);

      ID : constant T_Uint8 := Packet.Data_1 (1);
      Packet_Handler : CRTP_Packet_Handler;
      Succeeded : Boolean with Unreferenced;
   begin
      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_PARAM, Parameter_Channel'Enum_Rep (PARAM_READ_CH));
      if ID >= Parameter_Data.Parameter_Variables_Count then
         --  Invalid
         CRTP_Append_T_Uint8_Data
           (Packet_Handler,
            T_Uint8'Last,
            Succeeded);
         CRTP_Append_T_Uint8_Data
           (Packet_Handler,
            ID,
            Succeeded);
         CRTP_Append_T_Uint8_Data
           (Packet_Handler,
            ENOENT,
            Succeeded);
      else
         CRTP_Append_T_Uint8_Data
           (Packet_Handler,
            ID,
            Succeeded);
         declare
            V : Parameter_Variable
            renames Parameter_Data.Parameter_Variables (Integer (ID)).all;
         begin
            case V.Parameter_Type.Size is
               when One_Byte =>
                  declare
                     procedure Append_Data is new CRTP_Append_Data
                       (T_Uint8);
                     Variable : T_Uint8 with Address => V.Variable;
                  begin
                     Append_Data (Packet_Handler, Variable, Succeeded);
                  end;
               when Two_Bytes =>
                  declare
                     procedure Append_Data is new CRTP_Append_Data
                       (T_Uint16);
                     Variable : T_Uint16 with Address => V.Variable;
                  begin
                     Append_Data (Packet_Handler, Variable, Succeeded);
                  end;
               when Four_Bytes =>
                  declare
                     procedure Append_Data is new CRTP_Append_Data
                       (T_Uint32);
                     Variable : T_Uint32 with Address => V.Variable;
                  begin
                     Append_Data (Packet_Handler, Variable, Succeeded);
                  end;
               when Eight_Bytes =>
                  declare
                     procedure Append_Data is new CRTP_Append_Data
                       (T_Uint64);
                     Variable : T_Uint64 with Address => V.Variable;
                  begin
                     Append_Data (Packet_Handler, Variable, Succeeded);
                  end;
            end case;
         end;
      end if;
      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Packet_Handler),
         Succeeded);
      null;
   end Parameter_Read_Process;

end Parameter;
