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
set projectRootDir [file normalize ${scriptDir}/../..]

# Cleanup files
file delete ${projectRootDir}/[dict get ${AIT::project::aitConfig} "name"].ait.json

# Search for a valid board part
if [dict exists ${AIT::project::board} "board_part"] {
    set boardFound False
    foreach boardName [dict get ${AIT::project::board} "board_part"] {
        lassign [split ${boardName} {:}] vendorName shortName
        if {[version -short] >= 2025.1} {
            # In versions newer than 2025.1, we have to install the board part through the Xilinx Board Store
            xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
            xhub::install -quiet [xhub::get_xitems -quiet ${vendorName}:xilinx_board_store:${shortName}:*]
            xhub::update -quiet [xhub::get_xitems -quiet ${vendorName}:xilinx_board_store:${shortName}:*]
            set_param board.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]
        }
        set boardPart [get_board_parts -latest_file_version -quiet ${vendorName}:${shortName}:*]
        if {${boardPart} ne ""} {
            set boardFound True
            break
        }
    }
    if {!${boardFound}} {
        AIT::utils::error_msg "Board part ([string trim [dict get ${AIT::project::board} "board_part"]]) is missing, design will fail. Please add the corresponding board files to the Vivado installation"
    }
}

# Create project and set board files
create_project -force [dict get ${AIT::project::aitConfig} "name"] [dict get ${AIT::project::aitConfig} "name"] -part [dict get ${AIT::project::board} "chip_part"]

dict set AIT::project::aitJsonDict "project_name" [dict get ${AIT::project::aitConfig} "name"]
dict set AIT::project::aitJsonDict "user_id" ${AIT::project::userID}

# Set project properties:
# Repository path
# Do not generate simulation scripts
# Synthesis target language
set_property -dict [list \
    ip_repo_paths {HLS} \
    sim.ip.auto_export_scripts {false} \
    target_language [dict get ${AIT::project::aitConfig} "target_language"]
] [current_project]

# Set board part, at this point we should already know that the part is available
if [dict exists ${AIT::project::board} "board_part"] {
    dict set AIT::project::aitJsonDict "board_part" ${boardPart}
    set_property -dict [list \
        board_part ${boardPart}
    ] [current_project]
}

# If enabled, set cache location
if {![dict get ${AIT::project::aitConfig} "disable_IP_caching"]} {
    config_ip_cache -import_from_project -use_cache_location [dict get ${AIT::project::aitConfig} "IP_cache_location"]
}

