#------------------------------------------------------------------------#
#    (C) Copyright 2017-2022 Barcelona Supercomputing Center             #
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

# Configuration variables
set script_path [file dirname [file normalize [info script]]]
if {[catch {source -notrace $script_path/../projectVariables.tcl}]} {
    puts "\[AIT\] ERROR: Failed sourcing project variables"
    exit 1
}

variable bitmap_bitInfo "0x00000000"
set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | ([expr $interconOpt - 1]<<2)]]

variable name_ManagedRst processor_system_reset/peripheral_aresetn

# Create .datainterfaces.txt file
set dataInterfaces_file [open ../${name_Project}.datainterfaces.txt "w"]

## Board-specific generic procedures
## Can be overwritten through the file procs.tcl on the board folder

# Connects source pin received as argument to the output of the clock generator IP
proc connectClock {srcPin} {
    connect_bd_net -quiet [get_bd_pins $srcPin] [get_bd_pins clock_generator/clk_out1]
}

# Connects reset
proc connectRst {rst_source rst_name} {
    connect_bd_net -quiet $rst_source [get_bd_pins processor_system_reset/${rst_name}_aresetn]
}

# Sets target frequency, retrieves actual achieved frequency and returns it
proc setAndGetFreq {targetFreq} {
    aitInfo "Using generic setAndGetFreq procedure"

    set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $targetFreq] [get_bd_cells clock_generator]
    set actFreq [expr [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_out1]]/1000000]

    return $actFreq
}

# Returns base frequency used to feed the clock generator
proc getBaseFreq {} {

    if {[llength [get_bd_pins -quiet clock_generator/clk_in1]] > 0} {
        # Using single pin clocks
        set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_in1]]
    } else {
        # Using differential clock
        set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_intf_pins clock_generator/clk_in1_d]]

    }
    return $baseFreq
}

# Maps board memory to address map
proc configureAddressMap {address_map} {
    aitInfo "Using generic configureAddressMap procedure"

    upvar #0 arch_device arch_device

    # Assign memory address space
    if {($arch_device eq "zynq") || ($arch_device eq "zynqmp")} {
        assign_bd_address [get_bd_addr_segs -regexp ".*HP._DDR_LOW.*"]
        set_property -quiet offset [dict get $address_map "mem_base_addr"] [get_bd_addr_segs -regexp ".*SEG_.*HP._DDR_LOW.*"]
        set_property -quiet range [dict get $address_map "mem_size"] [get_bd_addr_segs -regexp ".*SEG_.*HP._DDR_LOW.*"]
    } else {
        for {set i 0} {$i < [dict get $address_map "mem_num_banks"]} {incr i} {
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_${i}.*_DDR4_ADDRESS_BLOCK"] -offset [expr [dict get $address_map "mem_base_addr"] + [dict get $address_map "mem_bank_size"]*$i] -range [dict get $address_map "mem_bank_size"]
        }
    }
}

# Generates HDL wrapper
proc generateWrapper {} {
    aitInfo "Using generic generateWrapper procedure"

    upvar #0 target_lang target_lang

    set_property target_language $target_lang [current_project]

    make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
}

## Misc procedures
# Returns the binary representation of $i
# width determines the length of the returned string with 0-padding, must be always bigger or equal to the width of i
proc dec2bin {i width} {
	set res {}
	while {$i > 0} {
		set res [expr $i%2]$res
		set i [expr $i/2]
	}
	if {$res eq {}} {set res 0}

	set res [string repeat 0 [expr $width - [string length $res]]]$res
	return $res
}

# Converts an ascii string to a hex string of 32-bit values separated by \n
proc ascii2hex {str} {
    set len [string length $str]
    # Force the string length to be multiple of 4
    if {$len%4} {
        append str [string repeat "\0" [expr 4 - $len%4]]
    }
    set str_out ""
    for {set i 0} {$i < $len} {incr i 4} {
        foreach char [split [string reverse [string range $str $i [expr $i+3]]] ""] {
            append str_out [format %02X [scan $char %c]]
        }
        append str_out "\n"
    }
    return $str_out
}

# Compares a bd address segment dictionary with the segment size
proc comp_bd_addr_seg {a b} {
    if {[dict get $a size] < [dict get $b size]} {
        return -1
    } elseif {[dict get $a size] == [dict get $b size]} {
        return 0
    } else {
        return 1
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
                set inter_conf [list \
                    CONFIG.NUM_MI $num_mi \
                    CONFIG.NUM_SI {1} \
                ]

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
proc createNestedInterconnect {parent_inter {num 1}} {
    upvar #0 interconOpt interconOpt
    upvar #0 board_interfaces board_interfaces

    set index [lsearch -regexp $board_interfaces $parent_inter]
    set board_interfaces [lreplace $board_interfaces $index $index]

    aitInfo "Creating $num nested interconnects for $parent_inter"

    set parent_inter_slaves [get_property CONFIG.NUM_SI [get_bd_cells $parent_inter]]
    set_property CONFIG.NUM_SI [expr $parent_inter_slaves + $num - 1] [get_bd_cells $parent_inter]
    for {set i 0} {$i < $num} {incr i} {
        set nested_inter "${parent_inter}_$i"
        set port_num [format %02u [expr $parent_inter_slaves + $i - 1]]

        # Create new nested interconnect and configure it
        create_bd_cell -vlnv xilinx.com:ip:axi_interconnect $nested_inter
        set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.STRATEGY $interconOpt] [get_bd_cells $nested_inter]

        # Connect clocks and resets
        connectClock [get_bd_pins $nested_inter/ACLK]
        connectClock [get_bd_pins $nested_inter/M00_ACLK]
        connectRst [get_bd_pins $nested_inter/ARESETN] "interconnect"
        connectRst [get_bd_pins $nested_inter/M00_ARESETN] "peripheral"

        # Connect nested interconnect to parent interconnect
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $parent_inter/S${port_num}_AXI] [get_bd_intf_pins $nested_inter/M00_AXI]

        connectClock [get_bd_pins $parent_inter/S${port_num}_ACLK]
        connectRst [get_bd_pins $parent_inter/S${port_num}_ARESETN] "peripheral"

        save_bd_design

        lappend board_interfaces "$nested_inter 0"
    }
    set board_interfaces [lsort -integer -index 1 -increasing $board_interfaces]
}

# Connects the IP to the host through the given port
proc connectToInterface {src intf role {num ""}} {
    upvar #0 board_interfaces intf_list interconOpt interconOpt interconPriority interconPriority

    if {$num ne ""} {
        set index [lsearch -regexp $intf_list ${role}_AXI_${intf}.*_${num}]
    } else {
        set index [lsearch -regexp $intf_list ${role}_AXI_${intf}(_[0-9])?]
    }
    set interface [lindex [lindex $intf_list $index] 0]
    set counter [lindex [lindex $intf_list $index] 1]
    set intf_list [lreplace $intf_list $index $index]

    # Interconnect is full
    if {!($counter%16) && ($counter > 0)} {
        aitError "${intf} interface occupation is 100%"
    }

    set inter ${interface}
    set port ${role}[format %02u [expr $counter%16]]

    set_property -dict [list CONFIG.NUM_${role}I [expr ($counter%16) + 1]] [get_bd_cells $inter]
    set_property -quiet -dict [list CONFIG.STRATEGY $interconOpt] [get_bd_cells $inter]

    if {$interconPriority} {
        #Enable advanced settings in order to set priorities and set proper data path
        set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH.VALUE_SRC PROPAGATED] [get_bd_cells $inter]
        #set priority (0-15)
        set_property -dict [list CONFIG.${port}_ARB_PRIORITY [expr 15 - ($counter%16)]] [get_bd_cells $inter]
    }
    connectClock [get_bd_pins $inter/${port}_ACLK]
    connectRst [get_bd_pins $inter/${port}_ARESETN] "peripheral"
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $src] [get_bd_intf_pins $inter/${port}_AXI]

    incr counter
    lappend intf_list "$interface $counter"

    set intf_list [lsort -integer -index 1 -increasing $intf_list]
    return [list "$interface" "${port}_AXI"]
}

