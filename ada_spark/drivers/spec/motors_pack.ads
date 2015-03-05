package Motors_Pack is

   --  Procedures and functions
   procedure Motors_Init;
   pragma Import (C, Motors_Init, "motorsInit");

end Motors_Pack;