# Suppress known warning and critical warning messages
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
if [file isdirectory ${projectRootDir}/IPs] {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ${projectRootDir}/IPs" [current_project]
    update_ip_catalog
    foreach IP [glob -nocomplain ${projectRootDir}/IPs/*.zip] {
        AIT::utils::info_msg "Adding auxiliary IP ${IP}"
        update_ip_catalog -add_ip ${IP} -repo_path ${projectRootDir}/IPs
    }
    foreach IP [glob -nocomplain ${projectRootDir}/IPs/*.{v,vhdl}] {
        AIT::utils::info_msg "Adding auxiliary IP ${IP}"
        import_files -norecurse ${IP}
        update_ip_catalog
    }
    AIT::utils::info_msg "Auxiliary IPs sucessfully added"
}

# If exists, add board IP repository
if [file isdirectory ${projectRootDir}/board/IPs] {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ${projectRootDir}/board/IPs" [current_project]
    update_ip_catalog
    foreach IP [glob -nocomplain ${projectRootDir}/board/IPs/*.zip] {
        AIT::utils::info_msg "Adding board IP ${IP}"
        update_ip_catalog -add_ip ${IP} -repo_path ${projectRootDir}/board/IPs
    }
    AIT::utils::info_msg "Board IPs sucessfully added"
}

# Update IP catalog
update_ip_catalog

# If exists, add constraints file
if [file isdirectory ${projectRootDir}/board/constraints] {
    add_files -fileset constrs_1 -norecurse ${projectRootDir}/board/constraints
    reorder_files -fileset constrs_1 -front [get_files -quiet create_pblocks.xdc]
    if {![dict get ${AIT::project::aitConfig} "power_monitor"]} {
        remove_files -fileset constrs_1 [get_files -quiet power_monitor.xdc]
    }
    if {![dict get ${AIT::project::aitConfig} "ompif"]} {
        remove_files -fileset constrs_1 [get_files -quiet ompif.xdc]
    }
    if [dict get ${AIT::project::aitConfig} "disable_static_constraints"] {
        remove_files -fileset constrs_1 [get_files -quiet board_static.xdc]
    }
}

# Generate board base design from template
AIT::templates::base_design [dict get ${AIT::project::aitConfig} "name"]

# Open Block Design
open_bd_design [get_files [dict get ${AIT::project::aitConfig} "name"]_design.bd]

# Set Out-Of-Context synthesis
set_property synth_checkpoint_mode {Hierarchical} [get_files [current_bd_design].bd]

# If available, execute the user defined pre-design tcl script
if [file exists ${projectRootDir}/user/tcl/userPreDesign.tcl] {
    AIT::utils::info_msg "Loading user pre-design script"
    if [catch {source -notrace ${projectRootDir}/user/tcl/userPreDesign.tcl}] {
        AIT::utils::error_msg "Failed sourcing board pre base design"
    }
}

# Initialize board base design with required IPs
AIT::design::init_bd

if [dict get ${AIT::project::aitConfig} "memory_interleaving_stride"] {
    dict set AIT::project::aitJsonDict "interleaving" [dict get ${AIT::project::aitConfig} "memory_interleaving_stride"]
}

set accID 0
set accTypeID 0
set enabledIntfsDict [dict create]
set schedCount 0
set schedAccID 0
set schedTtype 0
set xtasksConfigStr "type\t#ins\tname\tfreq"
set AIT::project::xtasksConfigBin ""

# Import accelerators json
dict set AIT::project::aitJsonDict "accs" ${AIT::project::accs}
if [dict exists ${AIT::project::userConfig} "interface_groups"] {
    dict set AIT::project::aitJsonDict "interface_groups" [dict get ${AIT::project::userConfig} "interface_groups"]
}

AIT::utils::info_msg "Instantiating accelerators..."

dict with AIT::project::aitJsonDict {
    dict for {accKey accDict} ${accs} {
        dict with accs {
            ##nagelfar variable accKey varName
            dict with ${accKey} {

                # Get variables from the accelerators json
                set accHash ${type}
                set accName ${name}
                set numInstances ${num_instances}
                set taskCreator ${task_creation}

                # Set hwruntime parameters for this accelerator type
                set schedCount [expr {${schedCount} | ((${numInstances}-1) << ${accTypeID}*8)}]
                set schedAccID [expr {${schedAccID} | (${accID} << ${accTypeID}*8)}]
                set schedTtype [expr {${schedTtype} | ((${accHash} & 0xFFFFFFFF) << ${accTypeID}*32)}]

                # Set xtasks config string for this accelerator type
                append xtasksConfigStr "\n[format "%019d" ${accHash}]\t"
                append xtasksConfigStr "[format "%03d" ${numInstances}]\t"
                append xtasksConfigStr "[format "%-32s" [string range ${accName} 0 30]]"
                append xtasksConfigStr "[format "%03d" ${::actFreq}]"

                # Set xtasks config bin for this accelerator type
                set binWord [expr {${numInstances} | ((${accHash} & 0xFFFF) << 16)}]
                append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
                set binWord [expr {(${accHash} >> 16) | (((${::actFreq}*1000) & 0xFF) << 24)}]
                append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
                set binWord [expr {(${::actFreq}*1000) >> 8}]
                append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
                # Max length is 31 characters, but there are 8 padding bits at the end
                set accNameBin "${accName}[string repeat "\0" [expr {32 - [string length ${accName}]}]]"
                # Convert ascii to hexadecimal string
                append AIT::project::xtasksConfigBin [AIT::utils::ascii_to_hex ${accNameBin}]

                # Create accelerator instances dictionary to store each instance dictionary
                dict update ${accKey} "instances" instancesDict {
                    set instancesDict {}
                    for {set instanceNum 0} {${instanceNum} < ${numInstances}} {incr instanceNum} {
                        # Create accelerator instance dictionary to store information for each instance
                        dict update instancesDict ${instanceNum} instDict {
                            set instDict {}
                            set instRegslicePipelineStages [dict get ${AIT::project::aitConfig} "regslice_pipeline_stages"]
                            if [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"] {
                                set instRegslicePipelineStages [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"]
                            }

                            AIT::utils::info_msg "Generating instance ${instanceNum} of ${accKey}..."

                            # Create accelerator hierarchy
                            lassign [AIT::templates::ompss_acc ${accName} ${instanceNum}] accHier accIP

                            # Connect clk and rst pins
                            dict set instDict "rst" [AIT::resets::connect_reset [get_bd_pins ${accHier}/managed_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]]
                            dict set instDict "clk" [AIT::clocks::connect_clock [get_bd_pins ${accHier}/aclk]]

                            # Store accelerator placement information, if it exists
                            if [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "placement"] {
                                set instSLR [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "placement"]
                                set memSLR [dict get ${AIT::project::board} "arch" "slr" "memory"]
                                set hwruntimeSLR [dict get ${AIT::project::board} "arch" "slr" "memory"]
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
                            dict update instDict "streams" streamsDict {
                                set streamsDict {}

                                ## outPort
                                dict update streamsDict "outStream" streamDict {
                                    # Initialize outStream dictionary
                                    set streamDict {}
                                    set outStreamAccPin [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_outPort(_V)*?]
                                    set outStreamInnerPin ${outStreamAccPin}
                                    dict set streamDict "src" ${outStreamAccPin}
                                    if {[dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "outStream" "debug"]
                                        && [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "outStream" "debug"]} {
                                        dict set streamDict "debug" true
                                    }
                                }

                                ## inPort
                                dict update streamsDict "inStream" streamDict {
                                    # Initialize inStream dictionary
                                    set streamDict {}
                                    set inStreamAccPin [get_bd_intf_pins -regexp ${accIP}/mcxx_inPort(_V)*?]
                                    set inStreamInnerPin ${inStreamAccPin}
                                    dict set streamDict "src" ${inStreamAccPin}
                                    if {[dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "inStream" "debug"]
                                        && [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "inStream" "debug"]} {
                                        dict set streamDict "debug" true
                                    }
                                }

                                ## spawnInPort
                                # If this is a task creator accelerator, instantiate the newtask_spawner
                                if {${taskCreator}} {
                                    dict update streamsDict "spawnInStream" streamDict {
                                        # Initialize spawnInStream dictionary
                                        set streamDict {}
                                        set spawnInAccPin [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_spawnInPort(_V)*?]
                                        dict set streamDict "src" ${spawnInAccPin}
                                        lassign [AIT::AXIS::add_newtask_spawner ${spawnInAccPin} ${inStreamInnerPin} ${outStreamInnerPin} ${imp} ${accName}_${instanceNum}] outStreamInnerPin inStreamInnerPin
                                        if {[dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "spawnInStream" "debug"]
                                            && [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "streams" "spawnInStream" "debug"]} {

                                            AIT::design::debug_intf ${spawnInAccPin}
                                            dict set streamDict "debug" true
                                        }
                                    }
                                }

                                # Add accID to outStream AXI-Stream TID bus
                                set outStreamInnerPin [AIT::AXIS::add_accID ${outStreamInnerPin} ${accID} ${accName}_${instanceNum}]

                                if [dict exists ${instDict} "placement"] {
                                    dict set instDict "regslice_pipeline_stages" ${instRegslicePipelineStages}
                                    lassign [AIT::AXIS::add_reg_slice ${inStreamInnerPin} ${hwruntimeSLR} ${instSLR} ${instRegslicePipelineStages} inStream ${accName}_${instanceNum}] inStreamInnerPin regSliceConstrStr
                                    append accConstrStr ${regSliceConstrStr}
                                    lassign [AIT::AXIS::add_reg_slice ${outStreamInnerPin} ${instSLR} ${hwruntimeSLR} ${instRegslicePipelineStages} outStream ${accName}_${instanceNum}] outStreamInnerPin regSliceConstrStr
                                    append accConstrStr ${regSliceConstrStr}
                                } elseif [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"] {
                                    dict set instDict "regslice_pipeline_stages" ${instRegslicePipelineStages}
                                    lassign [AIT::AXIS::add_reg_slice ${inStreamInnerPin} "" "" ${instRegslicePipelineStages} inStream ${accName}_${instanceNum}] inStreamInnerPin regSliceConstrStr
                                    lassign [AIT::AXIS::add_reg_slice ${outStreamInnerPin} "" "" ${instRegslicePipelineStages} outStream ${accName}_${instanceNum}] outStreamInnerPin regSliceConstrStr
                                }

                                # Connect AXI-Stream pins
                                connect_bd_intf_net [get_bd_intf_pins ${accHier}/inStream] ${inStreamInnerPin}
                                connect_bd_intf_net ${outStreamInnerPin} [get_bd_intf_pins ${accHier}/outStream]
                                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accHier}/outStream] [get_bd_intf_pins ${AIT::templates::hwruntime::hier}/hwr_inStream/S${accID}_AXIS]
                                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${AIT::templates::hwruntime::hier}/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins ${accHier}/inStream]

                                if {[dict exists ${streamsDict} "inStream" "debug"]
                                    && [dict get ${streamsDict} "inStream" "debug"]} {

                                    AIT::design::debug_intf ${inStreamAccPin}
                                }

                                if {[dict exists ${streamsDict} "outStream" "debug"]
                                    && [dict get ${streamsDict} "outStream" "debug"]} {

                                    AIT::design::debug_intf ${outStreamAccPin}
                                }
                            }

                            dict update instDict "interfaces" interfacesDict {
                                set interfacesDict {}

                                ### AXI interfaces
                                ## OMPIF ports
                                if {[get_bd_pins -quiet ${accIP}/ompif_*] ne ""} {
                                    connect_bd_net [get_bd_pins ${AIT::templates::OMPIF::hier}/ompif_rank] [get_bd_pins ${accIP}/ompif_rank]
                                    connect_bd_net [get_bd_pins ${AIT::templates::OMPIF::hier}/ompif_size] [get_bd_pins ${accIP}/ompif_size]
                                }

                                ## Instrumentation port
                                set instrAccPin [get_bd_intf_pins -quiet -regexp ${accIP}/mcxx_instr(_V)*?]
                                if {${instrAccPin} ne ""} {
                                    # Create and connect the instrumentation_adapter
                                    set instrAdapterIP [create_bd_cell -type ip -vlnv bsc:ompss:instrumentation_adapter ${accHier}/instrumentation_adapter]
                                    connect_bd_intf_net ${instrAccPin} [get_bd_intf_pins ${instrAdapterIP}/event_in]
                                    AIT::clocks::connect_clock [AIT::clocks::get_associated_clk_pin ${instrAdapterIP}/event_in]
                                    AIT::resets::connect_reset [AIT::resets::get_associated_rst_pin [AIT::clocks::get_associated_clk_pin ${instrAdapterIP}/event_in]] [get_bd_pins system_reset/clk_app_managed_rstn]
                                    set instrInnerPin [get_bd_intf_pins ${instrAdapterIP}/instr_buf]
                                    dict update interfacesDict "instr_buffer" intfDict {
                                        # Initialize interface dictionary
                                        set intfDict {}
                                        dict set intfDict "src" ${instrAccPin}

                                        if [dict exists ${instDict} "placement"] {
                                            lassign [AIT::AXI::add_reg_slice ${instrInnerPin} ${instSLR} ${memSLR} ${instRegslicePipelineStages} instr ${accName}_${instanceNum}] instrInnerPin regSliceConstrStr
                                            append accConstrStr ${regSliceConstrStr}
                                            append accConstrStr "add_cells_to_pblock \
                                                \[get_pblocks slr${instSLR}_pblock\] \
                                                \[get_cells */${accName}_${instanceNum}/instrumentation_adapter\]\n"
                                        } elseif [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"] {
                                            lassign [AIT::AXI::add_reg_slice ${instrInnerPin} "" "" ${instRegslicePipelineStages} instr ${accName}_${instanceNum}] instrInnerPin regSliceConstrStr
                                        }
                                    }
                                    # Connect instr_buffer pin
                                    set instrHierPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accHier}/instr_buffer]
                                    connect_bd_intf_net ${instrInnerPin} ${instrHierPin}

                                    if {[dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" "instr_buffer" "debug"]
                                        && [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" "instr_buffer" "debug"]} {

                                        AIT::design::debug_intf ${instrAccPin}
                                        dict set intfDict "debug" true
                                    }

                                    if [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" "instr_buffer" "group"] {
                                        set intfGroup [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" "instr_buffer" "group"]
                                        set intfGroupPin [AIT::AXI::connect_to_intf_group ${accName}_${instanceNum}/instr_buffer ${intfGroup}]/M00_AXI
                                        dict set intfDict "group" ${intfGroup}
                                        dict set enabledIntfsDict ${intfGroupPin} "keyDict" "interface_groups ${intfGroup}"
                                    } else {
                                        dict set enabledIntfsDict ${instrHierPin} "keyDict" "accs ${accName} instances ${instanceNum} interfaces instr_buffer"
                                    }
                                }

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
                                        dict set intfDict "src" ${intfAccPin}
                                        dict set intfDict "width" [get_property CONFIG.DATA_WIDTH ${intfAccPin}]

                                        # Check if data interface is disabled
                                        if [dict exists ${AIT::project::userConfig} "accs" ${accKey} "instances" ${instanceNum} "interfaces" ${intfName} "dst"] {
                                            set intfUserDst [dict get ${AIT::project::userConfig} "accs" ${accKey} "instances" ${instanceNum} "interfaces" ${intfName} "dst"]
                                            dict set intfDict "dst" ${intfUserDst}
                                            if [string equal -nocase ${intfUserDst} "none"] {
                                                AIT::utils::info_msg "Interface ${intfName} disabled"
                                                continue
                                            }
                                        }

                                        # Add register slice to AXI pin
                                        if [dict exists ${instDict} "placement"] {
                                            lassign [AIT::AXI::add_reg_slice ${intfInnerPin} ${instSLR} ${memSLR} ${instRegslicePipelineStages} ${intfName} ${accName}_${instanceNum}] intfInnerPin regSliceConstrStr
                                            append accConstrStr ${regSliceConstrStr}
                                        } elseif [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "regslice_pipeline_stages"] {
                                            lassign [AIT::AXI::add_reg_slice ${intfInnerPin} "" "" ${instRegslicePipelineStages} ${intfName} ${accName}_${instanceNum}] intfInnerPin regSliceConstrStr
                                        }

                                        set intfHierPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${intfHierPin}]
                                        connect_bd_intf_net ${intfInnerPin} ${intfHierPin}

                                        # Mark AXI pin for debug
                                        if {[dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "debug"]
                                            && [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "debug"]} {

                                            AIT::design::debug_intf ${intfAccPin}
                                            dict set intfDict "debug" true
                                        }
                                        if [dict exists ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "group"] {
                                            set intfGroup [dict get ${AIT::project::userConfig} "accs" ${accName} "instances" ${instanceNum} "interfaces" ${intfName} "group"]
                                            set intfGroupPin [AIT::AXI::connect_to_intf_group ${accName}_${instanceNum}/${intfName} ${intfGroup}]/M00_AXI
                                            dict set intfDict "group" ${intfGroup}
                                            dict set enabledIntfsDict ${intfGroupPin} "keyDict" "interface_groups ${intfGroup}"
                                        } else {
                                            dict set enabledIntfsDict ${intfHierPin} "keyDict" "accs ${accName} instances ${instanceNum} interfaces ${intfName}"
                                        }
                                    }
                                }
                            }

                            # If the accelerator is constrained, create constraints file
                            if [info exists accConstrStr] {
                                file mkdir ${projectRootDir}/constraints
                                set accConstrFile [open ${projectRootDir}/constraints/${accName}_${instanceNum}.xdc "w"]
                                puts ${accConstrFile} ${accConstrStr}
                                close ${accConstrFile}
                                unset accConstrStr
                                add_files -fileset constrs_1 -norecurse ${projectRootDir}/constraints/${accName}_${instanceNum}.xdc
                                reorder_files -fileset constrs_1 -back [get_files -quiet ${accName}_${instanceNum}.xdc]
                            }

                            # Increase global accelerator id
                            incr accID

                            regenerate_bd_layout -hierarchy ${accHier}
                            save_bd_design -quiet

                            AIT::utils::info_msg "Successfully generated instance ${instanceNum} of ${accKey}"
                        }
                    }
                }
            }
        }
        incr accTypeID
    }
}