proc connectToMasterInterface {src {num ""}} {
    return [connectToInterface $src master M $num]
}

proc connectToDataInterface {src {num ""}} {
    upvar #0 dataInterfaces_map dataInterfaces_map interleaving_stride interleaving_stride
    upvar dataInterfaces_file dataInterfaces_file

    # If num is empty, look for src in dataInterfaces_map
    if {$num eq ""} {
        set index [lsearch -regexp $dataInterfaces_map $src]
        if {$index != -1} {
            set port [lindex [lindex $dataInterfaces_map $index] 1]
            # Port must be 'S_AXI_data_X' where X is the value we need for $num
            regsub {S_AXI_data_} $port "" num
        }
    }

    set interface [connectToInterface $src data S $num]

    if {$interleaving_stride ne "None"} {
        connect_bd_net [get_bd_pins ${src}_awaddr] [get_bd_pins [lindex $interface 0]/[lindex $interface 1]_awaddr]
        connect_bd_net [get_bd_pins ${src}_araddr] [get_bd_pins [lindex $interface 0]/[lindex $interface 1]_araddr]
    }

    # Add a line to datainterfaces.txt
    puts $dataInterfaces_file "$src\t[lindex $interface 0]"

    return "$interface"
}

proc connectToControlInterface {src {num ""}} {
    return [connectToInterface $src control S $num]
}

proc connectToCoherentInterface {src {num ""}} {
    return [connectToInterface $src coherent S $num]
}

proc createAXISInterconnect {name numSlaves numMasters} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $name
    set_property -dict [list CONFIG.NUM_SI $numSlaves CONFIG.NUM_MI $numMasters] [get_bd_cells $name]
    if {$numSlaves > 1} {
        set_property -dict [list CONFIG.ARB_ON_TLAST {1} CONFIG.ARB_ON_MAX_XFERS {0}] [get_bd_cells $name]
    }

    connectClock [get_bd_pins $name/ACLK]
    connectRst [get_bd_pins $name/ARESETN] "interconnect"

    connectClock [get_bd_pins -regexp $name/(M|S)[0-9]{2}_AXIS_ACLK]
    connectRst [get_bd_pins -regexp $name/(M|S)[0-9]{2}_AXIS_ARESETN] "peripheral"

}

proc removeUnusedInter {} {
    set access_type_list {data coherent control master}
    set interconnect_list [get_bd_cells -regexp (M|S)_AXI_(([join $access_type_list "|"])_?)+(_[0-9])?_Inter]

    foreach interconnect $interconnect_list {
        upvar #0 board_interfaces intf_list
        set index [lsearch $intf_list "$interconnect *"]
        set counter [lindex [lindex $intf_list $index] 1]
        if {$counter == 0} {
            set intf_list [lreplace $intf_list $index $index]
            delete_bd_objs [get_bd_cells $interconnect]
            set intf_list [lsort -integer -index 1 -increasing $intf_list]
            save_bd_design
        }
    }
}

proc getInterfaceOccupation {} {
    set access_type_list {data coherent control master}
    set interconnect_list [get_bd_cells -regexp (M|S)_AXI_(([join $access_type_list "|"])_?)+(_[0-9])?_Inter]
    upvar #0 board_interfaces intf_list

    foreach interconnect $interconnect_list {
        set role [string trim [regsub -all {_AXI_.+$} $interconnect ""] "/"]
        set counter [expr [get_property CONFIG.NUM_${role}I $interconnect] - 1]
        if {$counter < 16} {
            lappend intf_list "$interconnect $counter"
            set intf_list [lsort -integer -index 1 -increasing $intf_list]
        }
    }
}

proc getAvailableDataPorts {} {
    upvar #0 board_interfaces board_interfaces
    set available_ports 0

    foreach interface $board_interfaces {
        foreach {inter counter} $interface {
            if {[string match "*data*" $inter]} {
                incr available_ports [expr 16 - $counter]
            }
        }
    }
    return $available_ports
}

# If available, overwrite board-specific procedures
if {[file exists ./board/$board/procs.tcl]} {
    aitInfo "Loading board-specific procedures"
    if {[catch {source -notrace ./board/$board/procs.tcl}]} {
        aitError "Failed overwriting board-specific procedures"
    }
}

# If available and enabled, add register slices for static logic
if {[file exists ./board/$board/staticRegSlices.tcl] && (($slr_slices eq "static") || ($slr_slices eq "all"))} {
    aitInfo "Loading static register slices script"
    if {[catch {source -notrace ./board/$board/staticRegSlices.tcl}]} {
        aitError "Failed loading static logic register slices"
    }
}

# Compute addresses
# Length unit is 64-bit words
set bd_addr_segments [list \
    [dict create name cmdInQueue bd_seg_name Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $cmdInSubqueue_len*$num_accs*8]] \
    [dict create name cmdOutQueue bd_seg_name Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $cmdOutSubqueue_len*$num_accs*8]] \
    [dict create name hwruntime_rst bd_seg_name Hardware_Runtime/hwruntime_rst/S_AXI/Reg size 4096] \
]
if {$advanced_hwruntime && $enable_spawn_queues} {
    lappend bd_addr_segments [dict create name spawnInQueue bd_seg_name Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $spawnInQueue_len*8]]
    lappend bd_addr_segments [dict create name spawnOutQueue bd_seg_name Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $spawnOutQueue_len*8]]
} else {

}
if {$hwcounter || $hwinst} {
    lappend bd_addr_segments [dict create name hwcounter bd_seg_name HW_Counter/s_axi/reg0 size 4096]
}
# Sort the segments in decreasing size to minimize fragmentation when assigning addresses
set bd_addr_segments [lsort -decreasing -command comp_bd_addr_seg $bd_addr_segments]

set addr_hwruntime_spawnInQueue 0x0000000000000000
set addr_hwruntime_spawnOutQueue 0x0000000000000000
set addr_hwcounter 0x0000000000000000
if {!$advanced_hwruntime || !$enable_spawn_queues} {
    set spawnInQueue_len 0
    set spawnOutQueue_len 0
}

set bitInfo_offset 0x20000
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
    set format_addr [format 0x%016x [expr [dict get $address_map "ompss_base_addr"] + $addr]]
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
    } elseif {$name eq "hwruntime_rst"} {
        set addr_hwruntime_rst $format_addr
    } elseif {$name eq "hwcounter"} {
        set addr_hwcounter $format_addr
    }
    set addr [expr $addr + $size]
}

if {($arch_device eq "zynq") || ($arch_device eq "zynqmp")} {
    variable addr_bitInfo "0x0000000080020000"
} elseif {$arch_device eq "alveo"} {
    variable addr_bitInfo [format 0x%016x [expr [dict get $address_map "ompss_base_addr"] + $bitInfo_offset]]
}

# Create project and set board files
create_project -force $name_Project $name_Project -part $chipPart
if {[info exists boardPart]} {
    foreach board_name $boardPart {
        if {[llength [get_boards ${board_name}:*]]} {
            set_property board_part [get_board_parts -latest_file_version ${board_name}:*] [current_project]
            break
        }
    }
}

