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

# Load auxiliary procedures
if {[catch {source -notrace tcl/scripts/utils.tcl}]} {
    puts "\[AIT\] ERROR: Failed loading auxiliary procedures"
    exit 1
}

# Project variables
AIT::utils::info_msg "Sourcing project variables"
if {[catch {source -notrace tcl/projectVariables.tcl}]} {
    AIT::utils::error_msg "Failed sourcing project variables"
}

# Load board-related procedures
AIT::utils::info_msg "Loading board-related procedures"
if {[catch {source -notrace tcl/scripts/board.tcl}]} {
    AIT::utils::error_msg "Failed board-related procedures"
}

# Load AXI datapath procedures
AIT::utils::info_msg "Loading AXI datapath procedures"
if {[catch {source -notrace tcl/scripts/axi_datapath.tcl}]} {
    AIT::utils::error_msg "Failed loading AXI datapath procedures"
}

# Load AXI-Stream datapath procedures
AIT::utils::info_msg "Loading AXI-Stream datapath procedures"
if {[catch {source -notrace tcl/scripts/axis_datapath.tcl}]} {
    AIT::utils::error_msg "Failed loading AXI-Stream datapath procedures"
}

# If available, overwrite board-specific procedures
if {[file exists board/${::AIT::board}/procs.tcl]} {
    AIT::utils::info_msg "Loading board-specific procedures"
    if {[catch {source -notrace board/${::AIT::board}/procs.tcl}]} {
        AIT::utils::error_msg "Failed overwriting ${::AIT::board} board-specific procedures"
    }
}

## Variables

# Cleanup files
file delete ../${::AIT::name_Project}.datainterfaces.txt
file delete ../${::AIT::name_Project}.debuginterfaces.txt

# Compute addresses
set bd_addr_segments [list \
    [dict create name cmdInQueue bd_seg_name Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr {${::AIT::cmdInSubqueue_len}*${::AIT::num_accs}*8}]] \
    [dict create name cmdOutQueue bd_seg_name Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr {${::AIT::cmdOutSubqueue_len}*${::AIT::num_accs}*8}]] \
    [dict create name managed_rstn bd_seg_name managed_reset/S_AXI/Reg size 4096] \
]
if {${::AIT::enable_spawn_queues}} {
    lappend bd_addr_segments [dict create name spawnInQueue bd_seg_name Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr {${::AIT::spawnInQueue_len}*8}]]
    lappend bd_addr_segments [dict create name spawnOutQueue bd_seg_name Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr {${::AIT::spawnOutQueue_len}*8}]]
}
if {${::AIT::hwcounter} || ${::AIT::hwinst}} {
    lappend bd_addr_segments [dict create name hwcounter bd_seg_name HW_Counter/s_axi/reg0 size 4096]
}
if {${::AIT::enable_pom_axilite}} {
    lappend bd_addr_segments [dict create name pom_axilite bd_seg_name Hardware_Runtime/Picos_OmpSs_Manager/axilite/reg_0 size 16384]
}
if {${::AIT::power_monitor}} {
    lappend bd_addr_segments [dict create name power_monitor bd_seg_name cms_subsystem/s_axi_ctrl/Mem* size [expr {256*1024}]]
}
if {${::AIT::thermal_monitor}} {
    lappend bd_addr_segments [dict create name thermal_monitor bd_seg_name system_management/S_AXI_LITE/Reg size 4096]
}

# Sort the segments in decreasing size to minimize fragmentation when assigning addresses
set bd_addr_segments [lsort -decreasing -command AIT::utils::comp_bd_addr_seg $bd_addr_segments]

set addr_hwruntime_spawnInQueue 0x0000000000000000
set addr_hwruntime_spawnOutQueue 0x0000000000000000
set addr_hwcounter 0x0000000000000000
set addr_pom_axilite 0x0000000000000000
set addr_power_monitor 0x0000000000000000
set addr_thermal_monitor 0x0000000000000000