if [dict get ${AIT::project::aitConfig} "ompif"] {
    foreach {accHash accNumInstances accName} {4294967299 1 ompif_message_sender 4294967300 1 ompif_message_receiver} {
        AIT::AXIS::add_accID soCmd ${accID} ${AIT::templates::OMPIF::hier}/[regsub -all {^ompif_} ${accName} ""]
        connect_bd_intf_net [get_bd_intf_pins ${AIT::templates::hwruntime::hier}/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins ${AIT::templates::OMPIF::hier}/inStream_[regsub -all {^ompif_message_} ${accName} ""]]
        connect_bd_intf_net [get_bd_intf_pins ${AIT::templates::OMPIF::hier}/outStream_[regsub -all {^ompif_message_} ${accName} ""]] [get_bd_intf_pins ${AIT::templates::hwruntime::hier}/hwr_inStream/S${accID}_AXIS]

        append xtasksConfigStr "\n[format "%019d" ${accHash}]\t"
        append xtasksConfigStr "[format "%03d" ${accNumInstances}]\t"
        append xtasksConfigStr "[format "%-32s" ${accName}]"
        append xtasksConfigStr "[format "%03d" ${::actFreq}]"

        set schedCount [expr {${schedCount} | ((${accNumInstances}-1) << ${accTypeID}*8)}]
        set schedAccID [expr {${schedAccID} | (${accID} << ${accTypeID}*8)}]
        set schedTtype [expr {${schedTtype} | ((${accHash} & 0xFFFFFFFF) << ${accTypeID}*32)}]
        incr accID ${accNumInstances}
        incr accTypeID

        set binWord [expr {${accNumInstances} | ((${accHash} & 0xFFFF) << 16)}]
        append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
        set binWord [expr {(${accHash} >> 16) | (((${::actFreq}*1000) & 0xFF) << 24)}]
        append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
        set binWord [expr {(${::actFreq}*1000) >> 8}]
        append AIT::project::xtasksConfigBin [format "%08X\n" ${binWord}]
        # Max length is 31 characters, but there are 8 padding bits at the end
        set accNameBin "${accName}[string repeat "\0" [expr {32 - [string length ${accName}]}]]"
        # Convert ascii to hexadecimal string
        append AIT::project::xtasksConfigBin [AIT::utils::ascii_to_hex ${accNameBin}]
    }
}

