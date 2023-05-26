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
    namespace eval AXIS {
        proc add_reg_slice {intf_pin accName instanceNum} {
            if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                # No placement info is provided for this instance
                AIT::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI-Stream pins will not be created"
            } else {
                set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]

                if {$slr != ${::AIT::board_slr_master}} {
                    # If the acc is in a different SLR
                    #   * Create register slices for stream pins
                    # Register slices are named axis_regSlice{in,out}_${orig_slr}_${dest_slr}
                    if {[get_property MODE $intf_pin] eq "Master"} {
                        # outStream slice
                        set axis_regSlice_out [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${accName}_${instanceNum}/axis_regSlice_out_${slr}_${::AIT::board_slr_master}]
                        set_property CONFIG.REG_CONFIG {16} $axis_regSlice_out
                        connect_bd_intf_net $intf_pin [get_bd_intf_pins $axis_regSlice_out/S_AXIS]
                        connect_bd_net [get_bd_pins $axis_regSlice_out/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                        connect_bd_net [get_bd_pins $axis_regSlice_out/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

                        # Return new outermost AXIS pin
                        set intf_pin [get_bd_intf_pins $axis_regSlice_out/M_AXIS]
                    } elseif {[get_property MODE $intf_pin] eq "Slave"} {
                        # inStream slice
                        set axis_regSlice_in [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${accName}_${instanceNum}/axis_regSlice_in_${::AIT::board_slr_master}_${slr}]
                        set_property CONFIG.REG_CONFIG {16} $axis_regSlice_in
                        connect_bd_intf_net [get_bd_intf_pins $axis_regSlice_in/M_AXIS] $intf_pin
                        connect_bd_net [get_bd_pins $axis_regSlice_in/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                        connect_bd_net [get_bd_pins $axis_regSlice_in/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

                        # Return new outermost AXIS pin
                        set intf_pin [get_bd_intf_pins $axis_regSlice_in/S_AXIS]
                    }
                }
            }
            return $intf_pin
        }

        # Mark AXI-Stream interface for debug
        proc mark_debug {intf_pin} {
            # Open debuginterfaces.txt file
            set debugInterfaces_file [open ../${::AIT::name_Project}.debuginterfaces.txt "a"]
            set intf_pin_net [get_bd_intf_nets -of_objects $intf_pin]

            set_property HDL_ATTRIBUTE.DEBUG {true} $intf_pin_net

            #FIXME: Vivado fails to create a new ILA when surpassing max of 16 probes
            if {[llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16} {
                AIT::warning_msg "Maximum number of debug probes reached ([llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16). Interface $intf_pin will not be connected to an ILA"
            } else {
                apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects $intf_pin]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

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

        proc add_stream_adapter {intf_pin accName instanceNum {accID '0x0'}} {
            set intf_name [string trimright [string replace [string range $intf_pin [expr [string last / $intf_pin] + 1] end] 0 [expr [string length "mcxx_"] - 1]] "_V"]
            set dir [get_property DIR $intf_pin]
            if {$dir eq "O"} {
                set stream_adapter [create_bd_cell -type module -reference bsc_ompss_hsToStreamAdapter ${accName}_${instanceNum}/Adapter_${intf_name}]
                set_property -dict [list \
                    CONFIG.TID_WIDTH [expr max(int(ceil(log(${::AIT::num_accs})/log(2))), 1)] \
                    CONFIG.ACCID $accID \
                 ] $stream_adapter
                connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_vld] [get_bd_pins -regexp ${intf_pin}_ap_vld]
                connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_ack] [get_bd_pins -regexp ${intf_pin}_ap_ack]
                connect_bd_net [get_bd_pins $stream_adapter/in_hs] ${intf_pin}
                connect_bd_net [get_bd_pins $stream_adapter/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                connect_bd_net [get_bd_pins $stream_adapter/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]
                return [get_bd_intf_pins $stream_adapter/outStream]
            } elseif {$dir eq "I"} {
                set stream_adapter [create_bd_cell -type module -reference bsc_ompss_streamToHsAdapter ${accName}_${instanceNum}/Adapter_${intf_name}]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_vld] [get_bd_pins -regexp ${intf_pin}_ap_vld]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_ack] [get_bd_pins -regexp ${intf_pin}_ap_ack]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs] ${intf_pin}
                connect_bd_net [get_bd_pins $stream_adapter/aclk] [get_bd_pins ${accName}_${instanceNum}/aclk]
                connect_bd_net [get_bd_pins $stream_adapter/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]
                return [get_bd_intf_pins $stream_adapter/inStream]
            }
        }

        proc add_newtask_spawner {acc_spawnInStream hier_inStream hier_outStream accName instanceNum} {
            set newtask_spawner [create_bd_cell -type ip -vlnv bsc:ompss:new_task_spawner_wrapper:1.0 ${accName}_${instanceNum}/new_task_spawner]
            connect_bd_net [get_bd_pins $newtask_spawner/clk] [get_bd_pins ${accName}_${instanceNum}/aclk]
            connect_bd_net [get_bd_pins $newtask_spawner/rstn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/stream_in] $hier_outStream
            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/ack_out] $acc_spawnInStream

            set tid_demux [create_bd_cell -type module -reference bsc_ompss_axis_tid_demux ${accName}_${instanceNum}/axis_tid_demux]
            connect_bd_net [get_bd_pins $tid_demux/clk] [get_bd_pins ${accName}_${instanceNum}/aclk]
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m0] $hier_inStream
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m1] [get_bd_intf_pins $newtask_spawner/ack_in]

            return [list [get_bd_intf_pins $newtask_spawner/stream_out] [get_bd_intf_pins $tid_demux/s]]
        }

        proc add_tid_subset_converter {intf_pin accID accName instanceNum} {
            set accIDWidth [expr max(int(ceil(log(${::AIT::num_accs})/log(2))), 1)]

            # We need to insert accID to the new_task_spawner TID AXI-Stream signal
            set tidSubsetConv [create_bd_cell -type module -reference bsc_ompss_axis_subset_converter ${accName}_${instanceNum}/TID_subset_converter]
            connect_bd_net [get_bd_pins $tidSubsetConv/clk] [get_bd_pins ${accName}_${instanceNum}/aclk]
            connect_bd_net [get_bd_pins $tidSubsetConv/aresetn] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

            # Add accID as AXI-Stream TID signal
            set_property -dict [list \
                CONFIG.ID_WIDTH $accIDWidth \
                CONFIG.ID $accID \
             ] $tidSubsetConv

            connect_bd_intf_net $intf_pin [get_bd_intf_pins $tidSubsetConv/S_AXIS]
            return [get_bd_intf_pins $tidSubsetConv/M_AXIS]
        }
    }
}
