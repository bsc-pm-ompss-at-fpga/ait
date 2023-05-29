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

# Load auxiliary procedures
if {[catch {source -notrace tcl/scripts/utils.tcl}]} {
    puts "\[AIT\] ERROR: Failed loading auxiliary procedures"
    exit 1
}

# Project variables
AIT::info_msg "Sourcing project variables"
if {[catch {source -notrace tcl/projectVariables.tcl}]} {
    AIT::error_msg "Failed sourcing project variables"
}

# Load board-related procedures
AIT::info_msg "Loading board-related procedures"
if {[catch {source -notrace tcl/scripts/board.tcl}]} {
    AIT::error_msg "Failed board-related procedures"
}

# Load AXI datapath procedures
AIT::info_msg "Loading AXI datapath procedures"
if {[catch {source -notrace tcl/scripts/axi_datapath.tcl}]} {
    AIT::error_msg "Failed loading AXI datapath procedures"
}

# Load AXI-Stream datapath procedures
AIT::info_msg "Loading AXI-Stream datapath procedures"
if {[catch {source -notrace tcl/scripts/axis_datapath.tcl}]} {
    AIT::error_msg "Failed loading AXI-Stream datapath procedures"
}

# If available and enabled, load static register slices procedures
if {[file exists board/${::AIT::board}/staticRegSlices.tcl] && ((${::AIT::slr_slices} eq "static") || (${::AIT::slr_slices} eq "all"))} {
    AIT::info_msg "Loading static register slices procedures"
    if {[catch {source -notrace board/${::AIT::board}/staticRegSlices.tcl}]} {
        AIT::error_msg "Failed loading static logic register slices"
    }
}

# If available, overwrite board-specific procedures
if {[file exists board/${::AIT::board}/procs.tcl]} {
    AIT::info_msg "Loading board-specific procedures"
    if {[catch {source -notrace board/${::AIT::board}/procs.tcl}]} {
        AIT::error_msg "Failed overwriting ${::AIT::board} board-specific procedures"
    }
}

## Variables
# BitInfo feature bitmap
variable bitmap_bitInfo 0x00000000
set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | ([expr ${::AIT::interconOpt} - 1]<<2)]]

# Cleanup files
file delete ../${::AIT::name_Project}.datainterfaces.txt
file delete ../${::AIT::name_Project}.debuginterfaces.txt

# Create .datainterfaces.txt file
set dataInterfaces_file [open ../${::AIT::name_Project}.datainterfaces.txt "w"]

# Compute addresses
set bd_addr_segments [list \
    [dict create name cmdInQueue bd_seg_name Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr ${::AIT::cmdInSubqueue_len}*${::AIT::num_accs}*8]] \
    [dict create name cmdOutQueue bd_seg_name Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr ${::AIT::cmdOutSubqueue_len}*${::AIT::num_accs}*8]] \
    [dict create name managed_rstn bd_seg_name *managed_reset* size 4096] \
]
if ${::AIT::enable_spawn_queues} {
    lappend bd_addr_segments [dict create name spawnInQueue bd_seg_name Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr ${::AIT::spawnInQueue_len}*8]]
    lappend bd_addr_segments [dict create name spawnOutQueue bd_seg_name Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr ${::AIT::spawnOutQueue_len}*8]]
}
if {${::AIT::hwcounter} || ${::AIT::hwinst}} {
    lappend bd_addr_segments [dict create name hwcounter bd_seg_name HW_Counter/s_axi/reg0 size 4096]
}
if ${::AIT::enable_pom_axilite} {
    lappend bd_addr_segments [dict create name pom_axilite bd_seg_name Hardware_Runtime/Picos_OmpSs_Manager/axilite/reg_0 size 16384]
}

# Sort the segments in decreasing size to minimize fragmentation when assigning addresses
set bd_addr_segments [lsort -decreasing -command AIT::comp_bd_addr_seg $bd_addr_segments]

set addr_hwruntime_spawnInQueue 0x0000000000000000
set addr_hwruntime_spawnOutQueue 0x0000000000000000
set addr_hwcounter 0x0000000000000000
set addr_pom_axilite 0x0000000000000000