AIT::utils::info_msg "Accelerators instantiated"

# We have to validate the design in order to propagate metadata
# Some interfaces signals might be optimized by Vivado (e.g. read/write buses)
validate_bd_design -quiet

# If we are generating a design for a discrete FPGA that uses DDR, check for
# available AXI interfaces to memory and instantiate a nested interconnect, if necessary
set avMemIntfs [AIT::design::get_available_mem_intfs]
if {[dict get ${AIT::project::board} "arch" "device"] eq "alveo"
    && [dict get ${AIT::project::board} "memory" "type"] eq "ddr"
    && [dict size ${enabledIntfsDict}] > ${avMemIntfs}} {

    foreach memIntf ${AIT::design::memIntfsList} {
        if {[dict get ${memIntf} "role"] eq "slave"} {
            AIT::AXI::create_nested_interconnect ${memIntf} [dict get ${AIT::project::board} "memory" "num_banks"]
        }
    }
}

# Check if there are enough available AXI interfaces to memory
if {[dict size ${enabledIntfsDict}] > [AIT::design::get_available_mem_intfs]} {
    AIT::utils::error_msg "Insufficient available AXI interfaces to memory ([dict size ${enabledIntfsDict}] > [AIT::design::get_available_mem_intfs])"
}

AIT::utils::info_msg "Connecting data interfaces to memory..."

