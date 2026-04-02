
set instanceName [lindex ${argv} 0]
set srcBitWidth [lindex ${argv} 1]
set srcClkName [lindex ${argv} 2]
set dstBitWidth [lindex ${argv} 3]
set dstClkName [lindex ${argv} 4]
set rwMode [lindex ${argv} 5]

# Create a custom AXI interconnect to perform width resizing and clock conversion
# because Xilinx interconnects don't give good timing results
namespace eval ${instanceName} {
    proc create_custom_interconnect {srcBitWidth srcClkName dstBitWidth dstClkName {rwMode "read_write"}} {
        set instanceName [namespace tail [namespace current]]
        set oldBdInstance [current_bd_instance .]

        # Create cell and set as current instance
        variable hier [create_bd_cell -type hier ${instanceName}]
        current_bd_instance ${hier}

        variable srcClkPin [get_bd_pins ${srcClkName}]
        variable dstClkPin [get_bd_pins ${dstClkName}]

        variable srcRstPin [AIT::resets::create_reset ${srcClkPin}]
        variable dstRstPin [AIT::resets::create_reset ${dstClkPin}]

        variable slaveIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI]
        variable masterIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI]

        variable slaveRegsliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice slave_regslice]
        variable clkConverterIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter clk_converter]
        variable middleRegsliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice middle_regslice]
        variable downsizerIP [create_bd_cell -type ip -vlnv bsc:axiu:axiu_dwidth_downsizer_vwrapper downsizer]
        variable masterRegsliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice master_regslice]
        variable protocolConverterIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter protocol_converter]

        set_property -dict [list \
            CONFIG.AXI_ADDR_WIDTH [AIT::board::get_addr_width] \
            CONFIG.AXI_SLV_DATA_WIDTH ${srcBitWidth} \
            CONFIG.AXI_MST_DATA_WIDTH ${dstBitWidth} \
        ] ${downsizerIP}

        if {${rwMode} eq "read_only"} {
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {READ_ONLY} \
            ] ${clkConverterIP}
            set_property -dict [list \
                CONFIG.READ {1} \
                CONFIG.WRITE {0} \
            ] ${downsizerIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {READ_ONLY} \
                CONFIG.REG_AR {1} \
            ] ${slaveRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {READ_ONLY} \
                CONFIG.REG_AR {1} \
            ] ${middleRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {READ_ONLY} \
                CONFIG.REG_AR {1} \
            ] ${masterRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {READ_ONLY} \
            ] ${protocolConverterIP}
        } elseif {${rwMode} eq "write_only"} {
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
            ] ${clkConverterIP}
            set_property -dict [list \
                CONFIG.READ {0} \
                CONFIG.WRITE {1} \
            ] ${downsizerIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${slaveRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${middleRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${masterRegsliceIP}
            set_property -dict [list \
                CONFIG.READ_WRITE_MODE.VALUE_SRC {USER} \
                CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
            ] ${protocolConverterIP}
        } else {
            set_property -dict [list \
                CONFIG.READ {1} \
                CONFIG.WRITE {1} \
            ] ${downsizerIP}
            set_property -dict [list \
                CONFIG.REG_AR {1} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${slaveRegsliceIP}
            set_property -dict [list \
                CONFIG.REG_AR {1} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${middleRegsliceIP}
            set_property -dict [list \
                CONFIG.REG_AR {1} \
                CONFIG.REG_AW {1} \
                CONFIG.REG_B {1} \
            ] ${masterRegsliceIP}
        }

        connect_bd_intf_net ${slaveIntfPin} [get_bd_intf_pins ${slaveRegsliceIP}/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins ${slaveRegsliceIP}/M_AXI] [get_bd_intf_pins ${clkConverterIP}/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins ${clkConverterIP}/M_AXI] [get_bd_intf_pins ${middleRegsliceIP}/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins ${middleRegsliceIP}/M_AXI] [get_bd_intf_pins ${downsizerIP}/slv]
        connect_bd_intf_net [get_bd_intf_pins ${downsizerIP}/mst] [get_bd_intf_pins ${masterRegsliceIP}/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins ${masterRegsliceIP}/M_AXI] [get_bd_intf_pins ${protocolConverterIP}/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins ${protocolConverterIP}/M_AXI] ${masterIntfPin}

        connect_bd_net ${srcClkPin} [get_bd_pins ${slaveRegsliceIP}/aclk] [get_bd_pins ${clkConverterIP}/s_axi_aclk]
        connect_bd_net ${srcRstPin} [get_bd_pins ${slaveRegsliceIP}/aresetn] [get_bd_pins ${clkConverterIP}/s_axi_aresetn]
        connect_bd_net ${dstClkPin} [get_bd_pins ${clkConverterIP}/m_axi_aclk] [get_bd_pins ${middleRegsliceIP}/aclk] [get_bd_pins ${downsizerIP}/clk] [get_bd_pins ${masterRegsliceIP}/aclk] [get_bd_pins ${protocolConverterIP}/aclk]
        connect_bd_net ${dstRstPin} [get_bd_pins ${clkConverterIP}/m_axi_aresetn] [get_bd_pins ${middleRegsliceIP}/aresetn] [get_bd_pins ${downsizerIP}/rstn] [get_bd_pins ${masterRegsliceIP}/aresetn] [get_bd_pins ${protocolConverterIP}/aresetn]

        current_bd_instance ${oldBdInstance}
    }
}

${instanceName}::create_custom_interconnect ${srcBitWidth} ${srcClkName} ${dstBitWidth} ${dstClkName} ${rwMode}