set bitInfo_offset 0x0
set addr [expr $bitInfo_offset + 4096]
for {set i 0} {$i < [llength $bd_addr_segments]} {incr i} {
    set cur_dict [lindex $bd_addr_segments $i]
    set size [dict get $cur_dict size]
    if {$size <= 4096} {
        set size 4096
    } elseif {$size & ($size-1)} { # Not power of 2
        set size_clog2 [expr int(ceil(log($size)/log(2)))]
        set size [expr int(pow(2, $size_clog2))]
    }
    if {$addr%$size} {
        set addr [expr $addr + $size - ($addr % $size)]
    }
    set format_addr [format 0x%016x [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + $addr]]
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
    }
    set addr [expr $addr + $size]
}

variable addr_bitInfo [format 0x%016x [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + $bitInfo_offset]]

# Create project and set board files
create_project -force ${::AIT::name_Project} ${::AIT::name_Project} -part ${::AIT::chipPart}
if {[info exists {::AIT::boardPart}]} {
    if {[llength [get_boards ${::AIT::boardPart}:*]]} {
        set_property board_part [get_board_parts -latest_file_version ${::AIT::boardPart}:*] [current_project]
    } else {
        AIT::error_msg "Board part is missing, design will fail. Please add the corresponding board files to the Vivado installation"
    }
}

# Set repository path
set_property ip_repo_paths {HLS} [current_project]

# Do not generate simulation scripts
set_property sim.ip.auto_export_scripts {false} [current_project]

