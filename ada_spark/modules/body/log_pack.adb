package body Log_Pack is

   task body Log_Task is
   begin
      loop
         null;
      end loop;
   end Log_Task;

   procedure Log_Init is
   begin
      if Is_Init then
         return;
      end if;

      Is_Init := True;
   end Log_Init;

   procedure Create_Log_Group
     (Name        : String;
      Has_Succeed : out Boolean) is
      New_Group      : constant access Log_Group := new Log_Group;
      Log_Groups_Aux : access Log_Group := Log_Groups;
   begin
      if Log_Groups_Count < MAX_LOG_NUMBER_OF_GROUPS and
        Name'Length <= MAX_LOG_VARIABLE_NAME_LENGTH then
         New_Group.Name := Name;
         New_Group.ID := Log_Groups_Count;
         while Log_Groups_Aux.Next /= null loop
            Log_Groups_Aux := Log_Groups_Aux.Next;
         end loop;
         Log_Groups_Aux.Next := New_Group;
         Log_Groups_Count := Log_Groups_Count + 1;
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end Create_Log_Group;

   procedure Append_Log_Variable_To_Group
     (Group_ID     : Natural;
      Name         : String;
      Storage_Type : Log_Variable_Type;
      Log_Type     : Log_Variable_Type;
      Variable     : System.Address;
      Has_Succeed  : out Boolean) is
      Group             : access Log_Group := Log_Groups;
      Log_Variables_Aux : access Log_Variable;
      New_Log_Variable  : constant access Log_Variable := new Log_Variable;
   begin
      --  Find the group to which we want append this variable/
      while Group.ID /= Group_ID loop
         Group := Group.Next;
      end loop;

      if Group = null then
         Has_Succeed := False;
         return;
      end if;

      if Group.Log_Variables_Count < MAX_LOG_NUMBER_OF_VARIABLES and
        Name'Length <= MAX_LOG_VARIABLE_NAME_LENGTH then
         Log_Variables_Aux := Group.Log_Variables;

         while Log_Variables_Aux.Next /= null loop
            Log_Variables_Aux := Log_Variables_Aux.Next;
         end loop;

         New_Log_Variable.Name := Name;
         New_Log_Variable.ID := Group.Log_Variables_Count;
         New_Log_Variable.Storage_Type := Storage_Type;
         New_Log_Variable.Log_Type := Log_Type;
         New_Log_Variable.Variable := Variable;

         Log_Variables_Aux.Next := New_Log_Variable;

         Group.Log_Variables_Count := Group.Log_Variables_Count + 1;
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end Append_Log_Variable_To_Group;

end Log_Pack;
