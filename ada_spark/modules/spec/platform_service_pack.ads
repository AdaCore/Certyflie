package Platform_Service_Pack is

   --  Procedures and functions

   --  Initialize the platform service module
   procedure Platform_Service_Init;

   --  Test if the platform service is initialized
   function Platform_Service_Test return Boolean;

private

   Is_Init : Boolean := False;

end Platform_Service_Pack;
