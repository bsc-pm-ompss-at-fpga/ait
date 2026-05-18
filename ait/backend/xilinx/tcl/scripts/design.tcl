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

namespace eval design {

    variable bdAddrSegmentsList
    variable bdAddrSegmentsDict
    variable memIntfsList

    # Instantiate System ILA and connect to intfPinName
    proc debug_intf {intfPinName} {
        set intfPin [get_bd_intf_pins -quiet ${intfPinName}]
        if {${intfPin} eq ""} {
            AIT::utils::error_msg "Interface to debug not found (${intfPinName})"
        }

        set intfPinClk [AIT::clocks::get_associated_clk_pin ${intfPin}]
        set src_clk [get_property NAME [get_driver_pin ${intfPinClk}]]

        set_property -dict [list \
            HDL_ATTRIBUTE.DEBUG {true}
        ] [get_bd_intf_nets -of_objects ${intfPin}]

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
        if [llength ${found_ila}] {
            set slot_num [get_property CONFIG.C_NUM_MONITOR_SLOTS ${ila_ip}]
            set_property -dict [list \
                CONFIG.C_NUM_MONITOR_SLOTS [expr {${slot_num} + 1}] \
                CONFIG.C_SLOT_${slot_num}_INTF_TYPE [get_property VLNV ${intfPin}]
            ] ${ila_ip}
        } else {
            set num_ila [llength [get_bd_cells -quiet -filter {VLNV =~ xilinx.com:ip:system_ila:*} *system_ila_${src_clk}*]]
            set ila_ip [create_bd_cell -vlnv xilinx.com:ip:system_ila system_ila_${src_clk}_${num_ila}]
            set slot_num 0
            set_property -dict [list \
                CONFIG.C_NUM_MONITOR_SLOTS [expr {${slot_num} + 1}] \
                CONFIG.C_SLOT_${slot_num}_INTF_TYPE [get_property VLNV ${intfPin}]
            ] ${ila_ip}
            AIT::clocks::connect_clock [get_bd_pins ${ila_ip}/clk]
            AIT::resets::connect_reset [get_bd_pins ${ila_ip}/resetn] [AIT::resets::get_synchronous_rst_pin [get_bd_pins ${ila_ip}/clk]]
        }

        # Connect intfPin to its corresponding port, depending on the type
        # NOTE: We can expand this to support other types (e.g. BRAM, GPIO, etc.)
        switch -glob -- [get_property VLNV ${intfPin}] {
            "xilinx.com:interface:aximm_rtl:*" {
                connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${ila_ip}/SLOT_${slot_num}_AXI]
            }
            "xilinx.com:interface:axis_rtl:*" {
                connect_bd_intf_net ${intfPin} [get_bd_intf_pins ${ila_ip}/SLOT_${slot_num}_AXIS]
            }
            default {
                AIT::utils::error_msg "Debug interface type not supported for interface ${intfPin}"
            }
        }
    }

    # Generate bitinfo features bitmap
    proc generate_bitinfo_bitmap {} {
        variable bitinfoBitmap 0x0
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "hwinst"] ? 1 : 0)<<0}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "hwinst"] || [dict get ${AIT::project::aitConfig} "hwcounter"])<<1}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ((([dict get ${AIT::project::aitConfig} "interconnect_opt"] eq "area") ? 0 : 1)<<2)}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "enable_pom_axilite"] ? 1 : 0)<<4}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "task_creation"] ? 1 : 0)<<5}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "deps_hwruntime"] ? 1 : 0)<<6}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "lock_hwruntime"] ? 1 : 0)<<7}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "disable_spawn_queues"] ? 0 : 1)<<8}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "power_monitor"] ? 1 : 0)<<9}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "thermal_monitor"] ? 1 : 0)<<10}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "ompif"] ? 1 : 0)<<11}]
        set bitinfoBitmap [expr {${bitinfoBitmap} | ([dict get ${AIT::project::aitConfig} "imp"] ? 1 : 0)<<12}]
        return [format 0x%08x ${bitinfoBitmap}]
    }

    proc generate_bd_addr_segments_dict {} {
        variable bdAddrSegmentsList
        variable bdAddrSegmentsDict
        # Compute address segments base addresses
        set offset 0
        foreach bdAddrSeg [lsort -increasing -command AIT::utils::comp_dict ${bdAddrSegmentsList}] {
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
                    set addr [format 0x%016x [expr {[dict get ${AIT::project::board} "memory" "ompss_base_addr"] + ${offset}}]]
                    incr offset ${size}
                }
            }
            dict append bdAddrSegmentsDict [dict get ${bdAddrSeg} "tag"] ${bdAddrSeg}
        }
    }

    proc generate_bitinfo_coe_str {} {
        variable bdAddrSegmentsDict

        # Fixed-length fields
        set bitinfoCoeStr "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
        append bitinfoCoeStr [format %08x ${AIT::project::bitinfoVersion}]\n
        append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "num_instances"]]\n
        append bitinfoCoeStr [format %08x [generate_bitinfo_bitmap]]\n
        append bitinfoCoeStr [format %08x [expr {${AIT::project::aitMajorVersion}<<22 | ${AIT::project::aitMinorVersion}<<11 | ${AIT::project::aitPatchVersion}}]]\n
        append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "wrapper_version"]]\n
        append bitinfoCoeStr [format %08x [AIT::board::get_base_freq]]\n
        append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "memory_interleaving_stride"]]\n
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdInQueueHwruntime" "addr"] 10 17]\n
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdInQueueHwruntime" "addr"] 2 9]\n
        append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "cmdin_subqueue_len"]]\n
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdOutQueueHwruntime" "addr"] 10 17]\n
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "cmdOutQueueHwruntime" "addr"] 2 9]\n
        append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "cmdout_subqueue_len"]]\n
        if  {![dict get ${AIT::project::aitConfig} "disable_spawn_queues"]} {
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnInQueueHwruntime" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnInQueueHwruntime" "addr"] 2 9]\n
            append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "spawnin_queue_len"]]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnOutQueueHwruntime" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "spawnOutQueueHwruntime" "addr"] 2 9]\n
            append bitinfoCoeStr [format %08x [dict get ${AIT::project::aitConfig} "spawnout_queue_len"]]\n
        } else {
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
        }
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "managedReset" "addr"] 10 17]\n
        append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "managedReset" "addr"] 2 9]\n
        if {[dict get ${AIT::project::aitConfig} "hwcounter"]
            || [dict get ${AIT::project::aitConfig} "hwinst"]} {
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "hwcounter" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "hwcounter" "addr"] 2 9]\n
        } else {
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
        }
        if {[dict get ${AIT::project::aitConfig} "enable_pom_axilite"]} {
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "pomAxilite" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "pomAxilite" "addr"] 2 9]\n
        } else {
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
        }
        if {[dict get ${AIT::project::aitConfig} "power_monitor"]} {
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "powerMonitor" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "powerMonitor" "addr"] 2 9]\n
        } else {
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
        }
        if {[dict get ${AIT::project::aitConfig} "thermal_monitor"]} {
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "thermalMonitor" "addr"] 10 17]\n
            append bitinfoCoeStr [string range [dict get ${bdAddrSegmentsDict} "thermalMonitor" "addr"] 2 9]\n
        } else {
            append bitinfoCoeStr [format %08x 0]\n
            append bitinfoCoeStr [format %08x 0]\n
        }

        # Calculate the bitinfo offset of each variable-length field
        # Variable-length fields are appended next to the fixed-length fields
        set xtasksConfigAccSize 44
        set numStaticFields 35
        set dynamicFieldSizes [list \
            [expr {${xtasksConfigAccSize}*[dict get ${AIT::project::aitConfig} "num_accs"]}] \
            [string length ${AIT::project::aitCall}] \
            [string length [get_property VLNV [get_bd_cells ${AIT::templates::hwruntime::hwruntimeIP}]]] \
            [string length [string trim {'} [dict get ${AIT::project::aitConfig} "bitinfo_note"]]] \
        ]
        set offset ${numStaticFields}
        foreach size ${dynamicFieldSizes} {
            lappend dynamicFieldOffsets ${offset}
            incr offset [expr {int(ceil(${size}/4.))}]
        }

        if {${offset} > 1024} {
            AIT::utils::error_msg "Bitinfo length (${offset}) is greater than its mapped region (1024)"
        }

        foreach dynamicFieldSize ${dynamicFieldSizes} dynamicFieldOffset ${dynamicFieldOffsets} {
            append bitinfoCoeStr [format %08X [expr {${dynamicFieldSize} | (${dynamicFieldOffset} << 16)}]]\n
        }
        append bitinfoCoeStr [format %08x ${AIT::project::userID}]\n

        # Set the board memory for discrete devices
        switch -- [dict get ${AIT::project::board} "arch" "device"] {
            "alveo" {
                if {[dict exists ${AIT::project::board} "memory" "size"]} {
                    set size [dict get ${AIT::project::board} "memory" "size"]
                } else {
                    set size [expr {[dict get ${AIT::project::board} "memory" "bank_size"]*[dict get ${AIT::project::board} "memory" "num_banks"]}]
                }
                set size [expr {${size}/2**30}]
            }
            default {
                set size 0
            }
        }
        append bitinfoCoeStr [format %08x ${size}]\n

        # Variable-length fields
        append bitinfoCoeStr ${AIT::project::xtasksConfigBin}
        append bitinfoCoeStr [AIT::utils::ascii_to_hex ${AIT::project::aitCall}]
        append bitinfoCoeStr [AIT::utils::ascii_to_hex [get_property VLNV [get_bd_cells ${AIT::templates::hwruntime::hwruntimeIP}]]]
        append bitinfoCoeStr [AIT::utils::ascii_to_hex [string trim {'} [dict get ${AIT::project::aitConfig} "bitinfo_note"]]]

        return [list ${bitinfoCoeStr} ${offset}]
    }

    # Returns the total number of free memory interfaces
    proc get_available_mem_intfs {} {
        variable memIntfsList

        set availableMemIntfs 0
        foreach memIntf ${memIntfsList} {
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
                set driverPin [get_driver_pin ${neighbourPin} ${visitedPins}]
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
        variable memIntfsList

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
                get_mem_intfs ${role} ${num} [get_property NAME ${nestedIP}] ${IPName}/${mode}[format %02u ${occupation}]_AXI ${intfDict} ${all}
                incr occupation
            }
            if {${all}} {
                lappend memIntfsList ${intfDict}
            }
        } else {
            if {(${occupation} < ${capacity}) || ${all}} {
                lappend memIntfsList ${intfDict}
            }
        }
    }

    # Instantiates and connects required common IPs
    proc init_bd {} {
        # Instantiate interconnects for every memory interface block defined in board_info.json
        initialize_mem_intfs

        # On alveo devices, connect host to memory
        if {([dict get ${AIT::project::board} "arch" "device"] eq "alveo") && ([dict get ${AIT::project::board} "memory" "type"] eq "ddr")} {
            set hostIntfDict [AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bridge_to_host/M_AXI]]

            if {[dict get ${AIT::project::aitConfig} "memory_interleaving_stride"]} {
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
            CONFIG.use_bram_block {Stand_Alone}
        ] ${bitinfo}

        # Create instance: bitInfo_BRAM_Ctrl, and set properties
        set bitinfoBRAMCtrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl bitInfo_BRAM_Ctrl]
        set_property -dict [list \
            CONFIG.PROTOCOL {AXI4LITE} \
            CONFIG.SINGLE_PORT_BRAM {1}
        ] ${bitinfoBRAMCtrl}

        # Create instance: managed_reset, and set properties
        set managedReset [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio managed_reset]
        set_property -dict [list \
            CONFIG.C_ALL_OUTPUTS {1} \
            CONFIG.C_DOUT_DEFAULT {0x00000001} \
            CONFIG.C_GPIO_WIDTH {1}
        ] ${managedReset}

        # Create instance: reset_AND, and set properties
        set resetAND [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic system_reset/managed_reset_AND]
        set_property -dict [list \
            CONFIG.C_SIZE {1} \
            CONFIG.C_OPERATION {and}
        ] ${resetAND}

        create_bd_pin -dir I -type rst system_reset/managed_reset
        create_bd_pin -dir O -type rst system_reset/clk_app_managed_rstn

        set appManagedSysReset [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_app_managed]
        set_property -dict [list \
            CONFIG.C_EXT_RST_WIDTH {1}
        ] ${appManagedSysReset}

        connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/slowest_sync_clk] [get_bd_pins system_reset/clk_app]
        connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/peripheral_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]
        connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/dcm_locked] [get_bd_pins system_reset/clock_generator_locked]
        connect_bd_net [get_bd_pins system_reset/managed_reset] [get_bd_pins system_reset/managed_reset_AND/Op1]
        connect_bd_net [get_bd_pins managed_reset/gpio_io_o] [get_bd_pins system_reset/managed_reset]
        connect_bd_net [get_bd_pins system_reset/managed_reset_AND/Op2] [get_bd_pins system_reset/proc_sys_reset_clk_app/peripheral_aresetn]
        connect_bd_net [get_bd_pins system_reset/managed_reset_AND/res] [get_bd_pins system_reset/proc_sys_reset_clk_app_managed/ext_reset_in]

        switch -- [dict get ${AIT::project::board} "arch" "device"] {
            "zynq" -
            "zynqmp" {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] 1
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins managed_reset/S_AXI] 1
            }
            default {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI]
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins managed_reset/S_AXI]
            }
        }
        connect_bd_intf_net [get_bd_intf_pins bitInfo_BRAM_Ctrl/BRAM_PORTA] [get_bd_intf_pins bitinfo/BRAM_PORTA]

        add_bd_addr_segment "bitinfo" bitinfo_BRAM_Ctrl/S_AXI 1
        add_bd_addr_segment "managedReset" managed_reset/S_AXI 4096

        AIT::templates::Picos_OmpSs_Manager

        # If enabled, instantiate OMPIF accelerators
        if [dict get ${AIT::project::aitConfig} "ompif"] {
            AIT::templates::OMPIF
        }

        # If enabled, add and connect hwcounter IP
        if {[dict get ${AIT::project::aitConfig} "hwcounter"]
            || [dict get ${AIT::project::aitConfig} "hwinst"]} {

            AIT::templates::hwcounter
        }

        if [dict get ${AIT::project::aitConfig} "power_monitor"] {
            AIT::board::add_power_monitor
        }

        if [dict get ${AIT::project::aitConfig} "thermal_monitor"] {
            AIT::board::add_thermal_monitor
        }

        # Set and get the actual PS frequency
        set ::actFreq [AIT::board::set_and_get_freq [dict get ${AIT::project::aitConfig} "clock"]]

        save_bd_design -quiet
    }

    proc add_bd_addr_segment {tag intfPinName size {addr 0}} {
        variable bdAddrSegmentsList

        set intfPin [get_bd_intf_pins ${intfPinName}]
        lappend bdAddrSegmentsList [dict create \
            tag ${tag} \
            bdSegName [get_bd_addr_segs -of_objects ${intfPin}] \
            size ${size} \
            addr [format 0x%016x ${addr}] \
        ]
    }

    # Returns a list with the available memory interfaces along with their role, occupation and capacity
    proc initialize_mem_intfs {{all False}} {
        variable memIntfsList

        dict with AIT::project::board "memory" {
            dict for {intfRole intfBlockList} ${interfaces} {
                set intfNum 0
                foreach intfBlock ${intfBlockList} {
                    get_mem_intfs ${intfRole} ${intfNum} ${intfRole}_Inter_${intfNum} ${intfBlock} {} ${all}
                    incr intfNum
                }
            }
        }
        set memIntfsList [lsort -command AIT::utils::comp_dict -increasing ${memIntfsList}]
    }
}