set bitInfo_offset 0x0
set addr [expr {$bitInfo_offset + 4096}]
for {set i 0} {$i < [llength $bd_addr_segments]} {incr i} {
    set cur_dict [lindex $bd_addr_segments $i]
    set size [dict get $cur_dict size]
    if {$size <= 4096} {
        set size 4096
    } elseif {$size & ($size-1)} { # Not power of 2
        set size_clog2 [expr {int(ceil(log($size)/log(2)))}]
        set size [expr {int(pow(2, $size_clog2))}]
    }
    if {$addr%$size} {
        incr addr [expr {$size - ($addr%$size)}]
    }
    set format_addr [format 0x%016x [expr {[dict get ${::AIT::address_map} "ompss_base_addr"] + $addr}]]
    lset bd_addr_segments $i [dict replace $cur_dict addr $format_addr size $size]

    set name [dict get $cur_dict name]
    if {$name eq "cmdInQueue"} {
        set addr_hwruntime_cmdInQueue $format_addr
    } elseif {$name eq "cmdOutQueue"} {
        set addr_hwruntime_cmdOutQueue $format_addr
    } elseif {$name eq "spawnInQueue"} {
        set addr_hwruntime_spawnInQueue $format_addr
    } elseif {$name eq "spawnOutQueue"} {
        set addr_hwruntime_spawnOutQueue $format_addr
    } elseif {$name eq "hwcounter"} {
        set addr_hwcounter $format_addr
    } elseif {$name eq "pom_axilite"} {
        set addr_pom_axilite $format_addr
    } elseif {$name eq "managed_rstn"} {
        set addr_managed_reset $format_addr
    } elseif {$name eq "power_monitor"} {
        set addr_power_monitor $format_addr
    } elseif {$name eq "thermal_monitor"} {
        set addr_thermal_monitor $format_addr
    }
    incr addr $size
}

variable addr_bitInfo [format 0x%016x [expr {[dict get ${::AIT::address_map} "ompss_base_addr"] + $bitInfo_offset}]]

# Create project and set board files
create_project -force ${::AIT::name_Project} ${::AIT::name_Project} -part ${::AIT::chipPart}
if {[info exists {::AIT::boardPart}]} {
    set board_found False
    foreach board_name ${::AIT::boardPart} {
        set board_part [get_board_parts -latest_file_version ${board_name}:*]
        if {$board_part ne ""} {
            set_property board_part $board_part [current_project]
            set board_found True
            break
        }
    }
    if {! $board_found } {
        AIT::utils::error_msg "Board part (${::AIT::boardPart}) is missing, design will fail. Please add the corresponding board files to the Vivado installation"
    }
}

# Set repository path
set_property ip_repo_paths {HLS} [current_project]

# Do not generate simulation scripts
set_property sim.ip.auto_export_scripts {false} [current_project]

# If enabled, set cache location
if {${::AIT::IP_caching}} {
    config_ip_cache -import_from_project -use_cache_location ${::AIT::path_CacheLocation}
}

# Suppress known messages wrongly marked as critical warnings
set_msg_config -id {[BD 41-237]} -severity {CRITICAL WARNING} -regexp -string {".*Bus Interface property MASTER_TYPE does not match between /(Hardware_Runtime|bitInfo)/.*BRAM_PORT(A|B).* and .*"} -suppress
set_msg_config -id {[BD 41-1753]} -severity WARNING -suppress
set_msg_config -id {[BD_TCL-1002]} -severity WARNING -suppress

