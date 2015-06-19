package Log_Pack is
   --  Types

   --  Type represneting al the variable types we can log.
   type Log_Variable_Type is
     (LOG_UINT8,
      LOG_UINT16,
      LOG_UINT32,
      LOG_INT8,
      LOG_INT16,
      LOG_INT32,
      LOG_FLOAT,
      LOG_FP16);
   for Log_Variable_Type use
     (LOG_UINT8  => 1,
      LOG_UINT16 => 2,
      LOG_UINT32 => 3,
      LOG_INT8   => 4,
      LOG_INT16  => 5,
      LOG_INT32  => 6,
      LOG_FLOAT  => 7,
      LOG_FP16   => 8);
   for Log_Variable_Type'Size use 8;

   --  Type representing all the avalaible log channels.
   type Log_Channel is
     (TOC_CH,
      CONTROL_CH,
      LOG_CH);
   for Log_Channel use
     (TOC_CH     => 0,
      CONTROL_CH => 1,
      LOG_CH     => 2);
   for Log_Channel'Size use 2;

   --  Type reprensenting all the log commands.
   --  LOG_CMD_GET_INFO is requested at connexion to fetch the TOC.
   --  LOG_CMD_GET_ITEM is requested whenever the client wants to
   --  fetch the newest variable data.
   type Log_Command is
     (LOG_CMD_GET_INFO,
      LOG_CMD_GET_ITEM);
   for Log_Command use
     (LOG_CMD_GET_INFO => 0,
      LOG_CMD_GET_ITEM => 1);
   for Log_Command'Size use 8;

   --  Type representing all the available control commands.
   type Log_Control_Command is
     (CONTROL_CREATE_BLOCK,
      CONTROL_APPEND_BLOCK,
      CONTROL_DELETE_BLOCK,
      CONTROL_START_BLOCK,
      CONTROL_STOP_BLOCK,
      CONTROL_RESET);
   for Log_Control_Command use
     (CONTROL_CREATE_BLOCK => 0,
      CONTROL_APPEND_BLOCK => 1,
      CONTROL_DELETE_BLOCK => 2,
      CONTROL_START_BLOCK  => 3,
      CONTROL_STOP_BLOCK   => 4,
      CONTROL_RESET        => 5);
   for Log_Control_Command'Size use 8;

end Log_Pack;
