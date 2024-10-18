#------------------------------------------------------------------------#
#    (C) Copyright 2017-2024 Barcelona Supercomputing Center             #
#                            Centro Nacional de Supercomputacion         #
#                                                                        #
#    This file is part of OmpSs@FPGA toolchain.                          #
#                                                                        #
#    This code is free software; you can redistribute it and/or modify   #
#    it under the terms of the GNU Lesser General Public License as      #
#    published by the Free Software Foundation; either version 3 of      #
#    the License, or (at your option) any later version.                 #
#                                                                        #
#    OmpSs@FPGA toolchain is distributed in the hope that it will be     #
#    useful, but WITHOUT ANY WARRANTY; without even the implied          #
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    #
#    See the GNU Lesser General Public License for more details.         #
#                                                                        #
#    You should have received a copy of the GNU Lesser General Public    #
#    License along with this code. If not, see <www.gnu.org/licenses/>.  #
#------------------------------------------------------------------------#

namespace eval AIT {
    namespace eval AXI {

        # Adds a register slice to the intf_name interface of the ip_name IP
        # If optional argument intf_pin is passed, the register slice will be
        # connected to intf_pin (either slave or master) and left
        # hanging from the other side
        proc add_reg_slice {ip_name intf_name slr_master slr_slave {intf_pin ""} {num_pipeline_stages ""} {prefix ""}} {
            # If the master and slave SLRs are different, create register slice for interface pins
            # Register slices are named ${prefix}${intf_name}_regslice_slr_${slr_master}_${slr_slave}
            if {$slr_master != $slr_slave} {
                set ip_cell [get_bd_cells -hierarchical $ip_name]
                set num_slr_crossings [expr {abs($slr_master - $slr_slave)}]

                lassign [split $num_pipeline_stages ':'] num_master_stages num_middle_stages num_slave_stages
                lassign [split ${::AIT::regslice_pipeline_stages} ':'] num_default_master_stages num_default_middle_stages num_default_slave_stages
                if {$num_master_stages == ""} { set num_master_stages $num_default_master_stages }
                if {$num_middle_stages == ""} { set num_middle_stages $num_default_middle_stages }
                if {$num_slave_stages == ""} { set num_slave_stages $num_default_slave_stages }

                set axiRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice ${ip_cell}/${prefix}${intf_name}_regslice_slr_${slr_master}_${slr_slave}]
                set_property -dict [ list \
                    CONFIG.NUM_SLR_CROSSINGS ${num_slr_crossings} \
                    CONFIG.REG_AR {15} \
                    CONFIG.REG_AW {15} \
                    CONFIG.REG_B {15} \
                    CONFIG.REG_R {15} \
                    CONFIG.REG_W {15} \
                 ] $axiRegSlice

                if {$num_master_stages == "auto"} {
                    set_property CONFIG.USE_AUTOPIPELINING {1} $axiRegSlice
                } else {
                    # Decrement number of stages by one as the IP already assumes it
                    incr num_master_stages -1
                    incr num_middle_stages -1
                    incr num_slave_stages -1

                    # Master SLR
                    set_property -dict [ list \
                        CONFIG.PIPELINES_MASTER_AR ${num_master_stages} \
                        CONFIG.PIPELINES_MASTER_AW ${num_master_stages} \
                        CONFIG.PIPELINES_MASTER_B ${num_master_stages} \
                        CONFIG.PIPELINES_MASTER_R ${num_master_stages} \
                        CONFIG.PIPELINES_MASTER_W ${num_master_stages} \
                        CONFIG.USE_AUTOPIPELINING {0} \
                     ] $axiRegSlice

                    # Middle SLR
                    if {$num_slr_crossings > 1} {
                        set_property -dict [ list \
                            CONFIG.PIPELINES_MIDDLE_AR ${num_middle_stages} \
                            CONFIG.PIPELINES_MIDDLE_AW ${num_middle_stages} \
                            CONFIG.PIPELINES_MIDDLE_B ${num_middle_stages} \
                            CONFIG.PIPELINES_MIDDLE_R ${num_middle_stages} \
                            CONFIG.PIPELINES_MIDDLE_W ${num_middle_stages} \
                         ] $axiRegSlice
                    }

                    # Slave SLR
                    if {$num_slr_crossings > 0} {
                        set_property -dict [ list \
                            CONFIG.PIPELINES_SLAVE_AR ${num_slave_stages} \
                            CONFIG.PIPELINES_SLAVE_AW ${num_slave_stages} \
                            CONFIG.PIPELINES_SLAVE_B ${num_slave_stages} \
                            CONFIG.PIPELINES_SLAVE_R ${num_slave_stages} \
                            CONFIG.PIPELINES_SLAVE_W ${num_slave_stages} \
                         ] $axiRegSlice
                    }
                }

                # If no intf_pin passed, we assume that we are adding a register slice on an already-connected
                # interface, so we must first delete the net and get both ends of the connection
                if {$intf_pin eq ""} {
                    set intf_pin [get_bd_intf_pins ${ip_cell}/${intf_name}]
                    lassign [get_bd_intf_pins -of_objects [get_bd_intf_nets -boundary_type lower -of_objects $intf_pin]] master_intf slave_intf
                    delete_bd_objs [get_bd_intf_nets -boundary_type lower -of_objects $intf_pin]

                    if {[get_property MODE $intf_pin] == "Master"} {
                        connect_bd_intf_net [get_bd_intf_pins $axiRegSlice/M_AXI] $slave_intf
                        set intf_pin $master_intf
                    } elseif {[get_property MODE $intf_pin] == "Slave"} {
                        connect_bd_intf_net $master_intf [get_bd_intf_pins $axiRegSlice/S_AXI]
                        set intf_pin $slave_intf
                    }
                }

                # Connect interface pin accordingly and look for its clock and reset
                if {[get_property MODE $intf_pin] == "Master"} {
                    connect_bd_intf_net $intf_pin [get_bd_intf_pins $axiRegSlice/S_AXI]
                    set new_intf_pin [get_bd_intf_pins $axiRegSlice/M_AXI]

                    # Set READ_WRITE_MODE according to the master interface
                    # Vivado propagates this, but we need this early in case we're using interleavers
                    set_property CONFIG.READ_WRITE_MODE [get_property CONFIG.READ_WRITE_MODE $intf_pin] $axiRegSlice
                } elseif {[get_property MODE $intf_pin] == "Slave"} {
                    connect_bd_intf_net [get_bd_intf_pins $axiRegSlice/M_AXI] $intf_pin
                    set new_intf_pin [get_bd_intf_pins $axiRegSlice/S_AXI]
                }

                set clk_pin [AIT::board::get_clk_pin_from_intf_pin $intf_pin]
                set rst_net [AIT::board::get_rst_net_from_clk_pin $clk_pin]
                AIT::board::connect_clock [get_bd_pins $axiRegSlice/aclk] $clk_pin
                AIT::board::connect_reset [get_bd_pins $axiRegSlice/aresetn] $rst_net

                # Return new outermost AXI pin
                set intf_pin $new_intf_pin
            }
            return $intf_pin
        }