dict for {intfKey intfVal} ${enabledIntfsDict} {
    set intfDict [dict get ${AIT::project::aitJsonDict} {*}[dict get ${intfVal} "keyDict"]]
    dict with intfDict {
        dict update intfDict "dst" dst {
            if [dict get ${AIT::project::aitConfig} "memory_interleaving_stride"] {
                AIT::AXI::add_addrInterleaver ${intfKey} [regsub -all {(^(m_axi_)?(mcxx_)?|(_V)*$)} [get_property NAME ${intfKey}] ""]
            }

            if [dict exists ${intfDict} "dst"] {
                set dst [dict get [AIT::AXI::connect_to_mem_intf ${intfKey} ${dst}] "num"]
            } else {
                set dst [dict get [AIT::AXI::connect_to_mem_intf ${intfKey}] "num"]
            }

            AIT::utils::info_msg "Connected ${intfKey} to memory interface ${dst}"
        }
    }
    dict set AIT::project::aitJsonDict {*}[dict get ${intfVal} "keyDict"] ${intfDict}
}

save_bd_design -quiet

AIT::utils::info_msg "Data interfaces connected"

# Add SLR constraints to static logic
# Should be defined in board's procs.tcl
if {[dict exists ${AIT::project::board} "arch" "slr"] && ![dict get ${AIT::project::aitConfig} "disable_static_constraints"]} {

    set staticConstrStr [AIT::board::static_logic_register_slices]
    if [string length ${staticConstrStr}] {
        file mkdir ${projectRootDir}/constraints
        set staticConstrFile [open ${projectRootDir}/constraints/[dict get ${AIT::project::board} "name"]_ompss.xdc "w"]
        puts ${staticConstrFile} ${staticConstrStr}
        close ${staticConstrFile}
        add_files -fileset constrs_1 -norecurse constraints/[dict get ${AIT::project::board} "name"]_ompss.xdc
        reorder_files -fileset constrs_1 -back [get_files [dict get ${AIT::project::board} "name"]_ompss.xdc]
    }
}

