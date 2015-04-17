pragma Profile (Ravenscar);
with Commander_Pack; use Commander_Pack;
with Protected_IO_Pack;

procedure Main is
begin
   Protected_IO_Pack.Initialize;
end Main;
