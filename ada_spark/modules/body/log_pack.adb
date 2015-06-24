with Ada.Unchecked_Conversion;

package body Log_Pack is

   --     task body Log_Task is
   --     begin
   --        loop
   --           null;
   --        end loop;
   --     end Log_Task;

   --  Public procedures and functions

   procedure Log_Init is
   begin
      if Is_Init then
         return;
      end if;

      CRTP_Register_Callback (CRTP_PORT_LOG, Log_CRTP_Handler'Access);

      Is_Init := True;
   end Log_Init;


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
      Log_Variables_Index : Natural;
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

      Log_Data.Log_Variables_Count := Log_Data.Log_Variables_Count + 1;
      Log_Data.Log_Variables (Integer (Log_Data.Log_Variables_Count))
        := Log_Data.Log_Groups
          (Group_ID).Log_Variables (Log_Variables_Index)'Access;
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
         when TOC_CH =>
            Log_TOC_Process (Packet);
         when CONTROL_CH =>
            null;
         when others =>
            null;
      end case;
   end Log_CRTP_Handler;

   procedure Log_TOC_Process (Packet : CRTP_Packet) is
      function T_Uint8_To_Log_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Log_Command);
      procedure CRTP_Append_T_Uint8_Data is new CRTP_Append_Data
        (T_Uint8);
      procedure CRTP_Append_T_Uint32_Data is new CRTP_Append_Data
        (T_Uint32);
      Command        : Log_Command;
      Packet_Handler : CRTP_Packet_Handler;
      Has_Succeed    : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      Command := T_Uint8_To_Log_Command (Packet.Data_1 (1));
      Packet_Handler := CRTP_Create_Packet
        (CRTP_PORT_LOG, Log_Channel'Enum_Rep (TOC_CH));
      CRTP_Append_T_Uint8_Data
        (Packet_Handler,
         Log_Command'Enum_Rep (Command),
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
               MAX_LOG_NUMBER_OF_GROUPS * MAX_LOG_NUMBER_OF_VARIABLES,
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

                  Log_Var := Log_Data.Log_Variables (Integer (Var_ID)).all;
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

   function String_To_Log_Name (Name : String) return Log_Name is
      Result : Log_Name := (others => ASCII.NUL);
   begin
      Result (1 .. Name'Length) := Name;

      return Result;
   end String_To_Log_Name;

   procedure Append_Raw_Data_Variable_Name_To_Packet
     (Variable       : Log_Variable;
      Group          : Log_Group;
      Packet_Handler : in out CRTP_Packet_Handler;
      Has_Succeed     : out Boolean) is
      subtype Log_Complete_Name is
        String (1 .. Variable.Name_Length + Group.Name_Length);
      subtype Log_Complete_Name_Raw is
        T_Uint8_Array (1 .. Variable.Name_Length + Group.Name_Length);
      function Log_Complete_Name_To_Log_Complete_Name_Raw is new
        Ada.Unchecked_Conversion (Log_Complete_Name, Log_Complete_Name_Raw);
      procedure CRTP_Append_Log_Complete_Name_Raw_Data is new
        CRTP_Append_Data (Log_Complete_Name_Raw);

      Complete_Name : constant Log_Complete_Name
        := Variable.Name (1 .. Variable.Name_Length) &
                        Group.Name (1 .. Group.Name_Length);
      Complete_Name_Raw : Log_Complete_Name_Raw;
   begin
      Complete_Name_Raw :=
        Log_Complete_Name_To_Log_Complete_Name_Raw (Complete_Name);
      CRTP_Append_Log_Complete_Name_Raw_Data
        (Packet_Handler,
         Complete_Name_Raw,
         Has_Succeed);
   end Append_Raw_Data_Variable_Name_To_Packet;

end Log_Pack;
