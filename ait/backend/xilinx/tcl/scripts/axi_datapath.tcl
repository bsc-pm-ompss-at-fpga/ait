namespace eval AIT {
    namespace eval AXI {
        proc add_reg_slice {AXI_port port_name accName instanceNum} {
            if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                # No placement info is provided for this instance
                AIT::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI ports will not be created"
            } else {
                set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]

                if {$slr != ${::AIT::board_slr_master}} {
                    # If the acc is in a different SLR
                    #   * Create register slices for data ports
                    # Register slices are named axi_regSlice_slr_acc_${port_index}_${slr_orig}_${slr_dest}
                    #   note that the slave side is close to the acc master axi port
                    # Task-creating accelerators will not have register slices as they do not use data ports
                    set axiRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice ${accName}_${instanceNum}/${port_name}_regslice_slr_acc_${slr}_${::AIT::board_slr_master}]
                    set_property -dict [ list \
                        CONFIG.REG_AR {15} \
                        CONFIG.REG_AW {15} \
                        CONFIG.REG_B {15} \
                        CONFIG.REG_R {15} \
                        CONFIG.REG_W {15} \
                        CONFIG.USE_AUTOPIPELINING {1} \
                        ] $axiRegSlice
                    # Connect acc - slice
                    connect_bd_intf_net [get_bd_intf_pins $axiRegSlice/S_AXI] $AXI_port 
                    connect_bd_net [get_bd_pins $axiRegSlice/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                    connect_bd_net [get_bd_pins $axiRegSlice/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

                    # Return new outermost AXI port
                    set AXI_port $axiRegSlice/M_AXI
                }
            }
            return $AXI_port
        }

        proc add_addrInterleaver {AXI_port port_name accName instanceNum} {
            set addrInterleaver [create_bd_cell -type module -reference addrInterleaver ${accName}_${instanceNum}/${port_name}_addrInterleaver]
            create_bd_pin -dir O -from 63 -to 0 ${accName}_${instanceNum}/${port_name}_awaddr
            create_bd_pin -dir O -from 63 -to 0 ${accName}_${instanceNum}/${port_name}_araddr
            connect_bd_net [get_bd_pins ${AXI_port}_awaddr] [get_bd_pins $addrInterleaver/in_awaddr]
            connect_bd_net [get_bd_pins ${AXI_port}_araddr] [get_bd_pins $addrInterleaver/in_araddr]
            connect_bd_net [get_bd_pins ${accName}_${instanceNum}/${port_name}_awaddr] [get_bd_pins $addrInterleaver/out_awaddr]
            connect_bd_net [get_bd_pins ${accName}_${instanceNum}/${port_name}_araddr] [get_bd_pins $addrInterleaver/out_araddr]
        }

        # Mark AXI interface for debug
        proc mark_debug {AXI_port} {
            # Open debuginterfaces.txt file
            set debugInterfaces_file [open ../${::AIT::name_Project}.debuginterfaces.txt "a"]

            set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects $AXI_port]]
            apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects $AXI_port]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

            set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]

            # Add a line to debuginterfaces.txt
            puts $debugInterfaces_file "$AXI_port"
            close $debugInterfaces_file
        }
    }
}
