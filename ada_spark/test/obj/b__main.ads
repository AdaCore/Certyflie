pragma Ada_95;
with System;
package ada_main is
   pragma Warnings (Off);

   gnat_argc : Integer;
   gnat_argv : System.Address;
   gnat_envp : System.Address;

   pragma Import (C, gnat_argc);
   pragma Import (C, gnat_argv);
   pragma Import (C, gnat_envp);

   gnat_exit_status : Integer;
   pragma Import (C, gnat_exit_status);

   GNAT_Version : constant String :=
                    "GNAT Version: Pro 7.4.0w (20150305-49)" & ASCII.NUL;
   pragma Export (C, GNAT_Version, "__gnat_version");

   Ada_Main_Program_Name : constant String := "_ada_main" & ASCII.NUL;
   pragma Export (C, Ada_Main_Program_Name, "__gnat_ada_main_program_name");

   procedure adainit;
   pragma Export (C, adainit, "adainit");

   procedure adafinal;
   pragma Export (C, adafinal, "adafinal");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer;
   pragma Export (C, main, "main");

   type Version_32 is mod 2 ** 32;
   u00001 : constant Version_32 := 16#2816ed74#;
   pragma Export (C, u00001, "mainB");
   u00002 : constant Version_32 := 16#fbff4c67#;
   pragma Export (C, u00002, "system__standard_libraryB");
   u00003 : constant Version_32 := 16#f8ed8679#;
   pragma Export (C, u00003, "system__standard_libraryS");
   u00004 : constant Version_32 := 16#3ffc8e18#;
   pragma Export (C, u00004, "adaS");
   u00005 : constant Version_32 := 16#28f088c2#;
   pragma Export (C, u00005, "ada__text_ioB");
   u00006 : constant Version_32 := 16#1559b345#;
   pragma Export (C, u00006, "ada__text_ioS");
   u00007 : constant Version_32 := 16#ca3f4ca0#;
   pragma Export (C, u00007, "ada__exceptionsB");
   u00008 : constant Version_32 := 16#12dbb701#;
   pragma Export (C, u00008, "ada__exceptionsS");
   u00009 : constant Version_32 := 16#a46739c0#;
   pragma Export (C, u00009, "ada__exceptions__last_chance_handlerB");
   u00010 : constant Version_32 := 16#3aac8c92#;
   pragma Export (C, u00010, "ada__exceptions__last_chance_handlerS");
   u00011 : constant Version_32 := 16#fb0c3f68#;
   pragma Export (C, u00011, "systemS");
   u00012 : constant Version_32 := 16#a207fefe#;
   pragma Export (C, u00012, "system__soft_linksB");
   u00013 : constant Version_32 := 16#a056eebf#;
   pragma Export (C, u00013, "system__soft_linksS");
   u00014 : constant Version_32 := 16#b01dad17#;
   pragma Export (C, u00014, "system__parametersB");
   u00015 : constant Version_32 := 16#85263217#;
   pragma Export (C, u00015, "system__parametersS");
   u00016 : constant Version_32 := 16#b19b6653#;
   pragma Export (C, u00016, "system__secondary_stackB");
   u00017 : constant Version_32 := 16#506df001#;
   pragma Export (C, u00017, "system__secondary_stackS");
   u00018 : constant Version_32 := 16#39a03df9#;
   pragma Export (C, u00018, "system__storage_elementsB");
   u00019 : constant Version_32 := 16#d6cf756c#;
   pragma Export (C, u00019, "system__storage_elementsS");
   u00020 : constant Version_32 := 16#41837d1e#;
   pragma Export (C, u00020, "system__stack_checkingB");
   u00021 : constant Version_32 := 16#75b35480#;
   pragma Export (C, u00021, "system__stack_checkingS");
   u00022 : constant Version_32 := 16#393398c1#;
   pragma Export (C, u00022, "system__exception_tableB");
   u00023 : constant Version_32 := 16#5515597d#;
   pragma Export (C, u00023, "system__exception_tableS");
   u00024 : constant Version_32 := 16#ce4af020#;
   pragma Export (C, u00024, "system__exceptionsB");
   u00025 : constant Version_32 := 16#936f529e#;
   pragma Export (C, u00025, "system__exceptionsS");
   u00026 : constant Version_32 := 16#37d758f1#;
   pragma Export (C, u00026, "system__exceptions__machineS");
   u00027 : constant Version_32 := 16#b895431d#;
   pragma Export (C, u00027, "system__exceptions_debugB");
   u00028 : constant Version_32 := 16#48ee26d6#;
   pragma Export (C, u00028, "system__exceptions_debugS");
   u00029 : constant Version_32 := 16#570325c8#;
   pragma Export (C, u00029, "system__img_intB");
   u00030 : constant Version_32 := 16#f9d7dfaa#;
   pragma Export (C, u00030, "system__img_intS");
   u00031 : constant Version_32 := 16#b98c3e16#;
   pragma Export (C, u00031, "system__tracebackB");
   u00032 : constant Version_32 := 16#6531e6b3#;
   pragma Export (C, u00032, "system__tracebackS");
   u00033 : constant Version_32 := 16#9ed49525#;
   pragma Export (C, u00033, "system__traceback_entriesB");
   u00034 : constant Version_32 := 16#fb57c918#;
   pragma Export (C, u00034, "system__traceback_entriesS");
   u00035 : constant Version_32 := 16#8c33a517#;
   pragma Export (C, u00035, "system__wch_conB");
   u00036 : constant Version_32 := 16#e0711dba#;
   pragma Export (C, u00036, "system__wch_conS");
   u00037 : constant Version_32 := 16#9721e840#;
   pragma Export (C, u00037, "system__wch_stwB");
   u00038 : constant Version_32 := 16#cd6031bb#;
   pragma Export (C, u00038, "system__wch_stwS");
   u00039 : constant Version_32 := 16#92b797cb#;
   pragma Export (C, u00039, "system__wch_cnvB");
   u00040 : constant Version_32 := 16#efc6a749#;
   pragma Export (C, u00040, "system__wch_cnvS");
   u00041 : constant Version_32 := 16#6033a23f#;
   pragma Export (C, u00041, "interfacesS");
   u00042 : constant Version_32 := 16#ece6fdb6#;
   pragma Export (C, u00042, "system__wch_jisB");
   u00043 : constant Version_32 := 16#6fb6be68#;
   pragma Export (C, u00043, "system__wch_jisS");
   u00044 : constant Version_32 := 16#10558b11#;
   pragma Export (C, u00044, "ada__streamsB");
   u00045 : constant Version_32 := 16#2e6701ab#;
   pragma Export (C, u00045, "ada__streamsS");
   u00046 : constant Version_32 := 16#db5c917c#;
   pragma Export (C, u00046, "ada__io_exceptionsS");
   u00047 : constant Version_32 := 16#12c8cd7d#;
   pragma Export (C, u00047, "ada__tagsB");
   u00048 : constant Version_32 := 16#ce72c228#;
   pragma Export (C, u00048, "ada__tagsS");
   u00049 : constant Version_32 := 16#c3335bfd#;
   pragma Export (C, u00049, "system__htableB");
   u00050 : constant Version_32 := 16#7fce8c82#;
   pragma Export (C, u00050, "system__htableS");
   u00051 : constant Version_32 := 16#089f5cd0#;
   pragma Export (C, u00051, "system__string_hashB");
   u00052 : constant Version_32 := 16#dd90e7fc#;
   pragma Export (C, u00052, "system__string_hashS");
   u00053 : constant Version_32 := 16#66549ba8#;
   pragma Export (C, u00053, "system__unsigned_typesS");
   u00054 : constant Version_32 := 16#b44f9ae7#;
   pragma Export (C, u00054, "system__val_unsB");
   u00055 : constant Version_32 := 16#76fc7693#;
   pragma Export (C, u00055, "system__val_unsS");
   u00056 : constant Version_32 := 16#27b600b2#;
   pragma Export (C, u00056, "system__val_utilB");
   u00057 : constant Version_32 := 16#57ac8996#;
   pragma Export (C, u00057, "system__val_utilS");
   u00058 : constant Version_32 := 16#d1060688#;
   pragma Export (C, u00058, "system__case_utilB");
   u00059 : constant Version_32 := 16#df0556bf#;
   pragma Export (C, u00059, "system__case_utilS");
   u00060 : constant Version_32 := 16#84a27f0d#;
   pragma Export (C, u00060, "interfaces__c_streamsB");
   u00061 : constant Version_32 := 16#8bb5f2c0#;
   pragma Export (C, u00061, "interfaces__c_streamsS");
   u00062 : constant Version_32 := 16#8b9de966#;
   pragma Export (C, u00062, "system__crtlS");
   u00063 : constant Version_32 := 16#431faf3c#;
   pragma Export (C, u00063, "system__file_ioB");
   u00064 : constant Version_32 := 16#5c7dde0d#;
   pragma Export (C, u00064, "system__file_ioS");
   u00065 : constant Version_32 := 16#b7ab275c#;
   pragma Export (C, u00065, "ada__finalizationB");
   u00066 : constant Version_32 := 16#19f764ca#;
   pragma Export (C, u00066, "ada__finalizationS");
   u00067 : constant Version_32 := 16#95817ed8#;
   pragma Export (C, u00067, "system__finalization_rootB");
   u00068 : constant Version_32 := 16#b4fe4cf8#;
   pragma Export (C, u00068, "system__finalization_rootS");
   u00069 : constant Version_32 := 16#769e25e6#;
   pragma Export (C, u00069, "interfaces__cB");
   u00070 : constant Version_32 := 16#4a38bedb#;
   pragma Export (C, u00070, "interfaces__cS");
   u00071 : constant Version_32 := 16#e1cd958f#;
   pragma Export (C, u00071, "system__os_libB");
   u00072 : constant Version_32 := 16#d7b69782#;
   pragma Export (C, u00072, "system__os_libS");
   u00073 : constant Version_32 := 16#1a817b8e#;
   pragma Export (C, u00073, "system__stringsB");
   u00074 : constant Version_32 := 16#85b32e0e#;
   pragma Export (C, u00074, "system__stringsS");
   u00075 : constant Version_32 := 16#0693a5c0#;
   pragma Export (C, u00075, "system__file_control_blockS");
   u00076 : constant Version_32 := 16#b580e371#;
   pragma Export (C, u00076, "crtp_packS");
   u00077 : constant Version_32 := 16#4fee957e#;
   pragma Export (C, u00077, "typesS");
   u00078 : constant Version_32 := 16#d004d958#;
   pragma Export (C, u00078, "imu_packB");
   u00079 : constant Version_32 := 16#4ce914b0#;
   pragma Export (C, u00079, "imu_packS");
   u00080 : constant Version_32 := 16#84ad4a42#;
   pragma Export (C, u00080, "ada__numericsS");
   u00081 : constant Version_32 := 16#1c1388b9#;
   pragma Export (C, u00081, "interfaces__c__extensionsS");
   u00082 : constant Version_32 := 16#b238711b#;
   pragma Export (C, u00082, "generic_queue_packB");
   u00083 : constant Version_32 := 16#3a3963bb#;
   pragma Export (C, u00083, "generic_queue_packS");
   u00084 : constant Version_32 := 16#fd83e873#;
   pragma Export (C, u00084, "system__concat_2B");
   u00085 : constant Version_32 := 16#f9ace8b8#;
   pragma Export (C, u00085, "system__concat_2S");
   u00086 : constant Version_32 := 16#9d39c675#;
   pragma Export (C, u00086, "system__memoryB");
   u00087 : constant Version_32 := 16#a271595c#;
   pragma Export (C, u00087, "system__memoryS");
   --  BEGIN ELABORATION ORDER
   --  ada%s
   --  interfaces%s
   --  system%s
   --  system.case_util%s
   --  system.case_util%b
   --  system.htable%s
   --  system.img_int%s
   --  system.img_int%b
   --  system.parameters%s
   --  system.parameters%b
   --  system.crtl%s
   --  interfaces.c_streams%s
   --  interfaces.c_streams%b
   --  system.standard_library%s
   --  system.exceptions_debug%s
   --  system.exceptions_debug%b
   --  system.storage_elements%s
   --  system.storage_elements%b
   --  system.stack_checking%s
   --  system.stack_checking%b
   --  system.string_hash%s
   --  system.string_hash%b
   --  system.htable%b
   --  system.strings%s
   --  system.strings%b
   --  system.os_lib%s
   --  system.traceback_entries%s
   --  system.traceback_entries%b
   --  ada.exceptions%s
   --  system.soft_links%s
   --  system.unsigned_types%s
   --  system.val_uns%s
   --  system.val_util%s
   --  system.val_util%b
   --  system.val_uns%b
   --  system.wch_con%s
   --  system.wch_con%b
   --  system.wch_cnv%s
   --  system.wch_jis%s
   --  system.wch_jis%b
   --  system.wch_cnv%b
   --  system.wch_stw%s
   --  system.wch_stw%b
   --  ada.exceptions.last_chance_handler%s
   --  ada.exceptions.last_chance_handler%b
   --  system.concat_2%s
   --  system.concat_2%b
   --  system.exception_table%s
   --  system.exception_table%b
   --  ada.io_exceptions%s
   --  ada.numerics%s
   --  ada.tags%s
   --  ada.streams%s
   --  ada.streams%b
   --  interfaces.c%s
   --  interfaces.c.extensions%s
   --  system.exceptions%s
   --  system.exceptions%b
   --  system.exceptions.machine%s
   --  system.file_control_block%s
   --  system.file_io%s
   --  system.finalization_root%s
   --  system.finalization_root%b
   --  ada.finalization%s
   --  ada.finalization%b
   --  system.memory%s
   --  system.memory%b
   --  system.standard_library%b
   --  system.secondary_stack%s
   --  system.file_io%b
   --  interfaces.c%b
   --  ada.tags%b
   --  system.soft_links%b
   --  system.os_lib%b
   --  system.secondary_stack%b
   --  system.traceback%s
   --  ada.exceptions%b
   --  system.traceback%b
   --  ada.text_io%s
   --  ada.text_io%b
   --  generic_queue_pack%s
   --  generic_queue_pack%b
   --  imu_pack%s
   --  imu_pack%b
   --  types%s
   --  crtp_pack%s
   --  main%b
   --  END ELABORATION ORDER


end ada_main;
