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

## Board-specific generic procedures
## Can be overwritten through the file procs.tcl on the board folder

namespace eval AIT {
    namespace eval board {
        variable board_axi_intfs

        # Instantiates and connects required common IPs
        proc init_bd {} {
            # If interconnect priorities are enabled, set PCIe master as max priority
            if {${::AIT::interconPriority}} {
                set data_width 32
                if {${::AIT::arch_device} eq "alveo"} {
                    set data_width 512
                } elseif {${::AIT::arch_device} eq "zynqmp"} {
                    set data_width 128
                } elseif {${::AIT::arch_device} eq "zynq"} {
                    set data_width 64
                }

                set_property -dict [list \
                    CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
                    CONFIG.XBAR_DATA_WIDTH.VALUE_SRC {PROPAGATED} \
                    CONFIG.XBAR_DATA_WIDTH $data_width \
                    CONFIG.S00_ARB_PRIORITY {15} \
                 ] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
            }

            # If enabled, simplify interconnection to memory
            if {${::AIT::simplify_interconnection}} {
                move_bd_cells [get_bd_cells /] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
                delete_bd_objs [get_bd_cells S_AXI_Inter]
                set_property name {S_AXI_Inter} [get_bd_cells DDR_S_AXI_Inter]
            }

            get_board_axi_intfs

            # Create instance: bitInfo, and set properties
            set bitInfo [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen bitInfo]
            set_property -dict [list \
                CONFIG.Byte_Size {8} \
                CONFIG.EN_SAFETY_CKT {false} \
                CONFIG.Enable_32bit_Address {true} \
                CONFIG.Fill_Remaining_Memory_Locations {false} \
                CONFIG.Load_Init_File {false} \
                CONFIG.Memory_Type {Single_Port_RAM} \
                CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
                CONFIG.Remaining_Memory_Locations {0} \
                CONFIG.Use_Byte_Write_Enable {true} \
                CONFIG.Use_RSTA_Pin {false} \
                CONFIG.Write_Depth_A {1024} \
                CONFIG.Write_Width_B {32} \
                CONFIG.Read_Width_A {32} \
                CONFIG.Read_Width_B {32} \
                CONFIG.use_bram_block {Stand_Alone} \
             ] $bitInfo

            # Create instance: bitInfo_BRAM_Ctrl, and set properties
            set bitInfo_BRAM_Ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl bitInfo_BRAM_Ctrl]
            set_property -dict [list \
                CONFIG.PROTOCOL {AXI4} \
                CONFIG.SINGLE_PORT_BRAM {1} \
             ] $bitInfo_BRAM_Ctrl

            # Create instance: managed_reset, and set properties
            set managed_reset [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio managed_reset]
            set_property -dict [list \
                CONFIG.C_ALL_OUTPUTS {1} \
                CONFIG.C_DOUT_DEFAULT {0x00000001} \
                CONFIG.C_GPIO_WIDTH {1} \
             ] $managed_reset

            # Create instance: reset_AND, and set properties
            set reset_AND [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic reset_AND]
            set_property -dict [list \
                CONFIG.C_SIZE {1} \
                CONFIG.C_OPERATION {and} \
             ] $reset_AND

