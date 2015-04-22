pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Protected_IO_Pack;
with Syslink_Pack; use Syslink_Pack;
with Console_Pack; use Console_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;
with SensFusion6_Pack; use SensFusion6_Pack;

procedure Main is
begin
   --  Use for thread safe printing
   Protected_IO_Pack.Initialize;

   --  Module initialization
   Platform_Service_Init;
   Commander_Init;
   Syslink_Init;
   Console_Init;
end Main;