# Add BSC auxiliary IPs
if {[file isdirectory IPs]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] IPs" [current_project]
    update_ip_catalog
    foreach {IP} [glob -nocomplain IPs/*.zip] {
        AIT::utils::info_msg "Adding auxiliary IP $IP"
        update_ip_catalog -add_ip $IP -repo_path IPs
    }
    foreach {IP} [glob -nocomplain IPs/*.{v,vhdl}] {
        AIT::utils::info_msg "Adding auxiliary IP $IP"
        import_files -norecurse $IP
    }
    update_ip_catalog
}

# If exists, add board IP repository
if {[file isdirectory board/${::AIT::board}/IPs/]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] board/${::AIT::board}/IPs" [current_project]
    update_ip_catalog
    foreach {IP} [glob -nocomplain board/${::AIT::board}/IPs/*.zip] {
        update_ip_catalog -add_ip $IP -repo_path board/${::AIT::board}/IPs
    }
}

# Update IP catalog
update_ip_catalog

# Generate board base design from template
set argv ${::AIT::name_Project}
if {[catch {source -notrace board/${::AIT::board}/baseDesign.tcl}]} {
    AIT::utils::error_msg "Failed sourcing board base design"
}

# Open Block Design
open_bd_design [get_files ${::AIT::name_Design}.bd]

# Set Out-Of-Context synthesis
set_property synth_checkpoint_mode {Hierarchical} [get_files [current_bd_design].bd]

# If available, execute the user defined pre-design tcl script
if {[file exists tcl/scripts/userPreDesign.tcl]} {
    if {[catch {source -notrace tcl/scripts/userPreDesign.tcl}]} {
        AIT::utils::error_msg "Failed sourcing board pre base design"
    }
}

# Add required common IPs
AIT::board::init_bd

# Add OmpSs Manager template
if {[catch {source -notrace tcl/templates/Picos_OmpSs_Manager.tcl}]} {
    AIT::utils::error_msg "Failed sourcing Picos_OmpSs_Manager template"
}

if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins Hardware_Runtime/S_AXI_GP] M 1
} else {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins Hardware_Runtime/S_AXI_GP] M
}

AIT::board::connect_clock [get_bd_pins Hardware_Runtime/clk]
AIT::board::connect_reset [get_bd_pins Hardware_Runtime/rstn] [get_bd_pins /system_reset/clk_app_rstn]
AIT::board::connect_reset [get_bd_pins Hardware_Runtime/managed_rstn] [get_bd_pins system_reset/clk_app_managed_rstn]

if {${::AIT::hwruntime_interconnect} == "centralized"} {
    set hwruntime_interconnect_script "tcl/scripts/hwr_central_interconnect.tcl"
} else {
    set hwruntime_interconnect_script "tcl/scripts/hwr_dist_interconnect.tcl"
}

# Instantiate hwruntime interconnect tree
if {[catch {source $hwruntime_interconnect_script}]} {
    AIT::utils::error_msg "Failed sourcing $hwruntime_interconnect_script"
}

# Set and get the actual PS frequency
set actFreq [AIT::board::set_and_get_freq ${::AIT::clockFreq}]

save_bd_design

############# Start Block Design generation ############
#### User IPs
set accID 0
set acc_axi_pins []

foreach acc ${::AIT::accs} {
    lassign [split $acc ":"] accHash accNumInstances accName taskCreator

    if {$accName == "ompif_message_sender"} {
        if {[catch {source "tcl/templates/ompif_message_sender.tcl"}]} {
            AIT::utils::error_msg "Failed sourcing ompif_message_sender template"
        }

        connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/M_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${accID}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins ompif_message_sender_0/axis_clk_conv_in/S_AXIS]

        incr accID
        continue
    } elseif {$accName == "ompif_message_receiver"} {
        if {[catch {source "tcl/templates/ompif_message_receiver.tcl"}]} {
            AIT::utils::error_msg "Failed sourcing ompif_message_receiver template"
        }

        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins ompif_message_receiver_0/axis_clk_conv_in/S_AXIS]
        connect_bd_intf_net [get_bd_intf_pins ompif_message_receiver_0/M_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${accID}_AXIS]

        incr accID
        continue
    }

    for {set instanceNum 0} {${instanceNum} < $accNumInstances} {incr instanceNum} {
        # Create accelerator hierarchy
        lassign [AIT::board::create_acc_hier $accName $instanceNum] acc_hier acc_ip

        # Connect clk and rst pins
        AIT::board::connect_clock [get_bd_pins $acc_hier/aclk]
        AIT::board::connect_reset [get_bd_pins $acc_hier/managed_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]

        ## AXI interfaces
        # Get list of M_AXI interfaces
        # Check if task creator memory ports are disabled
        if {${taskCreator} && ${::AIT::disable_creator_ports}} {
            set list_acc_axi_pins [list]
        } else {
            # NOTE: Only handle AXI interfaces generated by mcxx, which start with the "mcxx_" prefix
            set list_acc_axi_pins [get_bd_intf_pins -quiet $acc_ip/m_axi_mcxx_*]
        }

        # Create accelerator AXI data path and store it in a dictionary
        foreach acc_axi_pin $list_acc_axi_pins {
            # Get pin name and remove leading and trailing unwanted chars
            set pin_name [regsub -all {(^m_axi_|(_V)*$)} [get_property NAME $acc_axi_pin] ""]

            # Outermost AXI interface that will be connected to memory
            set hier_inner_axi_pin $acc_axi_pin

            # Add register slice to AXI pin
            if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
                if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                    # No placement info is provided for this instance
                    AIT::utils::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI pins will not be created"
                } else {
                    set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]
                    # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
                    # num_pipelines format: master:middle:slave
                    # Pass unused optional arguments as ""
                    set hier_inner_axi_pin [AIT::AXI::add_reg_slice ${accName}_${instanceNum} $pin_name $slr ${::AIT::board_memory_slr} $hier_inner_axi_pin ${::AIT::regslice_pipeline_stages} acc_]
                }
            }

            # Add address interleaver to AXI pin
            if {${::AIT::interleaving_stride} ne "None"} {
                AIT::AXI::add_addrInterleaver $hier_inner_axi_pin $pin_name $accName $instanceNum
            }

            set hier_outter_axi_pin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $acc_hier/$pin_name]
            connect_bd_intf_net $hier_inner_axi_pin $hier_outter_axi_pin

            lappend acc_axi_pins $hier_outter_axi_pin
        }

        ## AXI-Stream interfaces
        # If available, forward the outPort
        # Check if acc has already AXI-Stream pins instead of handshake
        if {[get_bd_intf_pins -quiet -regexp $acc_ip/mcxx_outPort(_V)*?] ne ""} {
            set hier_outStream [get_bd_intf_pins -regexp $acc_ip/mcxx_outPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp $acc_ip/mcxx_outPort(_V)*?] ne ""} {
            # Create and connect the hsToStreamAdapter
            set hier_outStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp $acc_ip/mcxx_outPort(_V)*?] $accName $instanceNum $accID]
        }

        # If available, forward the inPort
        if {[get_bd_intf_pins -quiet -regexp $acc_ip/mcxx_inPort(_V)*?] ne ""} {
            set hier_inStream [get_bd_intf_pins -regexp $acc_ip/mcxx_inPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp $acc_ip/mcxx_inPort(_V)*?] ne ""} {
            # Create and connect the streamToHsAdapter
            set hier_inStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp $acc_ip/mcxx_inPort(_V)*?] $accName $instanceNum]
        }

        # If this is a task creator, instantiate the newtask_spawner
        if {${taskCreator}} {
            if {[get_bd_intf_pins -quiet -regexp $acc_ip/mcxx_spawnInPort(_V)*?] ne ""} {
                set acc_spawnInStream [get_bd_intf_pins -regexp $acc_ip/mcxx_spawnInPort(_V)*?]
            } elseif {[get_bd_pins -quiet -regexp $acc_ip/mcxx_spawnInPort(_V)*?] ne ""} {
                # Create and connect the streamToHsAdapter
                set acc_spawnInStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp $acc_ip/mcxx_spawnInPort(_V)*?] $accName $instanceNum]
            }

            lassign [AIT::AXIS::add_newtask_spawner $acc_spawnInStream $hier_inStream $hier_outStream $accName $instanceNum] hier_outStream hier_inStream
        }

        set hier_outStream [AIT::AXIS::add_tid_subset_converter $hier_outStream $accID $accName $instanceNum]

        # Add register slice to AXI-Stream pins
        if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
            if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                # No placement info is provided for this instance
                AIT::utils::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI-Stream pins will not be created"
            } else {
                set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]
                set hier_inStream [AIT::AXIS::add_reg_slice ${accName}_${instanceNum} inStream ${::AIT::board_hwruntime_slr} $slr $hier_inStream ${::AIT::regslice_pipeline_stages} acc_]
                set hier_outStream [AIT::AXIS::add_reg_slice ${accName}_${instanceNum} outStream $slr ${::AIT::board_hwruntime_slr} $hier_outStream ${::AIT::regslice_pipeline_stages} acc_]
            }
        }

        ## Other interfaces
        # OMPIF ports
        if {[get_bd_pins -quiet $acc_ip/ompif_*] ne ""} {
             connect_bd_net [get_bd_pins $acc_ip/ompif_rank] [get_bd_pins cluster_rank_slice/Dout]
             connect_bd_net [get_bd_pins $acc_ip/ompif_size] [get_bd_pins cluster_size_slice/Dout]
        }
        # If available, forward the instrumentation pins
        if {[get_bd_intf_pins -quiet -regexp $acc_ip/mcxx_instr(_V)*?] ne ""} {
            # Create and connect the Adapter_instr
            set acc_hier_adapter_instr [create_bd_cell -type ip -vlnv bsc:ompss:adapter_instr $acc_hier/Adapter_instr]
            set_property -dict [list \
                CONFIG.AXI_ADDR_WIDTH {64} \
                CONFIG.COUNTER_WIDTH {64} \
                CONFIG.FIFO_LEN {32} \
                CONFIG.MAX_EVENT_BUF_LEN {128} \
             ] $acc_hier_adapter_instr

            connect_bd_intf_net [get_bd_intf_pins -regexp $acc_ip/mcxx_instr(_V)*?] [get_bd_intf_pins $acc_hier/Adapter_instr/event_in]

            AIT::board::connect_clock [get_bd_pins $acc_hier/Adapter_instr/clk]
            AIT::board::connect_reset [get_bd_pins $acc_hier/Adapter_instr/rstn] [AIT::board::get_rst_net_from_clk_pin [get_bd_pins $acc_hier/Adapter_instr/clk]]

            set instr_inner_axi_pin [get_bd_intf_pins $acc_hier/Adapter_instr/instr_buf]

            if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
                if {!([dict exists ${::AIT::acc_placement} $accName] && ([llength [dict get ${::AIT::acc_placement} $accName]] > ${instanceNum}))} {
                    # No placement info is provided for this instance
                    AIT::utils::warning_msg "No placement info provided for instance ${instanceNum} of ${accName}. Slices for AXI pins will not be created"
                } else {
                    set slr [lindex [dict get ${::AIT::acc_placement} $accName] ${instanceNum}]
                    # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
                    # num_pipelines format: master:middle:slave
                    # Pass unused optional arguments as ""
                    set instr_inner_axi_pin [AIT::AXI::add_reg_slice ${accName}_${instanceNum} mcxx_instr $slr ${::AIT::board_memory_slr} $instr_inner_axi_pin ${::AIT::regslice_pipeline_stages} acc_]
                }
            }
            # Connect instr_buffer pin
            set instr_outter_axi_pin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $acc_hier/instr_buffer]
            connect_bd_intf_net $instr_inner_axi_pin $instr_outter_axi_pin
            lappend acc_axi_pins $instr_outter_axi_pin
        }

        # If available, forward the frequency pin
        if {[get_bd_pins -quiet $acc_ip/mcxx_freqPort*] ne ""} {
            # Create and connect constant with freq
            set accFreq [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant $acc_hier/accFreq]
            set_property -dict [list \
                CONFIG.CONST_VAL $actFreq \
                CONFIG.CONST_WIDTH {10} \
             ] $accFreq
            connect_bd_net [get_bd_pins $accFreq/dout] [get_bd_pins $acc_ip/mcxx_freqPort*]
        }

        # Connect AXI-Stream pins
        connect_bd_intf_net [get_bd_intf_pins $acc_hier/inStream] $hier_inStream
        connect_bd_intf_net $hier_outStream [get_bd_intf_pins $acc_hier/outStream]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $acc_hier/outStream] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${accID}_AXIS]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${accID}_AXIS] [get_bd_intf_pins $acc_hier/inStream]

        # Mark AXI-Stream pin for debug
        if {(${::AIT::debugInterfaces} eq "stream") || (${::AIT::debugInterfaces} eq "both")} {
            AIT::AXIS::mark_debug [get_bd_intf_pins $acc_hier/inStream]
            AIT::AXIS::mark_debug [get_bd_intf_pins $acc_hier/outStream]
        }

        # Increase global acc id
        incr accID

        regenerate_bd_layout -hierarchy $acc_hier
        save_bd_design
    }

}

# If we are generating a design for a discrete FPGA that uses DDR, check for
# available AXI interfaces to memory and instantiate a nested interconnect, if necessary
if {(${::AIT::arch_device} eq "alveo") && ([dict get ${::AIT::address_map} "mem_type"] eq "ddr") && ([llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs])} {
    AIT::board::create_nested_interconnect [get_bd_cells S_AXI_Inter] [dict get ${::AIT::address_map} "mem_num_banks"]
    save_bd_design
}

# Check if there are enough available AXI interfaces to memory
if {[llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs]} {
    AIT::utils::error_msg "Insufficient available AXI interfaces to memory ([llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs])"
}

# Connect data pins to memory interconnection
foreach axi_pin $acc_axi_pins {
    set intf [AIT::board::connect_to_axi_intf $axi_pin S]

    # Mark AXI pin for debug
    if {(${::AIT::debugInterfaces} eq "AXI") || (${::AIT::debugInterfaces} eq "both")} {
        AIT::AXI::mark_debug $axi_pin
    }
}
save_bd_design

# If using it, configure addrInterleaver IP
if {${::AIT::interleaving_stride} ne "None"} {
    set num_banks [dict get ${::AIT::address_map} "mem_num_banks"]
    set lg [expr {log($num_banks)/log(2)}]
    if { floor($lg) - ceil($lg) != 0 } {
        #number of banks is not power of 2
        #   -> use the larger base2 num of banks available
        set num_banks [expr {int(pow(2, floor($lg)))}]
    }

    set addrInterleaver [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:module_ref:bsc_axiu_addrInterleaver:*}]
    set_property -dict [list \
        CONFIG.BANK_SIZE [dict get ${::AIT::address_map} "mem_bank_size"] \
        CONFIG.NUM_BANKS $num_banks \
        CONFIG.STRIDE ${::AIT::interleaving_stride} \
        CONFIG.BASE_ADDR [dict get ${::AIT::address_map} "mem_base_addr"] \
     ] $addrInterleaver
}

# If enabled, add and connect hwcounter IP
if {${::AIT::hwcounter} || ${::AIT::hwinst}} {
    create_bd_cell -type module -reference bsc_axiu_hwcounter HW_Counter

    if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
        AIT::board::connect_to_axi_intf [get_bd_intf_pins HW_Counter/S_AXI] M 1
    } else {
        AIT::board::connect_to_axi_intf [get_bd_intf_pins HW_Counter/S_AXI] M
    }

    save_bd_design
}

# Add slr constraints to static logic
if {(${::AIT::slr_slices} eq "static") || (${::AIT::slr_slices} eq "all")} {
    # Should be defined in board's procs.tcl
    AIT::board::static_logic_register_slices
}

AIT::board::cleanup_bd
save_bd_design

# Mark custom interfaces for debug
if {${::AIT::debugInterfaces} eq "custom"} {
    foreach intf ${::AIT::debugInterfaces_list} {
        set intf_pin [get_bd_intf_pins $intf]
        if {[llength [get_bd_intf_pins -quiet -filter {VLNV =~ xilinx.com:interface:aximm_rtl:*} $intf_pin]]} {
            AIT::AXI::mark_debug $intf_pin
        } elseif {[llength [get_bd_intf_pins -quiet -filter {VLNV =~ xilinx.com:interface:axis_rtl:*} $intf_pin]]} {
            AIT::AXIS::mark_debug $intf_pin
        } else {
            AIT::utils::error_msg "Interface type not recognized ($intf)"
        }
    }
    save_bd_design
}

# Some boards require to configure IPs after acc instantiation
AIT::board::after_acc_configuration

# Propagate parameters
validate_bd_design -force -quiet
save_bd_design

# Wipe clean address map
delete_bd_objs [get_bd_addr_segs]

AIT::board::configure_address_map

# Map hwruntime queues to address space
foreach bd_addr_seg $bd_addr_segments {
    set name [dict get $bd_addr_seg name]
    set addr [dict get $bd_addr_seg addr]
    set range [dict get $bd_addr_seg size]
    set bd_seg_name [dict get $bd_addr_seg bd_seg_name]
    AIT::utils::info_msg "Assign $name BD address, range $range address $addr"
    assign_bd_address [get_bd_addr_segs $bd_seg_name] -range $range -offset $addr
}

# Map bitinfo BRAM to address space
if {(${::AIT::arch_device} ne "simulation") && (${::AIT::arch_device} ne "shell")} {
    assign_bd_address [get_bd_addr_segs bitInfo_BRAM_Ctrl/S_AXI/Mem0] -range 4K -offset $addr_bitInfo
}

# Store real PS frequency in xtasks config file
set config_file [open ../${::AIT::name_Project}.xtasks.config "r"]
set newConfig_file [open ../${::AIT::name_Project}.xtasks.config.new "w"]
gets $config_file line
puts $newConfig_file "type\t#ins\tname\tfreq"
while { [gets $config_file line] >= 0 } {
    set line [string range $line 0 54]
    puts $newConfig_file "$line\t$actFreq"
}
close $config_file
close $newConfig_file
exec mv ../${::AIT::name_Project}.xtasks.config.new ../${::AIT::name_Project}.xtasks.config

# Generate xtasks.config binary string and POM scheduler parameters
set xtasks_bin_str ""
set sched_count 0
set sched_accid 0
set sched_ttype 0
set accid 0
set i 0
foreach acc ${::AIT::accs} {
    lassign [split $acc ":"] accHash accNumInstances accName
    set bin_word [expr {$accNumInstances | (($accHash & 0xFFFF) << 16)}]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    set bin_word [expr {($accHash >> 16) | ((($actFreq*1000) & 0xFF) << 24)}]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    set bin_word [expr {($actFreq*1000) >> 8}]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    if {[string length $accName] > 31} {
        set accName [string range $accName 0 30]
    }
    # Max length is 31 characters, but there are 8 padding bits at the end
    append accName [string repeat "\0" [expr {32 - [string length $accName]}]]
    # Convert ascii to hexadecimal string
    append xtasks_bin_str [AIT::utils::ascii2hex $accName]

    set sched_count [expr {$sched_count | (($accNumInstances-1) << $i*8)}]
    set sched_accid [expr {$sched_accid | ($accid << $i*8)}]
    set sched_ttype [expr {$sched_ttype | (($accHash & 0xFFFFFFFF) << $i*32)}]
    incr accid $accNumInstances
    incr i
}

if {${::AIT::task_creation}} {
    if {[llength ${::AIT::accs}] > 16} {
        AIT::utils::error_msg "Max number of accelerator types supported by POM is 16, but design has [llength ${::AIT::accs}]"
    }
    set_property -dict [list \
        CONFIG.SCHED_COUNT 0x[AIT::utils::long_int_to_hex 128 $sched_count] \
        CONFIG.SCHED_ACCID 0x[AIT::utils::long_int_to_hex 128 $sched_accid] \
        CONFIG.SCHED_TTYPE 0x[AIT::utils::long_int_to_hex 512 $sched_ttype] \
     ] [get_bd_cells -hierarchical Picos_OmpSs_Manager]
}

set bitInfo_intlv_stride 0
if {${::AIT::interleaving_stride} ne "None"} {
    set bitInfo_intlv_stride ${::AIT::interleaving_stride}
}

set hwruntime_vlnv [get_property VLNV [get_bd_cells /Hardware_Runtime/Picos_OmpSs_Manager]]

# Fixed-length fields
set bitInfo_coe "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
append bitInfo_coe [format %08x ${::AIT::version_bitInfo}]\n
append bitInfo_coe [format %08x ${::AIT::num_accs}]\n
append bitInfo_coe [format %08x [AIT::board::generate_bitmap_bitinfo]]\n
append bitInfo_coe [format %08x [expr {${::AIT::version_major_ait}<<22 | ${::AIT::version_minor_ait}<<11 | ${::AIT::version_patch_ait}}]]\n
append bitInfo_coe [format %08x ${::AIT::version_wrapper}]\n
append bitInfo_coe [format %08x [AIT::board::get_base_freq]]\n
append bitInfo_coe [format %08x $bitInfo_intlv_stride]\n
append bitInfo_coe [string range $addr_hwruntime_cmdInQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_cmdInQueue 2 9]\n
append bitInfo_coe [format %08x ${::AIT::cmdInSubqueue_len}]\n
append bitInfo_coe [string range $addr_hwruntime_cmdOutQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_cmdOutQueue 2 9]\n
append bitInfo_coe [format %08x ${::AIT::cmdOutSubqueue_len}]\n
append bitInfo_coe [string range $addr_hwruntime_spawnInQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_spawnInQueue 2 9]\n
append bitInfo_coe [format %08x ${::AIT::spawnInQueue_len}]\n
append bitInfo_coe [string range $addr_hwruntime_spawnOutQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_spawnOutQueue 2 9]\n
append bitInfo_coe [format %08x ${::AIT::spawnOutQueue_len}]\n
append bitInfo_coe [string range $addr_managed_reset 10 17]\n
append bitInfo_coe [string range $addr_managed_reset 2 9]\n
append bitInfo_coe [string range $addr_hwcounter 10 17]\n
append bitInfo_coe [string range $addr_hwcounter 2 9]\n
append bitInfo_coe [string range $addr_pom_axilite 10 17]\n
append bitInfo_coe [string range $addr_pom_axilite 2 9]\n
append bitInfo_coe [string range $addr_power_monitor 10 17]\n
append bitInfo_coe [string range $addr_power_monitor 2 9]\n
append bitInfo_coe [string range $addr_thermal_monitor 10 17]\n
append bitInfo_coe [string range $addr_thermal_monitor 2 9]\n

# Calculate the bitinfo offset of each variable-length field
# Variable-length fields are appended next to the fixed-length fields
set xtasks_config_acc_size 44
set num_static_fields 34
set dynamic_field_sizes [list [expr {$xtasks_config_acc_size*[llength ${::AIT::accs}]}] [string length ${::AIT::ait_call}] [string length $hwruntime_vlnv] [string length ${::AIT::bitInfo_note}]]
set dynamic_field_offsets [list]
set offset $num_static_fields
foreach size $dynamic_field_sizes {
    lappend dynamic_field_offsets $offset
    incr offset [expr {int(ceil($size/4.))}]
}
set bitinfo_len $offset
if {$bitinfo_len > 1024} {
    AIT::utils::error_msg "BitInfo length ($bitinfo_len) is greater than its mapped region (1024)"
}

for {set i 0} {$i < [llength $dynamic_field_sizes]} {incr i} {
    append bitInfo_coe [format %08X [expr {[lindex $dynamic_field_sizes $i] | ([lindex $dynamic_field_offsets $i] << 16)}]]\n
}
append bitInfo_coe [format %08x ${::AIT::user_id}]\n
append bitInfo_coe $xtasks_bin_str
append bitInfo_coe [AIT::utils::ascii2hex ${::AIT::ait_call}]
append bitInfo_coe [AIT::utils::ascii2hex $hwruntime_vlnv]
append bitInfo_coe [AIT::utils::ascii2hex ${::AIT::bitInfo_note}]

# Create bitInfo.coe file
set bitInfo_file [open ${::AIT::name_Project}/bitInfo.coe "w"]
puts $bitInfo_file $bitInfo_coe
close $bitInfo_file

# Load bitInfo coe file
set_property -dict [list \
    CONFIG.Write_Depth_A $bitinfo_len \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [pwd]/${::AIT::name_Project}/bitInfo.coe \
 ] [get_bd_cells bitInfo]

# Update outdated IPs
update_ip_catalog -rebuild -scan_changes
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS != {}]

# If exists, add constraints file
if {[file isdirectory board/${::AIT::board}/constraints/]} {
    add_files -fileset constrs_1 -norecurse board/${::AIT::board}/constraints/
}

# Delete floorplanning constrains if not needed
# We should only keep board related constraints
if {(${::AIT::floorplanning_constr} ne "static") && (${::AIT::floorplanning_constr} ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet {static_common_floorplan.xdc static_board_floorplan.xdc}]
} else {
    reorder_files -fileset constrs_1 -back [get_files -quiet {static_common_floorplan.xdc}]
}

if {(${::AIT::floorplanning_constr} ne "acc") && (${::AIT::floorplanning_constr} ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet acc_common_floorplan.xdc]
} else {
    reorder_files -fileset constrs_1 -back [get_files -quiet {acc_common_floorplan.xdc}]
}

reorder_files -fileset constrs_1 -front [get_files -quiet create_pblocks.xdc]

# If available, execute the user defined post-design tcl script
if {[file exists tcl/scripts/userPostDesign.tcl]} {
    if {[catch {source -notrace tcl/scripts/userPostDesign.tcl}]} {
        AIT::utils::error_msg "Failed sourcing board post base design"
    }
}

# If enabled, configure register slices on AXI Interconnects
if {${::AIT::interconRegSlice_all}} {
    set interconnects [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:axi_interconnect:*}]

    foreach inter $interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property CONFIG.M[format %02u $i]_HAS_REGSLICE {4} $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property CONFIG.S[format %02u $i]_HAS_REGSLICE {4} $inter
        }
    }
} elseif {${::AIT::interconRegSlice_mem}} {
    set interconnects [get_bd_cells -hierarchical -regexp -filter {VLNV =~ xilinx.com:ip:axi_interconnect:.* && NAME =~ {S_AXI(_[0-9]*)?_Inter}} .*]

    foreach inter $interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property CONFIG.M[format %02u $i]_HAS_REGSLICE {4} $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property CONFIG.S[format %02u $i]_HAS_REGSLICE {4} $inter
        }
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
