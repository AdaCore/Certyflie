package Communication is

   --  Procedures and functions

   --  Initialize all the communication related modules.
   procedure Communication_Init;

   --  Test if the communication modules is initialized.
   function Communication_Test return Boolean;

private

   --  Global variables and constants

   Is_Init : Boolean := False;

end Communication;
