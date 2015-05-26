package Communication_Pack is

   --  Procedures and functions

   --  Initialize all the communication related modules
   procedure Communication_Init;

   --  Test if the communication modules is initialized
   function Communication_Test return Boolean;

Private

   --  Global variables and constants

   Is_Init : Boolean := False;

end Communication_Pack;
