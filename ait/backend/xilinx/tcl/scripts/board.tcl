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

## Board-specific generic procedures
## Can be overwritten through the file procs.tcl on the board folder

namespace eval AIT {
    namespace eval board {
        # Placeholder for power monitor feature
        proc add_power_monitor {} {
            AIT::utils::error_msg "Board [dict get ${AIT::vars::board} "name"] has no support for power monitoring"
        }

        # Placeholder for thermal monitor feature
        proc add_thermal_monitor {} {
            AIT::utils::error_msg "Board [dict get ${AIT::vars::board} "name"] has no support for thermal monitoring"
        }

        # Maps board memory to address map
        proc configure_address_map {} {
            set boardMemType [dict get ${AIT::vars::board} "memory" "type"]
            set boardMemBaseAddr [dict get ${AIT::vars::board} "memory" "base_addr"]

            # Assign memory address space
            if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
                || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {

                set boardMemSize [dict get ${AIT::vars::board} "memory" "size"]
                # Zynq DDR address segment name format: /bridge_to_host/S_AXI_HPX/HPX_DDR_LOWOCM
                # ZynqMP DDR address segment name format: /bridge_to_host/S_AXI_GPY/HPX_DDR_LOW, being
                # S_AXI_HPX the AXI interface used
                foreach memBdAddrSeg [get_bd_addr_segs -regexp {.*/HP[0-9]_DDR_LOW(OCM)?}] {
                    assign_bd_address ${memBdAddrSeg} -offset ${boardMemBaseAddr} -range ${boardMemSize}
                }

                # Exclude unused DDR address segments
                foreach exclBdAddrSeg [list {DDR_HIGH} {QSPI} {LPS_OCM} {PCIE_LOW}] {
                    foreach memBdAddrSeg [get_bd_addr_segs -quiet -regexp "/bridge_to_host/.*/HP\[0-9\]_${exclBdAddrSeg}"] {
                        assign_bd_address -quiet ${memBdAddrSeg}
                        exclude_bd_addr_seg [get_bd_addr_segs -regexp ".*/SEG_bridge_to_host_HP\[0-9\]_${exclBdAddrSeg}"]
                    }
                }
            } elseif {[dict get ${AIT::vars::board} "arch" "device"] eq "alveo"} {
                set boardMemBankSize [dict get ${AIT::vars::board} "memory" "bank_size"]
                set boardMemNumBanks [dict get ${AIT::vars::board} "memory" "num_banks"]
                if {${boardMemType} eq "ddr"} {
                    set memBankNum 0
                    # DDR address segment name format: /bridge_to_host/memory/DDR_X/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK, being
                    # DDR_X each DDR bank
                    foreach memBdAddrSeg [get_bd_addr_segs -regexp {.*/DDR_[0-9]/.*/C0_DDR4_ADDRESS_BLOCK}] {
                        assign_bd_address ${memBdAddrSeg} -offset [expr {${boardMemBaseAddr} + ${boardMemBankSize}*${memBankNum}}] -range ${boardMemBankSize}
                        incr memBankNum
                    }

                    # Exclude unused DDR_CTRL segments
                    # DDR_CTRL address segment name format: /bridge_to_host/memory/DDR_X/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG, being
                    # DDR_X each DDR bank
                    foreach memBdAddrSeg [get_bd_addr_segs -regexp {/bridge_to_host/memory/DDR_[0-9]/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG}] {
                        assign_bd_address -quiet ${memBdAddrSeg}
                        exclude_bd_addr_seg [get_bd_addr_segs -regexp {/bridge_to_host/.*/SEG_DDR_C0_REG_?[0-9]?}]
                    }
                } elseif {${boardMemType} eq "hbm"} {
                    set memBankNum 0
                    # HBM address segment name format: /bridge_to_host/memory/HBM/SAXI_XX[_8HI]/HBM_MEMYY, being
                    # SAXI_XX[_8HI] the AXI interface used
                    # HBM_MEMYY each HBM bank
                    foreach memBdAddrSeg [get_bd_addr_segs -regexp {.*/SAXI_[0-9]{2}(_8HI)?/HBM_MEM[0-9]{2}}] {
                        assign_bd_address ${memBdAddrSeg} -offset [expr {(${memBankNum}%${boardMemNumBanks})*${boardMemBankSize}}] -range ${boardMemBankSize}
                        incr memBankNum
                    }
                }

                if {[dict get ${AIT::vars::aitConfig} "ompif"]} {
                    # Add ompif and ethernet mapping
                    # Some addresses are accessible thorugh jtag and qdma
                    # The jtag master doesn't have access to the bitinfo, so all addresses must be hardcoded
                    assign_bd_address [get_bd_addr_segs ethernet_subsystem/eth_100G_controller_0/s_axi/reg0] -range 16384 -offset 0x100000
                    assign_bd_address [get_bd_addr_segs ethernet_subsystem/eth_100G_rx_wrapper_0/s_axi/reg0] -range 16384 -offset 0x104000
                    assign_bd_address [get_bd_addr_segs OMPIF/message_sender/ompif_message_sender/cntrl/reg0] -range 16384 -offset 0x108000
                    assign_bd_address [get_bd_addr_segs OMPIF/message_receiver/ompif_message_receiver/cntrl/Reg] -range 16384 -offset 0x114000
                    assign_bd_address [get_bd_addr_segs jtag_gpio/S_AXI/Reg] -range 4096 -offset 0x10C000
                    assign_bd_address -target_address_space OMPIF/message_receiver/ompif_message_receiver/bufwr [get_bd_addr_segs axi_inter_msg_recv_bufwr/axiu_dwidth_downsize_0/slv/reg0]
                    assign_bd_address -target_address_space OMPIF/message_receiver/ompif_message_receiver/memcpy [get_bd_addr_segs axi_inter_msg_recv_memcpy/axiu_dwidth_downsize_0/slv/reg0]
                    assign_bd_address -target_address_space OMPIF/message_sender/ompif_message_sender/moMEM [get_bd_addr_segs axi_inter_msg_send/axiu_dwidth_downsize_0/slv/reg0]
                }
            }
        }