# If enabled, set cache location
if ${::AIT::IP_caching} {
    check_ip_cache -import_from_project -use_cache_location ${::AIT::path_CacheLocation}
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
        AIT::info_msg "Adding auxiliary IP $IP"
        update_ip_catalog -add_ip $IP -repo_path IPs
    }
    foreach {IP} [glob -nocomplain IPs/*.{v,vhdl}] {
        AIT::info_msg "Adding auxiliary IP $IP"
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
    AIT::error_msg "Failed sourcing board base design"
}

# Open Block Design
open_bd_design ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd

# Set synthesis by IP
set_property synth_checkpoint_mode {Hierarchical} [get_files ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd]

# If available, execute the user defined pre-design tcl script
if {[file exists tcl/scripts/userPreDesign.tcl]} {
    if {[catch {source -notrace tcl/scripts/userPreDesign.tcl}]} {
        AIT::error_msg "Failed sourcing board pre base design"
    }
}

# Add required common IPs
AIT::board::init_bd

# Add OmpSs Manager template
if {[catch {source -notrace tcl/templates/Picos_OmpSs_Manager.tcl}]} {
    AIT::error_msg "Failed sourcing Picos_OmpSs_Manager template"
}

if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins Hardware_Runtime/S_AXI_GP] M 1
} else {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins Hardware_Runtime/S_AXI_GP] M
}

AIT::board::connect_clock [get_bd_pins Hardware_Runtime/aclk]
AIT::board::connect_reset [get_bd_pins Hardware_Runtime/interconnect_aresetn] "interconnect"
AIT::board::connect_reset [get_bd_pins Hardware_Runtime/peripheral_aresetn] "peripheral"
connect_bd_net [get_bd_pins Hardware_Runtime/managed_aresetn] [get_bd_pins reset_AND/Res]

if {${::AIT::hwruntime_interconnect} == "centralized"} {
    set hwruntime_interconnect_script "tcl/scripts/hwr_central_interconnect.tcl"
} else {
    set hwruntime_interconnect_script "tcl/scripts/hwr_dist_interconnect.tcl"
}

# Instantiate hwruntime interconnect tree
if {[catch {source $hwruntime_interconnect_script}]} {
    AIT::error_msg "Failed sourcing $hwruntime_interconnect_script"
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

    set accName_long ${accName}_ompss

    for {set instanceNum 0} {${instanceNum} < $accNumInstances} {incr instanceNum} {

        if {[catch {source -notrace tcl/templates/dummy_acc.tcl}]} {
            AIT::error_msg "Failed sourcing dummy acc template"
        }

        # Create dummy acc hierarchy and instantiate IP
        set_property name ${accName}_${instanceNum} [get_bd_cells dummy_acc]
        create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper:1.0 ${accName}_${instanceNum}/$accName_long

        # Replace dummy acc by IP instance and delete it
        replace_bd_cell -quiet ${accName}_${instanceNum}/dummy_acc ${accName}_${instanceNum}/$accName_long
        delete_bd_objs [get_bd_cells ${accName}_${instanceNum}/dummy_acc]

        # Connect clk and rst pins
        AIT::board::connect_clock [get_bd_pins ${accName}_${instanceNum}/aclk]
        connect_bd_net [get_bd_pins ${accName}_${instanceNum}/managed_aresetn] [get_bd_pins reset_AND/Res]

        ## AXI interfaces
        # Get list of M_AXI interfaces
        # NOTE: Only handle AXI interfaces generated by mcxx, which start with the "mcxx_" prefix
        set list_acc_axi_pins [get_bd_intf_pins -quiet ${accName}_${instanceNum}/$accName_long/m_axi_mcxx_*]

        # Create accelerator AXI data path and store it in a dictionary
        foreach acc_axi_pin $list_acc_axi_pins {
            set pin_name [string replace [string range $acc_axi_pin [expr [string last / $acc_axi_pin] + 1] end] 0 [expr [string length "m_axi_"] - 1]]

            # Outermost AXI interface that will be connected to memory
            set hier_inner_axi_pin $acc_axi_pin

            # Add register slice to AXI pin
            if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
                set hier_inner_axi_pin [AIT::AXI::add_reg_slice $hier_inner_axi_pin $pin_name $accName $instanceNum]
            }

            # Add address interleaver to AXI pin
            if {${::AIT::interleaving_stride} ne "None"} {
                AIT::AXI::add_addrInterleaver $hier_inner_axi_pin $pin_name $accName $instanceNum
            }

            set hier_outter_axi_pin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accName}_${instanceNum}/$pin_name]
            connect_bd_intf_net $hier_inner_axi_pin $hier_outter_axi_pin

            lappend acc_axi_pins $hier_outter_axi_pin
        }

        ## AXI-Stream interfaces
        # If available, forward the outPort
        # Check if acc has already AXI-Stream pins instead of handshake
        if {[get_bd_intf_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_outPort(_V)*?] ne ""} {
            set hier_outStream [get_bd_intf_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_outPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_outPort(_V)*?] ne ""} {
            # Create and connect the hsToStreamAdapter
            set hier_outStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_outPort(_V)*?] $accName $instanceNum $accID]
        }

        # If available, forward the inPort
        if {[get_bd_intf_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_inPort(_V)*?] ne ""} {
            set hier_inStream [get_bd_intf_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_inPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_inPort(_V)*?] ne ""} {
            # Create and connect the streamToHsAdapter
            set hier_inStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_inPort(_V)*?] $accName $instanceNum]
        }

        # If this is a task creator, instantiate the newtask_spawner
        if ${taskCreator} {
            if {[get_bd_intf_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_spawnInPort(_V)*?] ne ""} {
                set acc_spawnInStream [get_bd_intf_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_spawnInPort(_V)*?]
            } elseif {[get_bd_pins -quiet -regexp ${accName}_${instanceNum}/$accName_long/mcxx_spawnInPort(_V)*?] ne ""} {
                # Create and connect the streamToHsAdapter
                set acc_spawnInStream [AIT::AXIS::add_stream_adapter [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_spawnInPort(_V)*?] $accName $instanceNum]
            }

            lassign [AIT::AXIS::add_newtask_spawner $acc_spawnInStream $hier_inStream $hier_outStream $accName $instanceNum] hier_outStream hier_inStream
        }

        set hier_outStream [AIT::AXIS::add_tid_subset_converter $hier_outStream $accID $accName $instanceNum]

        # Add register slice to AXI-Stream pins
        if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
            set hier_inStream [AIT::AXIS::add_reg_slice $hier_inStream $accName $instanceNum]
            set hier_outStream [AIT::AXIS::add_reg_slice $hier_outStream $accName $instanceNum]
        }

        ## Other interfaces
        # If available, forward the instrumentation pins
        if {([get_bd_pins -quiet ${accName}_${instanceNum}/$accName_long/mcxx_instr_*] ne "") || ([get_bd_pins -quiet ${accName}_${instanceNum}/$accName_long/mcxx_hwcounterPort*] ne "")} {

            # Create counter for the current accelerator
            set hwinst_counter [create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary ${accName}_${instanceNum}/hwinst_counter]
            set_property CONFIG.Output_Width {64} $hwinst_counter
            connect_bd_net [get_bd_pins ${accName}_${instanceNum}/aclk] [get_bd_pins $hwinst_counter/CLK]

            if {[get_bd_pins -quiet ${accName}_${instanceNum}/$accName_long/mcxx_instr_*] ne ""} {

                # Create and connect the Adapter_instr
                create_bd_cell -type ip -vlnv bsc:ompss:Adapter_instr_wrapper:1.0 ${accName}_${instanceNum}/Adapter_instr
                connect_bd_net [get_bd_pins -regexp ${accName}_${instanceNum}/Adapter_instr/in(_V)*?_ap_vld] [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_instr(_V)*?_ap_vld]
                connect_bd_net [get_bd_pins -regexp ${accName}_${instanceNum}/Adapter_instr/in(_V)*?_ap_ack] [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_instr(_V)*?_ap_ack]
                connect_bd_net [get_bd_pins -regexp ${accName}_${instanceNum}/Adapter_instr/in(_V)*?] [get_bd_pins -regexp ${accName}_${instanceNum}/$accName_long/mcxx_instr(_V)*?]
                AIT::board::connect_clock [get_bd_pins ${accName}_${instanceNum}/Adapter_instr/ap_clk]
                connect_bd_net [get_bd_pins ${accName}_${instanceNum}/Adapter_instr/ap_rst_n] [get_bd_pins ${accName}_${instanceNum}/managed_aresetn]

                # Connect to hwcounter
                connect_bd_net [get_bd_pins $hwinst_counter/Q] [get_bd_pins ${accName}_${instanceNum}/Adapter_instr/hwcounter]

                set instr_inner_axi_pin [get_bd_intf_pins -quiet ${accName}_${instanceNum}/Adapter_instr/m_axi* -filter {NAME =~ "*instr_buffer"}]

                if {(${::AIT::slr_slices} eq "acc") || (${::AIT::slr_slices} eq "all")} {
                    set instr_inner_axi_pin [AIT::AXI::add_reg_slice $instr_axi_pin $accName $instanceNum]
                }

                # Connect instr_buffer pin
                set instr_outter_axi_pin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accName}_${instanceNum}/instr_buffer]
                connect_bd_intf_net $instr_inner_axi_pin $instr_outter_axi_pin
                lappend acc_axi_pins $instr_outter_axi_pin
            }

            if {[get_bd_pins -quiet ${accName}_${instanceNum}/$accName_long/mcxx_hwcounterPort*] ne ""} {
                connect_bd_net [get_bd_pins $hwinst_counter/Q] [get_bd_pins ${accName}_${instanceNum}/$accName_long/mcxx_hwcounterPort*]
            }
        }

        # If available, forward the frequency pin
        if {[get_bd_pins -quiet ${accName}_${instanceNum}/$accName_long/mcxx_freqPort*] ne ""} {
            # Create and connect constant with freq
            set accFreq [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ${accName}_${instanceNum}/accFreq]
            set_property -dict [list \
                CONFIG.CONST_VAL $actFreq \
                CONFIG.CONST_WIDTH {10} \
             ] $accFreq
            connect_bd_net [get_bd_pins $accFreq/dout] [get_bd_pins ${accName}_${instanceNum}/$accName_long/mcxx_freqPort*]
        }

        # Connect AXI-Stream pins
        connect_bd_intf_net [get_bd_intf_pins ${accName}_${instanceNum}/inStream] $hier_inStream
        connect_bd_intf_net [get_bd_intf_pins ${accName}_${instanceNum}/outStream] $hier_outStream
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${instanceNum}/outStream] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${accID}_AXIS]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${instanceNum}/inStream] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${accID}_AXIS]

        # Mark AXI-Stream pin for debug
        if {(${::AIT::debugInterfaces} eq "stream") || (${::AIT::debugInterfaces} eq "both")} {
            AIT::AXIS::mark_debug [get_bd_intf_pins ${accName}_${instanceNum}/inStream]
            AIT::AXIS::mark_debug [get_bd_intf_pins ${accName}_${instanceNum}/outStream]
        }

        # Increase global acc id
        incr accID

        regenerate_bd_layout -hierarchy [get_bd_cell ${accName}_${instanceNum}]
        save_bd_design
    }

}

# If we are generating a design for a discrete FPGA that uses DDR, check for
# available AXI interfaces to memory and instantiate a nested interconnect, if necessary
if {(${::AIT::arch_device} eq "alveo") && ([dict get ${::AIT::address_map} "mem_type"] eq "ddr") && ([llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs])} {
    AIT::board::create_nested_interconnect S_AXI_Inter [dict get ${::AIT::address_map} "mem_num_banks"]
    save_bd_design
}

# Check if there are enough available AXI interfaces to memory
if {[llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs]} {
    AIT::error_msg "Insufficient available AXI interfaces to memory ([llength $acc_axi_pins] > [AIT::board::get_available_axi_intfs])"
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
    set lg [expr log($num_banks)/log(2)]
    if { floor($lg) - ceil($lg) != 0 } {
        #number of banks is not power of 2
        #   -> use the larger base2 num of banks available
        set num_banks [expr int(pow(2, floor($lg)))]
    }

    set addrInterleaver [get_bd_cell -hierarchical -filter {VLNV =~ *bsc_ompss_addrInterleaver*}]
    set_property -dict [list \
        CONFIG.BANK_SIZE [dict get ${::AIT::address_map} "mem_bank_size"] \
        CONFIG.NUM_BANKS $num_banks \
        CONFIG.STRIDE ${::AIT::interleaving_stride} \
        CONFIG.BASE_ADDR [dict get ${::AIT::address_map} "mem_base_addr"] \
     ] $addrInterleaver
}

# If enabled, add and connect hwcounter IP
if {${::AIT::hwcounter} || ${::AIT::hwinst}} {
    create_bd_cell -type module -reference bsc_ompss_hwcounter HW_Counter

    if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
        AIT::board::connect_to_axi_intf [get_bd_intf_pins HW_Counter/S_AXI] M 1
    } else {
        AIT::board::connect_to_axi_intf [get_bd_intf_pins HW_Counter/S_AXI] M
    }

    AIT::board::connect_clock [get_bd_pins HW_Counter/s_axi_aclk]

    if ${::AIT::hwinst} {
        set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<0]]
    }
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<1]]
    save_bd_design
}

# Add slr constraints to static logic
if {(${::AIT::slr_slices} eq "static") || (${::AIT::slr_slices} eq "all")} {
    # From board's staticRegSlices.tcl
    AIT::static_logic_register_slices
    save_bd_design
}

close $dataInterfaces_file

AIT::board::cleanup_bd
save_bd_design

# Mark custom interfaces for debug
if {${::AIT::debugInterfaces} eq "custom"} {
    foreach intf ${::AIT::debugInterfaces_list} {
        set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]]
        if {[llength [get_bd_intf_pins -quiet -filter {VLNV =~ *aximm_rtl*} $intf]]} {
            AIT::AXI::mark_debug $intf
        } elseif {[llength [get_bd_intf_pins -quiet -filter {VLNV =~ *axis_rtl*} $intf]]} {
            AIT::AXIS::mark_debug $intf
        } else {
            AIT::error_msg "Interface type not recognized ($intf)"
        }
    }
    save_bd_design
}

# Propagate parameters
validate_bd_design -force -quiet
save_bd_design

# Create pl_ompss_fpga.dtsi file
set ompss_at_fpga_DeviceTree_file [open ${::AIT::name_Project}/pl_ompss_at_fpga.dtsi "w"]
set ompss_at_fpga_node "&amba_pl {\n"
append ompss_at_fpga_node "\tompss_at_fpga: ompss_at_fpga@0 {\n\t\tcompatible = \"ompss-at-fpga\";\n"
append ompss_at_fpga_node "\t\tbitstreaminfo = <&bitInfo_BRAM_Ctrl>;\n"
append ompss_at_fpga_node "\t};\n};"
puts $ompss_at_fpga_DeviceTree_file $ompss_at_fpga_node
close $ompss_at_fpga_DeviceTree_file

set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<9]]
if ${::AIT::task_creation} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<7]]
}
if ${::AIT::simplify_interconnection} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<3]]
}

# Wipe clean address map
delete_bd_objs [get_bd_addr_segs]

AIT::board::configure_address_map

# Map hwruntime queues to address space
foreach bd_addr_seg $bd_addr_segments {
    set name [dict get $bd_addr_seg name]
    set addr [dict get $bd_addr_seg addr]
    set range [dict get $bd_addr_seg size]
    set bd_seg_name [dict get $bd_addr_seg bd_seg_name]
    AIT::info_msg "Assign $name BD address, range $range address $addr"
    assign_bd_address [get_bd_addr_segs $bd_seg_name] -range $range -offset $addr
}

if ${::AIT::task_creation} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<5]]
}

if ${::AIT::deps_hwruntime} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<6]]
}

if ${::AIT::enable_spawn_queues} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<8]]
}

if ${::AIT::lock_hwruntime} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<7]]
}

if ${::AIT::enable_pom_axilite} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<4]]
}

if ${::AIT::simplify_interconnection} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<3]]
}

# Map bitinfo BRAM to address space
if {(${::AIT::arch_device} ne "simulation") && (${::AIT::arch_device} ne "shell")} {
    assign_bd_address [get_bd_addr_segs *bitInfo_BRAM_Ctrl*] -range 4K -offset $addr_bitInfo
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
    set bin_word [expr $accNumInstances | (($accHash & 0xFFFF) << 16)]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    set bin_word [expr ($accHash >> 16) | ((($actFreq*1000) & 0xFF) << 24)]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    set bin_word [expr ($actFreq*1000) >> 8]
    append xtasks_bin_str [format "%08X\n" $bin_word]
    if {[string length $accName] > 31} {
        set accName [string range $accName 0 30]
    }
    # Max length is 31 characters, but there are 8 padding bits at the end
    append accName [string repeat " " [expr 32-[string length $accName]]]
    # Convert ascii to hexadecimal string
    append xtasks_bin_str [AIT::ascii2hex $accName]

    set sched_count [expr $sched_count | (($accNumInstances-1) << $i*8)]
    set sched_accid [expr $sched_accid | ($accid << $i*8)]
    set sched_ttype [expr $sched_ttype | (($accHash & 0xFFFFFFFF) << $i*32)]
    incr accid $accNumInstances
    incr i
}

if ${::AIT::task_creation} {
    if {[llen ${::AIT::accs}] > 16} {
        AIT::error_msg "Max number of accelerator types supported by POM is 16, but design has [llen ${::AIT::accs}]"
    }
    set_property -dict [list \
        CONFIG.SCHED_COUNT 0x[AIT::long_int_to_hex 128 $sched_count] \
        CONFIG.SCHED_ACCID 0x[AIT::long_int_to_hex 128 $sched_accid] \
        CONFIG.SCHED_TTYPE 0x[AIT::long_int_to_hex 512 $sched_ttype] \
     ] [get_bd_cells */Picos_OmpSs_Manager]
}

