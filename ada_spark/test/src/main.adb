pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Protected_IO_Pack;
with Console_Pack; use Console_Pack;

procedure Main is
begin
   Protected_IO_Pack.Initialize;
   Console_Init;
end Main;
