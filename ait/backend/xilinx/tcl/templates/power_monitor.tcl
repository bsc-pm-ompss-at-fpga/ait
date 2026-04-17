namespace eval powerMonitor {
    # Add CMS subsystem
    variable cmsIP [create_bd_cell -type ip -vlnv xilinx.com:ip:cms_subsystem cms_subsystem]

    # Add an additional 50MHz clock for the CMS subsystem
    set cmsClkPin [AIT::clocks::create_clock 50 "power_monitor"]

    # Add a reset for the 50MHz clock
    set cmsRstPin [AIT::resets::create_reset ${cmsClkPin}]

    # Add and connect external ports
    set satelliteUartIntfPort [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 satellite_uart]
    set satelliteGpioPort [create_bd_port -dir I -from 3 -to 0 -type intr satellite_gpio]
    set_property CONFIG.SENSITIVITY {EDGE_RISING} ${satelliteGpioPort}
    connect_bd_intf_net ${satelliteUartIntfPort} [get_bd_intf_pins ${cmsIP}/satellite_uart]
    connect_bd_net ${satelliteGpioPort} [get_bd_pins ${cmsIP}/satellite_gpio]

    if {[dict get ${AIT::project::board} "memory" "type"] eq "hbm"} {
        connect_bd_net [get_bd_pins bridge_to_host/memory/HBM/DRAM_1_STAT_TEMP] [get_bd_pins ${cmsIP}/hbm_temp_2]
        connect_bd_net [get_bd_pins bridge_to_host/memory/HBM/DRAM_0_STAT_TEMP] [get_bd_pins ${cmsIP}/hbm_temp_1]
        connect_bd_net [get_bd_pins bridge_to_host/HBM_CATTRIP] [get_bd_pins ${cmsIP}/interrupt_hbm_cattrip]
    }

    # Connect CMS to the M_AXI interconnect
    AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${cmsIP}/s_axi_ctrl] "" ${cmsClkPin} ${cmsRstPin}

    # Add address segments to the project variable
    lappend AIT::project::bdAddrSegmentsList [dict create \
        name powerMonitor \
        bdSegName ${cmsIP}/s_axi_ctrl/Mem* \
        size [expr {256*1024}] \
        addr [format 0x%016x 0x0]
    ]
}
