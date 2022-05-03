set project_directory [get_property DIRECTORY [current_project]]
set project [get_property NAME [current_project]]
set ram_module pkt_fifo_maxi_vu9m1_r_crdb_vu9_cdc_bram
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name $ram_module
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Write_Width_A {149} CONFIG.Write_Depth_A {32} CONFIG.Read_Width_A {149} CONFIG.Write_Width_B {149} CONFIG.Read_Width_B {149} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_REGCEB_Pin {false} CONFIG.Disable_Collision_Warnings {true}] [get_ips $ram_module]
generate_target {instantiation_template} [get_files /$project_directory/$project.srcs/sources_1/ip/$ram_module/$ram_module.xci]