            connect_bd_net [get_bd_pins managed_reset/gpio_io_o] [get_bd_pins reset_AND/Op1]
            connect_reset [get_bd_pins reset_AND/Op2] "peripheral"

            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                connect_to_axi_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M 1
                connect_to_axi_intf [get_bd_intf_pins managed_reset/S_AXI] M 1
            } else {
                connect_to_axi_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M
                connect_to_axi_intf [get_bd_intf_pins managed_reset/S_AXI] M
            }
            connect_bd_intf_net [get_bd_intf_pins bitInfo/BRAM_PORTA] [get_bd_intf_pins bitInfo_BRAM_Ctrl/BRAM_PORTA]
            connect_clock [get_bd_pins bitInfo_BRAM_Ctrl/s_axi_aclk]
            connect_reset [get_bd_pins bitInfo_BRAM_Ctrl/s_axi_aresetn] "peripheral"
            connect_clock [get_bd_pins managed_reset/s_axi_aclk]
            connect_reset [get_bd_pins managed_reset/s_axi_aresetn] "peripheral"
        }

        # Initializes board_axi_intfs variable with the available AXI interfaces along with their occupation
        proc get_board_axi_intfs {} {
            variable board_axi_intfs
            set board_axi_intfs {}

            set interconnect_list [get_bd_cells -regexp (M|S)_AXI(_([0-9])*)?_Inter]
            foreach interconnect $interconnect_list {
                set mode [string trim [regsub -all {_AXI_.+$} $interconnect ""] "/"]
                set counter [expr [get_property CONFIG.NUM_${mode}I $interconnect] - 1]
                set capacity 16
                if {$counter < $capacity} {
                    lappend board_axi_intfs "$mode [string trim $interconnect "/"] $counter $capacity"
                }
            }

            set board_axi_intfs [lsort -integer -index 2 -increasing $board_axi_intfs]
        }

        # Returns the total number of free AXI data interfaces
        proc get_available_axi_intfs {} {
            variable board_axi_intfs
            set available_axi_intfs 0

            foreach intf $board_axi_intfs {
                foreach {mode name counter capacity} $intf {
                    if {$mode eq "S"} {
                        incr available_axi_intfs [expr $capacity - $counter]
                    }
                }
            }

            return $available_axi_intfs
        }

        # Maps board memory to address map
        proc configure_address_map {} {
            AIT::info_msg "Using generic configure_address_map procedure"

            set mem_type [dict get ${::AIT::address_map} "mem_type"]
            set base_addr [dict get ${::AIT::address_map} "mem_base_addr"]

            # Assign memory address space
            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                set mem_size [dict get ${::AIT::address_map} "mem_size"]
                # Zynq DDR address segment name format: /bridge_to_host/S_AXI_HPX/HPX_DDR_LOWOCM, being
                # S_AXI_HPX the AXI interface used
                foreach addr_seg [get_bd_addr_segs -regexp ".*/S_AXI_HP[0-9]/HP[0-9]_DDR_LOWOCM"] {
                    assign_bd_address $addr_seg -offset $base_addr -range $mem_size
                }
            } elseif {${::AIT::arch_device} eq "alveo"} {
                set bank_size [dict get ${::AIT::address_map} "mem_bank_size"]
                set num_banks [dict get ${::AIT::address_map} "mem_num_banks"]
                if {$mem_type eq "ddr"} {
                    set bank_num 0
                    # DDR address segment name format: /bridge_to_host/memory/DDR_X/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK, being
                    # DDR_X each DDR bank
                    foreach addr_seg [get_bd_addr_segs -regexp ".*/DDR_[0-9]/.*/C0_DDR4_ADDRESS_BLOCK"] {
                        assign_bd_address $addr_seg -offset [expr $base_addr + $bank_size*$bank_num] -range $bank_size
                        incr bank_num
                    }
                } elseif {$mem_type eq "hbm"} {
                    set bank_num 0
                    # HBM address segment name format: /bridge_to_host/memory/HBM/SAXI_XX[_8HI]/HBM_MEMYY, being
                    # SAXI_XX[_8HI] the AXI interface used
                    # HBM_MEMYY each HBM bank
                    foreach addr_seg [get_bd_addr_segs -regexp ".*/SAXI_[0-9]{2}(_8HI)?/HBM_MEM[0-9]{2}"] {
                        assign_bd_address $addr_seg -offset [expr 0x0 + ($bank_num%$num_banks)*$bank_size] -range $bank_size
                        incr bank_num
                    }
                }
            }
        }

        # Creates and connects a tree of interconnects that allows an arbitrary number of AXI-stream slaves to connect to up to 16 AXI-stream masters
        proc create_inStream_Inter_tree { stream_name nmasters nslaves clk inter_rstn peri_rstn } {
            set ninter [expr int(ceil($nslaves/16.))]
            set prev_ninter $nslaves
            set inter_level 0
            set inter_stride 1

            # First level uses interconnects with more than one master if required
            for {set i 0} {$i < $ninter} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_$i

                # Last interconnect may need less slaves
                if {($i == $ninter-1) && ($prev_ninter%16)} {
                    set num_si [expr $prev_ninter%16]
                } else {
                    set num_si 16
                }

                # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
                if {$num_si > 1} {
                    set inter_conf [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
                } else {
                    set inter_conf {}
                }

                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                lappend inter_conf CONFIG.NUM_MI $nmasters CONFIG.NUM_SI $num_si
                set_property -dict $inter_conf $inter

                connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                for {set j 0} {$j < $num_si} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {$j < $nmasters} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter $ninter
            set ninter [expr int(ceil($ninter/16.))]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set m 0} {$m < $nmasters} {incr m} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_m${m}_$i

                        # Last interconnect may need less slaves
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_si [expr $prev_ninter%16]
                        } else {
                            set num_si 16
                        }

                        if {$num_si > 1} {
                            set inter_conf [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
                        } else {
                            set inter_conf {}
                        }

                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                        lappend inter_conf \
                            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
                            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
                            CONFIG.NUM_MI {1} \
                            CONFIG.NUM_SI $num_si
                        set_property -dict $inter_conf $inter

                        connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                        connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                        for {set j 0} {$j < $num_si} {incr j} {
                            set inf_num [format %02u $j]
                            connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                            connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net $clk [get_bd_pins $inter_name/M00_AXIS_ACLK]
                        connect_bd_net $peri_rstn [get_bd_pins $inter_name/M00_AXIS_ARESETN]

                        for {set j 0} {$j < $num_si} {incr j} {
                            set master_inter_num [expr $i*16 + $j]
                            set master_inter_level [expr $inter_level-1]
                            if {$inter_level == 1} {
                                set master_inf [format %02u $m]
                                set master_inter ${stream_name}_lvl${master_inter_level}_$master_inter_num
                            } else {
                                set master_inf 00
                                set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_$master_inter_num
                            }
                            set slave [format %02u [expr $j%16]]
                            connect_bd_intf_net [get_bd_intf_pins $master_inter/M${master_inf}_AXIS] [get_bd_intf_pins $inter_name/S${slave}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr int(ceil($ninter/16.))]
                incr inter_level
            }
            return [expr $inter_level-1]
        }

        # Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
        proc create_outStream_Inter_tree { stream_name nslaves nmasters clk inter_rstn peri_rstn } {
            set ninter [expr int(ceil($nmasters/16.))]
            set prev_ninter $nmasters
            set inter_level 0
            set stride 1

            # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
            if {$nslaves > 1} {
                set arb_config [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
            } else {
                set arb_config {}
            }

            # First level uses interconnects with more than one slave if required
            for {set i 0} {$i < $ninter} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_$i

                # Last interconnect may need less masters
                if {($i == $ninter-1) && ($prev_ninter%16)} {
                    set num_mi [expr $prev_ninter%16]
                } else {
                    set num_mi 16
                }

                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                set inter_conf $arb_config
                lappend inter_conf CONFIG.NUM_MI $num_mi CONFIG.NUM_SI $nslaves

                for {set j 0} {$j < $num_mi} {incr j} {
                    set master_num [format %02u $j]
                    set base_dest [format "32\'d%d" [expr $i*$stride*16 + $j*$stride]]
                    set high_dest [format "32\'d%d" [expr $i*$stride*16 + ($j+1)*$stride - 1]]
                    lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
                }

                set_property -dict $inter_conf $inter

                connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                for {set j 0} { $j < $num_mi} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {$j < $nslaves} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter $ninter
            set ninter [expr int(ceil($ninter/16.))]
            set stride [expr $stride*16]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set s 0} {$s < $nslaves} {incr s} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_s${s}_$i

                        # Last interconnect may need less masters
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_mi [expr $prev_ninter%16]
                        } else {
                            set num_mi 16
                        }

                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                        set inter_conf [list CONFIG.NUM_MI $num_mi CONFIG.NUM_SI {1}]

                        for {set j 0} {$j < $num_mi} {incr j} {
                            set master_num [format %02u $j]
                            set base_dest [format "32\'d%d" [expr $i*$stride*16 + $j*$stride]]
                            set high_dest [format "32\'d%d" [expr $i*$stride*16 + ($j+1)*$stride - 1]]
                            lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
                        }

                        set_property -dict $inter_conf $inter

                        connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                        connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                        for {set j 0} { $j < $num_mi} {incr j} {
                            set inf_num [format %02u $j]
                            connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                            connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net $clk [get_bd_pins $inter_name/S00_AXIS_ACLK]
                        connect_bd_net $peri_rstn [get_bd_pins $inter_name/S00_AXIS_ARESETN]

                        for {set j 0} {$j < $num_mi} {incr j} {
                            set slave_inter_num [expr $i*16+$j]
                            set slave_inter_level [expr $inter_level-1]
                            set master [format %02u $j]
                            if {$inter_level == 1} {
                                set slave_inf [format %02u $s]
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_$slave_inter_num
                            } else {
                                set slave_inf 00
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_s${s}_$slave_inter_num
                            }
                            connect_bd_intf_net [get_bd_intf_pins $slave_inter/S${slave_inf}_AXIS] [get_bd_intf_pins $inter_name/M${master}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr int(ceil($ninter/16.))]
                set stride [expr $stride*16]
                incr inter_level
            }
            return [expr $inter_level-1]
        }

        # Creates and connects a nested interconnect
        proc create_nested_interconnect {parent_inter {num 1}} {
            variable board_axi_intfs
            set index [lsearch -regexp $board_axi_intfs $parent_inter]
            set board_axi_intfs [lreplace $board_axi_intfs $index $index]

            AIT::info_msg "Creating $num nested interconnects for $parent_inter"

            set parent_inter_slaves [get_property CONFIG.NUM_SI [get_bd_cells $parent_inter]]
            set_property CONFIG.NUM_SI [expr $parent_inter_slaves + $num - 1] [get_bd_cells $parent_inter]
            for {set i 0} {$i < $num} {incr i} {
                set nested_inter "${parent_inter}_$i"
                set intf_num [format %02u [expr $parent_inter_slaves + $i - 1]]

                # Create new nested interconnect and configure it
                set nested_inter [create_bd_cell -vlnv xilinx.com:ip:axi_interconnect $nested_inter]
                set_property -dict [list \
                    CONFIG.NUM_MI {1} \
                    CONFIG.NUM_SI {1} \
                    CONFIG.STRATEGY ${::AIT::interconOpt} \
                 ] $nested_inter

                # Connect clocks and resets
                connect_clock [get_bd_pins $nested_inter/ACLK]
                connect_clock [get_bd_pins $nested_inter/M00_ACLK]
                connect_reset [get_bd_pins $nested_inter/ARESETN] "interconnect"
                connect_reset [get_bd_pins $nested_inter/M00_ARESETN] "peripheral"

                # Connect nested interconnect to parent interconnect
                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $parent_inter/S${intf_num}_AXI] [get_bd_intf_pins $nested_inter/M00_AXI]

                connect_clock [get_bd_pins $parent_inter/S${intf_num}_ACLK]
                connect_reset [get_bd_pins $parent_inter/S${intf_num}_ARESETN] "peripheral"

                lappend board_axi_intfs "S [string trim $nested_inter "/"] 0 16"
            }
            set board_axi_intfs [lsort -integer -index 2 -increasing $board_axi_intfs]
        }

        # Connects the IP to the host through the given interface
        proc connect_to_axi_intf {src mode {num ""}} {
            variable board_axi_intfs

            # Look for src in dataInterfaces_map
            set index [lsearch -regexp ${::AIT::dataInterfaces_map} [string trim $src "/"]]
            if {$index != -1} {
                set intf [lindex [lindex ${::AIT::dataInterfaces_map} $index] 1]
                # Interface must be 'S_AXI_X' where X is the value we need for $num
                regsub {S_AXI_} $intf "" num
            }

            # Get AXI interface by num or the least occupied
            if {$num ne ""} {
                set index [lsearch -exact $board_axi_intfs [lsearch -regexp -inline -index 1 [lsearch -all -inline -index 0 $board_axi_intfs $mode] .*_(0)?$num.*]]
                if {$index == -1} {
                    if {$mode eq "S"} {
                        set mode "slave"
                    } elseif {$mode eq "M"} {
                        set mode "master"
                    }
                    AIT::error_msg "Cannot connect $src to $mode interface $num. It does not exist"
                }
            } else {
                set index [lsearch -index 0 $board_axi_intfs $mode]
            }

            set mode [lindex [lindex $board_axi_intfs $index] 0]
            set dst_name [lindex [lindex $board_axi_intfs $index] 1]
            set counter [lindex [lindex $board_axi_intfs $index] 2]
            set capacity [lindex [lindex $board_axi_intfs $index] 3]
            set board_axi_intfs [lreplace $board_axi_intfs $index $index]

            # Interconnect is full
            if {!($counter%$capacity) && ($counter > 0)} {
                AIT::error_msg "${dst_name} interface occupation is 100%"
            }

            set dst [get_bd_cells -hierarchical $dst_name]

            set intf ${mode}[format %02u $counter]

            set_property CONFIG.NUM_${mode}I [expr $counter + 1] $dst
            set_property -quiet CONFIG.STRATEGY ${::AIT::interconOpt} $dst

            if {($mode eq "S") && ${::AIT::interconPriority}} {
                set data_width 32
                if {${::AIT::arch_device} eq "alveo"} {
                    set data_width 512
                } elseif {${::AIT::arch_device} eq "zynqmp"} {
                    set data_width 128
                } elseif {${::AIT::arch_device} eq "zynq"} {
                    set data_width 64
                }

                # Enable advanced settings, set priority (0-15) and set proper data path
                set_property -dict [list \
                    CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
                    CONFIG.XBAR_DATA_WIDTH.VALUE_SRC {PROPAGATED} \
                    CONFIG.${intf}_ARB_PRIORITY [expr 15 - ($counter%16)] \
                    CONFIG.XBAR_DATA_WIDTH $data_width \
                 ] $dst
            }

            set axi_pin [get_bd_intf_pins $dst/${intf}_AXI]
            set clk_pin [get_bd_pins $dst/${intf}_ACLK]
            set rst_pin [get_bd_pins $dst/${intf}_ARESETN]

            # Only interleave slave interfaces
            if {($mode eq "S") && (${::AIT::interleaving_stride} ne "None")} {
                connect_bd_net -quiet [get_bd_pins -quiet ${src}_araddr_intlv] [get_bd_pins -quiet ${axi_pin}_araddr] -boundary_type upper
                connect_bd_net -quiet [get_bd_pins -quiet ${src}_awaddr_intlv] [get_bd_pins -quiet ${axi_pin}_awaddr] -boundary_type upper
            }

            connect_clock $clk_pin
            connect_reset $rst_pin "peripheral"
            connect_bd_intf_net -boundary_type upper $src $axi_pin

            incr counter

            lappend board_axi_intfs "$mode $dst_name $counter $capacity"
            set board_axi_intfs [lsort -integer -index 2 -increasing $board_axi_intfs]

            return [list "$dst_name" "${mode}_AXI"]
        }

        # Connects source clock pin to the output of the clock generator IP
        proc connect_clock {src_clk} {
            if {!([llength [get_bd_nets -quiet -of_objects $src_clk]])} {
                connect_bd_net $src_clk [get_bd_pins clock_generator/clk_out1]
            }
        }

        # Connects source reset to either interconnect or peripheral reset
        proc connect_reset {src_rst dst_rst} {
            if {!([llength [get_bd_nets -quiet -of_objects $src_rst]])} {
                connect_bd_net $src_rst [get_bd_pins processor_system_reset/${dst_rst}_aresetn]
            }
        }

        # Sets target frequency, retrieves actual achieved frequency and returns it
        proc set_and_get_freq {targetFreq} {
            AIT::info_msg "Using generic set_and_get_freq procedure"

            set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $targetFreq [get_bd_cells clock_generator]
            set actFreq [expr [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_out1]]/1000000]

            return $actFreq
        }

        # Returns base frequency used to feed the clock generator
        proc get_base_freq {} {

            if {[llength [get_bd_pins -quiet clock_generator/clk_in1]]} {
                # Using single pin clocks
                set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_in1]]
            } else {
                # Using differential clock
                set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_intf_pins clock_generator/clk_in1_d]]

            }
            return $baseFreq
        }


        # Generates HDL wrapper
        proc generate_wrapper {} {
            AIT::info_msg "Using generic generate_wrapper procedure"

            set_property target_language ${::AIT::target_lang} [current_project]

            make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
        }

        # Removes derelict and unused IPs
        proc cleanup_bd {} {
            variable board_axi_intfs

            foreach axi_intf $board_axi_intfs {
                foreach {mode name counter capacity} $axi_intf {
                    if {$counter == 0} {
                        set mem_type [dict get ${::AIT::address_map} "mem_type"]
                        if {$mem_type eq "hbm"} {
                            set intf [string trim [string trim $name {_Inter}] {S_AXI_}]
                            set_property CONFIG.USER_SAXI_$intf {false} [get_bd_cells -hierarchical HBM]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/memory/S${intf}_AXI]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/S${intf}_AXI]
                        }
                        delete_bd_objs [get_bd_cells -hierarchical $name]
                    }
                }
            }
        }
    }
}