# Generate .bin file
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Set repository path
set_property ip_repo_paths ./HLS [current_project]

# Suppress known messages wrongly marked as critical warnings
set_msg_config -id {[BD 41-237]} -severity {CRITICAL WARNING} -regexp -string "Bus Interface property MASTER_TYPE does not match between \/\(Hardware_Runtime\|bitInfo\)\/.*BRAM_PORT\(A\|B\).* and .*" -suppress
set_msg_config -id {[BD 41-1753]} -severity WARNING -suppress
set_msg_config -id {[BD_TCL-1002]} -severity WARNING -suppress

# Add BSC auxiliary IPs
if {[file isdirectory ./IPs/]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ./IPs" [current_project]
    update_ip_catalog
    foreach {IP} [glob -nocomplain ./IPs/*.zip] {
        update_ip_catalog -add_ip $IP -repo_path IPs
    }
    foreach {IP} [glob -nocomplain ./IPs/*.{v,vhdl}] {
        import_files -norecurse $IP
    }
    foreach {IP} [glob -nocomplain ./IPs/hwruntime/*/*.zip] {
        update_ip_catalog -add_ip $IP -repo_path ./IPs
    }
    update_ip_catalog
}

# If exists, add board IP repository
if {[file isdirectory ./board/$board/IPs/]} {
    set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] ./board/$board/IPs" [current_project]
    update_ip_catalog
    foreach {IP} [glob -nocomplain ./board/$board/IPs/*.zip] {
        update_ip_catalog -add_ip $IP -repo_path ./board/$board/IPs
    }
}

# Update IP catalog
update_ip_catalog

# Generate Block Design from template
set argv $name_Project
if {[catch {source -notrace ./board/$board/baseDesign.tcl}]} {
    aitError "Failed sourcing board base design"
}

# Open Block Design
open_bd_design $name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd

# Set synthesis by IP
set_property synth_checkpoint_mode Hierarchical [get_files $name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd]

# Do not generate simulation scripts
set_property sim.ip.auto_export_scripts false [current_project]

# If enabled, set cache location
if {$IP_caching} {
    check_ip_cache -import_from_project -use_cache_location $path_CacheLocation
}

#If interconnect priorities are enabled, set PCIe master as max priority
if {$interconPriority} {
    set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH.VALUE_SRC PROPAGATED] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
    set_property -dict [list CONFIG.S00_ARB_PRIORITY 15] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
}

# If enabled, simplify interconnection to memory
if {$simplify_interconnection} {
    move_bd_cells [get_bd_cells /] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
    delete_bd_objs [get_bd_cells S_AXI_data_control_coherent_Inter]
    set_property name S_AXI_data_control_coherent_Inter [get_bd_cells DDR_S_AXI_Inter]
}

# If available, execute the user defined pre-design tcl script
if {[file exists $script_path/userPreDesign.tcl]} {
    if {[catch {source -notrace $script_path/userPreDesign.tcl}]} {
        aitError "Failed sourcing board pre base design"
    }
}

getInterfaceOccupation

if {$hwruntime eq "fom"} {
    variable name_hwruntime Fast_OmpSs_Manager
} elseif {$hwruntime eq "som"} {
    variable name_hwruntime Smart_OmpSs_Manager
} elseif {$hwruntime eq "pom"} {
    variable name_hwruntime Picos_OmpSs_Manager
}

variable hwruntime_template tcl/templates/hwruntime/$hwruntime/$name_hwruntime.tcl

# Add OmpSs Manager template
if {[catch {source -notrace $hwruntime_template}]} {
    aitError "Failed sourcing $name_hwruntime template"
}

if {($arch_device eq "zynq") || ($arch_device eq "zynqmp")} {
    connectToMasterInterface Hardware_Runtime/S_AXI_GP 1
} else {
    connectToMasterInterface Hardware_Runtime/S_AXI_GP
}

connectClock [get_bd_pins Hardware_Runtime/aclk]
connectRst [get_bd_pins Hardware_Runtime/interconnect_aresetn] "interconnect"
connectRst [get_bd_pins Hardware_Runtime/peripheral_aresetn] "peripheral"

# Min value of MAX_ACCS is 2
set hwruntime_max_accs [expr max($num_accs, 2)]
set_property -dict [list CONFIG.Write_Depth_A [expr $cmdInSubqueue_len*$hwruntime_max_accs] CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/cmdInQueue]
set_property -dict [list CONFIG.Write_Depth_A [expr $cmdOutSubqueue_len*$hwruntime_max_accs] CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/cmdOutQueue]
set_property -dict [list CONFIG.MAX_ACCS $hwruntime_max_accs] [get_bd_cells Hardware_Runtime/$name_hwruntime]

if {$advanced_hwruntime} {
    set hwruntime_max_acc_creators [expr max($num_acc_creators, 2)]
    set_property -dict [list CONFIG.MAX_ACC_CREATORS $hwruntime_max_acc_creators CONFIG.ENABLE_SPAWN_QUEUES $enable_spawn_queues] [get_bd_cells Hardware_Runtime/$name_hwruntime]
    if {$enable_spawn_queues} {
        set_property -dict [list CONFIG.Write_Depth_A $spawnInQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnInQueue]
        set_property -dict [list CONFIG.Write_Depth_A $spawnOutQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnOutQueue]
        set_property -dict [list CONFIG.SPAWNIN_QUEUE_LEN $spawnInQueue_len CONFIG.SPAWNOUT_QUEUE_LEN $spawnOutQueue_len] [get_bd_cells Hardware_Runtime/$name_hwruntime]
    }
    # Add the second port to bitInfo and connect it to xOM
    set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false}] [get_bd_cells bitInfo]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Hardware_Runtime/bitInfo] [get_bd_intf_pins bitInfo/BRAM_PORTB]
}

if {$hwruntime eq "pom"} {
    set_property -dict [list CONFIG.PICOS_ARGS $picos_args_hash] [get_bd_cells Hardware_Runtime/$name_hwruntime]
}

# Use managed reset for the accelerators reset signal
variable name_ManagedRst Hardware_Runtime/managed_aresetn

set_property -dict [list CONFIG.MAX_ACC_TYPES [expr max([llength $accs], 2)]] [get_bd_cells Hardware_Runtime/$name_hwruntime]
set_property -dict [list CONFIG.CMDIN_SUBQUEUE_LEN $cmdInSubqueue_len CONFIG.CMDOUT_SUBQUEUE_LEN $cmdOutSubqueue_len] [get_bd_cells Hardware_Runtime/$name_hwruntime]
set num_common_hwruntime_intf 1
set num_acc_no_creators [expr $num_accs-$num_acc_creators]
if {$lock_hwruntime} {
    incr num_common_hwruntime_intf
    # Enable lock support if needed
    set_property -dict [list CONFIG.LOCK_SUPPORT {1}] [get_bd_cells Hardware_Runtime/$name_hwruntime]
}

#prefix_inStream
set pi hwr_inStream
#prefix_outStream
set po hwr_outStream
create_bd_cell -type hier $pi
create_bd_cell -type hier $po

for {set i 0} {$i < $num_accs} {incr i} {
    # Don't format i because there can potentially be more than 100 accelerators
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/S${i}_AXIS
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $po/M${i}_AXIS
}

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/cmdout_in
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/cmdin_out
create_bd_pin -dir I $pi/clk
create_bd_pin -dir I $pi/interconnect_aresetn
create_bd_pin -dir I $pi/peripheral_aresetn
connectClock [get_bd_pins $pi/clk]
connectRst [get_bd_pins $pi/interconnect_aresetn] "interconnect"
connectRst [get_bd_pins $pi/peripheral_aresetn] "peripheral"
create_bd_pin -dir I $po/clk
create_bd_pin -dir I $po/interconnect_aresetn
create_bd_pin -dir I $po/peripheral_aresetn
connectClock [get_bd_pins $po/clk]
connectRst [get_bd_pins $po/interconnect_aresetn] "interconnect"
connectRst [get_bd_pins $po/peripheral_aresetn] "peripheral"
if {$advanced_hwruntime} {
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/spawn_in
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/taskwait_in
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/spawn_out
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/taskwait_out
}
if {$lock_hwruntime} {
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/lock_in
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/lock_out
}

if {$hwruntime_interconnect == "centralized"} {
    set hwruntime_interconnect_script "tcl/scripts/hwr_central_interconnect.tcl"
} else {
    set hwruntime_interconnect_script "tcl/scripts/hwr_dist_interconnect.tcl"
}

# Regular variables set outside the sourced script seem to not be propagated, only if they are set in the global namespace
set ::enable_spawn_queues $enable_spawn_queues
if {[catch {source -notrace $hwruntime_interconnect_script}]} {
    aitError "Failed sourcing $hwruntime_interconnect_script"
}

# Move the interconnects to the Hardware_Runtime hierarchy
move_bd_cells [get_bd_cells Hardware_Runtime] [get_bd_cells $pi]
move_bd_cells [get_bd_cells Hardware_Runtime] [get_bd_cells $po]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter Hardware_Runtime/axis_subset_converter_cmdin
set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] [get_bd_cells Hardware_Runtime/axis_subset_converter_cmdin]
set_property -dict [list CONFIG.M_TID_WIDTH {1}] [get_bd_cells Hardware_Runtime/axis_subset_converter_cmdin]
connect_bd_net [get_bd_pins Hardware_Runtime/aclk] [get_bd_pins Hardware_Runtime/axis_subset_converter_cmdin/aclk]
connect_bd_net [get_bd_pins Hardware_Runtime/$name_hwruntime/managed_aresetn] [get_bd_pins Hardware_Runtime/axis_subset_converter_cmdin/aresetn]

connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/cmdout_in] [get_bd_intf_pins Hardware_Runtime/$pi/cmdout_in]
connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/cmdin_out] [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_cmdin/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$po/cmdin_out] [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_cmdin/M_AXIS]
if {$advanced_hwruntime} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter Hardware_Runtime/axis_subset_converter_spawn
    set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] [get_bd_cells Hardware_Runtime/axis_subset_converter_spawn]
    set_property -dict [list CONFIG.M_TID_WIDTH {1} CONFIG.TID_REMAP "1'b1"] [get_bd_cells Hardware_Runtime/axis_subset_converter_spawn]
    connect_bd_net [get_bd_pins Hardware_Runtime/aclk] [get_bd_pins Hardware_Runtime/axis_subset_converter_spawn/aclk]
    connect_bd_net [get_bd_pins Hardware_Runtime/$name_hwruntime/managed_aresetn] [get_bd_pins Hardware_Runtime/axis_subset_converter_spawn/aresetn]
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter Hardware_Runtime/axis_subset_converter_taskwait
    set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] [get_bd_cells Hardware_Runtime/axis_subset_converter_taskwait]
    set_property -dict [list CONFIG.M_TID_WIDTH {1} CONFIG.TID_REMAP "1'b1"] [get_bd_cells Hardware_Runtime/axis_subset_converter_taskwait]
    connect_bd_net [get_bd_pins Hardware_Runtime/aclk] [get_bd_pins Hardware_Runtime/axis_subset_converter_taskwait/aclk]
    connect_bd_net [get_bd_pins Hardware_Runtime/$name_hwruntime/managed_aresetn] [get_bd_pins Hardware_Runtime/axis_subset_converter_taskwait/aresetn]

    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/spawn_in] [get_bd_intf_pins Hardware_Runtime/$pi/spawn_in]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/spawn_out]          [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_spawn/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_spawn/M_AXIS] [get_bd_intf_pins Hardware_Runtime/$po/spawn_out]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/taskwait_in] [get_bd_intf_pins Hardware_Runtime/$pi/taskwait_in]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/taskwait_out]          [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_taskwait/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_taskwait/M_AXIS] [get_bd_intf_pins Hardware_Runtime/$po/taskwait_out]
}
if {$lock_hwruntime} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter Hardware_Runtime/axis_subset_converter_lock
    set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] [get_bd_cells Hardware_Runtime/axis_subset_converter_lock]
    set_property -dict [list CONFIG.M_TID_WIDTH {1}] [get_bd_cells Hardware_Runtime/axis_subset_converter_lock]
    connect_bd_net [get_bd_pins Hardware_Runtime/aclk] [get_bd_pins Hardware_Runtime/axis_subset_converter_lock/aclk]
    connect_bd_net [get_bd_pins Hardware_Runtime/$name_hwruntime/managed_aresetn] [get_bd_pins Hardware_Runtime/axis_subset_converter_lock/aresetn]

    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/lock_in] [get_bd_intf_pins Hardware_Runtime/$pi/lock_in]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/lock_out]         [get_bd_intf_pins Hardware_Runtime/axis_subset_converter_lock/S_AXIS]
    connect_bd_intf_net get_bd_intf_pins Hardware_Runtime/axis_subset_converter_lock/M_AXIS] [get_bd_intf_pins Hardware_Runtime/$po/lock_out]
}

# Set and get the actual PS frequency
set actFreq [setAndGetFreq $clockFreq]

save_bd_design

############# Start Block Design generation ############
#### User IPs
set accID 0
set accIDWidth [expr max(int(ceil(log($num_accs)/log(2))), 1)]
set axi_ports []

foreach acc $accs {
    lassign [split $acc ":"] accHash accNumInstances accName taskCreator

    set accName_long ${accName}_ompss

    for {set j 0} {$j < $accNumInstances} {incr j} {

        if {[catch {source -notrace tcl/templates/dummy_acc.tcl}]} {
            aitError "Failed sourcing dummy acc template"
        }

        # Create dummy acc hierarchy and instantiate IP
        set_property name ${accName}_$j [get_bd_cells dummy_acc]
        create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper:1.0 ${accName}_$j/$accName_long

        # Replace dummy acc by IP instance and delete it
        replace_bd_cell -quiet ${accName}_$j/dummy_acc ${accName}_$j/$accName_long
        delete_bd_objs [get_bd_cells ${accName}_$j/dummy_acc]

        # Connect clk and rst pins
        connectClock [get_bd_pins ${accName}_$j/aclk]
        connect_bd_net [get_bd_pins ${accName}_$j/managed_aresetn] [get_bd_pins $name_ManagedRst]

        # If available, forward the outPort
        # Check if acc has already stream ports instead of handshake
        if {[get_bd_intf_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?] ne ""} {
            set hier_outStream [get_bd_intf_pins -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?] ne ""} {
            # Create and connect the hsToStreamAdapter
            set stream_adapter [create_bd_cell -type module -reference hsToStreamAdapter ${accName}_$j/Adapter_outStream]
            set_property -dict [list CONFIG.TID_WIDTH [expr max(int(ceil(log($num_accs)/log(2))), 1)] CONFIG.ACCID $accID] $stream_adapter
            connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_vld] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?_ap_vld]
            connect_bd_net [get_bd_pins $stream_adapter/in_hs_ap_ack] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?_ap_ack]
            connect_bd_net [get_bd_pins $stream_adapter/in_hs] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?]
            connect_bd_net [get_bd_pins $stream_adapter/aclk] [get_bd_pins ${accName}_$j/aclk]
            connect_bd_net [get_bd_pins $stream_adapter/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
            set hier_outStream [get_bd_intf_pins $stream_adapter/outStream]
        }

        # If available, forward the inPort
        if {[get_bd_intf_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?] ne ""} {
            set hier_inStream [get_bd_intf_pins -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?]
        } elseif {[get_bd_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?] ne ""} {
            # Create and connect the streamToHsAdapter
            set stream_adapter [create_bd_cell -type module -reference streamToHsAdapter ${accName}_$j/Adapter_inStream]
            connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_vld] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?_ap_vld]
            connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_ack] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?_ap_ack]
            connect_bd_net [get_bd_pins $stream_adapter/out_hs] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_inPort(_V)*?]
            connect_bd_net [get_bd_pins $stream_adapter/aclk] [get_bd_pins ${accName}_$j/aclk]
            connect_bd_net [get_bd_pins $stream_adapter/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
            set hier_inStream [get_bd_intf_pins $stream_adapter/inStream]
        }

        # If this is a task creator, instantiate the newtask_spawner
        if {$taskCreator} {
            if {[get_bd_intf_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?] ne ""} {
                set acc_spawnInStream [get_bd_intf_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?]
            } elseif {[get_bd_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?] ne ""} {
                # Create and connect the streamToHsAdapter
                set stream_adapter [create_bd_cell -type module -reference streamToHsAdapter ${accName}_$j/Adapter_spawnInStream]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_vld] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?_ap_vld]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs_ap_ack] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?_ap_ack]
                connect_bd_net [get_bd_pins $stream_adapter/out_hs] [get_bd_pins -regexp ${accName}_$j/$accName_long/mcxx_spawnInPort(_V)*?]
                connect_bd_net [get_bd_pins $stream_adapter/aclk] [get_bd_pins ${accName}_$j/aclk]
                connect_bd_net [get_bd_pins $stream_adapter/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]

                set acc_spawnInStream [get_bd_intf_pins $stream_adapter/inStream]
            }

            set newtask_spawner [create_bd_cell -type ip -vlnv bsc:ompss:new_task_spawner_wrapper:1.0 ${accName}_${j}/new_task_spawner]
            connect_bd_net [get_bd_pins $newtask_spawner/clk] [get_bd_pins ${accName}_$j/aclk]
            connect_bd_net [get_bd_pins $newtask_spawner/rstn] [get_bd_pins ${accName}_$j/managed_aresetn]

            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/stream_in] [get_bd_intf_pins $hier_outStream]
            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/ack_out] [get_bd_intf_pins $acc_spawnInStream]

            set tid_demux [create_bd_cell -quiet -type module -reference axis_tid_demux ${accName}_$j/axis_tid_demux]
            connect_bd_net [get_bd_pins $tid_demux/clk] [get_bd_pins ${accName}_$j/aclk]
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m0] [get_bd_intf_pins $hier_inStream]
            connect_bd_intf_net [get_bd_intf_pins $tid_demux/m1] [get_bd_intf_pins $newtask_spawner/ack_in]

            # We need to insert accID to the new_task_spawner TID AXI-Stream signal
            set tidSubsetConv [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter ${accName}_${j}/TID_subset_converter]
            connect_bd_net [get_bd_pins $tidSubsetConv/aclk] [get_bd_pins ${accName}_$j/aclk]
            connect_bd_net [get_bd_pins $tidSubsetConv/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]

            # Format accID as a 4-bit value
            set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] $tidSubsetConv
            set_property -dict [list CONFIG.M_TID_WIDTH $accIDWidth CONFIG.TID_REMAP "$accIDWidth'b[dec2bin $accID $accIDWidth]"] $tidSubsetConv

            connect_bd_intf_net [get_bd_intf_pins $newtask_spawner/stream_out] [get_bd_intf_pins $tidSubsetConv/S_AXIS]

            set hier_inStream [get_bd_intf_pins ${accName}_$j/axis_tid_demux/s]
            set hier_outStream [get_bd_intf_pins $tidSubsetConv/M_AXIS]
        } else {
            if {[get_bd_intf_pins -quiet -regexp ${accName}_$j/$accName_long/mcxx_outPort(_V)*?] ne ""} {
                # We need to insert accID to the accelerator TID AXI-Stream signal
                set tidSubsetConv [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter ${accName}_${j}/TID_subset_converter]
                connect_bd_net [get_bd_pins $tidSubsetConv/aclk] [get_bd_pins ${accName}_$j/aclk]
                connect_bd_net [get_bd_pins $tidSubsetConv/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]

                # Format accID as a 4-bit value
                set_property -dict [list CONFIG.M_TID_WIDTH.VALUE_SRC USER] $tidSubsetConv
                set_property -dict [list CONFIG.M_TID_WIDTH $accIDWidth CONFIG.TID_REMAP "$accIDWidth'b[dec2bin $accID $accIDWidth]"] $tidSubsetConv

                connect_bd_intf_net [get_bd_intf_pins $hier_outStream] [get_bd_intf_pins $tidSubsetConv/S_AXIS]
                set hier_outStream [get_bd_intf_pins $tidSubsetConv/M_AXIS]
            }
        }

        # Get list of M_AXI interfaces
        # NOTE: Only handle AXI interfaces generated by mcxx, which start with the "mcxx_" prefix
        set list_acc_AXIPorts [get_bd_intf_pins -quiet ${accName}_$j/$accName_long/m_axi_mcxx_*]

        # Store each M_AXI port to dictionary
        foreach acc_AXIPort $list_acc_AXIPorts {
            set port_path [string range $acc_AXIPort 0 [expr [string last / $acc_AXIPort] - 1]]
            set port_IP [string range $port_path [expr [string last / $port_path] + 1] end]
            set port_name [string replace [string range $acc_AXIPort [expr [string last / $acc_AXIPort] + 1] end] 0 [expr [string length "m_axi_"] - 1]]

            # Outermost AXI interface that will be connected to memory
            set hier_AXIPort $acc_AXIPort

            if {($slr_slices eq "acc") || ($slr_slices eq "all")} {
                if {!([dict exists $acc_placement $accHash] && ([llength [dict get $acc_placement $accHash]] > $j))} {
                    # No placement info is provided for this instance
                    aitWarning "No placement info provided for instance $j of ${accName}. Slices will not be created"
                } else {
                    set slr [lindex [dict get $acc_placement $accHash] $j]

                    if {$slr != $board_slr_master} {
                        # If the acc is in a different SLR
                        #   * Create register slices for data ports
                        # Register slices are named axi_regSlice_slr_acc_${port_index}_${slr_orig}_${slr_dest}
                        #   note that the slave side is close to the acc master axi port
                        # Task-creating accelerators will not have register slices as they do not use data ports
                        set axiRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice ${accName}_$j/${port_name}_regslice_slr_acc_${slr}_${board_slr_master}]
                        set_property -dict [ list \
                            CONFIG.REG_AR {15} \
                            CONFIG.REG_AW {15} \
                            CONFIG.REG_B {15} \
                            CONFIG.REG_R {15} \
                            CONFIG.REG_W {15} \
                            CONFIG.USE_AUTOPIPELINING {1} \
                            ] $axiRegSlice
                        # Connect acc - slice
                        connect_bd_intf_net [get_bd_intf_pins $hier_AXIPort] [get_bd_intf_pins $axiRegSlice/S_AXI]
                        connect_bd_net [get_bd_pins $axiRegSlice/aclk] [get_bd_pins ${accName}_$j/aclk]
                        connect_bd_net [get_bd_pins $axiRegSlice/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
                        # Slice master ports will be connected later
                        lappend slicePorts [get_bd_intf_pins $axiRegSlice/M_AXI]

                        # Save ports to be connected with acc hierarchy
                        set listAccPorts $slicePorts
                        set hier_AXIPort $axiRegSlice/M_AXI
                    }
                }
            }

            if {$interleaving_stride ne "None"} {
                set addrInterleaver [create_bd_cell -type module -reference addrInterleaver ${accName}_$j/${port_name}_addrInterleaver]
                create_bd_pin -dir O -from 63 -to 0 ${accName}_$j/${port_name}_awaddr
                create_bd_pin -dir O -from 63 -to 0 ${accName}_$j/${port_name}_araddr
                connect_bd_net [get_bd_pins ${hier_AXIPort}_awaddr] [get_bd_pins $addrInterleaver/in_awaddr]
                connect_bd_net [get_bd_pins ${hier_AXIPort}_araddr] [get_bd_pins $addrInterleaver/in_araddr]
                connect_bd_net [get_bd_pins ${accName}_$j/${port_name}_awaddr] [get_bd_pins $addrInterleaver/out_awaddr]
                connect_bd_net [get_bd_pins ${accName}_$j/${port_name}_araddr] [get_bd_pins $addrInterleaver/out_araddr]
            }

            create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accName}_$j/$port_name
            connect_bd_intf_net [get_bd_intf_pins ${accName}_$j/$port_name] [get_bd_intf_pins $hier_AXIPort]

            lappend axi_ports ${accName}_$j/$port_name
        }

        if {($slr_slices eq "acc") || ($slr_slices eq "all")} {
            if {!([dict exists $acc_placement $accHash] && ([llength [dict get $acc_placement $accHash]] > $j))} {
                # No placement info is provided for this instance
                aitWarning "No placement info provided for instance $j of ${accName}. Slices will not be created"
            } else {
                set slr [lindex [dict get $acc_placement $accHash] $j]

                if {$slr != $board_slr_master} {
                    # Create register slices for stream ports
                    # slices are named axis_regSlice{in,out}_${orig_slr}_${dest_slr}
                    # inStream slice
                    set axis_regSlice_in [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${accName}_$j/axis_regSlice_in_${board_slr_master}_${slr}]
                    set_property -dict [ list \
                        CONFIG.REG_CONFIG {16} \
                        ] $axis_regSlice_in
                    connect_bd_intf_net $hier_inStream [get_bd_intf_pins $axis_regSlice_in/M_AXIS]
                    connect_bd_net [get_bd_pins $axis_regSlice_in/aclk] [get_bd_pins ${accName}_$j/aclk]
                    connect_bd_net [get_bd_pins $axis_regSlice_in/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]

                    # outStream slice
                    set axis_regSlice_out [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice ${accName}_$j/axis_regSlice_out_${slr}_${board_slr_master}]
                    set_property -dict [ list \
                        CONFIG.REG_CONFIG {16} \
                        ] $axis_regSlice_out
                    connect_bd_intf_net $hier_outStream [get_bd_intf_pins $axis_regSlice_out/S_AXIS]
                    connect_bd_net [get_bd_pins $axis_regSlice_out/aclk] [get_bd_pins ${accName}_$j/aclk]
                    connect_bd_net [get_bd_pins $axis_regSlice_out/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]

                    set hier_inStream [get_bd_intf_pins $axis_regSlice_in/S_AXIS]
                    set hier_outStream [get_bd_intf_pins $axis_regSlice_out/M_AXIS]
                }
            }
        }

        connect_bd_intf_net [get_bd_intf_pins ${accName}_$j/inStream] $hier_inStream
        connect_bd_intf_net [get_bd_intf_pins ${accName}_$j/outStream] $hier_outStream

        # If available, forward the instrumentation ports
        if {([get_bd_pins -quiet ${accName}_$j/$accName_long/mcxx_instr_*] ne "") || ([get_bd_pins -quiet ${accName}_$j/$accName_long/mcxx_hwcounterPort*] ne "")} {

            # Create counter for the current accelerator
            create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary ${accName}_$j/hwinst_counter
            set_property -dict [list CONFIG.Output_Width {64}] [get_bd_cells ${accName}_$j/hwinst_counter]
            connect_bd_net [get_bd_pins ${accName}_$j/aclk] [get_bd_pins ${accName}_$j/hwinst_counter/CLK]

            if {[get_bd_pins -quiet ${accName}_$j/$accName_long/mcxx_instr_*] ne ""} {

                # Create and connect the Adapter_instr
                create_bd_cell -type ip -vlnv bsc:ompss:Adapter_instr_wrapper:1.0 ${accName}_$j/Adapter_instr
                connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V_ap_vld] [get_bd_pins ${accName}_$j/$accName_long/mcxx_instr_V_ap_vld]
                connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V_ap_ack] [get_bd_pins ${accName}_$j/$accName_long/mcxx_instr_V_ap_ack]
                connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V] [get_bd_pins ${accName}_$j/$accName_long/mcxx_instr_V]
                connectClock [get_bd_pins ${accName}_$j/Adapter_instr/ap_clk]
                connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/ap_rst_n] [get_bd_pins ${accName}_$j/managed_aresetn]

                # Connect to hwcounter
                connect_bd_net [get_bd_pins ${accName}_$j/hwinst_counter/Q] [get_bd_pins ${accName}_$j/Adapter_instr/hwcounter]

                set instr_AXIPort [get_bd_intf_pins -quiet ${accName}_$j/Adapter_instr/m_axi* -filter {NAME =~ "*instr_buffer"}]

                if {($slr_slices eq "acc") || ($slr_slices eq "all")} {
                    if {!([dict exists $acc_placement $accHash] && ([llength [dict get $acc_placement $accHash]] > $j))} {
                        # No placement info is provided for this instance
                        aitWarning "No placement info provided for instance $j of ${accName}. Slices will not be created"
                    } else {
                        set slr [lindex [dict get $acc_placement $accHash] $j]

                        if {$slr != $board_slr_master} {
                            # If the acc is in a different SLR
                            #   * Create register slices for instrumentation ports
                            # Register slices are named instr_regSlice_slr_acc_${slr_orig}_${slr_dest}
                            #   note that the slave side is close to the acc master axi port
                            set axiRegSlice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice ${accName}_$j/instr_regslice_slr_acc_${slr}_${board_slr_master}]
                            set_property -dict [ list \
                                CONFIG.REG_AR {15} \
                                CONFIG.REG_AW {15} \
                                CONFIG.REG_B {15} \
                                CONFIG.REG_R {15} \
                                CONFIG.REG_W {15} \
                                CONFIG.USE_AUTOPIPELINING {1} \
                                ] $axiRegSlice
                            # Connect acc - slice
                            connect_bd_intf_net [get_bd_intf_pins -quiet ${accName}_$j/Adapter_instr/m_axi* -filter {NAME =~ "*instr_buffer"}] [get_bd_intf_pins $axiRegSlice/S_AXI]
                            connect_bd_net [get_bd_pins $axiRegSlice/aclk] [get_bd_pins ${accName}_$j/aclk]
                            connect_bd_net [get_bd_pins $axiRegSlice/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
                            # Slice master ports will be connected later
                            lappend slicePorts [get_bd_intf_pins $axiRegSlice/M_AXI]
                            set instr_AXIPort $axiRegSlice/M_AXI
                        }
                    }
                }

                # Connect buffer port
                create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 ${accName}_$j/instr_buffer
                connect_bd_intf_net [get_bd_intf_pins $instr_AXIPort] [get_bd_intf_pins ${accName}_$j/instr_buffer]
                lappend axi_ports ${accName}_$j/instr_buffer
            }

            if {[get_bd_pins -quiet ${accName}_$j/$accName_long/mcxx_hwcounterPort*] ne ""} {
                connect_bd_net [get_bd_pins ${accName}_$j/hwinst_counter/Q] [get_bd_pins ${accName}_$j/$accName_long/mcxx_hwcounterPort*]
            }
        }

        # If available, forward the frequency port
        if {[get_bd_pins -quiet ${accName}_$j/$accName_long/mcxx_freqPort*] ne ""} {
            # Create and connect constant with freq
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ${accName}_$j/accFreq
            set_property -dict [list CONFIG.CONST_VAL $actFreq CONFIG.CONST_WIDTH {10}] [get_bd_cells ${accName}_$j/accFreq]
            connect_bd_net [get_bd_pins ${accName}_$j/accFreq/dout] [get_bd_pins ${accName}_$j/$accName_long/mcxx_freqPort*]
        }

        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/outStream] [get_bd_intf_pins Hardware_Runtime/$pi/S${accID}_AXIS]
        connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/inStream] [get_bd_intf_pins Hardware_Runtime/$po/M${accID}_AXIS]

        regenerate_bd_layout -hierarchy [get_bd_cell ${accName}_$j]

        save_bd_design

        # Increase global acc id
        incr accID

    }

}

# If we are generating a design for a discrete FPGA that uses DDR, check for
# available ports to memory and instantiate a nested interconnect, if necessary
if {($arch_device eq "alveo") && ([dict get $address_map "mem_type"] eq "ddr") && ([llength $axi_ports] > [getAvailableDataPorts])} {
    createNestedInterconnect S_AXI_data_control_coherent_Inter [dict get $address_map "mem_num_banks"]
}

# Check if there are enough available ports to memory
if {[llength $axi_ports] > [getAvailableDataPorts]} {
    aitError "Insufficient available ports to memory"
}

# Connect data ports to memory interconnection
foreach port $axi_ports {
    set intf [connectToDataInterface $port]

    save_bd_design
}

# If using it, configure addrInterleaver IP
if {$interleaving_stride ne "None"} {
    set num_banks [dict get $address_map "mem_num_banks"]
    set lg [expr log($num_banks)/log(2)]
    if { floor($lg) - ceil($lg) != 0 } {
        #number of banks is not power of 2
        #   -> use the larger base2 num of banks available
        set num_banks [expr int(pow(2, floor($lg)))]
    }

    set addrInterleaver [get_bd_cell -hierarchical -regexp .*_addrInterleaver]
    set_property -dict [list \
      CONFIG.BANK_SIZE [dict get $address_map "mem_bank_size"] \
      CONFIG.NUM_BANKS $num_banks \
      CONFIG.STRIDE $interleaving_stride \
      CONFIG.BASE_ADDR [dict get $address_map "mem_base_addr"] \
    ] $addrInterleaver
}

# If enabled, add and connect hwcounter IP
if {$hwcounter || $hwinst} {
    create_bd_cell -type module -reference hwcounter HW_Counter

    if {($arch_device eq "zynq") || ($arch_device eq "zynqmp")} {
        connectToMasterInterface HW_Counter/S_AXI 1
    } else {
        connectToMasterInterface HW_Counter/S_AXI
    }

    connectClock [get_bd_pins HW_Counter/s_axi_aclk]
    save_bd_design

    if {$hwinst} {
        set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<0]]
    }
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<1]]
}

# Add slr constraints to static logic
if {($slr_slices eq "static") || ($slr_slices eq "all")} {
    # From board's staticRegSlices.tcl
    staticLogicRegisters
}

close $dataInterfaces_file

removeUnusedInter

file delete ../${name_Project}.debuginterfaces.txt

# Mark AXI interfaces for debug
if {($debugInterfaces eq "AXI") || ($debugInterfaces eq "both")} {
    # Create .debuginterfaces.txt file
    set debugInterfaces_file [open ../${name_Project}.debuginterfaces.txt "w"]

    set axi_pin_list [get_bd_intf_pins -quiet -hierarchical -filter {VLNV =~ xilinx.com:interface:aximm_rtl:* && NAME =~ m_axi_mcxx*} -of_objects [get_bd_cells -hierarchical -filter {NAME =~ *_ompss}]]
    foreach axi_pin $axi_pin_list {
        set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $axi_pin]]]
        apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $axi_pin]]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

        # Add a line to debuginterfaces.txt
        puts $debugInterfaces_file "$axi_pin"
    }
    set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]
    close $debugInterfaces_file
}

# Mark AXI-Stream interfaces for debug
if {($debugInterfaces eq "stream") || ($debugInterfaces eq "both")} {
    # Open debuginterfaces.txt file
    set debugInterfaces_file [open ../${name_Project}.debuginterfaces.txt "a"]

    set stream_pin_list [get_bd_intf_pins -quiet -hierarchical -filter {VLNV =~ xilinx.com:interface:axis_rtl:*} -of_objects [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:module_ref:hsToStreamAdapter:* || VLNV =~ xilinx.com:module_ref:streamToHsAdapter:*}]]
    lappend stream_pin_list [get_bd_intf_pins -quiet -hierarchical -filter {VLNV =~ xilinx.com:interface:axis_rtl:* && NAME =~ mcxx_inPort*} -of_objects [get_bd_cells -hierarchical -filter {NAME =~ *_ompss}]]
    lappend stream_pin_list [get_bd_intf_pins -quiet -hierarchical -filter {VLNV =~ xilinx.com:interface:axis_rtl:* && NAME =~ M_AXIS} -of_objects [get_bd_cells -hierarchical -filter {NAME =~ TID_subset_converter}]]
    foreach stream_pin $stream_pin_list {
        set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $stream_pin]]]
        apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $stream_pin]]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

        # Add a line to debuginterfaces.txt
        puts $debugInterfaces_file "$stream_pin"
    }
    set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]
    close $debugInterfaces_file
}

# Mark custom interfaces for debug
if {$debugInterfaces eq "custom"} {
    # Open debuginterfaces.txt file
    set debugInterfaces_file [open ../${name_Project}.debuginterfaces.txt "w"]

    foreach intf $debugInterfaces_list {
        set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]]

        if {[string match xilinx.com:interface:aximm_rtl:* [get_property VLNV [get_bd_intf_pins $intf]]]} {
            apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]
        } elseif {[string match xilinx.com:interface:axis_rtl:* [get_property VLNV [get_bd_intf_pins $intf]]]} {
            apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]
        } else {
            aitError "Interface type not recognized ($intf)"
        }

        # Add a line to debuginterfaces.txt
        puts $debugInterfaces_file "$intf"
    }

    set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]

    close $debugInterfaces_file
}

# Propagate parameters
validate_bd_design -force -quiet
save_bd_design

# Create pl_ompss_fpga.dtsi file
set ompss_at_fpga_DeviceTree_file [open $name_Project/pl_ompss_at_fpga.dtsi "w"]
set ompss_at_fpga_node "&amba_pl {\n"
append ompss_at_fpga_node "\tompss_at_fpga: ompss_at_fpga@0 {\n\t\tcompatible = \"ompss-at-fpga\";\n"
append ompss_at_fpga_node "\t\tbitstreaminfo = <&bitInfo_BRAM_Ctrl>;\n"
append ompss_at_fpga_node "\t};\n};"
puts $ompss_at_fpga_DeviceTree_file $ompss_at_fpga_node
close $ompss_at_fpga_DeviceTree_file

# Connect Hardware Runtime to accelerators and map queues to address space
foreach bd_addr_seg $bd_addr_segments {
    set name [dict get $bd_addr_seg name]
    set addr [dict get $bd_addr_seg addr]
    set range [dict get $bd_addr_seg size]
    set bd_seg_name [dict get $bd_addr_seg bd_seg_name]
    aitInfo "Assign $name BD address, range $range address $addr"
    assign_bd_address [get_bd_addr_segs $bd_seg_name] -range $range -offset $addr
}

if {$advanced_hwruntime} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<7]]
}

if {$hwruntime eq "som"} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<8]]
} elseif {$hwruntime eq "pom"} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<9]]
}

if {$simplify_interconnection} {
    set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<3]]
}

if {$arch_device ne "simulation"} {
    assign_bd_address [get_bd_addr_segs *bitInfo_BRAM_Ctrl*] -range 4K -offset $addr_bitInfo
}

configureAddressMap $address_map

# Store real PS frequency in xtasks config file
set config_file [open ../${name_Project}.xtasks.config "r"]
set newConfig_file [open ../${name_Project}.xtasks.config.new "w"]
gets $config_file line
puts $newConfig_file "type\t#ins\tname\tfreq"
while { [gets $config_file line] >= 0 } {
    set line [string range $line 0 54]
    puts $newConfig_file "$line\t$actFreq"
}
close $config_file
close $newConfig_file
exec mv ../${name_Project}.xtasks.config.new ../${name_Project}.xtasks.config

# Generate xtasks.config binary string
set xtasks_bin_str ""
foreach acc $accs {
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
    append xtasks_bin_str [ascii2hex $accName]
}

set bitInfo_intlv_stride 0
if {$interleaving_stride ne "None"} {
    set bitInfo_intlv_stride $interleaving_stride
}

# Create bitInfo.coe file
set bitInfo_file [open $name_Project/bitInfo.coe "w"]
set bitInfo_coe "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
append bitInfo_coe [format %08x $version_bitInfo]\n
append bitInfo_coe [format %08x $num_accs]\n
append bitInfo_coe [format %08x $bitmap_bitInfo]\n
append bitInfo_coe [format %08x [expr $version_major_ait<<16 | $version_minor_ait]]\n
append bitInfo_coe [format %08x $version_wrapper]\n
append bitInfo_coe [format %08x [getBaseFreq]]\n
append bitInfo_coe [string range $addr_hwruntime_cmdInQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_cmdInQueue 2 9]\n
append bitInfo_coe [format %08x $cmdInSubqueue_len]\n
append bitInfo_coe [string range $addr_hwruntime_cmdOutQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_cmdOutQueue 2 9]\n
append bitInfo_coe [format %08x $cmdOutSubqueue_len]\n
append bitInfo_coe [string range $addr_hwruntime_spawnInQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_spawnInQueue 2 9]\n
append bitInfo_coe [format %08x $spawnInQueue_len]\n
append bitInfo_coe [string range $addr_hwruntime_spawnOutQueue 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_spawnOutQueue 2 9]\n
append bitInfo_coe [format %08x $spawnOutQueue_len]\n
append bitInfo_coe [string range $addr_hwruntime_rst 10 17]\n
append bitInfo_coe [string range $addr_hwruntime_rst 2 9]\n
append bitInfo_coe [string range $addr_hwcounter 10 17]\n
append bitInfo_coe [string range $addr_hwcounter 2 9]\n
append bitInfo_coe $xtasks_bin_str
append bitInfo_coe "FFFFFFFF\n"
append bitInfo_coe [ascii2hex $ait_call\n]
append bitInfo_coe "FFFFFFFF\n"
set hwruntime_vlnv [get_property VLNV [get_bd_cells /Hardware_Runtime/$name_hwruntime]]
append bitInfo_coe [ascii2hex $hwruntime_vlnv\n]
append bitInfo_coe "FFFFFFFF\n"
append bitInfo_coe [ascii2hex $bitInfo_note\n]
append bitInfo_coe "FFFFFFFF\n"
append bitInfo_coe [format %08x $bitInfo_intlv_stride]\n
append bitInfo_coe "FFFFFFFF;"
puts $bitInfo_file $bitInfo_coe
close $bitInfo_file

# Configure memory as a 1024-word deep 32b-word wide True-Dual Port RAM
set_property -dict [list CONFIG.Write_Width_A {32} CONFIG.Write_Width_B {32} CONFIG.Read_Width_A {32} CONFIG.Read_Width_B {32} CONFIG.Write_Depth_A 1024 CONFIG.EN_SAFETY_CKT {false} CONFIG.Load_Init_File {true} CONFIG.Coe_File [pwd]/$name_Project/bitInfo.coe] [get_bd_cells bitInfo]

# Update outdated IPs
update_ip_catalog -rebuild -scan_changes
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS!={}]

# If exists, add constraints file
if {[file isdirectory ./board/$board/constraints/]} {
    add_files -fileset constrs_1 -norecurse ./board/$board/constraints/
}

# Delete floorplanning constrains if requested
# We should only keep board related constraints
if {($floorplanning_constr ne "static") && ($floorplanning_constr ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet static_floorplan.xdc]
}

if {($floorplanning_constr ne "acc") && ($floorplanning_constr ne "all")} {
    remove_files -fileset constrs_1 [get_files -quiet acc_floorplan_common.xdc]
}

reorder_files -fileset constrs_1 -front [get_files -quiet create_pblocks.xdc]

# If available, execute the user defined post-design tcl script
if {[file exists $script_path/userPostDesign.tcl]} {
    if {[catch {source -notrace $script_path/userPostDesign.tcl}]} {
        aitError "Failed sourcing board post base design"
    }
}

# If enabled, configure register slices on AXI Interconnects
if {$interconRegSlice_all} {
    set interconnects [get_bd_cells -hierarchical -regexp -filter {VLNV =~ xilinx.com:ip:axi_interconnect.*} .*]

    foreach inter $interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI [get_bd_cells $inter]]} {incr i} {
            set_property -dict [list CONFIG.M[format %02u $i]_HAS_REGSLICE {4}] [get_bd_cells $inter]
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI [get_bd_cells $inter]]} {incr i} {
            set_property -dict [list CONFIG.S[format %02u $i]_HAS_REGSLICE {4}] [get_bd_cells $inter]
        }
    }
} elseif {$interconRegSlice_mem} {
    set interconnects [get_bd_cells -hierarchical -regexp -filter {VLNV =~ xilinx.com:ip:axi_interconnect.* && NAME =~ {.*(data|control|coherent|master).*}} .*]

    foreach inter $interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI [get_bd_cells $inter]]} {incr i} {
            set_property -dict [list CONFIG.M[format %02u $i]_HAS_REGSLICE {4}] [get_bd_cells $inter]
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI [get_bd_cells $inter]]} {incr i} {
            set_property -dict [list CONFIG.S[format %02u $i]_HAS_REGSLICE {4}] [get_bd_cells $inter]
        }
    }
}

# Regenerate layout and validate BD
regenerate_bd_layout
regenerate_bd_layout -routing
if {[catch {validate_bd_design -force}]} {
    save_bd_design
    aitError "Block Design could not be validated"
}

generateWrapper

update_compile_order -fileset sources_1

# Save Block Design
save_bd_design
