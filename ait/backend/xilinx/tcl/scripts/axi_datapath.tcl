#------------------------------------------------------------------------#
#    (C) Copyright 2017-2023 Barcelona Supercomputing Center             #
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
        proc add_reg_slice {intf_pin intf_name accName instanceNum} {
            if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                # No placement info is provided for this instance
                AIT::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI pins will not be created"
            } else {
                set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]

                if {$slr != ${::AIT::board_slr_master}} {
                    # If the acc is in a different SLR
                    #   * Create register slices for data pins
                    # Register slices are named axi_regSlice_slr_acc_${pin_index}_${slr_orig}_${slr_dest}
                    #   note that the slave side is close to the acc master axi pin
                    # Task-creating accelerators will not have register slices as they do not use data pins
                    set axiRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice ${accName}_${instanceNum}/${intf_name}_regslice_slr_acc_${slr}_${::AIT::board_slr_master}]
                    set_property -dict [ list \
                        CONFIG.REG_AR {15} \
                        CONFIG.REG_AW {15} \
                        CONFIG.REG_B {15} \
                        CONFIG.REG_R {15} \
                        CONFIG.REG_W {15} \
                        CONFIG.USE_AUTOPIPELINING {1} \
                     ] $axiRegSlice
                    # Connect acc - slice
                    connect_bd_intf_net [get_bd_intf_pins $axiRegSlice/S_AXI] $intf_pin
                    connect_bd_net [get_bd_pins $axiRegSlice/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                    connect_bd_net [get_bd_pins $axiRegSlice/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

                    # Return new outermost AXI pin
                    set intf_pin [get_bd_intf_pins $axiRegSlice/M_AXI]
                }
            }
            return $intf_pin
        }

        proc add_addrInterleaver {intf_pin intf_name accName instanceNum} {
            set rw_mode [get_property CONFIG.READ_WRITE_MODE $intf_pin]
            if {($rw_mode eq "READ_WRITE") || ($rw_mode eq "READ_ONLY")} {
                set araddrInterleaver [create_bd_cell -type module -reference bsc_ompss_addrInterleaver ${accName}_${instanceNum}/${intf_name}_araddrInterleaver]
                create_bd_pin -dir O -from 63 -to 0 ${accName}_${instanceNum}/${intf_name}_araddr_intlv
                connect_bd_net [get_bd_pins ${intf_pin}_araddr] [get_bd_pins $araddrInterleaver/in_addr]
                connect_bd_net [get_bd_pins ${accName}_${instanceNum}/${intf_name}_araddr_intlv] [get_bd_pins $araddrInterleaver/out_addr]
            }
            if {($rw_mode eq "READ_WRITE") || ($rw_mode eq "WRITE_ONLY")} {
                set awaddrInterleaver [create_bd_cell -type module -reference bsc_ompss_addrInterleaver ${accName}_${instanceNum}/${intf_name}_awaddrInterleaver]
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
                AIT::warning_msg "Maximum number of debug probes reached ([llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16). Interface $intf_pin will not be connected to an ILA"
            } else {

                apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects $intf_pin]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

                set_property -dict [list \
                    CONFIG.C_EN_STRG_QUAL {1} \
                    CONFIG.C_PROBE0_MU_CNT {2} \
                    CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
                 ] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]

                # Add a line to debuginterfaces.txt
                puts $debugInterfaces_file "$intf_pin"
                close $debugInterfaces_file
            }
        }
    }
}
