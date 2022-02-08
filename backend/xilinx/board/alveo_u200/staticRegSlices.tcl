proc createDdrRegSlice {ddrName ddrPort board_slr_master migSlr} {
	set ddrRegSlice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 \
		bridge_to_host/DDR/${ddrName}_${ddrPort}_slr_static_${board_slr_master}_${migSlr} ]
	set_property -dict [ list \
		CONFIG.NUM_SLR_CROSSINGS {0} \
		CONFIG.REG_AR {15} \
		CONFIG.REG_AW {15} \
		CONFIG.REG_B {15} \
		CONFIG.REG_R {15} \
		CONFIG.REG_W {15} \
		CONFIG.USE_AUTOPIPELINING {1} \
		] $ddrRegSlice
    # Delete interface nets
    delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/C0_DDR4_${ddrPort}]]
    connect_bd_intf_net [get_bd_intf_pins $ddrRegSlice/M_AXI] [get_bd_intf_pins bridge_to_host/DDR/${ddrName}/C0_DDR4_${ddrPort}]
    connect_bd_intf_net [get_bd_intf_pins $ddrRegSlice/S_AXI] [get_bd_intf_pins bridge_to_host/DDR/${ddrName}_${ddrPort}]

    connect_bd_net [get_bd_pins $ddrRegSlice/aclk] [get_bd_pins bridge_to_host/DDR/${ddrName}/c0_ddr4_ui_clk]
    connect_bd_net [get_bd_pins $ddrRegSlice/aresetn] [get_bd_pins /bridge_to_host/DDR/${ddrName}_procSysRst/peripheral_aresetn]
}

proc staticLogicRegisters {} {
    upvar #0 board_slr_master board_slr_master

    #DDR 0
    createDdrRegSlice DDR_0 S_AXI $board_slr_master 0
    createDdrRegSlice DDR_0 S_AXI_CTRL $board_slr_master 0
    #DDR 3
    createDdrRegSlice DDR_3 S_AXI $board_slr_master 2
    createDdrRegSlice DDR_3 S_AXI_CTRL $board_slr_master 2

}
