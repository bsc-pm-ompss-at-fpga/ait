namespace eval thermalMonitor {
    # Add CMS subsystem
    variable sysMgmtIP [create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz system_management]

    # Add an additional 100MHz clock for the System Management IP
    set sysMgmtClkPin [AIT::clocks::create_clock 100 "thermal_monitor"]

    # Add a reset for the 100MHz clock
    set sysMgmtRstPin [AIT::resets::create_reset ${sysMgmtClkPin}]

    # Connect System Management IP to the M_AXI interconnect
    AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${sysMgmtIP}/S_AXI_LITE] "" ${sysMgmtClkPin} ${sysMgmtRstPin}

    # Add address segments to the project variable
    lappend AIT::project::bdAddrSegmentsList [dict create \
        name thermalMonitor \
        bdSegName ${sysMgmtIP}/S_AXI_LITE/Reg \
        size {4096} \
        addr [format 0x%016x 0x0]
    ]

    save_bd_design
}