        proc add_addrInterleaver {intf_pin intf_name accName instanceNum} {
            set rw_mode [get_property CONFIG.READ_WRITE_MODE $intf_pin]
            if {($rw_mode eq "READ_WRITE") || ($rw_mode eq "READ_ONLY")} {
                set araddrInterleaver [create_bd_cell -type module -reference bsc_axiu_addrInterleaver ${accName}_${instanceNum}/${intf_name}_araddrInterleaver]
                create_bd_pin -dir O -from 63 -to 0 ${accName}_${instanceNum}/${intf_name}_araddr_intlv
                connect_bd_net [get_bd_pins ${intf_pin}_araddr] [get_bd_pins $araddrInterleaver/in_addr]
                connect_bd_net [get_bd_pins ${accName}_${instanceNum}/${intf_name}_araddr_intlv] [get_bd_pins $araddrInterleaver/out_addr]
            }
            if {($rw_mode eq "READ_WRITE") || ($rw_mode eq "WRITE_ONLY")} {
                set awaddrInterleaver [create_bd_cell -type module -reference bsc_axiu_addrInterleaver ${accName}_${instanceNum}/${intf_name}_awaddrInterleaver]
                create_bd_pin -dir O -from 63 -to 0 ${accName}_${instanceNum}/${intf_name}_awaddr_intlv
                connect_bd_net [get_bd_pins ${intf_pin}_awaddr] [get_bd_pins $awaddrInterleaver/in_addr]
                connect_bd_net [get_bd_pins ${accName}_${instanceNum}/${intf_name}_awaddr_intlv] [get_bd_pins $awaddrInterleaver/out_addr]
            }
        }

        # Mark AXI interface for debug
        proc mark_debug {intf_pin} {
            # Open debuginterfaces.txt file
            set debugInterfaces_file [open ../${::AIT::name_Project}.debuginterfaces.txt "a"]
            set intf_pin_net [get_bd_intf_nets -of_objects $intf_pin]

            set_property HDL_ATTRIBUTE.DEBUG {true} $intf_pin_net

            #FIXME: Vivado fails to create a new ILA when surpassing max of 16 probes
            if {[llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16} {
                AIT::utils::warning_msg "Maximum number of debug probes reached ([llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16). Interface $intf_pin will not be connected to an ILA"
            } else {

                apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects $intf_pin]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_app SYSTEM_ILA "Auto" APC_EN "0" }]

                # Add a line to debuginterfaces.txt
                puts $debugInterfaces_file "$intf_pin"
                close $debugInterfaces_file
            }
        }
    }
}