        # Enables the memory interface specified in intfDict
        proc enable_mem_intf {intfDict} {
            if {([dict get ${AIT::vars::board} "memory" "type"] eq "hbm") && ([dict get ${intfDict} "role"] eq "slave")} {
                set intfNum [format %02u [dict get ${intfDict} "num"]]
                set memIP [get_bd_cells -hierarchical -filter {VLNV =~ "xilinx.com:ip:hbm:*"}]
                set_property -dict [list \
                  CONFIG.USER_SAXI_${intfNum} {true} \
                ] ${memIP}
                AIT::design::connect_clock [get_bd_pins ${memIP}/AXI_${intfNum}_ACLK]
                AIT::design::connect_reset [get_bd_pins ${memIP}/AXI_${intfNum}_ARESET_N]
            } elseif {[dict get ${AIT::vars::board} "arch" "device"] eq "zynq"} {
                set intfNum [dict get ${intfDict} "num"]
                set memIP [get_bd_cells -hierarchical -filter {VLNV =~ "xilinx.com:ip:processing_system7:*"}]
                if {[dict get ${intfDict} "role"] eq "slave"} {
                    set_property -dict [list \
                      CONFIG.PCW_S_AXI_HP${intfNum}_DATA_WIDTH {64} \
                      CONFIG.PCW_USE_S_AXI_HP${intfNum} {1} \
                    ] ${memIP}
                    AIT::design::connect_clock [AIT::design::get_associated_clk_pin [dict get ${intfDict} "pinBlock"]]
                } elseif {[dict get ${intfDict} "role"] eq "master"} {
                    set_property -dict [list \
                      CONFIG.PCW_USE_M_AXI_GP${intfNum} {1} \
                    ] ${memIP}
                    AIT::design::connect_clock [AIT::design::get_associated_clk_pin [dict get ${intfDict} "pinBlock"]]
                }
            } elseif {[dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp"} {
                set intfNum [dict get ${intfDict} "num"]
                set memIP [get_bd_cells -hierarchical -filter {VLNV =~ "xilinx.com:ip:zynq_ultra_ps_e:*"}]
                if {[dict get ${intfDict} "role"] eq "slave"} {
                    # We must increment by 2 if the interface is slave, because the HP ports start at 2
                    incr intfNum 2
                    set_property -dict [list \
                      CONFIG.PSU__SAXIGP${intfNum}__DATA_WIDTH {128} \
                      CONFIG.PSU__USE__S_AXI_GP${intfNum} {1} \
                    ] ${memIP}
                    AIT::design::connect_clock [AIT::design::get_associated_clk_pin [dict get ${intfDict} "pinBlock"]]
                } elseif {[dict get ${intfDict} "role"] eq "master"} {
                    set_property -dict [list \
                      CONFIG.PSU__MAXIGP${intfNum}__DATA_WIDTH {128} \
                      CONFIG.PSU__USE__M_AXI_GP${intfNum} {1} \
                    ] ${memIP}
                    AIT::design::connect_clock [AIT::design::get_associated_clk_pin [dict get ${intfDict} "pinBlock"]]
                }
            }
        }

        # Generates HDL wrapper
        proc generate_wrapper {} {
            set_property target_language [dict get ${AIT::vars::aitConfig} "target_language"] [current_project]
            make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
        }

        # Returns the number of bits needed to address the board memory
        proc get_addr_width {} {
            if {[dict exists ${AIT::vars::board} "memory" "size"]} {
                set size [dict get ${AIT::vars::board} "memory" "size"]
            } else {
                set size [expr {[dict get ${AIT::vars::board} "memory" "bank_size"]*[dict get ${AIT::vars::board} "memory" "num_banks"]}]
            }
            return [expr {int(ceil(log(${size})/log(2)))}]
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
            return ${baseFreq}
        }

        # Sets target frequency, retrieves actual achieved frequency and returns it
        proc set_and_get_freq {targetFreq} {
            set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${targetFreq} [get_bd_cells clock_generator]
            set actFreq [expr {[get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_app]]/1000000}]

            return ${actFreq}
        }

        # Placeholder for static register slices feature
        proc static_logic_register_slices {} {
            AIT::utils::warning_msg "Board [dict get ${AIT::vars::board} "name"] has no support for static logic register slices"
        }
    }
}