set bitInfo_intlv_stride 0
if {${::AIT::interleaving_stride} ne "None"} {
    set bitInfo_intlv_stride ${::AIT::interleaving_stride}
}

set hwruntime_vlnv [get_property VLNV [get_bd_cells /Hardware_Runtime/Picos_OmpSs_Manager]]
set xtasks_config_acc_size 44
set dynamic_field_sizes [list [expr $xtasks_config_acc_size*[llen ${::AIT::accs}]] [string len ${::AIT::ait_call}] [string len $hwruntime_vlnv] [string len ${::AIT::bitInfo_note}]]
set dynamic_field_offsets [list]
# Calculate the bitinfo offset of each variable-length field
# Variable-length fields are appended next to the fixed-length fields which take 31 slots
set offset 31
foreach size $dynamic_field_sizes {
   lappend dynamic_field_offsets $offset
   incr offset [expr int(ceil($size/4.))]
}
set bitinfo_len $offset
if {$bitinfo_len > 1024} {
    AIT::error_msg "BitInfo length ($bitinfo_len) is greater than its mapped region (1024)"
}

# Create bitInfo.coe file
set bitInfo_file [open ${::AIT::name_Project}/bitInfo.coe "w"]
set bitInfo_coe "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
append bitInfo_coe [format %08x ${::AIT::version_bitInfo}]\n
append bitInfo_coe [format %08x ${::AIT::num_accs}]\n
append bitInfo_coe [format %08x $bitmap_bitInfo]\n
append bitInfo_coe [format %08x [expr ${::AIT::version_major_ait}<<22 | ${::AIT::version_minor_ait}<<11 | ${::AIT::version_patch_ait}]]\n
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
# CMS AXI-Lite interface address
append bitInfo_coe 0\n
append bitInfo_coe 0\n
for {set i 0} {$i < [llen $dynamic_field_sizes]} {incr i} {
   append bitInfo_coe [format %08X [expr [lindex $dynamic_field_sizes $i] | ([lindex $dynamic_field_offsets $i] << 16)]]\n
}
append bitInfo_coe $xtasks_bin_str
append bitInfo_coe [AIT::ascii2hex ${::AIT::ait_call}]
append bitInfo_coe [AIT::ascii2hex $hwruntime_vlnv]
append bitInfo_coe [AIT::ascii2hex ${::AIT::bitInfo_note}]
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
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS!={}]

