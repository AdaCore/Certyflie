with Ada.Unchecked_Conversion;

package body Parameter_Pack is

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
        Name'Length > MAX_PARAM_VARIABLE_NAME_LENGTH then
         Has_Succeed := False;
         return;
      end if;

      Parameter_Data.Parameter_Groups (Parameter_Groups_Index).Name :=
        String_To_Parameter_Name (Name);
      Parameter_Data.Parameter_Groups (Parameter_Groups_Index).Name_Length :=
        Name'Length + 1;
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
      Storage_Type   : Parameter_Variable_Type;
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
        Name'Length > MAX_PARAM_VARIABLE_NAME_LENGTH then
         return;
      end if;

      Group.Parameter_Variables (Parameter_Variables_Index).Name :=
        String_To_Parameter_Name (Name);
      Group.Parameter_Variables (Parameter_Variables_Index).Group_ID
        := Group_ID;
      Group.Parameter_Variables (Parameter_Variables_Index).Name_Length
        := Name'Length + 1;
      Group.Parameter_Variables (Parameter_Variables_Index).Storage_Type
        := Storage_Type;
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

      case Channel is
         when PARAM_TOC_CH =>
            Parameter_TOC_Process (Packet);
         when PARAM_READ_CH =>
            null;
         when PARAM_WRITE_CH =>
            null;
      end case;
   end Parameter_CRTP_Handler;

   ---------------------------
   -- Parameter_TOC_Process --
   ---------------------------

   procedure Parameter_TOC_Process (Packet : CRTP_Packet)
   is
      --------------------------------------
      -- T_Uint8_To_Parameter_TOC_Command --
      --------------------------------------

      function T_Uint8_To_Parameter_TOC_Command is new Ada.Unchecked_Conversion
        (T_Uint8, Parameter_TOC_Command);

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
            --  Add CRC. 1 for the moment..
            CRTP_Append_T_Uint32_Data
              (Packet_Handler,
               1,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_PARAM_NUMBER_OF_GROUPS,
               Has_Succeed);
            CRTP_Append_T_Uint8_Data
              (Packet_Handler,
               MAX_PARAM_NUMBER_OF_GROUPS * MAX_PARAM_NUMBER_OF_VARIABLES,
               Has_Succeed);

         when PARAM_CMD_GET_ITEM =>
            declare
               Var_ID          : constant T_Uint8 := Packet.Data_1 (2);
               Parameter_Var         : Parameter_Variable;
               Parameter_Var_Group   : Parameter_Group;
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
                  CRTP_Append_T_Uint8_Data
                    (Packet_Handler,
                     Parameter_Variable_Type'Enum_Rep
                       (Parameter_Var.Parameter_Type),
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
        String (1 .. Variable.Name_Length + Group.Name_Length);
      subtype Parameter_Complete_Name_Raw is
        T_Uint8_Array (1 .. Variable.Name_Length + Group.Name_Length);

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
        := Group.Name (1 .. Group.Name_Length) &
                        Variable.Name (1 .. Variable.Name_Length);
      Complete_Name_Raw : Parameter_Complete_Name_Raw;
   begin
      Complete_Name_Raw :=
        Parameter_Complete_Name_To_Parameter_Complete_Name_Raw (Complete_Name);
      CRTP_Append_Parameter_Complete_Name_Raw_Data
        (Packet_Handler,
         Complete_Name_Raw,
         Has_Succeed);
   end Append_Raw_Data_Variable_Name_To_Packet;

end Parameter_Pack;
