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
    namespace eval design {
        # Connects srcClk to dstClk (pin or net) or to the default clock
        proc connect_clock {srcClk {dstClk ""}} {
            if {${dstClk} eq ""} {
                set dstClk [get_bd_pins /clock_generator/clk_app]
            }
            if {!([llength [get_bd_nets -quiet -of_objects ${srcClk}]])} {
                if {[get_property CLASS ${dstClk}] eq "bd_net"} {
                    connect_bd_net ${srcClk} -net ${dstClk}
                } elseif {[get_property CLASS ${dstClk}] eq "bd_pin"} {
                    connect_bd_net ${srcClk} ${dstClk}
                }
            }
            return ${dstClk}
        }

        # Connects srcRst to dstRst (pin or net) or to the default reset
        proc connect_reset {srcRst {dstRst ""}} {
            if {${dstRst} eq ""} {
                set dstRst [get_bd_pins /system_reset/clk_app_rstn]
            }
            if {![llength [get_bd_nets -quiet -of_objects ${srcRst}]]} {
                if {[get_property CLASS ${dstRst}] eq "bd_net"} {
                    connect_bd_net ${srcRst} -net ${dstRst}
                } elseif {[get_property CLASS ${dstRst}] eq "bd_pin"} {
                    connect_bd_net ${srcRst} ${dstRst}
                }
            }
            return ${dstRst}
        }

        # Instantiate System ILA and connect to intfPinName
        proc debug_intf {intfPinName} {
            set intfPin [get_bd_intf_pins -quiet ${intfPinName}]
            if {${intfPin} eq ""} {
                AIT::utils::error_msg "Interface to debug not found (${intfPinName})"
            }

            set intfPinType [get_property VLNV ${intfPin}]
            set intfPinClk [get_associated_clk_pin ${intfPin}]
            set src_clk [get_property NAME [AIT::design::get_driver_pin ${intfPinClk}]]

            set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets -of_objects ${intfPin}]

            # Look for an available System ILA
            set found_ila ""
            foreach ila_ip [get_bd_cells -quiet -filter "(VLNV =~ xilinx.com:ip:system_ila*) && (NAME =~ system_ila_${src_clk}*)"] {
                if {[get_property CONFIG.C_NUM_MONITOR_SLOTS ${ila_ip}] < 16} {
                    set found_ila ${ila_ip}
                    break
                }
            }

            # If found available System ILA, increment used slots
            # If not, instantiate and connect a new one
            if {[llength ${found_ila}]} {
                set slot_num [get_property CONFIG.C_NUM_MONITOR_SLOTS ${ila_ip}]
                set_property -dict [list \
                    CONFIG.C_NUM_MONITOR_SLOTS [expr {${slot_num} + 1}] \
                    CONFIG.C_SLOT_${slot_num}_INTF_TYPE [get_property VLNV ${intfPin}] \
                 ] ${ila_ip}
            } else {
                set num_ila [llength [get_bd_cells -quiet -filter {VLNV =~ xilinx.com:ip:system_ila:*} *system_ila_${src_clk}*]]
                set ila_ip [create_bd_cell -vlnv xilinx.com:ip:system_ila system_ila_${src_clk}_${num_ila}]
                set slot_num 0
                set_property -dict [list \
                    CONFIG.C_NUM_MONITOR_SLOTS [expr {${slot_num} + 1}] \
                    CONFIG.C_SLOT_${slot_num}_INTF_TYPE [get_property VLNV ${intfPin}] \
                 ] ${ila_ip}
                AIT::design::connect_clock [get_bd_pins ${ila_ip}/clk]
                AIT::design::connect_reset [get_bd_pins ${ila_ip}/resetn] [AIT::design::get_synchronous_rst_pin [get_bd_pins ${ila_ip}/clk]]
            }

            # Connect intfPin to its corresponding port, depending on the type
            # NOTE: We can expand this to support other types (e.g. BRAM, GPIO, etc.)
            if {[string match "xilinx.com:interface:aximm_rtl:*" ${intfPinType}]} {
                connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${ila_ip}/SLOT_${slot_num}_AXI]
            } elseif {[string match "xilinx.com:interface:axis_rtl:*" ${intfPinType}]} {
                connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${ila_ip}/SLOT_${slot_num}_AXIS]
            } else {
                AIT::utils::error_msg "Debug interface type (${intfPinType}) not supported for interface ${intfPin}"
            }
        }

        # Generate bitinfo features bitmap
        proc generate_bitinfo_bitmap {} {
            variable bitinfoBitmap 0x0
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "hwinst"] ? 1 : 0)<<0}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "hwinst"] || [dict get ${AIT::vars::aitConfig} "hwcounter"])<<1}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ((([dict get ${AIT::vars::aitConfig} "interconnect_opt"] eq "area") ? 0 : 1)<<2)}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "enable_pom_axilite"] ? 1 : 0)<<4}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "task_creation"] ? 1 : 0)<<5}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "deps_hwruntime"] ? 1 : 0)<<6}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "lock_hwruntime"] ? 1 : 0)<<7}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "disable_spawn_queues"] ? 0 : 1)<<8}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "power_monitor"] ? 1 : 0)<<9}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "thermal_monitor"] ? 1 : 0)<<10}]
            set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::vars::aitConfig} "ompif"] ? 1 : 0)<<11}]
            return [format 0x%08x ${bitinfoBitmap}]
        }

        # Returns a clk bd_pin object of the clock associated to the input parameter intfPinName
        proc get_associated_clk_pin {intfPinName} {
            set intfPin [get_bd_intf_pins ${intfPinName}]
            set intfIP [get_bd_cells -of_objects ${intfPin}]
            set intfName [get_property NAME ${intfPin}]
            set intfClkPin [get_bd_pins -quiet -of_objects ${intfIP} -regexp -filter "(TYPE == clk) && (CONFIG.ASSOCIATED_BUSIF =~ .*${intfName}.*)"]
            if {![llength ${intfClkPin}]} {
                if {[get_property TYPE ${intfPin}] eq "hier"} {
                    set intfPinInnerNet [get_bd_intf_nets -boundary_type lower -of_objects ${intfPin}]
                    set innerNetIntfPin [get_bd_intf_pins -of_objects ${intfPinInnerNet} -filter "PATH != ${intfPin}"]
                    set intfClkPin [get_associated_clk_pin ${innerNetIntfPin}]
                } else {
                    AIT::utils::error_msg "Unknown interface type [get_property TYPE ${intfPin}]"
                }
            }
            return ${intfClkPin}
        }

        proc get_associated_rst_pin {clkPinName} {
            set clkPin [get_bd_pins ${clkPinName}]
            set clkIP [get_bd_cells -of_objects ${clkPin}]
            foreach rstPin [split [get_property CONFIG.ASSOCIATED_RESET ${clkPin}] {:}] {
                set rstPin [get_bd_pins -quiet ${clkIP}/${rstPin}]
                if {[llength ${rstPin}]} {
                    return ${rstPin}
                }
            }
            AIT::utils::warning_msg "No associated reset pin found for clock ${clkPinName}"
        }

        # Returns the total number of free memory interfaces
        proc get_available_mem_intfs {} {
            set availableMemIntfs 0
            foreach memIntf ${AIT::vars::memIntfsList} {
                dict with memIntf {
                    if {${role} eq "slave"} {
                        incr availableMemIntfs [expr {${capacity} - ${occupation}}]
                    }
                }
            }
            return ${availableMemIntfs}
        }

        # Returns the bd_pin object that drives the net where pinName is connected to
        proc get_driver_pin {pinName {visitedPins ""}} {
            set pin [get_bd_pins -quiet ${pinName}]

            # If the initial pin does not exist, return error
            if {![llength ${visitedPins}] && ![llength ${pin}]} {
                AIT::utils::error_msg "Pin ${pinName} does not exist"
            }

            set pinType [get_property TYPE ${pin}]

            # Check if the driver is in the current net and return it
            foreach pinNet [get_bd_nets -quiet -boundary_type both -of_objects ${pin}] {
                set driverPins [get_bd_pins -quiet -of_objects ${pinNet} -filter "(TYPE == ${pinType}) && (DIR == O)"]
                foreach driverPin ${driverPins} {
                    # Only return pin if is part of an IP (i.e. not a hierarchy pin)
                    if {[get_property VLNV [get_bd_cells -of_objects ${driverPin}]] ne ""} {
                        return ${driverPin}
                    }
                }
            }

            # If the driver is not in the current net, check the unvisited neighbouring pins
            lappend visitedPins ${pin}
            foreach neighbourPin [get_bd_pins -quiet -of_objects [get_bd_nets -boundary_type both -of_objects ${pin}] -filter "TYPE == ${pinType} && PATH != [join ${visitedPins} { && PATH != }]"] {
                set neighbourPinIP [get_bd_cells -of_objects ${neighbourPin}]
                if {!([get_property TYPE ${neighbourPinIP}] eq "hier" && [get_property VLNV ${neighbourPinIP}] ne "")} {
                    set driverPin [AIT::design::get_driver_pin ${neighbourPin} ${visitedPins}]
                    if {[llength ${driverPin}]} {
                        return ${driverPin}
                    }
                    lappend visitedPins ${neighbourPin}
                }
            }

            # At this point, if no source has been found and we are the initial pin, return a warning
            if {![llength ${visitedPins}]} {
                AIT::utils::warning_msg "No driver pin found for ${pinName}"
            }
        }

        proc get_mem_intfs {role num IPName pinBlock {parentDict ""} {all False}} {
            set occupation 0
            set capacity 16

            foreach IP [get_bd_cells -quiet ${IPName}] {
                if {${role} eq "master"} {
                    set mode "M"
                } elseif {${role} eq "slave"} {
                    set mode "S"
                }
                set occupation [get_property CONFIG.NUM_${mode}I ${IP}]
            }

            dict set intfDict "role" ${role}
            dict set intfDict "num" ${num}
            dict set intfDict "IPName" ${IPName}
            dict set intfDict "occupation" ${occupation}
            dict set intfDict "capacity" ${capacity}
            dict set intfDict "pinBlock" [list {*}${pinBlock}]
            dict set intfDict "parentDict" ${parentDict}

            set nestedIPs [get_bd_cells -quiet -regexp "${IPName}(_\[0-9\]+)"]
            if {[llength ${nestedIPs}]} {
                if {${role} eq "master"} {
                    set mode "S"
                } elseif {${role} eq "slave"} {
                    set mode "M"
                }
                foreach nestedIP ${nestedIPs} {
                    AIT::design::get_mem_intfs ${role} ${num} [get_property NAME ${nestedIP}] ${IPName}/${mode}[format %02u ${occupation}]_AXI ${intfDict} ${all}
                    incr occupation
                }
                if {${all}} {
                    lappend AIT::vars::memIntfsList ${intfDict}
                }
            } else {
                if {(${occupation} < ${capacity}) || ${all}} {
                    lappend AIT::vars::memIntfsList ${intfDict}
                }
            }
        }

        proc get_synchronous_rst_pin {clkPinName} {
            set clkPin [get_bd_pins ${clkPinName}]
            foreach rstPin [AIT::design::get_associated_rst_pin ${clkPin}] {
                set srcRstPin [AIT::design::get_driver_pin ${rstPin}]
                if {[llength ${srcRstPin}]} {
                    return ${srcRstPin}
                }
            }
            AIT::utils::warning_msg "No synchronous reset pin found for clock pin ${clkPinName}"
        }

        # Instantiates and connects required common IPs
        proc init_bd {} {

            # Instantiate interconnects for every memory interface block defined in board_info.json
            AIT::design::initialize_mem_intfs

            # On alveo devices, connect host to memory
            if {([dict get ${AIT::vars::board} "arch" "device"] eq "alveo") && ([dict get ${AIT::vars::board} "memory" "type"] eq "ddr")} {
                set hostIntfDict [AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bridge_to_host/M_AXI]]

                if {[dict get ${AIT::vars::aitConfig} "memory_interleaving_stride"]} {
                    AIT::AXI::add_addrInterleaver [get_bd_intf_pins bridge_to_host/M_AXI] host_M_AXI
                }

            }

            # Create instance: bitinfo, and set properties
            set bitinfo [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen bitinfo]
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
                CONFIG.Write_Width_B {32} \
                CONFIG.Read_Width_A {32} \
                CONFIG.Read_Width_B {32} \
                CONFIG.use_bram_block {Stand_Alone} \
            ] ${bitinfo}

            # Create instance: bitInfo_BRAM_Ctrl, and set properties
            set bitinfoBRAMCtrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl bitInfo_BRAM_Ctrl]
            set_property -dict [list \
                CONFIG.PROTOCOL {AXI4LITE} \
                CONFIG.SINGLE_PORT_BRAM {1} \
            ] ${bitinfoBRAMCtrl}

            # Create instance: managed_reset, and set properties
            set managedReset [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio managed_reset]
            set_property -dict [list \
                CONFIG.C_ALL_OUTPUTS {1} \
                CONFIG.C_DOUT_DEFAULT {0x00000001} \
                CONFIG.C_GPIO_WIDTH {1} \
            ] ${managedReset}

            # Create instance: reset_AND, and set properties
            set resetAND [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic system_reset/managed_reset_AND]
            set_property -dict [list \
                CONFIG.C_SIZE {1} \
                CONFIG.C_OPERATION {and} \
            ] ${resetAND}

            create_bd_pin -dir I -type rst system_reset/managed_reset
            create_bd_pin -dir O -type rst system_reset/clk_app_managed_rstn

            set appManagedSysReset [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_app_managed]
            set_property -dict [list \
                CONFIG.C_EXT_RST_WIDTH {1}
            ] ${appManagedSysReset}

            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/slowest_sync_clk] [get_bd_pins system_reset/clk_app]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/peripheral_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/dcm_locked] [get_bd_pins system_reset/clk_gen_locked]
            connect_bd_net [get_bd_pins system_reset/managed_reset] [get_bd_pins system_reset/managed_reset_AND/Op1]
            connect_bd_net [get_bd_pins managed_reset/gpio_io_o] [get_bd_pins system_reset/managed_reset]
            connect_bd_net [get_bd_pins system_reset/managed_reset_AND/Op2] [get_bd_pins system_reset/proc_sys_reset_clk_app/peripheral_aresetn]
            connect_bd_net [get_bd_pins system_reset/managed_reset_AND/res] [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/ext_reset_in]

            if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
                || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] 1
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins managed_reset/S_AXI] 1
            } else {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI]
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins managed_reset/S_AXI]
            }
            connect_bd_intf_net [get_bd_intf_pins bitInfo_BRAM_Ctrl/BRAM_PORTA] [get_bd_intf_pins bitinfo/BRAM_PORTA]

            AIT::templates::Picos_OmpSs_Manager

            if {[dict get ${AIT::vars::aitConfig} "power_monitor"]} {
                AIT::board::add_power_monitor
            }

            if {[dict get ${AIT::vars::aitConfig} "thermal_monitor"]} {
                AIT::board::add_thermal_monitor
            }

            # Set and get the actual PS frequency
            set ::actFreq [AIT::board::set_and_get_freq [dict get ${AIT::vars::aitConfig} "clock"]]

            save_bd_design -quiet
        }

        # Returns a list with the available memory interfaces along with their role, occupation and capacity
        proc initialize_mem_intfs {{all False}} {
            set ::AIT::vars::memIntfsList [list]
            dict with AIT::vars::board "memory" {
                dict for {intfRole intfBlockList} ${interfaces} {
                    set intfNum 0
                    foreach intfBlock ${intfBlockList} {
                        AIT::design::get_mem_intfs ${intfRole} ${intfNum} ${intfRole}_Inter_${intfNum} ${intfBlock} {} ${all}
                        incr intfNum
                    }
                }
            }
            set ::AIT::vars::memIntfsList [lsort -command AIT::utils::comp_dict -increasing ${AIT::vars::memIntfsList}]
        }
    }
}
