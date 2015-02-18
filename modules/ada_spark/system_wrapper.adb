package body System_Wrapper is
	procedure Ada_SystemLaunch is
	begin
		C_SystemInit;
	end Ada_SystemLaunch;
end System_Wrapper;