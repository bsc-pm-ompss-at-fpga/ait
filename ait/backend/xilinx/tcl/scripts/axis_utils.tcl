#------------------------------------------------------------------------#
#    (C) Copyright 2017-2025 Barcelona Supercomputing Center             #
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
        # Adds an AXIS subset converter to the target AXI-Stream pin and sets the TID to accID
        # If the target pin is already connected, breaks the connection and restores it with the subset converter in between
        # Returns the AXIS interface pin that shares MODE with the target pin
        proc add_accID {intfPin accID {bdInstance .}} {
            set oldBdInstance [current_bd_instance .]
            current_bd_instance ${bdInstance}

            set intfPin [get_bd_intf_pins ${intfPin}]
            set accIDWidth [expr {max(int(ceil(log([dict get ${AIT::vars::aitConfig} "num_instances"])/log(2))), 1)}]

            # Instantiate AXIS subset converter and connect it to target interfaces's clock and reset
            set axisAccIDIP [create_bd_cell -type module -reference bsc_axiu_axis_accID accID]
            set intfClkPin [AIT::design::connect_clock [get_bd_pins ${axisAccIDIP}/clk] [AIT::design::get_associated_clk_pin ${intfPin}]]
            AIT::design::connect_reset [get_bd_pins ${axisAccIDIP}/aresetn] [AIT::design::get_synchronous_rst_pin ${intfClkPin}]

            # Add accID as AXI-Stream TID signal
            set_property -dict [list \
                CONFIG.ID_WIDTH ${accIDWidth} \
                CONFIG.ID ${accID} \
            ] ${axisAccIDIP}

            # Check if target interface pin is an IP pin or a hierarchy pin and connect it accordingly
            if {[get_property TYPE ${intfPin}] eq "ip"} {
                # If the pin is already connected, get the other interface pin to restore the connection afterwards and delete the net
                set otherIntfPin [get_bd_intf_pins -quiet -of_objects [get_bd_intf_nets -quiet -of_objects ${intfPin}] -filter "PATH != ${intfPin}"]
                delete_bd_objs -quiet [get_bd_intf_nets -quiet -of_objects ${intfPin}]
                # If the target pin is an IP pin we must treat it as its mode
                if {[get_property MODE ${intfPin}] eq "Master"} {
                    set newIntfPin [get_bd_intf_pins ${axisAccIDIP}/M_AXIS]
                    connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${axisAccIDIP}/S_AXIS]
                    connect_bd_intf_net -quiet ${newIntfPin} ${otherIntfPin}
                } elseif {[get_property MODE ${intfPin}] eq "Slave"} {
                    set newIntfPin [get_bd_intf_pins ${axisAccIDIP}/S_AXIS]
                    connect_bd_intf_net [get_bd_intf_pins ${axisAccIDIP}/M_AXIS] ${intfPin}
                    connect_bd_intf_net -quiet ${otherIntfPin} ${newIntfPin}
                }
            } elseif {[get_property TYPE ${intfPin}] eq "hier"} {
                # If the pin is already connected, get the other interface pin to restore the connection afterwards and delete the net
                set otherIntfPin [get_bd_intf_pins -quiet -of_objects [get_bd_intf_nets -quiet -boundary_type lower -of_objects ${intfPin}] -filter "PATH != ${intfPin}"]
                delete_bd_objs -quiet [get_bd_intf_nets -quiet -boundary_type lower -of_objects ${intfPin}]
                # If the target pin is a hierarchy pin we must treat it as if it were the opposite of its mode
                if {[get_property MODE ${intfPin}] eq "Master"} {
                    set newIntfPin [get_bd_intf_pins ${axisAccIDIP}/M_AXIS]
                    connect_bd_intf_net ${newIntfPin} ${intfPin}
                    connect_bd_intf_net -quiet ${otherIntfPin} [get_bd_intf_pins ${axisAccIDIP}/S_AXIS]
                } elseif {[get_property MODE ${intfPin}] eq "Slave"} {
                    set newIntfPin [get_bd_intf_pins ${axisAccIDIP}/S_AXIS]
                    connect_bd_intf_net ${intfPin} ${newIntfPin}
                    connect_bd_intf_net -quiet [get_bd_intf_pins ${axisAccIDIP}/M_AXIS] ${otherIntfPin}
                }
            }

            save_bd_design -quiet
            current_bd_instance ${oldBdInstance}
            return ${newIntfPin}
        }

        # Adds a newtask_spawner IP to the given interface pin and connects it to the accelerator in and out streams
        # Returns the new in and out streams
        proc add_newtask_spawner {intfPin inStreamPin outStreamPin {imp False} {bdInstance .}} {
            set oldBdInstance [current_bd_instance .]
            current_bd_instance ${bdInstance}

            set intfPin [get_bd_intf_pins ${intfPin}]

            set newtaskSpawnerIP [create_bd_cell -type ip -vlnv bsc:ompss:newtask_spawner new_task_spawner]
            set intfClkPin [AIT::design::get_associated_clk_pin ${intfPin}]
            AIT::design::connect_clock [get_bd_pins ${newtaskSpawnerIP}/clk] ${intfClkPin}
            AIT::design::connect_reset [get_bd_pins ${newtaskSpawnerIP}/rstn] [AIT::design::get_synchronous_rst_pin ${intfClkPin}]

            connect_bd_intf_net ${outStreamPin} [get_bd_intf_pins ${newtaskSpawnerIP}/stream_in]
            connect_bd_intf_net [get_bd_intf_pins ${newtaskSpawnerIP}/ack_out] ${intfPin}

            set tidDemuxIP [create_bd_cell -type module -reference bsc_axiu_axis_tid_demux axis_tid_demux]
            AIT::design::connect_clock [get_bd_pins ${tidDemuxIP}/clk] ${intfClkPin}
            connect_bd_intf_net [get_bd_intf_pins ${tidDemuxIP}/m0] ${inStreamPin}
            connect_bd_intf_net [get_bd_intf_pins ${tidDemuxIP}/m1] [get_bd_intf_pins ${newtaskSpawnerIP}/ack_in]

            # Activate IMP if necessary
            set_property -dict [list \
                CONFIG.IMP ${imp} \
                CONFIG.MAX_ARGS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_args_per_task"] \
                CONFIG.MAX_DEPS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_deps_per_task"] \
                CONFIG.MAX_COPS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_copies_per_task"] \
                CONFIG.MAX_OWNS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_deps_per_task"] \
            ] ${newtaskSpawnerIP}

            if {${imp}} {
                connect_bd_net [get_bd_pins ${newtaskSpawnerIP}/ompif_rank] [get_bd_pins ${AIT::vars::OMPIF}/ompif_rank]
            }

            save_bd_design -quiet
            current_bd_instance ${oldBdInstance}

            return [list [get_bd_intf_pins ${newtaskSpawnerIP}/stream_out] [get_bd_intf_pins ${tidDemuxIP}/s]]
        }

        # Adds a register slice in an AXI-Stream interface
        # If the interface is already connected, it breaks the connection and instantiates the register slice in-between
        # Returns a tuple with the first element being the new interface pin and the second a string with the required constraints for the register slice
        proc add_reg_slice {intfPin {masterSLR ""} {slaveSLR ""} {numPipelineStages ""} {regSliceName ""} {bdInstance .}} {
            set oldBdInstance [current_bd_instance .]
            current_bd_instance ${bdInstance}

            set intfPin [get_bd_intf_pins ${intfPin}]
            set regSliceName [expr {(${regSliceName} eq "") ? [get_property NAME ${intfPin}] : ${regSliceName}}]
            append regSliceName _regslice[expr {(${masterSLR} eq "") ? "" : "_slr_${masterSLR}_${slaveSLR}"}]
            set constrStr ""

            lassign [split ${numPipelineStages} ':'] numStagesMaster numStagesMiddle numStagesSlave
            lassign [split [dict get ${AIT::vars::aitConfig} "regslice_pipeline_stages"] ':'] defaultNumStagesMaster defaultNumStagesMiddle defaultNumStagesSlave
            set numStagesMaster [expr {${numStagesMaster} eq "" ? ${defaultNumStagesMaster} : ${numStagesMaster}}]
            set numStagesMiddle [expr {${numStagesMiddle} eq "" ? ${defaultNumStagesMiddle} : ${numStagesMiddle}}]
            set numStagesSlave [expr {${numStagesSlave} eq "" ? ${defaultNumStagesSlave} : ${numStagesSlave}}]

            set axisRegSliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${regSliceName}]
            set intfClkPin [AIT::design::connect_clock [get_bd_pins ${axisRegSliceIP}/aclk] [AIT::design::get_associated_clk_pin ${intfPin}]]
            AIT::design::connect_reset [get_bd_pins ${axisRegSliceIP}/aresetn] [AIT::design::get_synchronous_rst_pin ${intfClkPin}]

            # Let Vivado handle the number of pipeline stages
            if {${numStagesMaster} eq "auto"} {
                set_property -dict [list \
                    CONFIG.REG_CONFIG {16} \
                ] ${axisRegSliceIP}

                # Unconstrain register slice to allow Vivado place it anywhere
                append constrStr "remove_cells_from_pblock -quiet \
                    \[get_pblocks -quiet -of \[get_cells -hierarchical -filter \"NAME =~ *${axisRegSliceIP}\"\]\] \
                    \[get_cells -hierarchical -filter \"NAME =~ *${axisRegSliceIP}\"\]\n"
            } else {
                # Decrement number of stages by one as the IP already assumes it
                incr numStagesMaster -1
                incr numStagesMiddle -1
                incr numStagesSlave -1

                # Master SLR
                set_property -dict [list \
                    CONFIG.NUM_SLR_CROSSINGS {0} \
                    CONFIG.PIPELINES_MASTER ${numStagesMaster} \
                    CONFIG.REG_CONFIG {15} \
                ] ${axisRegSliceIP}

                if {${masterSLR} != ${slaveSLR}} {
                    set numSLRCrossings [expr {abs(${masterSLR} - ${slaveSLR})}]
                    set_property -dict [list \
                        CONFIG.NUM_SLR_CROSSINGS ${numSLRCrossings} \
                    ] ${axisRegSliceIP}

                    # Middle SLR
                    if {${numSLRCrossings} > 1} {
                        set_property -dict [list \
                            CONFIG.PIPELINES_MIDDLE ${numStagesMiddle} \
                        ] ${axisRegSliceIP}
                    }

                    # Slave SLR
                    if {${numSLRCrossings} > 0} {
                        set_property -dict [list \
                            CONFIG.PIPELINES_SLAVE ${numStagesSlave} \
                        ] ${axisRegSliceIP}
                    }
                }

                if {${masterSLR} ne ""} {
                    # Constrain master-side register slice IP submodules to master SLR
                    append constrStr "add_cells_to_pblock \
                        \[get_pblocks slr${masterSLR}_pblock\] \
                        \[get_cells -hierarchical -filter \"NAME =~ *${axisRegSliceIP}*slr_master\"\]\n"
                }

                if {${slaveSLR} ne ""} {
                    # Constrain slave-side register slice IP submodules to slave SLR
                    append constrStr "add_cells_to_pblock \
                        \[get_pblocks slr${slaveSLR}_pblock\] \
                        \[get_cells -hierarchical -filter \"NAME =~ *${axisRegSliceIP}*slr_slave\"\]\n"
                }
            }

            # Check if target interface pin is an IP pin or a hierarchy pin and connect it accordingly
            if {[get_property TYPE ${intfPin}] eq "ip"} {
                # If the pin is already connected, get the other interface pin to restore the connection afterwards and delete the net
                set otherIntfPin [get_bd_intf_pins -quiet -of_objects [get_bd_intf_nets -quiet -of_objects ${intfPin}] -filter "PATH != ${intfPin}"]
                delete_bd_objs -quiet [get_bd_intf_nets -quiet -of_objects ${intfPin}]
                # If the target pin is an IP pin we must treat it as its mode
                if {[get_property MODE ${intfPin}] eq "Master"} {
                    set newIntfPin [get_bd_intf_pins ${axisRegSliceIP}/M_AXIS]
                    connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${axisRegSliceIP}/S_AXIS]
                    connect_bd_intf_net -quiet ${newIntfPin} ${otherIntfPin}
                } elseif {[get_property MODE ${intfPin}] eq "Slave"} {
                    set newIntfPin [get_bd_intf_pins ${axisRegSliceIP}/S_AXIS]
                    connect_bd_intf_net [get_bd_intf_pins ${axisRegSliceIP}/M_AXIS] ${intfPin}
                    connect_bd_intf_net -quiet ${otherIntfPin} ${newIntfPin}
                }
            } elseif {[get_property TYPE ${intfPin}] eq "hier"} {
                # If the pin is already connected, get the other interface pin to restore the connection afterwards and delete the net
                set otherIntfPin [get_bd_intf_pins -quiet -of_objects [get_bd_intf_nets -quiet -boundary_type lower -of_objects ${intfPin}] -filter "PATH != ${intfPin}"]
                delete_bd_objs -quiet [get_bd_intf_nets -quiet -boundary_type lower -of_objects ${intfPin}]
                # If the target pin is a hierarchy pin we must treat it as if it were the opposite of its mode
                if {[get_property MODE ${intfPin}] eq "Master"} {
                    set newIntfPin [get_bd_intf_pins ${axisRegSliceIP}/M_AXIS]
                    connect_bd_intf_net ${newIntfPin} ${intfPin}
                    connect_bd_intf_net -quiet ${otherIntfPin} [get_bd_intf_pins ${axisRegSliceIP}/S_AXIS]
                } elseif {[get_property MODE ${intfPin}] eq "Slave"} {
                    set newIntfPin [get_bd_intf_pins ${axisRegSliceIP}/S_AXIS]
                    connect_bd_intf_net ${intfPin} ${newIntfPin}
                    connect_bd_intf_net -quiet [get_bd_intf_pins ${axisRegSliceIP}/M_AXIS] ${otherIntfPin}
                }
            }

            # Return new outermost AXI-Stream pin
            set intfPin ${newIntfPin}

            save_bd_design -quiet
            current_bd_instance ${oldBdInstance}
            return [list ${intfPin} ${constrStr}]
        }

        # Adds an AXI-Stream adapter to a handshake interface pin
        # If it's a slave interface, adds a streamToHsAdapter
        # If it's a master interface, adds a hsToStreamAdapter
        # Returns the new interface pin
        proc add_stream_adapter {intfPin {accID 0x0} {bdInstance .}} {
            set oldBdInstance [current_bd_instance .]
            current_bd_instance ${bdInstance}

            set intfPin [get_bd_intf_pins ${intfPin}]

            if {[get_property DIR ${intfPin}] eq "O"} {
                set streamAdapterIP [create_bd_cell -type module -reference bsc_axiu_hsToStreamAdapter [get_property NAME ${intfPin}]_hsToStream]
                set_property -dict [list \
                    CONFIG.TID_WIDTH [expr {max(int(ceil(log([dict get ${AIT::vars::aitConfig} "num_instances"])/log(2))), 1)}] \
                    CONFIG.ACCID ${accID} \
                ] ${streamAdapterIP}
                connect_bd_net [get_bd_pins ${streamAdapterIP}/in_hs_ap_vld] [get_bd_pins -regexp ${intfPin}_ap_vld]
                connect_bd_net [get_bd_pins ${streamAdapterIP}/in_hs_ap_ack] [get_bd_pins -regexp ${intfPin}_ap_ack]
                connect_bd_net [get_bd_pins ${streamAdapterIP}/in_hs] ${intfPin}
                set clk_pin [AIT::design::connect_clock [get_bd_pins ${streamAdapterIP}/aclk] [AIT::design::get_associated_clk_pin ${intfPin}]]
                AIT::design::connect_reset [get_bd_pins ${streamAdapterIP}/aresetn] [AIT::design::get_synchronous_rst_pin ${clk_pin}]
                set intfPin [get_bd_intf_pins ${streamAdapterIP}/outStream]
            } elseif {[get_property DIR ${intfPin}] eq "I"} {
                set streamAdapterIP [create_bd_cell -type module -reference bsc_axiu_streamToHsAdapter [get_property NAME ${intfPin}]_streamToHs]
                connect_bd_net [get_bd_pins ${streamAdapterIP}/out_hs_ap_vld] [get_bd_pins -regexp ${intfPin}_ap_vld]
                connect_bd_net [get_bd_pins ${streamAdapterIP}/out_hs_ap_ack] [get_bd_pins -regexp ${intfPin}_ap_ack]
                connect_bd_net [get_bd_pins ${streamAdapterIP}/out_hs] ${intfPin}
                set clk_pin [AIT::design::connect_clock [get_bd_pins ${streamAdapterIP}/aclk] [AIT::design::get_associated_clk_pin ${intfPin}]]
                AIT::design::connect_reset [get_bd_pins ${streamAdapterIP}/aresetn] [AIT::design::get_synchronous_rst_pin ${clk_pin}]
                set intfPin [get_bd_intf_pins ${streamAdapterIP}/inStream]
            }

            save_bd_design -quiet
            current_bd_instance ${oldBdInstance}

            return ${intfPin}
        }

        # Creates and connects a tree of interconnects that allows an arbitrary number of AXI-stream slaves to connect to up to 16 AXI-stream masters
        proc create_inStream_Inter_tree { stream_name nmasters nslaves clk inter_rstn peri_rstn } {
            set ninter [expr {int(ceil(${nslaves}/16.))}]
            set prev_ninter ${nslaves}
            set inter_level 0
            set inter_stride 1

            # First level uses interconnects with more than one master if required
            for {set i 0} {${i} < ${ninter}} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_${i}
                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect ${inter_name}]

                # Last interconnect may need less slaves
                if {(${i} == ${ninter}-1) && (${prev_ninter}%16)} {
                    set num_si [expr {${prev_ninter}%16}]
                } else {
                    set num_si 16
                }

                set_property -dict [list \
                    CONFIG.NUM_MI ${nmasters} \
                    CONFIG.NUM_SI ${num_si} \
                ] ${inter}

                # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
                if {${num_si} > 1} {
                    set_property -dict [list \
                        CONFIG.ARB_ON_MAX_XFERS {0} \
                        CONFIG.ARB_ON_TLAST {1} \
                    ] ${inter}
                }

                connect_bd_net ${clk} [get_bd_pins ${inter_name}/ACLK]
                connect_bd_net ${inter_rstn} [get_bd_pins ${inter_name}/ARESETN]
                for {set j 0} {${j} < ${num_si}} {incr j} {
                    set inf_num [format %02u ${j}]
                    connect_bd_net ${clk} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ACLK]
                    connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {${j} < ${nmasters}} {incr j} {
                    set inf_num [format %02u ${j}]
                    connect_bd_net ${clk} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ACLK]
                    connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter ${ninter}
            set ninter [expr {int(ceil(${ninter}/16.))}]
            incr inter_level

            while {${ninter} < ${prev_ninter}} {
                for {set m 0} {${m} < ${nmasters}} {incr m} {
                    for {set i 0} {${i} < ${ninter}} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_m${m}_${i}
                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect ${inter_name}]

                        # Last interconnect may need less slaves
                        if {(${i} == ${ninter}-1) && (${prev_ninter}%16)} {
                            set num_si [expr {${prev_ninter}%16}]
                        } else {
                            set num_si 16
                        }

                        set_property -dict [list \
                            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
                            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
                            CONFIG.NUM_MI {1} \
                            CONFIG.NUM_SI ${num_si} \
                        ] ${inter}

                        # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
                        if {${num_si} > 1} {
                            set_property -dict [list \
                                CONFIG.ARB_ON_MAX_XFERS {0} \
                                CONFIG.ARB_ON_TLAST {1} \
                            ] ${inter}
                        }

                        connect_bd_net ${clk} [get_bd_pins ${inter_name}/ACLK]
                        connect_bd_net ${inter_rstn} [get_bd_pins ${inter_name}/ARESETN]
                        for {set j 0} {${j} < ${num_si}} {incr j} {
                            set inf_num [format %02u ${j}]
                            connect_bd_net ${clk} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ACLK]
                            connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net ${clk} [get_bd_pins ${inter_name}/M00_AXIS_ACLK]
                        connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/M00_AXIS_ARESETN]

                        for {set j 0} {${j} < ${num_si}} {incr j} {
                            set master_inter_num [expr {${i}*16 + ${j}}]
                            set master_inter_level [expr {${inter_level} - 1}]
                            if {${inter_level} == 1} {
                                set master_inf [format %02u ${m}]
                                set master_inter ${stream_name}_lvl${master_inter_level}_${master_inter_num}
                            } else {
                                set master_inf 00
                                set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_${master_inter_num}
                            }
                            set slave [format %02u [expr {${j}%16}]]
                            connect_bd_intf_net [get_bd_intf_pins ${master_inter}/M${master_inf}_AXIS] [get_bd_intf_pins ${inter_name}/S${slave}_AXIS]
                        }
                    }
                }
                set prev_ninter ${ninter}
                set ninter [expr {int(ceil(${ninter}/16.))}]
                incr inter_level
            }
            return [expr {${inter_level} - 1}]
        }

        # Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
        proc create_outStream_Inter_tree { stream_name nslaves nmasters clk inter_rstn peri_rstn } {
            set ninter [expr {int(ceil(${nmasters}/16.))}]
            set prev_ninter ${nmasters}
            set inter_level 0
            set stride 1

            # First level uses interconnects with more than one slave if required
            for {set i 0} {${i} < ${ninter}} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_${i}
                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect ${inter_name}]

                # Last interconnect may need less masters
                if {(${i} == ${ninter}-1) && (${prev_ninter}%16)} {
                    set num_mi [expr {${prev_ninter}%16}]
                } else {
                    set num_mi 16
                }

                set_property -dict [list \
                    CONFIG.NUM_MI {1} \
                    CONFIG.NUM_SI ${nslaves} \
                ] ${inter}

                # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
                if {${nslaves} > 1} {
                    set_property -dict [list \
                        CONFIG.ARB_ON_MAX_XFERS {0} \
                        CONFIG.ARB_ON_TLAST {1} \
                    ] ${inter}
                }

                for {set j 0} {${j} < ${num_mi}} {incr j} {
                    set master_num [format %02u ${j}]
                    set base_dest [format "32\'d%d" [expr {${i}*${stride}*16 + ${j}*${stride}}]]
                    set high_dest [format "32\'d%d" [expr {${i}*${stride}*16 + (${j}+1)*${stride} - 1}]]
                    set_property -dict [list \
                        CONFIG.NUM_MI [expr {${j} + 1}] \
                        CONFIG.M${master_num}_AXIS_BASETDEST ${base_dest} \
                        CONFIG.M${master_num}_AXIS_HIGHTDEST ${high_dest} \
                    ] ${inter}
                }

                connect_bd_net ${clk} [get_bd_pins ${inter_name}/ACLK]
                connect_bd_net ${inter_rstn} [get_bd_pins ${inter_name}/ARESETN]
                for {set j 0} { ${j} < ${num_mi}} {incr j} {
                    set inf_num [format %02u ${j}]
                    connect_bd_net ${clk} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ACLK]
                    connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {${j} < ${nslaves}} {incr j} {
                    set inf_num [format %02u ${j}]
                    connect_bd_net ${clk} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ACLK]
                    connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/S${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter ${ninter}
            set ninter [expr {int(ceil(${ninter}/16.))}]
            set stride [expr {${stride}*16}]
            incr inter_level

            while {${ninter} < ${prev_ninter}} {
                for {set s 0} {${s} < ${nslaves}} {incr s} {
                    for {set i 0} {${i} < ${ninter}} {incr i} {
                        set inter_name ${stream_name}_lvl${inter_level}_s${s}_${i}
                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect ${inter_name}]

                        # Last interconnect may need less masters
                        if {(${i} == ${ninter}-1) && (${prev_ninter}%16)} {
                            set num_mi [expr {${prev_ninter}%16}]
                        } else {
                            set num_mi 16
                        }

                        set_property -dict [list \
                            CONFIG.NUM_MI {1} \
                            CONFIG.NUM_SI {1} \
                        ] ${inter}

                        for {set j 0} {${j} < ${num_mi}} {incr j} {
                            set master_num [format %02u ${j}]
                            set base_dest [format "32\'d%d" [expr {${i}*${stride}*16 + ${j}*${stride}}]]
                            set high_dest [format "32\'d%d" [expr {${i}*${stride}*16 + (${j}+1)*${stride} - 1}]]

                            save_bd_design
                            set_property -dict [list \
                                CONFIG.NUM_MI [expr {${j} + 1}] \
                                CONFIG.M${master_num}_AXIS_BASETDEST ${base_dest} \
                                CONFIG.M${master_num}_AXIS_HIGHTDEST ${high_dest} \
                            ] ${inter}
                        }

                        connect_bd_net ${clk} [get_bd_pins ${inter_name}/ACLK]
                        connect_bd_net ${inter_rstn} [get_bd_pins ${inter_name}/ARESETN]
                        for {set j 0} { ${j} < ${num_mi}} {incr j} {
                            set inf_num [format %02u ${j}]
                            connect_bd_net ${clk} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ACLK]
                            connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/M${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net ${clk} [get_bd_pins ${inter_name}/S00_AXIS_ACLK]
                        connect_bd_net ${peri_rstn} [get_bd_pins ${inter_name}/S00_AXIS_ARESETN]

                        for {set j 0} {${j} < ${num_mi}} {incr j} {
                            set slave_inter_num [expr {${i}*16 + ${j}}]
                            set slave_inter_level [expr {${inter_level} - 1}]
                            set master [format %02u ${j}]
                            if {${inter_level} == 1} {
                                set slave_inf [format %02u ${s}]
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_${slave_inter_num}
                            } else {
                                set slave_inf 00
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_s${s}_${slave_inter_num}
                            }
                            connect_bd_intf_net [get_bd_intf_pins ${inter_name}/M${master}_AXIS] [get_bd_intf_pins ${slave_inter}/S${slave_inf}_AXIS]
                        }
                    }
                }
                set prev_ninter ${ninter}
                set ninter [expr {int(ceil(${ninter}/16.))}]
                set stride [expr {${stride}*16}]
                incr inter_level
            }
            return [expr {${inter_level} - 1}]
        }
    }
}
