proc createDdrRegSlice {ddrName ddrPort masterSLR migSlr ctrl} {
	set ddrRegSlice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 \
		bridge_to_host/DDR/${ddrName}/${ddrName}_${ddrPort}_slrX_${masterSLR}_${migSlr} ]
	set_property -dict [ list \
		CONFIG.NUM_SLR_CROSSINGS {0} \
		CONFIG.REG_AR {15} \
		CONFIG.REG_AW {15} \
		CONFIG.REG_B {15} \
		CONFIG.REG_R {15} \
		CONFIG.REG_W {15} \
		CONFIG.USE_AUTOPIPELINING {1} \
		] $ddrRegSlice
    #delete interface nets
    delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/DDR4/C0_DDR4_${ddrPort}]]
    save_bd_design
    connect_bd_intf_net [get_bd_intf_pins $ddrRegSlice/M_AXI] [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/DDR4/C0_DDR4_${ddrPort}]
    save_bd_design
    if { $ctrl } {
        connect_bd_intf_net [get_bd_intf_pins $ddrRegSlice/S_AXI] [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/DDR4_S_AXI_CTRL]
    } else {
        connect_bd_intf_net [get_bd_intf_pins $ddrRegSlice/S_AXI] [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/DDR4_S_AXI_regslice/M_AXI]
    }
    save_bd_design

    connect_bd_net [get_bd_pins $ddrRegSlice/aclk] [get_bd_pins bridge_to_host/DDR/${ddrName}/DDR4/c0_ddr4_ui_clk]
    save_bd_design
    connect_bd_net [get_bd_pins $ddrRegSlice/aresetn] [get_bd_pins bridge_to_host/DDR/${ddrName}/DDR4_proc_sys_reset/peripheral_aresetn]
    save_bd_design
}

proc staticLogicRegisters {} {
	set masterSLR 1

    #DDR0
    createDdrRegSlice DDR_2 S_AXI $masterSLR 2 False
    createDdrRegSlice DDR_2 S_AXI_CTRL $masterSLR 2 True

}
