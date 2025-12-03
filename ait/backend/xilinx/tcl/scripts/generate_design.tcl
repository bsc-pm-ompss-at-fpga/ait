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

set scriptDir [file dirname [file normalize [info script]]]
set projectRootDir ${scriptDir}/../..

# Cleanup files
file delete ${projectRootDir}/[dict get ${AIT::vars::aitConfig} "name"].ait.json

# List of OmpSs@FPGA address segments
# Includes address segment name, size and base address
# We set bitinfo address segment as size 1 so it will be the first one to be allocated
set bdAddrSegmentsList [lsort -increasing -command AIT::utils::comp_dict [list \
    [dict create \
        name bitinfo \
        bdSegName bitInfo_BRAM_Ctrl/S_AXI/Mem0 \
        size 1 \
        addr [format 0x%016x [dict get ${AIT::vars::board} "memory" "ompss_base_addr"]] \
    ] \
    [dict create \
        name cmdInQueueHwruntime \
        bdSegName Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0 \
        size [expr {[dict get ${AIT::vars::aitConfig} "cmdin_subqueue_len"]*[dict get ${AIT::vars::aitConfig} "num_instances"]*8}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name cmdOutQueueHwruntime \
        bdSegName Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0 \
        size [expr {[dict get ${AIT::vars::aitConfig} "cmdout_subqueue_len"]*[dict get ${AIT::vars::aitConfig} "num_instances"]*8}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name managedReset \
        bdSegName managed_reset/S_AXI/Reg \
        size 4096 \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name spawnInQueueHwruntime \
        bdSegName Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0 \
        size [expr {[dict get ${AIT::vars::aitConfig} "spawnin_queue_len"]*8}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name spawnOutQueueHwruntime \
        bdSegName Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0 \
        size [expr {[dict get ${AIT::vars::aitConfig} "spawnout_queue_len"]*8}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name hwcounter \
        bdSegName HW_Counter/s_axi/reg0 \
        size [expr {([dict get ${AIT::vars::aitConfig} "hwcounter"] || [dict get ${AIT::vars::aitConfig} "hwinst"]) ? 4096 : 0}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name pomAxilite \
        bdSegName Hardware_Runtime/Picos_OmpSs_Manager/axilite/reg_0 \
        size [expr {[dict get ${AIT::vars::aitConfig} "enable_pom_axilite"] ? 16*1024 : 0}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name powerMonitor \
        bdSegName cms_subsystem/s_axi_ctrl/Mem* \
        size [expr {[dict get ${AIT::vars::aitConfig} "power_monitor"] ? 256*1024 : 0}] \
        addr [format 0x%016x 0x0]
    ] \
    [dict create \
        name thermalMonitor \
        bdSegName system_management/S_AXI_LITE/Reg \
        size [expr {[dict get ${AIT::vars::aitConfig} "thermal_monitor"] ? 4096 : 0}] \
        addr [format 0x%016x 0x0]
    ]
]]

# Compute address segments base addresses
set offset 0
foreach bdAddrSeg ${bdAddrSegmentsList} {
    dict with bdAddrSeg {
        if {${size}} {
            if {${size} <= 4096} {
                set size 4096
            } elseif {${size} & (${size}-1)} { # Not power of 2
                set sizeClog2 [expr {int(ceil(log(${size})/log(2)))}]
                set size [expr {int(pow(2, ${sizeClog2}))}]
            }
            if {${offset}%${size}} {
                incr offset [expr {${size} - (${offset}%${size})}]
            }
            set addr [format 0x%016x [expr {[dict get ${AIT::vars::board} "memory" "ompss_base_addr"] + ${offset}}]]
            incr offset ${size}
        }
    }
    dict append bdAddrSegmentsDict [dict get ${bdAddrSeg} "name"] ${bdAddrSeg}
}
unset offset

# Create project and set board files
create_project -force [dict get ${AIT::vars::aitConfig} "name"] [dict get ${AIT::vars::aitConfig} "name"] -part [dict get ${AIT::vars::board} "chip_part"]

dict set ::AIT::vars::aitJsonDict "project_name" [dict get ${AIT::vars::aitConfig} "name"]
dict set AIT::vars::aitJsonDict "user_id" ${AIT::vars::userID}

if {[dict exists ${AIT::vars::board} "board_part"]} {
    set boardFound False
    foreach boardName [dict get ${AIT::vars::board} "board_part"] {
        set boardPart [get_board_parts -latest_file_version ${boardName}:*]
        if {${boardPart} ne ""} {
            dict set AIT::vars::aitJsonDict "board_part" ${boardPart}
            set_property board_part ${boardPart} [current_project]
            set boardFound True
            break
        }
    }
    if {!${boardFound}} {
        AIT::utils::error_msg "Board part ([string trim [dict get ${AIT::vars::board} "board_part"]]) is missing, design will fail. Please add the corresponding board files to the Vivado installation"
    }
}

# Set repository path
set_property ip_repo_paths {HLS} [current_project]

# Do not generate simulation scripts
set_property sim.ip.auto_export_scripts {false} [current_project]

# If enabled, set cache location
if {![dict get ${AIT::vars::aitConfig} "disable_IP_caching"]} {
    config_ip_cache -import_from_project -use_cache_location [dict get ${AIT::vars::aitConfig} "IP_cache_location"]
}

# Suppress known warning and critical warning messages
#set_msg_config -id {[BD 41-1753]} -severity {WARNING} -suppress
set_msg_config -id {[BD 41-237]} -severity {CRITICAL WARNING} -regexp -string {".*Bus Interface property MASTER_TYPE does not match between /(Hardware_Runtime|bitinfo)/.*BRAM_PORT(A|B).* and .*"} -suppress
set_msg_config -id {[BD 41-237]} -severity {WARNING} -regexp -string {".*Bus Interface property (AW|W|R|AR)USER_WIDTH does not match between .* and .*"} -suppress
set_msg_config -id {[BD 41-1629]} -severity {WARNING} -regexp -string {".*Slave segment <.*C0_DDR4_MEMORY_MAP_CTRL.*> is excluded from all addressing paths."} -suppress
set_msg_config -id {[BD 5-699]} -severity {WARNING} -regexp -string {".*No address segments matched 'get_bd_addr_segs -of_object .*C0_DDR4_MEMORY_MAP_CTRL.*'"} -suppress
set_msg_config -id {[BD 5-699]} -severity {WARNING} -regexp -string {".*No address segments matched 'get_bd_addr_segs -addressing -of_objects .*C0_DDR4_S_AXI_CTRL'"} -suppress
# The dangling interface net <NAME> will not be written out to the BD file.
set_msg_config -id {[BD 41-2671]} -severity {WARNING} -suppress
# This script was generated using Vivado <OLDER_VERSION>, but is now being run in <NEWER_VERSION> of Vivado.
set_msg_config -id {[BD_TCL-1002]} -severity {WARNING} -suppress
# The ECC Algorithm string is empty. Setting the Memory Map to default ECC value to ECC_NONE.
set_msg_config -id {[filemgmt 56-443]} -severity {WARNING} -suppress
# An attempt to modify the value of disabled parameter '<PARAM_NAME>' from '<OLD_VALUE>' to '<NEW_VALUE>' has been ignored for IP '<IP_NAME>'
set_msg_config -id {[IP_Flow 19-3374]} -severity {WARNING} -suppress
# The connection to interface pin <PIN_NAME> is being overridden by the user with net <NET_NAME>. This pin will not be connected as a part of interface connection <CON_NAME>.
set_msg_config -id {[BD 41-1306]} -severity {WARNING} -suppress
# This script was generated using Vivado <OLDER_VERSION> without IP versions in the create_bd_cell commands, but is now being run in <NEWER_VERSION> of Vivado. There may have been major IP version changes between Vivado <OLDER_VERSION> and <NEWER_VERSION>, which could impact the parameter settings of the IPs.
set_msg_config -id {[BD::TCL 103-2040]} -severity {WARNING} -suppress
# In IP Integrator, The Maximum address range supported is 2G. Selecting the address range more than 2G in the address editor may resets the value of Memory depth to default value (1024). please refer to the AXI BRAM Controller Product Guide.
set_msg_config -id {[xilinx.com:ip:axi_bram_ctrl:4.1-1]} -severity {INFO} -suppress
# In IP Integrator, please note that memory depth value gets calculated based on the Data Width of the IP and Address range selected in the Address Editor.Incase a validation error occured on the range of this parameter, please check if the selected Data width and the Address Range are valid. For valid Data width and memory depth values, please refer to the AXI BRAM Controller Product Guide.
set_msg_config -id {[xilinx.com:ip:axi_bram_ctrl:4.1-2]} -severity {INFO} -suppress


# Add BSC auxiliary IPs
if {[file isdirectory ${projectRootDir}/IPs]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ${projectRootDir}/IPs" [current_project]
    update_ip_catalog
    foreach IP [glob -nocomplain ${projectRootDir}/IPs/*.zip] {
        AIT::utils::info_msg "Adding auxiliary IP ${IP}..."
        update_ip_catalog -add_ip ${IP} -repo_path ${projectRootDir}/IPs
    }
    foreach IP [glob -nocomplain ${projectRootDir}/IPs/*.{v,vhdl}] {
        AIT::utils::info_msg "Adding auxiliary IP ${IP}..."
        import_files -norecurse ${IP}
        update_ip_catalog
    }
    AIT::utils::info_msg "Auxiliary IPs sucessfully added"
}

# If exists, add board IP repository
if {[file isdirectory ${projectRootDir}/board/IPs]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ${projectRootDir}/board/IPs" [current_project]
    update_ip_catalog
    foreach IP [glob -nocomplain ${projectRootDir}/board/IPs/*.zip] {
        AIT::utils::info_msg "Adding board IP ${IP}..."
        update_ip_catalog -add_ip ${IP} -repo_path ${projectRootDir}/board/IPs
    }
    AIT::utils::info_msg "Board IPs sucessfully added"
}

# Update IP catalog
update_ip_catalog

# If exists, add constraints file
if {[file isdirectory ${projectRootDir}/board/constraints]} {
    add_files -fileset constrs_1 -norecurse ${projectRootDir}/board/constraints
    reorder_files -fileset constrs_1 -front [get_files -quiet create_pblocks.xdc]
    if {![dict get ${AIT::vars::aitConfig} "power_monitor"]} {
        remove_files -fileset constrs_1 [get_files -quiet power_monitor.xdc]
    }
    if {![dict get ${AIT::vars::aitConfig} "ompif"]} {
        remove_files -fileset constrs_1 [get_files -quiet ompif.xdc]
    }
    if {[dict get ${AIT::vars::aitConfig} "disable_static_constraints"]} {
        remove_files -fileset constrs_1 [get_files -quiet board_static.xdc]
    }
}

# Generate board base design from template
AIT::templates::base_design [dict get ${AIT::vars::aitConfig} "name"]

# Open Block Design
open_bd_design [get_files [dict get ${AIT::vars::aitConfig} "name"]_design.bd]

# Set Out-Of-Context synthesis
set_property synth_checkpoint_mode {Hierarchical} [get_files [current_bd_design].bd]

# If available, execute the user defined pre-design tcl script
if {[file exists ${projectRootDir}/user/tcl/scripts/userPreDesign.tcl]} {
    if {[catch {source -notrace ${projectRootDir}/user/tcl/scripts/userPreDesign.tcl}]} {
        AIT::utils::error_msg "Failed sourcing board pre base design"
    }
}

# Initialize board base design with required IPs
AIT::design::init_bd

if {[dict get ${AIT::vars::aitConfig} "memory_interleaving_stride"]} {
    dict set AIT::vars::aitJsonDict "interleaving" [dict get ${AIT::vars::aitConfig} "memory_interleaving_stride"]
}

set ::AIT::vars::accID 0
set ::AIT::vars::numEnabledIntfs 0

# Instantiate OMPIF accelerators if needed
if {[dict get ${AIT::vars::aitConfig} "ompif"]} {
    AIT::templates::OMPIF
}

# Import accelerators json
dict set AIT::vars::aitJsonDict "accs" ${AIT::vars::accs}

AIT::utils::info_msg "Instantiating accelerators..."

dict with AIT::vars::aitJsonDict {
    dict for {accKey accDict} ${accs} {
        dict with accs {
            dict with ${accKey} {

                # Get variables from the accelerators json
                set accName ${name}
                set numInstances ${num_instances}
                set taskCreator ${task_creation}

                # Create accelerator instances dictionary to store each instance dictionary
                dict update ${accKey} "instances" instancesDict {
                    set instancesDict {}
                    for {set instanceNum 0} {${instanceNum} < ${numInstances}} {incr instanceNum} {
                        # Create accelerator instance dictionary to store information for each instance
                        dict update instancesDict ${instanceNum} instDict {
                            set instDict {}
                            set instRegslicePipelineStages [dict get ${AIT::vars::aitConfig} "regslice_pipeline_stages"]
                            if {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]} {
                                set instRegslicePipelineStages [dict get ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]
                            }

                            AIT::utils::info_msg "Generating instance ${instanceNum} of ${accKey}..."

                            # Create accelerator hierarchy
                            lassign [AIT::templates::ompss_acc ${accName} ${instanceNum}] accHier accIP

                            # Connect clk and rst pins
                            dict update instDict "rst" rst "clk" clk {
                                set rst [AIT::design::connect_reset [get_bd_pins ${accHier}/managed_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]]
                                set clk [AIT::design::connect_clock [get_bd_pins ${accHier}/aclk]]
                            }

                            # Store accelerator placement information, if it exists
                            if {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "placement"]} {
                                set instSLR [dict get ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "placement"]
                                set memSLR [dict get ${AIT::vars::board} "arch" "slr" "memory"]
                                set hwruntimeSLR [dict get ${AIT::vars::board} "arch" "slr" "memory"]
                                dict set instDict "placement" ${instSLR}

                                append accConstrStr "add_cells_to_pblock \
                                    \[get_pblocks slr${instSLR}_pblock\] \
                                    \[get_cells */${accName}_${instanceNum}/${accName}_ompss\]\n"
                                append accConstrStr "add_cells_to_pblock \
                                    \[get_pblocks slr${instSLR}_pblock\] \
                                    \[get_cells */${accName}_${instanceNum}/accID\]\n"

                                if {${taskCreator}} {
                                    append accConstrStr "add_cells_to_pblock \
                                        \[get_pblocks slr${instSLR}_pblock\] \
                                        \[get_cells */${accName}_${instanceNum}/new_task_spawner\]\n"
                                    append accConstrStr "add_cells_to_pblock \
                                        \[get_pblocks slr${instSLR}_pblock\] \
                                        \[get_cells */${accName}_${instanceNum}/axis_tid_demux\]\n"
                                }
                            }

                            ### AXI-Stream interfaces
                            #dict update instDict "streams" streamsDict {
                            #    set streamsDict {}

                                ## outPort
                            #    dict update streamsDict "outStream" streamDict {
                            #        # Initialize interface dictionary
                            #        set streamDict {}
                            #        dict update streamDict "src" src {
                                        # Check if acc has already AXI-Stream pins instead of handshake
                                        if {[get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_outPort(_V)*?] ne ""} {
                            #                set src [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_outPort(_V)*?]
                                            set outStreamInnerPin [get_bd_intf_pins -regexp ${accIP}/mcxx_outPort(_V)*?]
                                        } elseif {[get_bd_pins -quiet -regexp ${accIP}/mcxx_outPort(_V)*?] ne ""} {
                                            # Create and connect the hsToStreamAdapter
                            #                set src [get_bd_pins -quiet -regexp ${accIP}/mcxx_outPort(_V)*?]
                                            set outStreamInnerPin [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accIP}/mcxx_outPort(_V)*?] ${AIT::vars::accID} ${accName}_${instanceNum}]
                                            if {[dict exists ${instDict} "placement"]} {
                                                append accConstrStr "add_cells_to_pblock \
                                                    \[get_pblocks slr${instSLR}_pblock\] \
                                                    \[get_cells */${accName}_${instanceNum}/Adapter_outPort\]\n"
                                            }
                                        }
                            #        }
                            #    }

                                ## inPort
                            #    dict update streamsDict "inStream" streamDict {
                            #        # Initialize interface dictionary
                            #        set streamDict {}
                            #        dict update streamDict "src" src {
                                        # Check if acc has already AXI-Stream pins instead of handshake
                                        if {[get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_inPort(_V)*?] ne ""} {
                            #                set src [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_inPort(_V)*?]
                                            set inStreamInnerPin [get_bd_intf_pins -regexp ${accIP}/mcxx_inPort(_V)*?]
                                        } elseif {[get_bd_pins -quiet -regexp ${accIP}/mcxx_inPort(_V)*?] ne ""} {
                            #                set src [get_bd_pins -quiet -regexp ${accIP}/mcxx_inPort(_V)*?]
                                            # Create and connect the streamToHsAdapter
                                            set inStreamInnerPin [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accIP}/mcxx_inPort(_V)*?] "" ${accName}_${instanceNum}]
                                            if {[dict exists ${instDict} "placement"]} {
                                                append accConstrStr "add_cells_to_pblock \
                                                    \[get_pblocks slr${instSLR}_pblock\] \
                                                    \[get_cells */${accName}_${instanceNum}/Adapter_inPort\]\n"
                                            }
                                        }
                            #        }
                            #    }

                                ## spawnInPort
                                # If this is a task creator accelerator, instantiate the newtask_spawner
                                if {${taskCreator}} {
                            #        dict update streamsDict "spawnInStream" streamDict {
                            #            # Initialize interface dictionary
                            #            set streamDict {}
                            #            dict update streamDict "src" src {
                                            # Check if acc has already AXI-Stream pins instead of handshake
                                            if {[get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_spawnInPort(_V)*?] ne ""} {
                            #                    set src [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_spawinInPort(_V)*?]
                                                set spawnInAccPin [get_bd_intf_pins -regexp ${accIP}/mcxx_spawnInPort(_V)*?]
                                            } elseif {[get_bd_pins -quiet -regexp ${accIP}/mcxx_spawnInPort(_V)*?] ne ""} {
                            #                    set src [get_bd_pins -quiet -regexp ${accIP}/mcxx_spawnInPort(_V)*?]
                                                # Create and connect the streamToHsAdapter
                                                set spawnInAccPin [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accIP}/mcxx_spawnInPort(_V)*?] "" ${accName}_${instanceNum}]
                                            }
                                            lassign [AIT::AXIS::add_newtask_spawner ${spawnInAccPin} ${inStreamInnerPin} ${outStreamInnerPin} ${imp} ${accName}_${instanceNum}] outStreamInnerPin inStreamInnerPin
                            #            }
                            #        }
                                }

                                # Add accID to outStream AXI-Stream TID bus
                                set outStreamInnerPin [AIT::AXIS::add_accID ${outStreamInnerPin} ${AIT::vars::accID} ${accName}_${instanceNum}]

                                if {[dict exists ${instDict} "placement"]} {
                                    dict set instDict "regslice_pipeline_stages" ${instRegslicePipelineStages}
                                    lassign [AIT::AXIS::add_reg_slice ${inStreamInnerPin} ${hwruntimeSLR} ${instSLR} ${instRegslicePipelineStages} inStream ${accName}_${instanceNum}] inStreamInnerPin regSliceConstrStr
                                    append accConstrStr ${regSliceConstrStr}
                                    lassign [AIT::AXIS::add_reg_slice ${outStreamInnerPin} ${instSLR} ${hwruntimeSLR} ${instRegslicePipelineStages} outStream ${accName}_${instanceNum}] outStreamInnerPin regSliceConstrStr
                                    append accConstrStr ${regSliceConstrStr}
                                } elseif {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]} {
                                    dict set instDict "regslice_pipeline_stages" ${instRegslicePipelineStages}
                                    lassign [AIT::AXIS::add_reg_slice ${inStreamInnerPin} "" "" ${instRegslicePipelineStages} inStream ${accName}_${instanceNum}] inStreamInnerPin regSliceConstrStr
                                    lassign [AIT::AXIS::add_reg_slice ${outStreamInnerPin} "" "" ${instRegslicePipelineStages} outStream ${accName}_${instanceNum}] outStreamInnerPin regSliceConstrStr
                                }
                            #}

                            dict update instDict "interfaces" interfacesDict {
                                set interfacesDict {}

                                ### AXI interfaces
                                ## OMPIF ports
                                if {[get_bd_pins -quiet ${accIP}/ompif_*] ne ""} {
                                    connect_bd_net [get_bd_pins ${AIT::vars::OMPIF}/ompif_rank] [get_bd_pins ${accIP}/ompif_rank]
                                    connect_bd_net [get_bd_pins ${AIT::vars::OMPIF}/ompif_size] [get_bd_pins ${accIP}/ompif_size]
                                }

                                ## Instrumentation port
                                set instrAccPin [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_instr(_V)*?]
                                if {${instrAccPin} ne ""} {
                                    # Create and connect the Adapter_instr
                                    set adapterInstrIP [create_bd_cell -type ip -vlnv bsc:ompss:adapter_instr ${accHier}/Adapter_instr]
                                    connect_bd_intf_net ${instrAccPin} [get_bd_intf_pins ${adapterInstrIP}/event_in]
                                    AIT::design::connect_clock [AIT::design::get_associated_clk_pin ${adapterInstrIP}/event_in]
                                    AIT::design::connect_reset [AIT::design::get_associated_rst_pin [AIT::design::get_associated_clk_pin ${adapterInstrIP}/event_in]] [get_bd_pins system_reset/clk_app_managed_rstn]
                                    set instrInnerPin [get_bd_intf_pins ${adapterInstrIP}/instr_buf]
                                    dict update interfacesDict "instr_buffer" intfDict {
                                        # Initialize interface dictionary
                                        set intfDict {}
                                        dict update intfDict "src" src "width" width "dst" dst {
                                            set src ${instrAccPin}
                                            set width [get_property CONFIG.DATA_WIDTH ${instrAccPin}]
                                            set dst ""
                                        }

                                        if {[dict exists ${instDict} "placement"]} {
                                            lassign [AIT::AXI::add_reg_slice ${instrInnerPin} ${instSLR} ${memSLR} ${instRegslicePipelineStages} instr ${accName}_${instanceNum}] instrInnerPin regSliceConstrStr
                                            append accConstrStr ${regSliceConstrStr}
                                            append accConstrStr "add_cells_to_pblock \
                                                \[get_pblocks slr${instSLR}_pblock\] \
                                                \[get_cells */${accName}_${instanceNum}/Adapter_instr\]\n"
                                        } elseif {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]} {
                                            lassign [AIT::AXI::add_reg_slice ${instrInnerPin} "" "" ${instRegslicePipelineStages} instr ${accName}_${instanceNum}] instrInnerPin regSliceConstrStr
                                        }
                                    }
                                    # Connect instr_buffer pin
                                    set instrHierPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accHier}/instr_buffer]
                                    connect_bd_intf_net ${instrInnerPin} ${instrHierPin}
                                    incr AIT::vars::numEnabledIntfs
                                }

                                # If available, forward the frequency pin
                                if {[get_bd_pins -quiet ${accIP}/mcxx_freqPort*] ne ""} {
                                    # Create and connect constant with freq
                                    set accFreq [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ${accHier}/accFreq]
                                    set_property -dict [list \
                                        CONFIG.CONST_VAL ${::actFreq} \
                                        CONFIG.CONST_WIDTH {10} \
                                    ] ${accFreq}
                                    connect_bd_net [get_bd_pins ${accFreq}/dout] [get_bd_pins ${accIP}/mcxx_freqPort*]
                                }

                                # Connect AXI-Stream pins
                                connect_bd_intf_net [get_bd_intf_pins ${accHier}/inStream] ${inStreamInnerPin}
                                connect_bd_intf_net ${outStreamInnerPin} [get_bd_intf_pins ${accHier}/outStream]
                                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accHier}/outStream] [get_bd_intf_pins ${AIT::vars::HWR}/hwr_inStream/S${AIT::vars::accID}_AXIS]
                                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${AIT::vars::HWR}/hwr_outStream/M${AIT::vars::accID}_AXIS] [get_bd_intf_pins ${accHier}/inStream]

                                # Mark AXI-Stream pin for debug
                                #if {[dict get ${AIT::vars::aitConfig} "debug_intfs"] eq "stream"} {
                                #    AIT::design::debug_intf [get_bd_intf_pins ${accHier}/inStream]
                                #    AIT::design::debug_intf [get_bd_intf_pins ${accHier}/outStream]
                                #}

                                ## AXI interfaces
                                # Get list of M_AXI interfaces
                                # NOTE: Only handle AXI interfaces generated by mcxx, which start with the "mcxx_" prefix
                                set intfAccPinList [get_bd_intf_pins -regexp -filter {NAME =~ "(m_axi_)?mcxx_.*" && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} ${accIP}/*]

                                # Create accelerator AXI data path and store it in a dictionary
                                foreach intfAccPin ${intfAccPinList} {
                                    # Get pin name and remove leading and trailing unwanted chars
                                    set intfName [regsub -all {(^(m_axi_)?(mcxx_)?|(_V)*$)} [get_property NAME ${intfAccPin}] ""]
                                    dict update interfacesDict ${intfName} intfDict {

                                        # Initialize interface dictionary
                                        set intfDict {}

                                        # Hierarchy inner AXI interface that will be connected to the outer pin
                                        set intfInnerPin ${intfAccPin}

                                        # Hierarchy outer AXI interface that will be connected to memory
                                        set intfHierPin ${accHier}/${intfName}

                                        # Set interface basic information
                                        dict update intfDict "src" src "width" width "dst" dst {
                                            set src ${intfAccPin}
                                            set width [get_property CONFIG.DATA_WIDTH ${intfAccPin}]
                                            set dst ""
                                        }

                                        # Check if data interface is disabled
                                        if {[dict exists ${AIT::vars::userConfig} "accs" ${accKey} "instances" ${instanceNum} "interfaces" ${intfName} "dst"]} {
                                            set intfUserDst [dict get ${AIT::vars::userConfig} "accs" ${accKey} "instances" ${instanceNum} "interfaces" ${intfName} "dst"]
                                            if {[string equal -nocase ${intfUserDst} "none"]} {
                                                dict set intfDict "dst" None
                                                continue
                                            }
                                        }

                                        # Add register slice to AXI pin
                                        if {[dict exists ${instDict} "placement"]} {
                                            lassign [AIT::AXI::add_reg_slice ${intfInnerPin} ${instSLR} ${memSLR} ${instRegslicePipelineStages} ${intfName} ${accName}_${instanceNum}] intfInnerPin regSliceConstrStr
                                            append accConstrStr ${regSliceConstrStr}
                                        } elseif {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]} {
                                            lassign [AIT::AXI::add_reg_slice ${intfInnerPin} "" "" ${instRegslicePipelineStages} ${intfName} ${accName}_${instanceNum}] intfInnerPin regSliceConstrStr
                                        }

                                        # Mark AXI pin for debug
                                        if {[dict exists ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "debug"]
                                            && [dict get ${AIT::vars::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "debug"]} {
                                            dict set intfDict "debug" true
                                        }

                                        set intfHierPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${intfHierPin}]
                                        connect_bd_intf_net ${intfInnerPin} ${intfHierPin}
                                        incr AIT::vars::numEnabledIntfs
                                    }
                                }
                            }

                            # If the accelerator is constrained, create constraints file
                            if {[info exists accConstrStr]} {
                                file mkdir ${projectRootDir}/constraints
                                set accConstrFile [open ${projectRootDir}/constraints/${accName}_${instanceNum}.xdc "w"]
                                puts ${accConstrFile} ${accConstrStr}
                                close ${accConstrFile}
                                unset accConstrStr
                                add_files -fileset constrs_1 -norecurse ${projectRootDir}/constraints/${accName}_${instanceNum}.xdc
                                reorder_files -fileset constrs_1 -back [get_files -quiet ${accName}_${instanceNum}.xdc]
                            }

                            # Increase global accelerator id
                            incr AIT::vars::accID

                            regenerate_bd_layout -hierarchy ${accHier}
                            save_bd_design

                            AIT::utils::info_msg "Successfully generated instance ${instanceNum} of ${accKey}"
                        }
                    }
                }
            }
        }
    }
}

AIT::utils::info_msg "Accelerators instantiated"

# We have to validate the design in order to propagate metadata
# Some interfaces signals might be optimized by Vivado (e.g. read/write buses)
validate_bd_design -quiet

# If we are generating a design for a discrete FPGA that uses DDR, check for
# available AXI interfaces to memory and instantiate a nested interconnect, if necessary
set avMemIntfs [AIT::design::get_available_mem_intfs]
if {[dict get ${AIT::vars::board} "arch" "device"] eq "alveo"
    && [dict get ${AIT::vars::board} "memory" "type"] eq "ddr"
    && ${AIT::vars::numEnabledIntfs} > ${avMemIntfs}} {

    foreach memIntf ${AIT::vars::memIntfsList} {
        if {[dict get ${memIntf} "role"] eq "slave"} {
            AIT::AXI::create_nested_interconnect ${memIntf} [dict get ${AIT::vars::board} "memory" "num_banks"]
        }
    }
}

# Check if there are enough available AXI interfaces to memory
if {${AIT::vars::numEnabledIntfs} > [AIT::design::get_available_mem_intfs]} {
    AIT::utils::error_msg "Insufficient available AXI interfaces to memory (${AIT::vars::numEnabledIntfs} > [AIT::design::get_available_mem_intfs])"
}

AIT::utils::info_msg "Connecting data interfaces to memory..."

# Connect data pins to memory interconnection
dict for {accKey accDict} [dict get ${AIT::vars::aitJsonDict} "accs"] {
    dict for {instanceKey instanceDict} [dict get ${accDict} "instances"] {
        dict for {interfaceKey interfaceDict} [dict get ${instanceDict} "interfaces"] {
            dict with AIT::vars::aitJsonDict "accs" ${accKey} "instances" ${instanceKey} "interfaces" ${interfaceKey} {

                # Check if interface is disabled or has a specified dst
                if {[string equal -nocase ${dst} "none"]} {
                    AIT::utils::info_msg "Interface ${accKey}_${instanceKey}/${interfaceKey} disabled"
                    continue
                } else {
                    if {[dict get ${AIT::vars::aitConfig} "memory_interleaving_stride"]} {
                        AIT::AXI::add_addrInterleaver [get_bd_intf_pins ${accKey}_${instanceKey}/${interfaceKey}] ${interfaceKey}
                    }

                    if {[dict exists ${AIT::vars::userConfig} "accs" ${accKey} "instances" ${instanceKey} "interfaces" ${interfaceKey} "dst"]} {
                        set dst [dict get [AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${accKey}_${instanceKey}/${interfaceKey}] [dict get ${AIT::vars::userConfig} "accs" ${accKey} "instances" ${instanceKey} "interfaces" ${interfaceKey} "dst"]] "num"]
                    } else {
                        set dst [dict get [AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${accKey}_${instanceKey}/${interfaceKey}]] "num"]
                    }

                    # Mark interface for debug
                    if {[dict exists ${interfaceDict} "debug"]
                        && [dict get ${interfaceDict} "debug"]} {
                        AIT::design::debug_intf ${accKey}_${instanceKey}/${interfaceKey}
                        AIT::utils::info_msg "Interface ${accKey}_${instanceKey}/${interfaceKey} marked for debug"
                    }

                    AIT::utils::info_msg "Interface ${accKey}_${instanceKey}/${interfaceKey} connected to memory interface ${dst}"
                }
            }
        }
    }
}
save_bd_design -quiet

AIT::utils::info_msg "Data interfaces connected"

# If enabled, add and connect hwcounter IP
if {[dict get ${AIT::vars::aitConfig} "hwcounter"]
    || [dict get ${AIT::vars::aitConfig} "hwinst"]} {

    create_bd_cell -type module -reference bsc_axiu_hwcounter HW_Counter

    if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
        || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {

        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins HW_Counter/S_AXI] 1
    } else {
        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins HW_Counter/S_AXI]
    }

    save_bd_design -quiet
}

# Add SLR constraints to static logic
# Should be defined in board's procs.tcl
if {[dict exists ${AIT::vars::board} "arch" "slr"] && ![dict get ${AIT::vars::aitConfig} "disable_static_constraints"]} {
    set staticConstrStr [AIT::board::static_logic_register_slices]
    if {[string length ${staticConstrStr}]} {
        file mkdir ${projectRootDir}/constraints
        set staticConstrFile [open ${projectRootDir}/constraints/[dict get ${AIT::vars::board} "name"]_ompss.xdc "w"]
        puts ${staticConstrFile} ${staticConstrStr}
        close ${staticConstrFile}
        add_files -fileset constrs_1 -norecurse constraints/[dict get ${AIT::vars::board} "name"]_ompss.xdc
        reorder_files -fileset constrs_1 -back [get_files [dict get ${AIT::vars::board} "name"]_ompss.xdc]
    }
}

# Some boards require to configure IPs after acc instantiation
if {"AIT::board::after_acc_configuration" in [info procs AIT::board::after_acc_configuration]} {
    AIT::board::after_acc_configuration
}

# Propagate parameters
validate_bd_design -force -quiet
save_bd_design -quiet

# Wipe clean address map
delete_bd_objs [get_bd_addr_segs]

AIT::utils::info_msg "Configuring address map..."

AIT::board::configure_address_map

# Map hwruntime queues to address space
dict for {bdAddrSegmentKey bdAddrSegmentDict} ${bdAddrSegmentsDict} {
    dict with bdAddrSegmentDict {
        if {${size}} {
            assign_bd_address [get_bd_addr_segs ${bdSegName}] -range ${size} -offset ${addr}
        }
    }
}
save_bd_design -quiet

AIT::utils::info_msg "Address map configured"

# Generate xtasks.config binary string and POM scheduler parameters
# We have to include OMPIF accelerators here
set schedCount 0
set schedAccID 0
set schedTtype 0
set accID 0
set i 0
append xtasksConfigStr "type\t#ins\tname\tfreq"
dict for {accKey accDict} [dict get ${AIT::vars::aitJsonDict} "accs"] {
    dict with accDict {
        set accHash ${type}
        set accNumInstances ${num_instances}
        set accName [string range ${name} 0 30]

        set binWord [expr {${accNumInstances} | ((${accHash} & 0xFFFF) << 16)}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        set binWord [expr {(${accHash} >> 16) | (((${::actFreq}*1000) & 0xFF) << 24)}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        set binWord [expr {(${::actFreq}*1000) >> 8}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        # Max length is 31 characters, but there are 8 padding bits at the end
        set accNameBin "${accName}[string repeat "\0" [expr {32 - [string length ${accName}]}]]"
        # Convert ascii to hexadecimal string
        append xtasksBinStr [AIT::utils::ascii_to_hex ${accNameBin}]
        append xtasksConfigStr "\n[format "%019d" ${accHash}]\t"
        append xtasksConfigStr "[format "%03d" ${accNumInstances}]\t"
        append xtasksConfigStr "[format "%-32s" ${accName}]"
        append xtasksConfigStr "[format "%03d" ${::actFreq}]"

        set schedCount [expr {${schedCount} | ((${accNumInstances}-1) << ${i}*8)}]
        set schedAccID [expr {${schedAccID} | (${accID} << ${i}*8)}]
        set schedTtype [expr {${schedTtype} | ((${accHash} & 0xFFFFFFFF) << ${i}*32)}]
        incr accID ${accNumInstances}
        incr i
    }
}
if {[dict get ${AIT::vars::aitConfig} "ompif"]} {
    foreach {accHash accNumInstances accName} {4294967299 1 ompif_message_sender 4294967300 1 ompif_message_receiver} {
        AIT::AXIS::add_accID soCmd ${accID} ${AIT::vars::OMPIF}/[regsub -all {^ompif_} ${accName} ""]
        connect_bd_intf_net [get_bd_intf_pins ${AIT::vars::HWR}/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins ${AIT::vars::OMPIF}/inStream_[regsub -all {^ompif_message_} ${accName} ""]]
        connect_bd_intf_net [get_bd_intf_pins ${AIT::vars::OMPIF}/outStream_[regsub -all {^ompif_message_} ${accName} ""]] [get_bd_intf_pins ${AIT::vars::HWR}/hwr_inStream/S${accID}_AXIS]
        set binWord [expr {${accNumInstances} | ((${accHash} & 0xFFFF) << 16)}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        set binWord [expr {(${accHash} >> 16) | (((${::actFreq}*1000) & 0xFF) << 24)}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        set binWord [expr {(${::actFreq}*1000) >> 8}]
        append xtasksBinStr [format "%08X\n" ${binWord}]
        # Max length is 31 characters, but there are 8 padding bits at the end
        set accNameBin "${accName}[string repeat "\0" [expr {32 - [string length ${accName}]}]]"
        # Convert ascii to hexadecimal string
        append xtasksBinStr [AIT::utils::ascii_to_hex ${accNameBin}]
        append xtasksConfigStr "\n[format "%019d" ${accHash}]\t"
        append xtasksConfigStr "[format "%03d" ${accNumInstances}]\t"
        append xtasksConfigStr "[format "%-32s" ${accName}]"
        append xtasksConfigStr "[format "%03d" ${::actFreq}]"

        set schedCount [expr {${schedCount} | ((${accNumInstances}-1) << ${i}*8)}]
        set schedAccID [expr {${schedAccID} | (${accID} << ${i}*8)}]
        set schedTtype [expr {${schedTtype} | ((${accHash} & 0xFFFFFFFF) << ${i}*32)}]
        incr accID ${accNumInstances}
        incr i
    }
}

set xtasksConfigFile [open ${projectRootDir}/../[dict get ${AIT::vars::aitConfig} "name"].xtasks.config "w"]
puts ${xtasksConfigFile} ${xtasksConfigStr}
close ${xtasksConfigFile}

if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
    set_property -dict [list \
        CONFIG.SCHED_COUNT 0x[AIT::utils::long_int_to_hex 128 ${schedCount}] \
        CONFIG.SCHED_ACCID 0x[AIT::utils::long_int_to_hex 128 ${schedAccID}] \
        CONFIG.SCHED_TTYPE 0x[AIT::utils::long_int_to_hex 512 ${schedTtype}] \
    ] [get_bd_cells -hierarchical Picos_OmpSs_Manager]
}

# Fixed-length fields
set bitinfoCoeStr "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
append bitinfoCoeStr [format %08x ${AIT::vars::bitinfoVersion}]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "num_instances"]]\n
append bitinfoCoeStr [format %08x [AIT::design::generate_bitinfo_bitmap]]\n
append bitinfoCoeStr [format %08x [expr {${AIT::vars::aitMajorVersion}<<22 | ${AIT::vars::aitMinorVersion}<<11 | ${AIT::vars::aitPatchVersion}}]]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "wrapper_version"]]\n
append bitinfoCoeStr [format %08x [AIT::board::get_base_freq]]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "memory_interleaving_stride"]]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdInQueueHwruntime" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdInQueueHwruntime" "addr"] 2 9]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "cmdin_subqueue_len"]]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdOutQueueHwruntime" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdOutQueueHwruntime" "addr"] 2 9]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "cmdout_subqueue_len"]]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnInQueueHwruntime" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnInQueueHwruntime" "addr"] 2 9]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "spawnin_queue_len"]]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnOutQueueHwruntime" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnOutQueueHwruntime" "addr"] 2 9]\n
append bitinfoCoeStr [format %08x [dict get ${AIT::vars::aitConfig} "spawnout_queue_len"]]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "managedReset" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "managedReset" "addr"] 2 9]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "hwcounter" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "hwcounter" "addr"] 2 9]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "pomAxilite" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "pomAxilite" "addr"] 2 9]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "powerMonitor" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "powerMonitor" "addr"] 2 9]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "thermalMonitor" "addr"] 10 17]\n
append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "thermalMonitor" "addr"] 2 9]\n

# Calculate the bitinfo offset of each variable-length field
# Variable-length fields are appended next to the fixed-length fields
set xtasksConfigAccSize 44
set numStaticFields 35
set dynamicFieldSizes [list \
    [expr {${xtasksConfigAccSize}*[dict get ${AIT::vars::aitConfig} "num_accs"]}] \
    [string length ${AIT::vars::aitCall}] \
    [string length [get_property VLNV [get_bd_cells ${AIT::vars::HWR}/Picos_OmpSs_Manager]]] \
    [string length [dict get ${AIT::vars::aitConfig} "bitinfo_note"]] \
]
set offset ${numStaticFields}
foreach size ${dynamicFieldSizes} {
    lappend dynamicFieldOffsets ${offset}
    incr offset [expr {int(ceil(${size}/4.))}]
}
set bitinfoLen ${offset}
if {${bitinfoLen} > 1024} {
    AIT::utils::error_msg "Bitinfo length (${bitinfoLen}) is greater than its mapped region (1024)"
}

foreach dynamicFieldSize ${dynamicFieldSizes} dynamicFieldOffset ${dynamicFieldOffsets} {
    append bitinfoCoeStr [format %08X [expr {${dynamicFieldSize} | (${dynamicFieldOffset} << 16)}]]\n
}
append bitinfoCoeStr [format %08x ${AIT::vars::userID}]\n

# Set the board memory for discrete devices
if {[dict get ${AIT::vars::board} "arch" "device"] eq "alveo"} {
    if {[dict exists ${AIT::vars::board} "memory" "size"]} {
        set size [dict get ${AIT::vars::board} "memory" "size"]
    } else {
        set size [expr {[dict get ${AIT::vars::board} "memory" "bank_size"]*[dict get ${AIT::vars::board} "memory" "num_banks"]}]
    }
    set size [expr {${size}/2**30}]
} else {
    set size 0
}
append bitinfoCoeStr [format %08x ${size}]\n

# Variable-length fields
append bitinfoCoeStr ${xtasksBinStr}
append bitinfoCoeStr [AIT::utils::ascii_to_hex ${AIT::vars::aitCall}]
append bitinfoCoeStr [AIT::utils::ascii_to_hex [get_property VLNV [get_bd_cells ${AIT::vars::HWR}/Picos_OmpSs_Manager]]]
append bitinfoCoeStr [AIT::utils::ascii_to_hex [dict get ${AIT::vars::aitConfig} "bitinfo_note"]]

# Create bitinfo.coe file
set bitinfoCoeFile [open ${projectRootDir}/bitinfo.coe "w"]
puts ${bitinfoCoeFile} ${bitinfoCoeStr}
close ${bitinfoCoeFile}

# Load bitinfo coe file
set_property -dict [list \
    CONFIG.Write_Depth_A ${bitinfoLen} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File ${projectRootDir}/bitinfo.coe \
] [get_bd_cells bitinfo]

# Update outdated IPs
update_ip_catalog -rebuild -scan_changes
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS != {}]

# If available, execute the user defined post-design tcl script
if {[file exists ${projectRootDir}/user/tcl/scripts/userPostDesign.tcl]} {
    if {[catch {source -notrace ${projectRootDir}/user/tcl/scripts/userPostDesign.tcl}]} {
        AIT::utils::error_msg "Failed sourcing board post base design"
    }
}

# Regenerate layout and validate BD
regenerate_bd_layout
regenerate_bd_layout -routing
if {[catch {validate_bd_design -force}]} {
    save_bd_design
    AIT::utils::error_msg "Block Design could not be validated"
}

AIT::board::generate_wrapper

update_compile_order -fileset sources_1

# Save Block Design
save_bd_design

# Generate output files
set aitJsonFile [open ${projectRootDir}/../[dict get ${AIT::vars::aitConfig} "name"].ait.json "w"]
puts ${aitJsonFile} [AIT::utils::compile_json {dict accs {dict * {dict instances {dict * {dict interfaces {dict * dict}}}}}} ${AIT::vars::aitJsonDict}]
close ${aitJsonFile}
