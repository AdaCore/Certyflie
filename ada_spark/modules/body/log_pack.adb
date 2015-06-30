with Ada.Unchecked_Conversion;

package body Log_Pack is

   --  Public procedures and functions

   procedure Log_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_LOG, Log_CRTP_Handler'Access);

      Is_Init := True;
   end Log_Init;

   function Log_Test return Boolean is
   begin
      return Is_Init;
   end Log_Test;

   procedure Create_Log_Group
     (Name        : String;
      Group_ID    : out Natural;
      Has_Succeed : out Boolean) is
      Log_Groups_Index : constant Natural := Log_Data.Log_Groups_Index;
   begin
      if Log_Groups_Index > Log_Data.Log_Groups'Last or
        Name'Length > MAX_LOG_VARIABLE_NAME_LENGTH then
         Has_Succeed := False;
         return;
      end if;

      Log_Data.Log_Groups (Log_Groups_Index).Name :=
        String_To_Log_Name (Name);
      Log_Data.Log_Groups (Log_Groups_Index).Name_Length :=
        Name'Length + 1;
      Group_ID := Log_Groups_Index;
      Log_Data.Log_Groups_Index := Log_Groups_Index + 1;

      Has_Succeed := True;
   end Create_Log_Group;

   procedure Append_Log_Variable_To_Group
     (Group_ID     : Natural;
      Name         : String;
      Storage_Type : Log_Variable_Type;
      Log_Type     : Log_Variable_Type;
      Variable     : System.Address;
      Has_Succeed  : out Boolean) is
      Group               : Log_Group;
      Log_Variables_Index : Log_Variable_ID;
   begin
      Has_Succeed := False;

      --  If group ID doesn't exist.
      if Group_ID not in Log_Data.Log_Groups'Range then
         return;
      end if;

      Group := Log_Data.Log_Groups (Group_ID);
      Log_Variables_Index := Group.Log_Variables_Index;

      if Log_Variables_Index > Group.Log_Variables'Last or
        Name'Length > MAX_LOG_VARIABLE_NAME_LENGTH then
         return;
      end if;

      Group.Log_Variables (Log_Variables_Index).Name :=
        String_To_Log_Name (Name);
      Group.Log_Variables (Log_Variables_Index).Group_ID := Group_ID;
      Group.Log_Variables (Log_Variables_Index).Name_Length := Name'Length + 1;
      Group.Log_Variables (Log_Variables_Index).Storage_Type := Storage_Type;
      Group.Log_Variables (Log_Variables_Index).Log_Type := Log_Type;
      Group.Log_Variables (Log_Variables_Index).Variable := Variable;

      Group.Log_Variables_Index := Log_Variables_Index + 1;

      Log_Data.Log_Groups (Group_ID) := Group;

      Log_Data.Log_Variables (Log_Data.Log_Variables_Count)
        := Log_Data.Log_Groups
          (Group_ID).Log_Variables (Log_Variables_Index)'Access;

      Log_Data.Log_Variables_Count := Log_Data.Log_Variables_Count + 1;
      Has_Succeed := True;
   end Append_Log_Variable_To_Group;

   --  Private procedures and functions

   procedure Log_CRTP_Handler (Packet : CRTP_Packet) is
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

   procedure Log_TOC_Process (Packet : CRTP_Packet) is
      function T_Uint8_To_Log_TOC_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Log_TOC_Command);
      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);
      procedure CRTP_Append_T_Uint32_Data is new CRTP_Append_Data
        (T_Uint32);

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
               Log_Data.Log_Variables_Count,
               Has_Succeed);
            --  Add CRC. 0 for the moment..
            CRTP_Append_T_Uint32_Data
              (Packet_Handler,
               0,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_LOG_NUMBER_OF_GROUPS,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_LOG_NUMBER_OF_GROUPS * MAX_LOG_NUMBER_OF_VARIABLES_PER_GROUP,
               Has_Succeed);

         when LOG_CMD_GET_ITEM =>
            declare
               Var_ID          : constant T_Uint8 := Packet.Data_1 (2);
               Log_Var         : Log_Variable;
               Log_Var_Group   : Log_Group;
            begin
               if Var_ID < Log_Data.Log_Variables_Count then
                  CRTP_Append_T_Uint8_Data
                    (Packet_Handler,
                     Var_ID,
                     Has_Succeed);

                  Log_Var := Log_Data.Log_Variables (Var_ID).all;
                  Log_Var_Group := Log_Data.Log_Groups (Log_Var.Group_ID);
                  CRTP_Append_T_Uint8_Data
                    (Packet_Handler,
                     Log_Variable_Type'Enum_Rep (Log_Var.Log_Type),
                     Has_Succeed);
                  Append_Raw_Data_Variable_Name_To_Packet
                    (Log_Var,
                     Log_Var_Group,
                     Packet_Handler,
                     Has_Succeed);
               end if;
            end;
      end case;
      CRTP_Send_Packet
        (CRTP_Get_Packet_From_Handler (Packet_Handler),
         Has_Succeed);
   end Log_TOC_Process;

   procedure Log_Control_Process (Packet : CRTP_Packet) is
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
            null;
         when LOG_CONTROL_APPEND_BLOCK =>
            null;
         when LOG_CONTROL_DELETE_BLOCK =>
            null;
         when LOG_CONTROL_START_BLOCK =>
            null;
         when LOG_CONTROL_STOP_BLOCK =>
            null;
         when LOG_CONTROL_RESET =>
            Answer := 0;
      end case;

      Tx_Packet.Data_1 (3) := Answer;
      Tx_Packet.Size := 3;
      CRTP_Send_Packet (Tx_Packet, Has_Succeed);
   end Log_Control_Process;

   function Log_Create_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8 is
   begin
      return 0;
   end Log_Create_Block;

   function Log_Append_To_Block
     (Block_ID         : T_Uint8;
      Ops_Settings_Raw : T_Uint8_Array) return T_Uint8 is
      type Ops_Settings_Array is
        array (Ops_Settings_Raw'Range) of Log_Ops_Setting;
      function T_Uint8_Array_To_Ops_Settings_Array is
        new Ada.Unchecked_Conversion (T_Uint8_Array, Ops_Settings_Array);

      Block        : access Log_Block;
      Ops_Settings : Ops_Settings_Array;
   begin
      --  Block ID doesn't match anything
      if Block_ID not in Log_Blocks'Range then
         return ENOENT;
      end if;

      Block := Log_Blocks (Block_ID)'Access;

      --  Block not created
      if Block.Free then
         return ENOENT;
      end if;

      Ops_Settings := T_Uint8_Array_To_Ops_Settings_Array (Ops_Settings_Raw);

      declare
         Current_Block_Length : T_Uint8;
         Ops_Setting          : Log_Ops_Setting;
         Variable             : access Log_Variable;
      begin

         for I in Ops_Settings'Range loop
            Current_Block_Length := Calculate_Block_Length (Block);
            Ops_Setting := Ops_Settings (I);

            --  Trying to append a full block
            if Current_Block_Length + Type_Length (Ops_Setting.Log_Type) >
              CRTP_MAX_DATA_SIZE then
               return E2BIG;
            end if;

            --  Trying a to add a variable that does not exist
            if Ops_Setting.ID not in Log_Data.Log_Variables'Range or else
              Log_Data.Log_Variables (Ops_Setting.ID) = null then
               return ENOENT;
            end if;

            Variable := Log_Data.Log_Variables (Ops_Setting.ID);

            Append_Log_Variable_To_Block (Block, Variable);
         end loop;
      end;

      return 0;
   end Log_Append_To_Block;

   procedure Append_Log_Variable_To_Block
     (Block    : access Log_Block;
      Variable : access Log_Variable) is
      Variables_Aux : access Log_Variable := Block.Variables;
   begin
      --  No variables have been appended to this block until now.
      if Variables_Aux = null then
         Variables_Aux := Variable;
      else
         while Variables_Aux.Next /= null loop
            Variables_Aux := Variables_Aux.Next;
         end loop;

         Variables_Aux.Next := Variable;
      end if;
   end Append_Log_Variable_To_Block;

   function String_To_Log_Name (Name : String) return Log_Name is
      Result : Log_Name := (others => ASCII.NUL);
   begin
      Result (1 .. Name'Length) := Name;

      return Result;
   end String_To_Log_Name;

   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Variable        : Log_Variable;
      Group           : Log_Group;
      Packet_Handler  : in out CRTP_Packet_Handler;
      Has_Succeed     : out Boolean) is
      subtype Log_Complete_Name is
        String (1 .. Variable.Name_Length + Group.Name_Length);
      subtype Log_Complete_Name_Raw is
        T_Uint8_Array (1 .. Variable.Name_Length + Group.Name_Length);
      function Log_Complete_Name_To_Log_Complete_Name_Raw is new
        Ada.Unchecked_Conversion (Log_Complete_Name, Log_Complete_Name_Raw);
      procedure CRTP_Append_Log_Complete_Name_Raw_Data is new
        CRTP_Append_Data (Log_Complete_Name_Raw);

      Complete_Name     : constant Log_Complete_Name
        := Group.Name (1 .. Group.Name_Length) &
                            Variable.Name (1 .. Variable.Name_Length);
      Complete_Name_Raw : Log_Complete_Name_Raw;
   begin
      Complete_Name_Raw :=
        Log_Complete_Name_To_Log_Complete_Name_Raw (Complete_Name);
      CRTP_Append_Log_Complete_Name_Raw_Data
        (Packet_Handler,
         Complete_Name_Raw,
         Has_Succeed);
   end Append_Raw_Data_Variable_Name_To_Packet;

   function Calculate_Block_Length (Block : access Log_Block) return T_Uint8 is
      Variables    : access Log_Variable := Block.Variables;
      Block_Length : T_Uint8 := 0;
   begin

      while Variables /= null loop
         Block_Length := Block_Length + Type_Length (Variables.Log_Type);
         Variables := Variables.Next;
      end loop;

      return Block_Length;
   end Calculate_Block_Length;

end Log_Pack;
