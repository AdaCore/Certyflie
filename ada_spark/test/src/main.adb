pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Protected_IO_Pack;
with Syslink_Pack; use Syslink_Pack;
with Console_Pack; use Console_Pack;
with Platform_Service_Pack; use Platform_Service_Pack;

procedure Main is
begin
   Platform_Service_Init;
   Protected_IO_Pack.Initialize;
   Syslink_Init;
   Console_Init;
end Main;