# Some boards require to configure IPs after acc instantiation
if {"AIT::board::after_acc_configuration" in [info procs AIT::board::after_acc_configuration]} {
    AIT::board::after_acc_configuration
}

# Propagate parameters
validate_bd_design -force -quiet
save_bd_design -quiet

AIT::design::generate_bd_addr_segments_dict
AIT::board::configure_address_map

set xtasksConfigFile [open ${projectRootDir}/../products/[dict get ${AIT::project::aitConfig} "name"].xtasks.config "w"]
puts ${xtasksConfigFile} ${xtasksConfigStr}
close ${xtasksConfigFile}

if [dict get ${AIT::project::aitConfig} "task_creation"] {
    set_property -dict [list \
        CONFIG.SCHED_COUNT 0x[AIT::utils::long_int_to_hex 128 ${schedCount}] \
        CONFIG.SCHED_ACCID 0x[AIT::utils::long_int_to_hex 128 ${schedAccID}] \
        CONFIG.SCHED_TTYPE 0x[AIT::utils::long_int_to_hex 512 ${schedTtype}]
    ] ${AIT::templates::hwruntime::hwruntimeIP}
}

lassign [AIT::design::generate_bitinfo_coe_str] bitinfoCoeStr bitinfoLen

# Create bitinfo.coe file
set bitinfoCoeFile [open ${projectRootDir}/bitinfo.coe "w"]
puts ${bitinfoCoeFile} ${bitinfoCoeStr}
close ${bitinfoCoeFile}

