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
    namespace eval AXIS {
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

                set axisRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${ip_cell}/${prefix}${intf_name}_regslice_slr_${slr_master}_${slr_slave}]

                if {$num_master_stages == "auto"} {
                    set_property -dict [ list \
                        CONFIG.REG_CONFIG {16} \
                     ] $axisRegSlice
                } else {
                    # Decrement number of stages by one as the IP already assumes it
                    incr num_master_stages -1
                    incr num_middle_stages -1
                    incr num_slave_stages -1

                    # Master SLR
                    set_property -dict [ list \
                        CONFIG.NUM_SLR_CROSSINGS ${num_slr_crossings} \
                        CONFIG.PIPELINES_MASTER ${num_master_stages} \
                        CONFIG.REG_CONFIG {15} \
                     ] $axisRegSlice

                    # Middle SLR
                    if {$num_slr_crossings > 1} {
                        set_property -dict [ list \
                            CONFIG.PIPELINES_MIDDLE ${num_middle_stages} \
                         ] $axisRegSlice
                    }

                    # Slave SLR
                    if {$num_slr_crossings > 0} {
                        set_property -dict [ list \
                            CONFIG.PIPELINES_SLAVE ${num_slave_stages} \
                         ] $axisRegSlice
                    }
                }

                # If no intf_pin passed, we assume that we are adding a register slice on an already-connected
                # interface, so we must first delete the net and get both ends of the connection
                if {$intf_pin eq ""} {
                    set intf_pin [get_bd_intf_pins ${ip_cell}/${intf_name}]
                    lassign [get_bd_intf_pins -of_objects [get_bd_intf_nets -boundary_type lower -of_objects $intf_pin]] master_intf slave_intf
                    delete_bd_objs [get_bd_intf_nets -boundary_type lower -of_objects $intf_pin]

                    if {[get_property MODE $intf_pin] == "Master"} {
                        connect_bd_intf_net [get_bd_intf_pins $axisRegSlice/M_AXIS] $slave_intf
                        set intf_pin $master_intf
                    } elseif {[get_property MODE $intf_pin] == "Slave"} {
                        connect_bd_intf_net $master_intf [get_bd_intf_pins $axisRegSlice/S_AXIS]
                        set intf_pin $slave_intf
                    }
                }

                # Connect interface pin accordingly and look for its clock and reset
                if {[get_property MODE $intf_pin] == "Master"} {
                    connect_bd_intf_net $intf_pin [get_bd_intf_pins $axisRegSlice/S_AXIS]
                    set new_intf_pin [get_bd_intf_pins $axisRegSlice/M_AXIS]
                } elseif {[get_property MODE $intf_pin] == "Slave"} {
                    connect_bd_intf_net [get_bd_intf_pins $axisRegSlice/M_AXIS] $intf_pin
                    set new_intf_pin [get_bd_intf_pins $axisRegSlice/S_AXIS]
                }
                set clk_pin [AIT::board::get_clk_pin_from_intf_pin $intf_pin]
                set rst_net [AIT::board::get_rst_net_from_clk_pin $clk_pin]
                AIT::board::connect_clock [get_bd_pins $axisRegSlice/aclk] $clk_pin
                AIT::board::connect_reset [get_bd_pins $axisRegSlice/aresetn] $rst_net

                # Return new outermost AXI-Stream pin
                set intf_pin $new_intf_pin
            }
            return $intf_pin
        }

        proc add_stream_adapter {intf_pin accName instanceNum {accID '0x0'}} {
            set intf_name [regsub -all {(^mcxx_|(_V)*$)} [get_property NAME $intf_pin] ""]
            set dir [get_property DIR $intf_pin]
            if {$dir eq "O"} {
                set stream_adapter [create_bd_cell -type module -reference bsc_axiu_hsToStreamAdapter ${accName}_${instanceNum}/Adapter_${intf_name}]
                set_property -dict [list \
                    CONFIG.TID_WIDTH [expr {max(int(ceil(log(${::AIT::num_accs})/log(2))), 1)}] \
                    CONFIG.ACCID $accID \
                 ] $stream_adapter
                connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_vld] [get_bd_pins -regexp ${intf_pin}_ap_vld]
                connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_ack] [get_bd_pins -regexp ${intf_pin}_ap_ack]
                connect_bd_net [get_bd_pins $stream_adapter/in_hs] ${intf_pin}
                set clk_pin [AIT::board::connect_clock [get_bd_pins $stream_adapter/aclk] [AIT::board::get_clk_pin_from_intf_pin $intf_pin]]
                AIT::board::connect_reset [get_bd_pins $stream_adapter/aresetn] [AIT::board::get_rst_net_from_clk_pin $clk_pin]
                return [get_bd_intf_pins $stream_adapter/outStream]
            } elseif {$dir eq "I"} {
                set stream_adapter [create_bd_cell -type module -reference bsc_axiu_streamToHsAdapter ${accName}_${instanceNum}/Adapter_${intf_name}]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_vld] [get_bd_pins -regexp ${intf_pin}_ap_vld]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_ack] [get_bd_pins -regexp ${intf_pin}_ap_ack]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs] ${intf_pin}
                set clk_pin [AIT::board::connect_clock [get_bd_pins $stream_adapter/aclk] [AIT::board::get_clk_pin_from_intf_pin $intf_pin]]
                AIT::board::connect_reset [get_bd_pins $stream_adapter/aresetn] [AIT::board::get_rst_net_from_clk_pin $clk_pin]
                return [get_bd_intf_pins $stream_adapter/inStream]
            }
        }

        proc add_newtask_spawner {acc_spawnInStream hier_inStream hier_outStream accName instanceNum} {
            set newtask_spawner [create_bd_cell -type ip -vlnv bsc:ompss:new_task_spawner_wrapper:1.0 ${accName}_${instanceNum}/new_task_spawner]
            set clk_pin [AIT::board::get_clk_pin_from_intf_pin $acc_spawnInStream]
            AIT::board::connect_clock [get_bd_pins $newtask_spawner/clk] $clk_pin
            AIT::board::connect_reset [get_bd_pins $newtask_spawner/rstn] [AIT::board::get_rst_net_from_clk_pin $clk_pin]

            connect_bd_intf_net $hier_outStream [get_bd_intf_pins $newtask_spawner/stream_in]
            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/ack_out] $acc_spawnInStream

            set tid_demux [create_bd_cell -type module -reference bsc_axiu_axis_tid_demux ${accName}_${instanceNum}/axis_tid_demux]
            AIT::board::connect_clock [get_bd_pins $tid_demux/clk] [get_bd_pins ${accName}_${instanceNum}/aclk]
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m0] $hier_inStream
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m1] [get_bd_intf_pins $newtask_spawner/ack_in]

            return [list [get_bd_intf_pins $newtask_spawner/stream_out] [get_bd_intf_pins $tid_demux/s]]
        }

        proc add_tid_subset_converter {intf_pin accID accName instanceNum} {
            set accIDWidth [expr {max(int(ceil(log(${::AIT::num_accs})/log(2))), 1)}]

            # We need to insert accID to the new_task_spawner TID AXI-Stream signal
            set tidSubsetConv [create_bd_cell -type module -reference bsc_axiu_axis_subset_converter ${accName}_${instanceNum}/TID_subset_converter]
            set clk_pin [AIT::board::get_clk_pin_from_intf_pin $intf_pin]
            AIT::board::connect_clock [get_bd_pins $tidSubsetConv/clk] $clk_pin
            AIT::board::connect_reset [get_bd_pins $tidSubsetConv/aresetn] [AIT::board::get_rst_net_from_clk_pin $clk_pin]

            # Add accID as AXI-Stream TID signal
            set_property -dict [list \
                CONFIG.ID_WIDTH $accIDWidth \
                CONFIG.ID $accID \
             ] $tidSubsetConv

            connect_bd_intf_net $intf_pin [get_bd_intf_pins $tidSubsetConv/S_AXIS]
            return [get_bd_intf_pins $tidSubsetConv/M_AXIS]
        }

        # Mark AXI-Stream interface for debug
        proc mark_debug {intf_pin} {
            # Open debuginterfaces.txt file
            set debugInterfaces_file [open ../${::AIT::name_Project}.debuginterfaces.txt "a"]
            set intf_pin_net [get_bd_intf_nets -of_objects $intf_pin]

            set_property HDL_ATTRIBUTE.DEBUG {true} $intf_pin_net

            #FIXME: Vivado fails to create a new ILA when surpassing max of 16 probes
            if {[llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16} {
                AIT::utils::warning_msg "Maximum number of debug probes reached ([llength [get_bd_intf_nets -filter {HDL_ATTRIBUTE.DEBUG == true}]] > 16). Interface $intf_pin will not be connected to an ILA"
            } else {
                apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects $intf_pin]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_app SYSTEM_ILA "Auto" APC_EN "0" }]

                # Add a line to debuginterfaces.txt
                puts $debugInterfaces_file "$intf_pin"
                close $debugInterfaces_file
            }
        }
    }
}
