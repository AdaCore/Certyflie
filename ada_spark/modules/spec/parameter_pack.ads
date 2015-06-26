package Parameter_Pack is

   --  Types

   --  Type representing all the avalaible parameter module CRTP channels.
   type Parameter_Channel is
     (PARAM_TOC_CH,
      PARAM_READ_CH,
      PARAM_WRITE_CH);
   for Parameter_Channel use
     (PARAM_TOC_CH   => 0,
      PARAM_READ_CH  => 1,
      PARAM_WRITE_CH => 2);
   for Parameter_Channel'Size use 2;

   --  Type reprensenting all the param commands.
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

   --  Procedures and functions

   --  Initialize the paramater subystem.
   procedure Parameter_Init;

   --  Test if the parameter subsystem is initialized.
   function Parameter_Test return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

   --  Procedures and functions

   --  Handler called when a CRTP packet is received in the param
   --  port.
   procedure Parameter_CRTP_Handler (Packet : CRTP_Packet);

end Parameter_Pack;
