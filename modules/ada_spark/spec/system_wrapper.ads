package System_Wrapper
  with SPARK_Mode
is
	procedure C_SystemLaunch;
	procedure Ada_SystemLaunch;
	pragma Import(C, C_SystemLaunch, "systemLaunch");
	pragma Export(C, Ada_SystemLaunch, "ada_systemLaunch");

	MyConstant : aliased Integer := 0;
end System_Wrapper;
