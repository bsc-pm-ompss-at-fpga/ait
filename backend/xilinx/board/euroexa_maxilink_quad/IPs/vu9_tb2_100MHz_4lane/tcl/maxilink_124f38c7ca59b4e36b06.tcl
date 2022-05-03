create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name $rom_module
set_property -dict [list CONFIG.Memory_Type {Single_Port_ROM} CONFIG.Write_Width_A {42} CONFIG.Write_Depth_A {183} CONFIG.Load_Init_File {true} CONFIG.Coe_File "${src_directory}/coe/maxilink_ff116d1742ffd4268e10.coe" CONFIG.Read_Width_A {42} CONFIG.Write_Width_B {42} CONFIG.Read_Width_B {42} CONFIG.Port_A_Write_Rate {0}] [get_ips $rom_module]
generate_target {instantiation_template} [get_files /$project_directory/$project.srcs/sources_1/ip/$rom_module/$rom_module.xci]
