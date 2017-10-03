package Log is
   --  Types

   --  Type representing all the variable types we can log.
   type Log_Variable_Type is
     (LOG_UINT8,
      LOG_UINT16,
      LOG_UINT32,
      LOG_INT8,
      LOG_INT16,
      LOG_INT32,
      LOG_FLOAT);
   for Log_Variable_Type use
     (LOG_UINT8  => 1,
      LOG_UINT16 => 2,
      LOG_UINT32 => 3,
      LOG_INT8   => 4,
      LOG_INT16  => 5,
      LOG_INT32  => 6,
      LOG_FLOAT  => 7);
   for Log_Variable_Type'Size use 8;

   --  Procedures and functions

   --  Initialize the log subsystem.
   procedure Log_Init;

   --  Test if the log subsystem is initialized.
   function Log_Test return Boolean;

   Max_Name_Length : constant := 14;

   --  Create a log group if there is any space left and if the name
   --  is not too long.
   procedure Create_Log_Group
     (Name        : String;
      Group_ID    : out Natural;
      Has_Succeed : out Boolean)
   with Pre => Name'Length <= Max_Name_Length;

   --  Append a variable to a log group.
   procedure Append_Log_Variable_To_Group
     (Group_ID     : Natural;
      Name         : String;
      Log_Type     : Log_Variable_Type;
      Variable     : System.Address;
      Has_Succeed  : out Boolean)
   with Pre => Name'Length <= Max_Name_Length;

   --  Add a variable to a log group, creating the group if necessary.
   procedure Add_Log_Variable
     (Group    :     String;
      Name     :     String;
      Log_Type :     Log_Variable_Type;
      Variable :     System.Address;
      Success  : out Boolean)
   with Pre =>
       Group'Length <= Max_Name_Length and Name'Length <= Max_Name_Length;

end Log;