# If exists, add constraints file
if {[file isdirectory board/${::AIT::board}/constraints/]} {
    add_files -fileset constrs_1 -norecurse board/${::AIT::board}/constraints/
}

# Delete floorplanning constrains if requested
# We should only keep board related constraints
if {(${::AIT::floorplanning_constr} ne "static") && (${::AIT::floorplanning_constr} ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet static_floorplan.xdc]
}

if {(${::AIT::floorplanning_constr} ne "acc") && (${::AIT::floorplanning_constr} ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet acc_floorplan_common.xdc]
}

reorder_files -fileset constrs_1 -front [get_files -quiet create_pblocks.xdc]

# If available, execute the user defined post-design tcl script
if {[file exists tcl/scripts/userPostDesign.tcl]} {
    if {[catch {source -notrace tcl/scripts/userPostDesign.tcl}]} {
        AIT::error_msg "Failed sourcing board post base design"
    }
}

# If enabled, configure register slices on AXI Interconnects
if ${::AIT::interconRegSlice_all} {
    set interconnects [get_bd_cells -hierarchical -regexp -filter {VLNV =~ xilinx.com:ip:axi_interconnect.*} .*]

    foreach inter $interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property CONFIG.M[format %02u $i]_HAS_REGSLICE {4} $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property CONFIG.S[format %02u $i]_HAS_REGSLICE {4} $inter
        }
    }
} elseif ${::AIT::interconRegSlice_mem} {
    set interconnects [get_bd_cells -hierarchical -regexp -filter {VLNV =~ xilinx.com:ip:axi_interconnect.* && NAME =~ {S_AXI(_[0-9]*)?_Inter}} .*]

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
    AIT::error_msg "Block Design could not be validated"
}

AIT::board::generate_wrapper

update_compile_order -fileset sources_1

# Save Block Design
save_bd_design
