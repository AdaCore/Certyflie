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
with Ada.Containers.Bounded_Hashed_Maps;
with Ada.Real_Time;               use Ada.Real_Time;
with Ada.Real_Time.Timing_Events; use Ada.Real_Time.Timing_Events;
with Ada.Strings.Bounded;

with CRTP;                        use CRTP;
with Types;                       use Types;

with CRC;
with Generic_Vectors;

package body Log is

   --  Declarations previously in private part of spec

   --  Type representing all the available log module CRTP channels.
   type Log_Channel is
     (LOG_TOC_CH,
      LOG_CONTROL_CH,
      LOG_DATA_CH);
   for Log_Channel use
     (LOG_TOC_CH      => 0,
      LOG_CONTROL_CH  => 1,
      LOG_DATA_CH     => 2);
   for Log_Channel'Size use 2;

   --  Type representing all the log commands.
   --  LOG_CMD_GET_INFO is requested at connexion to fetch the TOC.
   --  LOG_CMD_GET_ITEM is requested at connexion to fetch data (name,
   --  type) of a variable.
   type Log_TOC_Command is
     (LOG_CMD_GET_ITEM,
      LOG_CMD_GET_INFO);
   for Log_TOC_Command use
     (LOG_CMD_GET_ITEM => 0,
      LOG_CMD_GET_INFO => 1);
   for Log_TOC_Command'Size use 8;

   --  Type representing all the available log control commands.
   type Log_Control_Command is
     (LOG_CONTROL_CREATE_BLOCK,
      LOG_CONTROL_APPEND_BLOCK,
      LOG_CONTROL_DELETE_BLOCK,
      LOG_CONTROL_START_BLOCK,
      LOG_CONTROL_STOP_BLOCK,
      LOG_CONTROL_RESET);
   for Log_Control_Command use
     (LOG_CONTROL_CREATE_BLOCK => 0,
      LOG_CONTROL_APPEND_BLOCK => 1,
      LOG_CONTROL_DELETE_BLOCK => 2,
      LOG_CONTROL_START_BLOCK  => 3,
      LOG_CONTROL_STOP_BLOCK   => 4,
      LOG_CONTROL_RESET        => 5);
   for Log_Control_Command'Size use 8;

   --  Global variables and constants

   --  Constant array registering the length of each log variable type
   --  in Bytes.
   Type_Length : constant array (Log_Variable_Type) of T_Uint8
     := (LOG_UINT8  => 1,
         LOG_UINT16 => 2,
         LOG_UINT32 => 4,
         LOG_INT8   => 1,
         LOG_INT16  => 2,
         LOG_INT32  => 4,
         LOG_FLOAT  => 4);

   --  Error code constants
   ENOENT : constant := 2;
   E2BIG  : constant := 7;
   ENOMEM : constant := 12;
   EEXIST : constant := 17;

   --  Maximum number of groups we can create.
   MAX_LOG_NUMBER_OF_GROUPS              : constant := 20;
   --  Maximum number of variables we can create inside a group.
   MAX_LOG_NUMBER_OF_VARIABLES_PER_GROUP : constant := 8;
   --  Maximum number of variables we can log at the same time.
   MAX_LOG_OPS                           : constant := 128;
   --  Maximum number of blocks we can create.
   MAX_LOG_BLOCKS                        : constant := 16;

   --  Types

   package Strings
   is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => Max_Name_Length);
   function "+" (B : Strings.Bounded_String) return String
                 renames Strings.To_String;

   subtype Log_Name is Strings.Bounded_String;
   function String_To_Log_Name (S : String) return Log_Name is
     (Strings.To_Bounded_String (S))
     with Pre => S'Length <= Max_Name_Length;

   subtype Group_Identifier is Natural range 0 .. MAX_LOG_NUMBER_OF_GROUPS - 1;

   --  Type representing a log variable.
   type Log_Variable is record
      Group_ID     : Group_Identifier;
      Name         : Log_Name;
      Log_Type     : Log_Variable_Type;
      Variable     : System.Address := System.Null_Address;
   end record;

   --  Storage for all the variables.

   Max_Variables : constant
     := MAX_LOG_NUMBER_OF_VARIABLES_PER_GROUP * MAX_LOG_NUMBER_OF_GROUPS;

   subtype Variable_Identifier is Natural range 0 .. Max_Variables - 1;

   package Log_Variables is new Generic_Vectors
     (Element_Type => Log_Variable);

   subtype Log_Variable_Array is Log_Variables.Vector
     (Capacity => Max_Variables);

   --  Storage for groups. A group has a name and contains a number of
   --  variables; a variable has a name, a type, and an address. A
   --  variable can only appear in one group, though there can be more
   --  than one variable referencing the same address. Groups are
   --  recognised by the client, and for a group to be used it must
   --  contain all the variables expected.

   package Group_Variables is new Generic_Vectors
     (Element_Type => Variable_Identifier);

   subtype Log_Group_Variable_Array is Group_Variables.Vector
     (Capacity => MAX_LOG_NUMBER_OF_VARIABLES_PER_GROUP);

   --  Type representing a log group.
   type Log_Group is record
      Name          : Log_Name;
      Log_Variables : Log_Group_Variable_Array;
   end record;

   package Log_Groups is new Generic_Vectors
     (Element_Type => Log_Group);

   subtype Log_Group_Array is Log_Groups.Vector
     (Capacity => MAX_LOG_NUMBER_OF_GROUPS);

   --  Type representing the log TOC

   type Log_TOC is record
      Log_Groups    : Log_Group_Array;
      Log_Variables : Log_Variable_Array;
   end record;

   --  Storage for Blocks.

   --  A Block is requested by the client, using a client-determined
   --  ID (type T_Uint8). It is a request to report a number of
   --  variables at an interval.
   --
   --  A particular variable can appear in more than one block.

   type Log_Operation is record     -- XXX might need to support addresses too
      Variable  : Variable_Identifier;
      Stored_As : Log_Variable_Type;
      Report_As : Log_Variable_Type;
   end record;

   subtype Operation_Identifier is Natural range 0 .. MAX_LOG_OPS - 1;
   package Log_Operations is new Generic_Vectors
     (Element_Type => Log_Operation);
   subtype Log_Operations_Array is Log_Operations.Vector
     (Capacity => MAX_LOG_OPS);

   --  Extension of the Timing_Event tagged type to store additional
   --  attributes : the client's block ID, and how often.
   type Log_Block_Timing_Event is new Timing_Event with record
      Client_Block_ID : T_Uint8;
      Period          : Time_Span;
   end record;

   --  Type representing a log block. A log block sends all
   --  its variables' data every time the Timing_Event timer expires.
   type Log_Block is record
      Free       : Boolean := True;
      Timer      : Log_Block_Timing_Event;
      Operations : Log_Operations_Array;
   end record;

   --  We use a map from the client's block ID to ours.
   function Uint8_Hash (Key : T_Uint8) return Ada.Containers.Hash_Type
   is (Ada.Containers.Hash_Type (Key));

   subtype Log_Block_ID is Integer range 0 .. MAX_LOG_BLOCKS - 1;

   package Log_Block_Maps is new Ada.Containers.Bounded_Hashed_Maps
     (Key_Type        => T_Uint8,
      Element_Type    => Log_Block_ID,
      Hash            => Uint8_Hash,
      Equivalent_Keys => "=");

   --  Type used to encode timestamps when sending log data.
   subtype Log_Time_Stamp is T_Uint8_Array (1 .. 3);

   --  Tasks and protected objects

   protected Log_Block_Timing_Event_Handler is
      pragma Interrupt_Priority;

      procedure Log_Run_Block (Event : in out Timing_Event);
      entry Get_Block_To_Run (ID : out T_Uint8);

   private
      Record_Required : Boolean := False;
      Block_To_Record : T_Uint8;  -- OK to lose records on overrun
   end Log_Block_Timing_Event_Handler;

   --  Global variables and constants

   Log_Block_Timer_Handler : constant Timing_Event_Handler
     := Log_Block_Timing_Event_Handler.Log_Run_Block'Access;

   Is_Init : Boolean := False;

   --  Log TOC
   Log_Data : aliased Log_TOC;

   --  Log blocks
   Log_Blocks : array (Log_Block_ID) of Log_Block;

   --  Map from client block ID to ours
   Log_Block_Map : Log_Block_Maps.Map (Capacity => MAX_LOG_BLOCKS,
                                       Modulus  => MAX_LOG_BLOCKS);

   --  Procedures and functions

   --  Handler called when a CRTP packet is received in the log
   --  port.
   procedure Log_CRTP_Handler (Packet : CRTP_Packet);

   --  Process a command related to TOC demands from the python client.
   procedure Log_TOC_Process (Packet : CRTP_Packet);

   --  Process a command related to log control.
   procedure Log_Control_Process (Packet : CRTP_Packet);

   --  Create a log block, contatining all the variables specified
   --  in Ops_Settings parameter.
   function Log_Create_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8;

   --  Delete the specified block.
   function Log_Delete_Block (Block_ID : T_Uint8) return T_Uint8;
   procedure Log_Delete_Block (Block_ID : Log_Block_ID);

   --  Append the variables specified in Ops_Settings to the
   --  block identified with Block_ID.
   function Log_Append_To_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8;

   --  Start logging the specified block at each period (in ms).
   function Log_Start_Block
     (Block_ID : T_Uint8;
      Period   : Natural) return T_Uint8;

   --  Stop logging the specified block.
   function Log_Stop_Block (Block_ID : T_Uint8) return T_Uint8;

   --  Delete all the log blocks.
   procedure Log_Reset;

   --  Calculate the current block length, to ensure that it will fit in
   --  a single CRTP packet.
   function Calculate_Block_Length (Block : Log_Block) return T_Uint8;
   pragma Inline (Calculate_Block_Length);

   --  Get a log timestamp from the current clock tick count.
   function Get_Log_Time_Stamp return Log_Time_Stamp;
   pragma Inline (Get_Log_Time_Stamp);

   --  Append raw data from the variable and group name.
   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Group_Name     : String;
      Variable_Name  : String;
      Packet_Handler : in out CRTP_Packet_Handler;
      Has_Succeed    : out Boolean);

   --  Public procedures and functions

   --------------
   -- Log_Init --
   --------------

   procedure Log_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_LOG, Log_CRTP_Handler'Access);

      Is_Init := True;
   end Log_Init;

   --------------
   -- Log_Test --
   --------------

   function Log_Test return Boolean is
   begin
      return Is_Init;
   end Log_Test;

   ----------------------
   -- Create_Log_Group --
   ----------------------

   procedure Create_Log_Group
     (Name        : String;
      Group_ID    : out Natural;
      Has_Succeed : out Boolean)
   is
      use type Ada.Containers.Count_Type;
   begin
      Has_Succeed := False;

      if Log_Data.Log_Groups.Length = MAX_LOG_NUMBER_OF_GROUPS then
         return;
      end if;

      Log_Data.Log_Groups.Append
        ((Name   => String_To_Log_Name (Name),
          others => <>));

      Group_ID := Log_Data.Log_Groups.Length - 1;

      Has_Succeed := True;
   end Create_Log_Group;

   ----------------------------------
   -- Append_Log_Variable_To_Group --
   ----------------------------------

   procedure Append_Log_Variable_To_Group
     (Group_ID     : Natural;
      Name         : String;
      Log_Type     : Log_Variable_Type;
      Variable     : System.Address;
      Has_Succeed  : out Boolean)
   is
      Group : Log_Group
      renames Log_Data.Log_Groups.Element_Access (Group_ID).all;
      use type Ada.Containers.Count_Type;
   begin
      Has_Succeed := False;

      if Group.Log_Variables.Length = MAX_LOG_NUMBER_OF_VARIABLES_PER_GROUP
      then
         return;
      end if;

      Log_Data.Log_Variables.Append ((Group_ID => Group_ID,
                                      Name     => String_To_Log_Name (Name),
                                      Log_Type => Log_Type,
                                      Variable => Variable));

      Group.Log_Variables.Append (Log_Data.Log_Variables.Length - 1);

      Has_Succeed := True;
   end Append_Log_Variable_To_Group;

   ----------------------
   -- Add_Log_Variable --
   ----------------------

   procedure Add_Log_Variable
     (Group    :     String;
      Name     :     String;
      Log_Type :     Log_Variable_Type;
      Variable :     System.Address;
      Success  : out Boolean)
   is
      Group_Name : constant Log_Name := String_To_Log_Name (Group);
      Group_ID : Integer := -1;
      use type Log_Name;
   begin
      Success := True;
      --  May be falsified if a new group is required but can't be
      --  created.

      for J in 0 .. Log_Data.Log_Groups.Length - 1 loop
         if Log_Data.Log_Groups.Element (J).Name = Group_Name then
            Group_ID := J;
            exit;
         end if;
      end loop;

      if Group_ID not in Group_Identifier then
         --  This will be a new group; create it.
         Create_Log_Group (Name        => Group,
                           Group_ID    => Group_ID,
                           Has_Succeed => Success);
      end if;

      --  Add the variable (if all OK so far).
      if Success then
         Append_Log_Variable_To_Group (Group_ID    => Group_ID,
                                       Name        => Name,
                                       Log_Type    => Log_Type,
                                       Variable    => Variable,
                                       Has_Succeed => Success);
      end if;
   end Add_Log_Variable;

   --  Private procedures and functions

   ----------------------
   -- Log_CRTP_Handler --
   ----------------------

   procedure Log_CRTP_Handler (Packet : CRTP_Packet)
   is
      ---------------------------------
      -- CRTP_Channel_To_Log_Channel --
      ---------------------------------

      function CRTP_Channel_To_Log_Channel is new Ada.Unchecked_Conversion
        (CRTP_Channel, Log_Channel);

      Channel : Log_Channel;
   begin
      Channel := CRTP_Channel_To_Log_Channel (Packet.Channel);

      case Channel is
         when LOG_TOC_CH =>
            Log_TOC_Process (Packet);
         when LOG_CONTROL_CH =>
            Log_Control_Process (Packet);
         when others =>
            null;
      end case;
   end Log_CRTP_Handler;

   ---------------------
   -- Log_TOC_Process --
   ---------------------

   procedure Log_TOC_Process (Packet : CRTP_Packet)
   is
      --------------------------------
      -- T_Uint8_To_Log_TOC_Command --
      --------------------------------

      function T_Uint8_To_Log_TOC_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Log_TOC_Command);

      ------------------------------
      -- CRTP_Append_T_Uint8_Data --
      ------------------------------

      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);

      -------------------------------
      -- CRTP_Append_T_Uint32_Data --
      -------------------------------

      procedure CRTP_Append_T_Uint32_Data is new CRTP_Append_Data
        (T_Uint32);

      function Log_Data_CRC32 return T_Uint32;
      function Log_Data_CRC32 return T_Uint32 is
         --  Note, this doesn't take account of uninitialized
         --  components of Log_Data, but since the only use (in
         --  cfclient, anyway) is to determine whether to load new
         --  data this will just add a minor startup load.
         function Log_TOC_CRC is new CRC.Make (Data_Kind => Log_TOC);
      begin
         return T_Uint32 (Log_TOC_CRC (Log_Data));
      end Log_Data_CRC32;

      Command        : Log_TOC_Command;
      Packet_Handler : CRTP_Packet_Handler;
      Has_Succeed    : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Log_TOC_Command (Packet.Data_1 (1));
      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_LOG, Log_Channel'Enum_Rep (LOG_TOC_CH));
      CRTP_Append_T_Uint8_Data
        (Packet_Handler,
         Log_TOC_Command'Enum_Rep (Command),
         Has_Succeed);

      case Command is
         when LOG_CMD_GET_INFO =>
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               T_Uint8 (Log_Data.Log_Variables.Length),
               Has_Succeed);

            CRTP_Append_T_Uint32_Data
              (Packet_Handler,
               Log_Data_CRC32,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_LOG_BLOCKS,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_LOG_OPS,
               Has_Succeed);

         when LOG_CMD_GET_ITEM =>
            declare
               Var_ID : constant Integer
                 := Integer (Packet.Data_1 (2));
            begin
               if Var_ID < Log_Data.Log_Variables.Length then
                  CRTP_Append_T_Uint8_Data
                    (Packet_Handler,
                     T_Uint8 (Var_ID),
                     Has_Succeed);

                  declare
                     Variable : Log_Variable renames
                       Log_Data.Log_Variables.Element_Access (Var_ID).all;
                     Group : Log_Group renames
                       Log_Data.Log_Groups.Element_Access
                         (Variable.Group_ID).all;
                  begin
                     CRTP_Append_T_Uint8_Data
                       (Packet_Handler,
                        Log_Variable_Type'Enum_Rep (Variable.Log_Type),
                        Has_Succeed);
                     Append_Raw_Data_Variable_Name_To_Packet
                       (+Group.Name,
                        +Variable.Name,
                        Packet_Handler,
                        Has_Succeed);
                  end;
               else
                  --  Return the packet with no content.
                  null;
               end if;
            end;
      end case;
      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Packet_Handler),
         Has_Succeed);
   end Log_TOC_Process;

   -------------------------
   -- Log_Control_Process --
   -------------------------

   procedure Log_Control_Process (Packet : CRTP_Packet)
   is
      ------------------------------------
      -- T_Uint8_To_Log_Control_Command --
      ------------------------------------

      function T_Uint8_To_Log_Control_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Log_Control_Command);

      Tx_Packet   : CRTP_Packet := Packet;
      Command     : Log_Control_Command;
      Answer      : T_Uint8;
      Has_Succeed : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Log_Control_Command (Packet.Data_1 (1));

      case Command is
         when LOG_CONTROL_CREATE_BLOCK =>
            Answer := Log_Create_Block
              (Block_ID         => Packet.Data_1 (2),
               Ops_Settings_Raw => Packet.Data_1 (3 .. Integer (Packet.Size)));
         when LOG_CONTROL_APPEND_BLOCK =>
            Answer := Log_Append_To_Block
              (Block_ID         => Packet.Data_1 (2),
               Ops_Settings_Raw => Packet.Data_1 (3 .. Integer (Packet.Size)));
         when LOG_CONTROL_DELETE_BLOCK =>
            Answer := Log_Delete_Block (Packet.Data_1 (2));
         when LOG_CONTROL_START_BLOCK =>
            Answer := Log_Start_Block
              (Block_ID => Packet.Data_1 (2),
               Period   => Integer (Packet.Data_1 (3) *  10));
         when LOG_CONTROL_STOP_BLOCK =>
            Answer := Log_Stop_Block (Packet.Data_1 (2));
         when LOG_CONTROL_RESET =>
            Log_Reset;
            Answer := 0;
      end case;

      Tx_Packet.Data_1 (3) := Answer;
      Tx_Packet.Size := 3;
      CRTP_Send_Packet (Tx_Packet, Has_Succeed);
   end Log_Control_Process;

   ----------------------
   -- Log_Create_Block --
   ----------------------

   function Log_Create_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8
   is
      use type Ada.Containers.Count_Type;
   begin
      --  Not enough memory to create a new block.
      if Log_Block_Map.Length = Log_Block_Map.Capacity then
         return ENOMEM;
      end if;

      --  Block with the same ID already exists.
      if Log_Block_Map.Contains (Block_ID) then
         return EEXIST;
      end if;

      pragma Assert ((for some Block of Log_Blocks => Block.Free),
                     "log create, no free log blocks");

      pragma Warnings
        (Off, """return"" statement missing following this statement");

      --  Find a free block
      for J in Log_Blocks'Range loop
         if Log_Blocks (J).Free then
         --  Map and set up the block.
            Log_Block_Map.Insert (Key => Block_ID, New_Item => J);

            Log_Blocks (J).Free := False;

            return Log_Append_To_Block (Block_ID, Ops_Settings_Raw);
         end if;
      end loop;

      pragma Warnings
        (On, """return"" statement missing following this statement");
   end Log_Create_Block;

   ----------------------
   -- Log_Delete_Block --
   ----------------------

   function Log_Delete_Block (Block_ID : T_Uint8) return T_Uint8
   is
      Cursor : Log_Block_Maps.Cursor := Log_Block_Map.Find (Block_ID);
   begin
      --  Block ID doesn't match anything
      if not Log_Block_Maps.Has_Element (Cursor) then
         return ENOENT;
      end if;

      Log_Delete_Block (Log_Block_Maps.Element (Cursor));
      Log_Block_Map.Delete (Cursor);

      return 0;
   end Log_Delete_Block;

   procedure Log_Delete_Block (Block_ID : Log_Block_ID)
   is
      Block : Log_Block renames Log_Blocks (Block_ID);
      Dummy : Boolean;
   begin
      --  Stop the timer.
      Cancel_Handler (Block.Timer, Dummy);

      --  Mark the block as a free one.
      Block.Free := True;
      Block.Operations.Clear;
   end Log_Delete_Block;

   -------------------------
   -- Log_Append_To_Block --
   -------------------------

   function Log_Append_To_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8
   is
      type Short_Log_Variable_Type is new Log_Variable_Type with Size => 4;

      type Ops_Setting is record
         Storage_Type : Short_Log_Variable_Type;
         Log_Type     : Short_Log_Variable_Type;
         Variable_ID  : T_Uint8;
      end record
        with Size => 16;
      for Ops_Setting use record
         Storage_Type at 0 range 0 .. 3;
         Log_Type     at 0 range 4 .. 7;
         Variable_ID  at 1 range 0 .. 7;
      end record;

      type Ops_Settings_Array is
        array (1 .. Ops_Settings_Raw'Length / 2) of Ops_Setting;

      -----------------------------------------
      -- T_Uint8_Array_To_Ops_Settings_Array --
      -----------------------------------------

      function T_Uint8_Array_To_Ops_Settings_Array is
        new Ada.Unchecked_Conversion (T_Uint8_Array, Ops_Settings_Array);

      Cursor : constant Log_Block_Maps.Cursor := Log_Block_Map.Find (Block_ID);
      ID : Log_Block_ID;
   begin
      --  Block ID doesn't match anything
      if not Log_Block_Maps.Has_Element (Cursor) then
         return ENOENT;
      end if;

      ID := Log_Block_Maps.Element (Cursor);
      pragma Assert (not Log_Blocks (ID).Free,
                     "log append, mapped block not free");

      declare
         Block : Log_Block renames Log_Blocks (ID);
         Current_Block_Length : T_Uint8;
         Variable             : Variable_Identifier;

         Ops_Settings : constant Ops_Settings_Array
           := T_Uint8_Array_To_Ops_Settings_Array (Ops_Settings_Raw);

         use type Ada.Containers.Count_Type;
      begin

         for O of Ops_Settings loop
            Current_Block_Length := Calculate_Block_Length (Block);

            --  Trying to append a full block
            if Current_Block_Length
              + Type_Length (Log_Variable_Type (O.Log_Type)) >
              CRTP_MAX_DATA_SIZE
            then
               return E2BIG;
            end if;

            --  Check not trying to add a variable that does not exist
            if Natural (O.Variable_ID) >  Log_Data.Log_Variables.Length
            then
               return ENOENT;
            end if;

            Variable := Variable_Identifier (O.Variable_ID);

            --  XXX Shouldn't we check that O.Storage_Type matches the
            --  variable's Storage_Type?

            Block.Operations.Append
              ((Variable => Variable,
                Stored_As =>
                  Log_Data.Log_Variables.Element (Variable).Log_Type,
                Report_As => Log_Variable_Type (O.Log_Type)));
         end loop;
      end;

      return 0;
   end Log_Append_To_Block;

   ---------------------
   -- Log_Start_Block --
   ---------------------

   function Log_Start_Block
     (Block_ID : T_Uint8;
      Period   : Natural) return T_Uint8
   is
      Cursor : constant Log_Block_Maps.Cursor := Log_Block_Map.Find (Block_ID);
   begin
      --  Block ID doesn't match anything
      if not Log_Block_Maps.Has_Element (Cursor) then
         return ENOENT;
      end if;

      declare
         ID : constant Log_Block_ID := Log_Block_Maps.Element (Cursor);
         Block : Log_Block renames Log_Blocks (ID);
         Dummy : Boolean;
      begin
         pragma Assert (not Block.Free, "log start, mapped block not free");

         if Period > 0 then
            Cancel_Handler (Block.Timer, Dummy);
            Block.Timer.Client_Block_ID := Block_ID;
            Block.Timer.Period := Milliseconds (Natural'Max (Period, 10));
            Set_Handler (Event   => Block.Timer,
                         At_Time => Clock + Block.Timer.Period,
                         Handler => Log_Block_Timer_Handler);
         else
            --  TODO: single shot run. Use worker task for it.
            null;
         end if;
      end;

      return 0;
   end Log_Start_Block;

   --------------------
   -- Log_Stop_Block --
   --------------------

   function Log_Stop_Block (Block_ID : T_Uint8) return T_Uint8
   is
      Dummy : Boolean;
      Cursor : constant Log_Block_Maps.Cursor := Log_Block_Map.Find (Block_ID);
   begin
      --  Block ID doesn't match anything
      if not Log_Block_Maps.Has_Element (Cursor) then
         return ENOENT;
      end if;

      --  Stop the timer.
      Cancel_Handler (Log_Blocks (Log_Block_Maps.Element (Cursor)).Timer,
                      Dummy);

      return 0;
   end Log_Stop_Block;

   ---------------
   -- Log_Reset --
   ---------------

   procedure Log_Reset is
      Dummy  : T_Uint8;
   begin
      if Is_Init then
         for Block of Log_Block_Map loop
            Log_Delete_Block (Block);
         end loop;
         Log_Block_Map.Clear;
      end if;
   end Log_Reset;

   ---------------------------------------------
   -- Append_Raw_Data_Variable_Name_To_Packet --
   ---------------------------------------------

   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Group_Name     : String;
      Variable_Name  : String;
      Packet_Handler : in out CRTP_Packet_Handler;
      Has_Succeed    : out Boolean)
   is
      subtype Log_Complete_Name is
        String (1 .. Group_Name'Length + 1 + Variable_Name'Length + 1);
      --  includes 2 nulls
      subtype Log_Complete_Name_Raw is
        T_Uint8_Array (Log_Complete_Name'Range);

      ------------------------------------------------
      -- Log_Complete_Name_To_Log_Complete_Name_Raw --
      ------------------------------------------------

      function Log_Complete_Name_To_Log_Complete_Name_Raw is new
        Ada.Unchecked_Conversion (Log_Complete_Name, Log_Complete_Name_Raw);

      --------------------------------------------
      -- CRTP_Append_Log_Complete_Name_Raw_Data --
      --------------------------------------------

      procedure CRTP_Append_Log_Complete_Name_Raw_Data is new
        CRTP_Append_Data (Log_Complete_Name_Raw);

      Complete_Name_Raw : constant Log_Complete_Name_Raw
        := Log_Complete_Name_To_Log_Complete_Name_Raw
          (Group_Name & ASCII.NUL & Variable_Name & ASCII.NUL);
   begin
      CRTP_Append_Log_Complete_Name_Raw_Data
        (Packet_Handler,
         Complete_Name_Raw,
         Has_Succeed);
   end Append_Raw_Data_Variable_Name_To_Packet;

   ----------------------------
   -- Calculate_Block_Length --
   ----------------------------

   function Calculate_Block_Length (Block : Log_Block) return T_Uint8
   is
      Block_Length : T_Uint8 := 0;
   begin

      for J in 0 .. Block.Operations.Length - 1 loop
         Block_Length := Block_Length
           + Type_Length (Block.Operations.Element (J).Report_As);
      end loop;

      return Block_Length;
   end Calculate_Block_Length;

   ------------------------
   -- Get_Log_Time_Stamp --
   ------------------------

   function Get_Log_Time_Stamp return Log_Time_Stamp
   is
      subtype  Time_T_Uint8_Array is T_Uint8_Array (1 .. 8);

      --------------------------------
      -- Time_To_Time_T_Uint8_Array --
      --------------------------------

      function Time_To_Time_T_Uint8_Array is new Ada.Unchecked_Conversion
        (Time, Time_T_Uint8_Array);

      Raw_Time   : Time_T_Uint8_Array;
      Time_Stamp : Log_Time_Stamp;
   begin
      Raw_Time := Time_To_Time_T_Uint8_Array (Clock);

      Time_Stamp := Raw_Time (6 .. 8);

      return Time_Stamp;
   end Get_Log_Time_Stamp;

   --  Tasks and protected objects

   ------------------------------------
   -- Log_Block_Timing_Event_Handler --
   ------------------------------------

   protected body Log_Block_Timing_Event_Handler is

      -------------------
      -- Log_Run_Block --
      -------------------

      procedure Log_Run_Block (Event : in out Timing_Event) is
         Actual_Event : Log_Block_Timing_Event
           renames Log_Block_Timing_Event (Timing_Event'Class (Event));
      begin
            Block_To_Record := Actual_Event.Client_Block_ID;
            Record_Required := True;

            Set_Handler (Event   => Event,
                         At_Time => Clock + Actual_Event.Period,
                         Handler => Log_Block_Timer_Handler);
      end Log_Run_Block;

      ---------------
      -- Run_Block --
      ---------------

      entry Get_Block_To_Run (ID : out T_Uint8) when Record_Required is
      begin
         Record_Required := False;
         ID := Block_To_Record;
      end Get_Block_To_Run;

   end Log_Block_Timing_Event_Handler;

   task body Logger is
      Client_Block_ID : T_Uint8;
      Block_ID        : Log_Block_ID;
      Variable        : System.Address;
      Time_Stamp      : Log_Time_Stamp;
      Packet_Handler  : CRTP_Packet_Handler;
      Has_Succeed     : Boolean
        with Unreferenced;

      --  Procedures used to append log data with different types

      ------------------------------------
      -- Procedures used to append data --
      ------------------------------------

      procedure CRTP_Append_Log_Time_Stamp_Data is new CRTP_Append_Data
        (Log_Time_Stamp);
      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);
      procedure CRTP_Append_T_Uint16_Data is new CRTP_Append_Data
        (T_Uint16);
      procedure CRTP_Append_T_Uint32_Data is new CRTP_Append_Data
        (T_Uint32);
      procedure CRTP_Append_T_Int8_Data is new CRTP_Append_Data
        (T_Int8);
      procedure CRTP_Append_T_Int16_Data is new CRTP_Append_Data
        (T_Int16);
      procedure CRTP_Append_T_Int32_Data is new CRTP_Append_Data
        (T_Int32);
      procedure CRTP_Append_Float_Data is new CRTP_Append_Data
        (Float);
   begin
      loop
         Log_Block_Timing_Event_Handler.Get_Block_To_Run
           (ID => Client_Block_ID);

         if CRTP_Is_Connected
           and then Log_Block_Map.Contains (Client_Block_ID)
           --  Bit of a race condition here! Blocks could have been reset.
         then

            Block_ID := Log_Block_Map (Client_Block_ID);

            Time_Stamp := Get_Log_Time_Stamp;

            Packet_Handler :=
              CRTP_Create_Packet
                (Port    => CRTP_PORT_LOG,
                 Channel => Log_Channel'Enum_Rep (LOG_DATA_CH));

            --  Add block ID to the packet.
            CRTP_Append_T_Uint8_Data (Handler     => Packet_Handler,
                                      Data        => Client_Block_ID,
                                      Has_Succeed => Has_Succeed);
            --  Add a timestamp to the packet
            CRTP_Append_Log_Time_Stamp_Data (Handler     => Packet_Handler,
                                             Data        => Time_Stamp,
                                             Has_Succeed => Has_Succeed);

            --  Add all the variables data in the packet
            for J in 0 .. Log_Blocks (Block_ID).Operations.Length - 1 loop
               declare
                  Op : Log_Operation renames
                    Log_Blocks (Block_ID).Operations.Element_Access (J).all;
               begin
                  --  Get the address of this operation's variable.
                  Variable :=
                    Log_Data.Log_Variables.Element (Op.Variable).Variable;

                  case Op.Report_As is
                     when LOG_UINT8 =>
                        declare
                           Value : T_Uint8;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Uint8_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_UINT16 =>
                        declare
                           Value : T_Uint16;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Uint16_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_UINT32 =>
                        declare
                           Value : T_Uint32;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Uint32_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_INT8 =>
                        declare
                           Value : T_Int8;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Int8_Data
                             (Handler      => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_INT16 =>
                        declare
                           Value : T_Int16;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Int16_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_INT32 =>
                        declare
                           Value : T_Int32;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_T_Int32_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                     when LOG_FLOAT =>
                        declare
                           Value : Float;
                           for Value'Address use Variable;
                        begin
                           CRTP_Append_Float_Data
                             (Handler     => Packet_Handler,
                              Data        => Value,
                              Has_Succeed => Has_Succeed);
                        end;
                  end case;
               end;
            end loop;

            CRTP_Send_Packet
              (Packet       => CRTP_Get_Packet_From_Handler (Packet_Handler),
               Has_Succeed  => Has_Succeed);

         else -- CRTP no longer connected
            Log_Reset;
            CRTP_Reset;
         end if;

      end loop;
   end Logger;

end Log;
