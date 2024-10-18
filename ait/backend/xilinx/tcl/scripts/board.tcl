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

## Board-specific generic procedures
## Can be overwritten through the file procs.tcl on the board folder

namespace eval AIT {
    namespace eval board {
        variable board_axi_inters

        # Instantiates and connects required common IPs
        proc init_bd {} {
            variable board_axi_inters

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
                delete_bd_objs [get_bd_cells S_AXI_Inter]
                move_bd_cells [get_bd_cells /] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
                set_property name {S_AXI_Inter} [get_bd_cells DDR_S_AXI_Inter]
            }

            set board_axi_inters [get_board_axi_inters]

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
                CONFIG.PROTOCOL {AXI4LITE} \
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
            set reset_AND [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic system_reset/managed_reset_AND]
            set_property -dict [list \
                CONFIG.C_SIZE {1} \
                CONFIG.C_OPERATION {and} \
             ] $reset_AND

            create_bd_pin -dir I -type rst system_reset/managed_reset
            create_bd_pin -dir O -type rst system_reset/clk_app_managed_rstn

            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_app_managed
            set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] [get_bd_cells system_reset/proc_sys_reset_clk_app_managed]

            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/slowest_sync_clk] [get_bd_pins system_reset/clk_app]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/peripheral_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/dcm_locked] [get_bd_pins system_reset/clk_gen_locked]
            connect_bd_net [get_bd_pins system_reset/managed_reset] [get_bd_pins system_reset/managed_reset_AND/Op1]
            connect_bd_net [get_bd_pins managed_reset/gpio_io_o] [get_bd_pins system_reset/managed_reset]
            connect_bd_net [get_bd_pins system_reset/managed_reset_AND/Op2] [get_bd_pins system_reset/proc_sys_reset_clk_app/peripheral_aresetn]
            connect_bd_net [get_bd_pins system_reset/managed_reset_AND/res] [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/ext_reset_in]

            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                connect_to_axi_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M 1
                connect_to_axi_intf [get_bd_intf_pins managed_reset/S_AXI] M 1
            } else {
                connect_to_axi_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M
                connect_to_axi_intf [get_bd_intf_pins managed_reset/S_AXI] M
            }
            connect_bd_intf_net [get_bd_intf_pins bitInfo_BRAM_Ctrl/BRAM_PORTA] [get_bd_intf_pins bitInfo/BRAM_PORTA]

            if {${::AIT::ompif}} {
                add_ethernet_subsystem
            }

            if {${::AIT::power_monitor}} {
                add_power_monitor
            }

            if {${::AIT::thermal_monitor}} {
                add_thermal_monitor
            }

            save_bd_design
        }

        proc create_acc_hier {accName instanceNum} {
            set acc_hier [create_bd_cell -type hier ${accName}_${instanceNum}]
            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $acc_hier/inStream
            create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $acc_hier/outStream
            create_bd_pin -type clk -dir I $acc_hier/aclk
            create_bd_pin -type rst -dir I $acc_hier/managed_aresetn

            set acc_ip [create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper:1.0 $acc_hier/${accName}_ompss]
            connect_clock [get_bd_pins $acc_hier/aclk] [get_bd_pins $acc_ip/ap_clk]
            connect_reset [get_bd_pins $acc_hier/managed_aresetn] [get_bd_pins $acc_ip/ap_rst_n]

            return [list $acc_hier $acc_ip]
        }

        # Returns a list with the available AXI interconnects along with their occupation, mode and capacity
        proc get_board_axi_inters {{all False}} {
            set board_axi_inters {}

            if {$all} {
                set axi_inter_list [get_bd_cells -regexp {(M|S)_AXI(_([0-9])*)?_Inter(_[0-9])?}]
            } else {
                set interconnect_list [get_bd_cells -regexp {(M|S)_AXI(_([0-9])*)?_Inter}]
                foreach interconnect $interconnect_list {
                    set nested_interconnect_list [get_bd_cells -quiet -regexp "${interconnect}_\[0-9\]"]
                    if {[llength $nested_interconnect_list]} {
                        set axi_inter_list [concat $axi_inter_list $nested_interconnect_list]
                    } else {
                        lappend axi_inter_list $interconnect
                    }
                }
            }

            foreach axi_inter $axi_inter_list {
                set mode [regsub -all {_AXI_.+$} [get_property NAME $axi_inter] ""]
                set num_intfs [get_property CONFIG.NUM_${mode}I $axi_inter]
                set last_intf [get_bd_intf_pins $axi_inter/${mode}[format %02u [expr {$num_intfs - 1}]]_AXI]
                set occupation [expr {$num_intfs - ![llength [get_bd_intf_nets -quiet -of_objects $last_intf]]}]
                set capacity 16
                if {$occupation < $capacity} {
                    lappend board_axi_inters "$mode [get_property NAME $axi_inter] $occupation $capacity"
                }
            }
            set board_axi_inters [lsort -integer -index 2 -increasing $board_axi_inters]
            return $board_axi_inters
        }

        # Returns the total number of free AXI data interfaces
        proc get_available_axi_intfs {} {
            variable board_axi_inters
            set available_axi_intfs 0

            foreach intf $board_axi_inters {
                foreach {mode name occupation capacity} $intf {
                    if {$mode eq "S"} {
                        incr available_axi_intfs [expr {$capacity - $occupation}]
                    }
                }
            }

            return $available_axi_intfs
        }

        # Maps board memory to address map
        proc configure_address_map {} {
            AIT::utils::info_msg "Using generic configure_address_map procedure"

            set mem_type [dict get ${::AIT::address_map} "mem_type"]
            set base_addr [dict get ${::AIT::address_map} "mem_base_addr"]

            # Assign memory address space
            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                set mem_size [dict get ${::AIT::address_map} "mem_size"]
                # Zynq DDR address segment name format: /bridge_to_host/S_AXI_HPX/HPX_DDR_LOWOCM
                # ZynqMP DDR address segment name format: /bridge_to_host/S_AXI_GPY/HPX_DDR_LOW, being
                # S_AXI_HPX the AXI interface used
                foreach addr_seg [get_bd_addr_segs -regexp {.*/HP[0-9]_DDR_LOW(OCM)?}] {
                    assign_bd_address $addr_seg -offset $base_addr -range $mem_size
                }

                # Exclude unused DDR address segments
                foreach excl_seg [list {DDR_HIGH} {QSPI} {LPS_OCM} {PCIE_LOW}] {
                    foreach addr_seg [get_bd_addr_segs -regexp "/bridge_to_host/.*/HP\[0-9\]_${excl_seg}"] {
                        assign_bd_address -quiet $addr_seg
                        exclude_bd_addr_seg [get_bd_addr_segs -regexp ".*/SEG_bridge_to_host_HP\[0-9\]_${excl_seg}"]
                    }
                }
            } elseif {${::AIT::arch_device} eq "alveo"} {
                set bank_size [dict get ${::AIT::address_map} "mem_bank_size"]
                set num_banks [dict get ${::AIT::address_map} "mem_num_banks"]
                if {$mem_type eq "ddr"} {
                    set bank_num 0
                    # DDR address segment name format: /bridge_to_host/memory/DDR_X/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK, being
                    # DDR_X each DDR bank
                    foreach addr_seg [get_bd_addr_segs -regexp {.*/DDR_[0-9]/.*/C0_DDR4_ADDRESS_BLOCK}] {
                        assign_bd_address $addr_seg -offset [expr {$base_addr + $bank_size*$bank_num}] -range $bank_size
                        incr bank_num
                    }

                    # Exclude unused DDR_CTRL segments
                    # DDR_CTRL address segment name format: /bridge_to_host/memory/DDR_X/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG, being
                    # DDR_X each DDR bank
                    foreach addr_seg [get_bd_addr_segs -regexp {/bridge_to_host/memory/DDR_[0-9]/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG}] {
                        assign_bd_address -quiet $addr_seg
                        exclude_bd_addr_seg [get_bd_addr_segs -regexp {/bridge_to_host/.*/SEG_DDR_C0_REG_?[0-9]?}]
                    }
                } elseif {$mem_type eq "hbm"} {
                    set bank_num 0
                    # HBM address segment name format: /bridge_to_host/memory/HBM/SAXI_XX[_8HI]/HBM_MEMYY, being
                    # SAXI_XX[_8HI] the AXI interface used
                    # HBM_MEMYY each HBM bank
                    foreach addr_seg [get_bd_addr_segs -regexp {.*/SAXI_[0-9]{2}(_8HI)?/HBM_MEM[0-9]{2}}] {
                        assign_bd_address $addr_seg -offset [expr {($bank_num%$num_banks)*$bank_size}] -range $bank_size
                        incr bank_num
                    }
                }
                if {${AIT::ompif}} {
                    # Add ompif and ethernet mapping
                    # Some addresses are accessible thorugh jtag and qdma
                    # The jtag master doesn't have access to the bitinfo, so all addresses must be hardcoded
                    assign_bd_address [get_bd_addr_segs ethernet_subsystem/eth_100G_controller_0/s_axi/reg0] -range 16384 -offset 0x100000
                    assign_bd_address [get_bd_addr_segs ethernet_subsystem/eth_100G_rx_wrapper_0/s_axi/reg0] -range 16384 -offset 0x104000
                    assign_bd_address [get_bd_addr_segs ompif_message_sender_0/ompif_message_sender/cntrl/reg0] -range 16384 -offset 0x108000
                    assign_bd_address [get_bd_addr_segs ompif_message_receiver_0/ompif_message_receiver/cntrl/Reg] -range 16384 -offset 0x114000
                    assign_bd_address [get_bd_addr_segs jtag_gpio/S_AXI/Reg] -range 4096 -offset 0x10C000
                    assign_bd_address -target_address_space /ompif_message_receiver_0/ompif_message_receiver/bufwr [get_bd_addr_segs axi_inter_msg_recv_bufwr/axiu_dwidth_downsize_0/slv/reg0]
                    assign_bd_address -target_address_space /ompif_message_receiver_0/ompif_message_receiver/memcpy [get_bd_addr_segs axi_inter_msg_recv_memcpy/axiu_dwidth_downsize_0/slv/reg0]
                    assign_bd_address -target_address_space /ompif_message_sender_0/ompif_message_sender/moMEM [get_bd_addr_segs axi_inter_msg_send/axiu_dwidth_downsize_0/slv/reg0]
                }
            }
        }

        # Placeholder for static register slices feature
        proc static_logic_register_slices {} {
            AIT::utils::warning_msg "Board ${::AIT::board} has no support for static logic register slices"
        }

        # Placeholder for power monitor feature
        proc add_power_monitor {} {
            AIT::utils::warning_msg "Board ${::AIT::board} has no support for power monitoring"
        }

        # Placeholder for thermal monitor feature
        proc add_thermal_monitor {} {
            AIT::utils::warning_msg "Board ${::AIT::board} has no support for thermal monitoring"
        }

        proc add_ethernet_subsystem {} {
            AIT::utils::error_msg "Board ${::AIT::board} has no support for ethernet"
        }

        # Creates and connects a tree of interconnects that allows an arbitrary number of AXI-stream slaves to connect to up to 16 AXI-stream masters
        proc create_inStream_Inter_tree { stream_name nmasters nslaves clk inter_rstn peri_rstn } {
            set ninter [expr {int(ceil($nslaves/16.))}]
            set prev_ninter $nslaves
            set inter_level 0
            set inter_stride 1

            # First level uses interconnects with more than one master if required
            for {set i 0} {$i < $ninter} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_$i

                # Last interconnect may need less slaves
                if {($i == $ninter-1) && ($prev_ninter%16)} {
                    set num_si [expr {$prev_ninter%16}]
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
            set ninter [expr {int(ceil($ninter/16.))}]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set m 0} {$m < $nmasters} {incr m} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_m${m}_$i

                        # Last interconnect may need less slaves
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_si [expr {$prev_ninter%16}]
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
                            set master_inter_num [expr {$i*16 + $j}]
                            set master_inter_level [expr {$inter_level - 1}]
                            if {$inter_level == 1} {
                                set master_inf [format %02u $m]
                                set master_inter ${stream_name}_lvl${master_inter_level}_$master_inter_num
                            } else {
                                set master_inf 00
                                set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_$master_inter_num
                            }
                            set slave [format %02u [expr {$j%16}]]
                            connect_bd_intf_net [get_bd_intf_pins $master_inter/M${master_inf}_AXIS] [get_bd_intf_pins $inter_name/S${slave}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr {int(ceil($ninter/16.))}]
                incr inter_level
            }
            return [expr {$inter_level - 1}]
        }

        # Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
        proc create_outStream_Inter_tree { stream_name nslaves nmasters clk inter_rstn peri_rstn } {
            set ninter [expr {int(ceil($nmasters/16.))}]
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
                    set num_mi [expr {$prev_ninter%16}]
                } else {
                    set num_mi 16
                }

                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                set inter_conf $arb_config
                lappend inter_conf CONFIG.NUM_MI $num_mi CONFIG.NUM_SI $nslaves

                for {set j 0} {$j < $num_mi} {incr j} {
                    set master_num [format %02u $j]
                    set base_dest [format "32\'d%d" [expr {$i*$stride*16 + $j*$stride}]]
                    set high_dest [format "32\'d%d" [expr {$i*$stride*16 + ($j+1)*$stride - 1}]]
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
            set ninter [expr {int(ceil($ninter/16.))}]
            set stride [expr {$stride*16}]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set s 0} {$s < $nslaves} {incr s} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_s${s}_$i

                        # Last interconnect may need less masters
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_mi [expr {$prev_ninter%16}]
                        } else {
                            set num_mi 16
                        }

                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                        set inter_conf [list CONFIG.NUM_MI $num_mi CONFIG.NUM_SI {1}]

                        for {set j 0} {$j < $num_mi} {incr j} {
                            set master_num [format %02u $j]
                            set base_dest [format "32\'d%d" [expr {$i*$stride*16 + $j*$stride}]]
                            set high_dest [format "32\'d%d" [expr {$i*$stride*16 + ($j+1)*$stride - 1}]]
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
                            set slave_inter_num [expr {$i*16 + $j}]
                            set slave_inter_level [expr {$inter_level - 1}]
                            set master [format %02u $j]
                            if {$inter_level == 1} {
                                set slave_inf [format %02u $s]
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_$slave_inter_num
                            } else {
                                set slave_inf 00
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_s${s}_$slave_inter_num
                            }
                            connect_bd_intf_net [get_bd_intf_pins $inter_name/M${master}_AXIS] [get_bd_intf_pins $slave_inter/S${slave_inf}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr {int(ceil($ninter/16.))}]
                set stride [expr {$stride*16}]
                incr inter_level
            }
            return [expr {$inter_level - 1}]
        }

        # Creates and connects a nested interconnect
        proc create_nested_interconnect {parent_inter {num 1}} {
            variable board_axi_inters
            set index [lsearch -regexp $board_axi_inters [get_property NAME $parent_inter]]
            set board_axi_inters [lreplace $board_axi_inters $index $index]

            AIT::utils::info_msg "Creating $num nested interconnects for $parent_inter"

            set parent_inter_slaves [get_property CONFIG.NUM_SI $parent_inter]
            set_property CONFIG.NUM_SI [expr {$parent_inter_slaves + $num - 1}] $parent_inter
            for {set i 0} {$i < $num} {incr i} {
                set nested_inter "${parent_inter}_$i"
                set intf_num [format %02u [expr {$parent_inter_slaves + $i - 1}]]

                # Create new nested interconnect and configure it
                set nested_inter [create_bd_cell -vlnv xilinx.com:ip:axi_interconnect $nested_inter]
                set_property -dict [list \
                    CONFIG.NUM_MI {1} \
                    CONFIG.NUM_SI {1} \
                    CONFIG.STRATEGY ${::AIT::interconOpt} \
                 ] $nested_inter

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
                        CONFIG.S${intf_num}_ARB_PRIORITY [expr {15 - ($intf_num%16)}] \
                        CONFIG.XBAR_DATA_WIDTH $data_width \
                     ] $parent_inter
                }

                # Connect clocks and resets
                connect_clock [get_bd_pins $nested_inter/ACLK]
                connect_clock [get_bd_pins $nested_inter/M00_ACLK]
                connect_reset [get_bd_pins $nested_inter/ARESETN] [get_bd_pins /system_reset/clk_app_rstn]
                connect_reset [get_bd_pins $nested_inter/M00_ARESETN]

                # Connect nested interconnect to parent interconnect
                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $nested_inter/M00_AXI] [get_bd_intf_pins $parent_inter/S${intf_num}_AXI]

                connect_clock [get_bd_pins $parent_inter/S${intf_num}_ACLK]
                connect_reset [get_bd_pins $parent_inter/S${intf_num}_ARESETN]
            }
            set board_axi_inters [get_board_axi_inters]
        }

        # Connects the IP to the host through the given interface
        proc connect_to_axi_intf {src mode {num ""} {clk ""} {rst ""}} {
            variable board_axi_inters

            # Open datainterfaces.txt file
            set datainterfaces_file [open ../${::AIT::name_Project}.datainterfaces.txt "a"]

            # Look for src in dataInterfaces_map
            set index [lsearch -regexp ${::AIT::dataInterfaces_map} ".*[string trimleft $src {/}].*"]
            if {$index != -1} {
                set intf [lindex [lindex ${::AIT::dataInterfaces_map} $index] 1]
                # Interface must be 'S_AXI_X' where X is the value we need for $num
                set num [regsub -all "(^(/)?${mode}_AXI_|(_Inter)?$)" $intf ""]
            }

            # Get AXI interface by num or the least occupied
            if {$num ne ""} {
                set index [lsearch -exact $board_axi_inters [lsearch -regexp -inline -index 1 [lsearch -all -inline -index 0 $board_axi_inters $mode] "${mode}_AXI_(${num}|[format %02u $num])_Inter"]]
                if {$index == -1} {
                    if {$mode eq "S"} {
                        set mode "slave"
                    } elseif {$mode eq "M"} {
                        set mode "master"
                    }
                    AIT::utils::error_msg "Cannot connect $src to $mode interface $num. It does not exist"
                }
            } else {
                set index [lsearch -index 0 $board_axi_inters $mode]
            }

            set mode [lindex [lindex $board_axi_inters $index] 0]
            set dst_name [lindex [lindex $board_axi_inters $index] 1]
            set occupation [lindex [lindex $board_axi_inters $index] 2]
            set capacity [lindex [lindex $board_axi_inters $index] 3]
            set board_axi_inters [lreplace $board_axi_inters $index $index]
            set intf_num [regsub -all "(^(/)?${mode}_AXI_|(_)?Inter(_\[0-9\]*)?$)" $dst_name ""]

            # Interconnect is full
            if {$occupation == $capacity} {
                AIT::utils::error_msg "${dst_name} interface occupation is 100%"
            }

            set dst [get_bd_cells -hierarchical $dst_name]

            set intf ${mode}[format %02u $occupation]

            set_property CONFIG.NUM_${mode}I [expr {$occupation + 1}] $dst
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
                    CONFIG.${intf}_ARB_PRIORITY [expr {15 - ($occupation%16)}] \
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

            set src_path [regsub [get_property NAME $src] [get_property PATH $src] ""]
            set src_clk_pin [get_clk_pin_from_intf_pin $src]
            set src_rst_pin [get_bd_pins -quiet -hierarchical -filter "TYPE == rst && PATH =~ ${src_path}*" [get_property -quiet CONFIG.ASSOCIATED_RESET $src_clk_pin]]

            if {$src_clk_pin ne ""} {
                connect_clock $src_clk_pin $clk
            }

            if {$src_rst_pin ne ""} {
                connect_reset $src_rst_pin $rst
            }

            connect_clock $clk_pin $clk
            connect_reset $rst_pin $rst
            connect_bd_intf_net -boundary_type upper $src $axi_pin

            incr occupation

            lappend board_axi_inters "$mode $dst_name $occupation $capacity"
            set board_axi_inters [lsort -integer -index 2 -increasing $board_axi_inters]

            # Add a line to datainterfaces.txt, if interface is indexable
            if {[llength $intf_num]} {
                puts $datainterfaces_file "$src\t$intf_num"
            }
            close $datainterfaces_file

            return [list "$dst_name" "${mode}_AXI"]
        }

        # Connects src_clk to dst_clk (pin or net) or to the default clock
        proc connect_clock {src_clk {dst_clk ""}} {
            if {$dst_clk eq ""} { set dst_clk [get_bd_pins clock_generator/clk_app] }
            if {!([llength [get_bd_nets -quiet -of_objects $src_clk]])} {
                if {[get_property CLASS $dst_clk] eq "bd_net"} {
                    connect_bd_net $src_clk -net $dst_clk
                } elseif {[get_property CLASS $dst_clk] eq "bd_pin"} {
                    connect_bd_net $src_clk $dst_clk
                }
            }
        }

        # Connects src_rst to dst_rst (pin or net) or to the default reset
        proc connect_reset {src_rst {dst_rst ""}} {
            if {$dst_rst eq ""} { set dst_rst [get_bd_pins system_reset/clk_app_rstn] }
            if {!([llength [get_bd_nets -quiet -of_objects $src_rst]])} {
                if {[get_property CLASS $dst_rst] eq "bd_net"} {
                    connect_bd_net $src_rst -net $dst_rst
                } elseif {[get_property CLASS $dst_rst] eq "bd_pin"} {
                    connect_bd_net $src_rst $dst_rst
                }
            }
        }

        # Returns a clk bd_pin object from where the input parameter clk_pin is generated
        proc get_source_clk_from_clk_pin {clk_pin} {
            set clk_domain [get_property CONFIG.CLK_DOMAIN $clk_pin]
            set source_clk [get_bd_pins -hierarchical -filter "(TYPE == clk) && (CONFIG.CLK_DOMAIN == $clk_domain) && (DIR == O)"]

            return $source_clk
        }

        # Returns a clk bd_pin object of the clock associated to the input parameter intf_pin
        proc get_clk_pin_from_intf_pin {intf_pin} {
            set ip [get_bd_cells -of_objects $intf_pin]
            set intf_name [get_property NAME $intf_pin]
            set clk_pin [get_bd_pins -quiet -of_objects $ip -regexp -filter "(TYPE == clk) && (CONFIG.ASSOCIATED_BUSIF =~ .*$intf_name.*)"]

            return $clk_pin
        }

        # Returns a bd_net of a reset net synchronous to the input parameter clk_pin
        # Iterates over the clock pins sharing the same net as clk_pin and looks for associated resets, then returns the first instance
        proc get_rst_net_from_clk_pin {clk_pin} {
            set clk_net [get_bd_nets -of_objects $clk_pin]
            foreach pin [get_bd_pins -of_objects $clk_net] {
                set clk_rst [get_property CONFIG.ASSOCIATED_RESET $pin]
                foreach clk_rst_pin [split $clk_rst {:}] {
                    set ip_path [string range [get_property PATH $pin] 0 [string last / [get_property PATH $pin]]]
                    set rst_net [get_bd_nets -of_objects [get_bd_pins $ip_path/$clk_rst_pin]]
                    if [llength $rst_net] {
                        return $rst_net
                    }
                }
            }
            AIT::utils::error_msg "No valid reset net found for clock pin ($clk_pin)"
        }

        # Sets target frequency, retrieves actual achieved frequency and returns it
        proc set_and_get_freq {targetFreq} {
            AIT::utils::info_msg "Using generic set_and_get_freq procedure"

            set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $targetFreq [get_bd_cells clock_generator]
            set actFreq [expr {[get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_app]]/1000000}]

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

        # Generate bitinfo features bitmap
        proc generate_bitmap_bitinfo {} {
            variable bitmap_bitInfo 0x0

            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::hwinst} == True)<<0}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::hwinst} || ${::AIT::hwcounter})<<1}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | ((${::AIT::interconOpt} - 1)<<2)}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::simplify_interconnection} == True)<<3}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::enable_pom_axilite} == True)<<4}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::task_creation} == True)<<5}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::deps_hwruntime} == True)<<6}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::lock_hwruntime} == True)<<7}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::enable_spawn_queues} == True)<<8}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::power_monitor} == True)<<9}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::thermal_monitor} == True)<<10}]
            set bitmap_bitInfo [expr {$bitmap_bitInfo | (${::AIT::ompif} == True)<<11}]

            return [format 0x%08x $bitmap_bitInfo]
        }

        # Generates HDL wrapper
        proc generate_wrapper {} {
            AIT::utils::info_msg "Using generic generate_wrapper procedure"

            set_property target_language ${::AIT::target_lang} [current_project]

            make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
        }

        # Removes derelict and unused IPs
        proc cleanup_bd {} {
            variable board_axi_inters

            foreach axi_intf $board_axi_inters {
                foreach {mode name occupation capacity} $axi_intf {
                    if {$occupation == 0} {
                        set mem_type [dict get ${::AIT::address_map} "mem_type"]
                        if {$mem_type eq "hbm"} {
                            set intf [regsub -all {(^S_AXI_|_Inter$)} $name ""]
                            set_property CONFIG.USER_SAXI_$intf {false} [get_bd_cells -hierarchical HBM]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/memory/S${intf}_AXI]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/S${intf}_AXI]
                        }
                        delete_bd_objs [get_bd_cells -hierarchical $name]
                    }
                }
            }
        }

        proc after_acc_configuration {} {
        }
    }
}