# Load bitinfo coe file
set_property -dict [list \
    CONFIG.Write_Depth_A ${bitinfoLen} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File ${projectRootDir}/bitinfo.coe
] [get_bd_cells bitinfo]

# Update outdated IPs
update_ip_catalog -rebuild -scan_changes
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS != {}]

# If available, execute the user defined post-design tcl script
if [file exists ${projectRootDir}/user/tcl/userPostDesign.tcl] {
    AIT::utils::info_msg "Loading user post-design script"
    if [catch {source -notrace ${projectRootDir}/user/tcl/userPostDesign.tcl}] {
        AIT::utils::error_msg "Failed sourcing board post base design"
    }
}

if {[version -short] >= 2024.2} {
    # We need to restore current_bd_design because upgrade_project does not maintain it
    AIT::utils::info_msg "Migrating available IPs to inline HDL versions"
    set oldBdDesign [current_bd_design .]
    save_bd_design -quiet
    upgrade_project -migrate_to_inline_hdl
    current_bd_design ${oldBdDesign}
}

# Regenerate layout and validate BD
regenerate_bd_layout
regenerate_bd_layout -routing
AIT::utils::info_msg "Validating design..."
if [catch {validate_bd_design -force}] {
    save_bd_design -quiet
    AIT::utils::error_msg "Block Design could not be validated"
}
AIT::utils::info_msg "Design validated"

AIT::utils::info_msg "Generating wrapper..."
AIT::board::generate_wrapper
AIT::utils::info_msg "Wrapper generated"

update_compile_order -fileset sources_1

# Save Block Design
save_bd_design -quiet

# Generate output files
set aitJsonFile [open ${projectRootDir}/../products/[dict get ${AIT::project::aitConfig} "name"].ait.json "w"]
puts ${aitJsonFile} [AIT::utils::dict_to_json ${AIT::project::aitJsonDict}]
close ${aitJsonFile}
