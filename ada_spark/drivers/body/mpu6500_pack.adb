package body MPU6500_Pack is

   procedure MPU6500_Init is
   begin
      if Is_Init then
         return;
      end if;

      --  TODO: implement the whole function
   end MPU6500_Init;

   function MPU6500_Test return Boolean is
   begin
      return Is_Init;
   end MPU6500_Test;

end MPU6500_Pack;
