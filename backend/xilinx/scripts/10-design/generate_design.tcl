#------------------------------------------------------------------------#
#    (C) Copyright 2017-2021 Barcelona Supercomputing Center             #
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

# Counters
if {$arch_type == "fpga"} {
	variable PCIe_Inter 0
}

# Create .datainterfaces.txt file
set dataInterfaces_file [open $path_Project/../${name_Project}.datainterfaces.txt "w"]

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
	return [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_in1]]
}

# Maps board DDR to the address map
proc configureAddressMap {addr_list size_DDR} {
	aitInfo "Using generic configureAddressMap procedure"

	# Assign DDR address space
	assign_bd_address [get_bd_addr_segs -regexp ".*_DDR_LOW.*"]
	assign_bd_address -quiet $addr_list
	set_property range $size_DDR [get_bd_addr_segs -regexp ".*_DDR_LOW.*"]
	set_property offset 0x0 [get_bd_addr_segs -regexp ".*_DDR_LOW.*"]
}

# Generates HDL wrapper
proc generateWrapper {} {
	aitInfo "Using generic generateWrapper procedure"

	upvar #0 target_lang target_lang

	set_property target_language $target_lang [current_project]

	make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
}

## Misc procedures

# Converts an ascii string to a hex string of 32-bit values separated by \n
proc ascii2hex {str} {
	set len [string length $str]
	# Force the string length to be multiple of 4
	if {[expr $len%4 != 0]} {
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

# Compares a bd address segment dictinary with the segment size
proc comp_bd_addr_seg {a b} {
	if {[expr [dict get $a size] < [dict get $b size]]} {
		return -1
	} elseif {[expr [dict get $a size] == [dict get $b size]]} {
		return 0
	} else {
		return 1
	}
}

# Creates and connects a tree of interconnects that allows an arbitrary number of AXI-stream slaves to connect to up to 16 AXI-stream masters
proc create_inStream_Inter_tree { stream_name nmasters nslaves } {
	set ninter [expr int(ceil($nslaves/16.))]
	set prev_ninter $nslaves
	set inter_level 0
	set inter_stride 1

	# First level uses interconnects with more than one master if required
	for {set i 0} {$i < $ninter} {incr i} {
		set inter_name ${stream_name}_lvl${inter_level}_$i

		# Last interconnect may need less slaves
		if {$i == $ninter-1 && [ expr $prev_ninter%16 ] != 0} {
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

		set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
		lappend inter_conf CONFIG.NUM_MI $nmasters CONFIG.NUM_SI $num_si
		set_property -dict $inter_conf $inter

		connectClock [get_bd_pins $inter_name/ACLK]
		connectRst [get_bd_pins $inter_name/ARESETN] "interconnect"
		for {set j 0} {$j < $num_si} {incr j} {
			set inf_num [ format %02u $j ]
			connectClock [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
			connectRst [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN] "peripheral"
		}
		for {set j 0} {$j < $nmasters} {incr j} {
			set inf_num [ format %02u $j ]
			connectClock [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
			connectRst [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN] "peripheral"
		}
	}

	set prev_ninter $ninter
	set ninter [ expr int(ceil($ninter/16.)) ]
	incr inter_level

	while {$ninter < $prev_ninter} {
		for {set m 0} {$m < $nmasters} {incr m} {
			for {set i 0} {$i < $ninter} {incr i} {

				set inter_name ${stream_name}_lvl${inter_level}_m${m}_$i

				# Last interconnect may need less slaves
				if {$i == $ninter-1 && [ expr $prev_ninter%16 ] != 0} {
					set num_si [expr $prev_ninter%16]
				} else {
					set num_si 16
				}

				if {$num_si > 1} {
					set inter_conf [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
				} else {
					set inter_conf {}
				}

				set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
				lappend inter_conf \
					CONFIG.M00_AXIS_BASETDEST {0x00000000} \
					CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
					CONFIG.NUM_MI {1} \
					CONFIG.NUM_SI $num_si
				set_property -dict $inter_conf $inter

				connectClock [get_bd_pins $inter_name/ACLK]
				connectRst [get_bd_pins $inter_name/ARESETN] "interconnect"
				for {set j 0} {$j < $num_si} {incr j} {
					set inf_num [ format %02u $j ]
					connectClock [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
					connectRst [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN] "peripheral"
				}
				connectClock [get_bd_pins $inter_name/M00_AXIS_ACLK]
				connectRst [get_bd_pins $inter_name/M00_AXIS_ARESETN] "peripheral"

				for {set j 0} {$j < $num_si} {incr j} {
					set master_inter_num [ expr $i*16 + $j ]
					set master_inter_level [ expr $inter_level-1 ]
					if {$inter_level == 1} {
						set master_inf [ format %02u $m ]
						set master_inter ${stream_name}_lvl${master_inter_level}_$master_inter_num
					} else {
						set master_inf 00
						set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_$master_inter_num
					}
					set slave [ format %02u [ expr $j%16 ] ]
					connect_bd_intf_net [get_bd_intf_pins $master_inter/M${master_inf}_AXIS] [get_bd_intf_pins $inter_name/S${slave}_AXIS]
				}
			}
		}
		set prev_ninter $ninter
		set ninter [ expr int(ceil($ninter/16.)) ]
		incr inter_level
	}
	return [expr $inter_level-1]
}

# Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
proc create_outStream_Inter_tree { stream_name nslaves nmasters } {
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
		if {$i == $ninter-1 && [ expr $prev_ninter%16 ] != 0} {
			set num_mi [ expr $prev_ninter%16 ]
		} else {
			set num_mi 16
		}

		set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
		set inter_conf $arb_config
		lappend inter_conf CONFIG.NUM_MI $num_mi CONFIG.NUM_SI $nslaves

		for {set j 0} {$j < $num_mi} {incr j} {
			set master_num [ format %02u $j ]
			set base_dest [ format "32\'d%d" [ expr $i*$stride*16 + $j*$stride ] ]
			set high_dest [ format "32\'d%d" [ expr $i*$stride*16 + ($j+1)*$stride - 1 ] ]
			lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
		}

		set_property -dict $inter_conf $inter

		connectClock [get_bd_pins $inter_name/ACLK]
		connectRst [get_bd_pins $inter_name/ARESETN] "interconnect"
		for {set j 0} { $j < $num_mi} {incr j} {
			set inf_num [ format %02u $j ]
			connectClock [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
			connectRst [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN] "peripheral"
		}
		for {set j 0} {$j < $nslaves} {incr j} {
			set inf_num [ format %02u $j ]
			connectClock [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
			connectRst [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN] "peripheral"
		}
	}

	set prev_ninter $ninter
	set ninter [ expr int(ceil($ninter/16.)) ]
	set stride [ expr $stride*16 ]
	incr inter_level

	while {$ninter < $prev_ninter} {
		for {set s 0} {$s < $nslaves} {incr s} {
			for {set i 0} {$i < $ninter} {incr i} {

				set inter_name ${stream_name}_lvl${inter_level}_s${s}_$i

				# Last interconnect may need less masters
				if {$i == $ninter-1 && [ expr $prev_ninter%16 ] != 0} {
					set num_mi [ expr $prev_ninter%16 ]
				} else {
					set num_mi 16
				}

				set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
				set inter_conf [ list \
					CONFIG.NUM_MI $num_mi \
					CONFIG.NUM_SI {1} \
				]

				for {set j 0} {$j < $num_mi} {incr j} {
					set master_num [ format %02u $j ]
					set base_dest [ format "32\'d%d" [ expr $i*$stride*16 + $j*$stride ] ]
					set high_dest [ format "32\'d%d" [ expr $i*$stride*16 + ($j+1)*$stride - 1 ] ]
					lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
				}

				set_property -dict $inter_conf $inter

				connectClock [get_bd_pins $inter_name/ACLK]
				connectRst [get_bd_pins $inter_name/ARESETN] "interconnect"
				for {set j 0} { $j < $num_mi} {incr j} {
					set inf_num [ format %02u $j ]
					connectClock [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
					connectRst [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN] "peripheral"
				}
				connectClock [get_bd_pins $inter_name/S00_AXIS_ACLK]
				connectRst [get_bd_pins $inter_name/S00_AXIS_ARESETN] "peripheral"

				for {set j 0} {$j < $num_mi} {incr j} {
					set slave_inter_num [ expr $i*16+$j ]
					set slave_inter_level [ expr $inter_level-1 ]
					set master [ format %02u $j ]
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
		set ninter [ expr int(ceil($ninter/16.)) ]
		set stride [ expr $stride*16 ]
		incr inter_level
	}
	return [expr $inter_level-1]
}

# Creates and connects a nested interconnect
proc createNestedInterconnect {} {
	upvar #0 interconOpt interconOpt
	upvar interface interface counter counter

	aitInfo "Creating nested interconnect for $interface"

	set parent_inter "${interface}_Inter"
	set nested_inter "${interface}_Inter_[expr $counter/16 - 1]"

	# Create new nested interconnect and configure it
	create_bd_cell -vlnv xilinx.com:ip:axi_interconnect $nested_inter
	set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.STRATEGY $interconOpt] [get_bd_cells $nested_inter]

	# Connect clocks and resets
	connectClock [get_bd_pins $nested_inter/ACLK]
	connectClock [get_bd_pins $nested_inter/S00_ACLK]
	connectClock [get_bd_pins $nested_inter/M00_ACLK]
	connectRst [get_bd_pins $nested_inter/ARESETN] "interconnect"
	connectRst [get_bd_pins $nested_inter/M00_ARESETN] "peripheral"
	connectRst [get_bd_pins $nested_inter/S00_ARESETN] "peripheral"

	# Disconnect lastly used port of parent interconnect
	set parent_intf_net [get_bd_intf_nets -of_objects [get_bd_intf_pins $parent_inter/S[format %02u [expr 15 - ($counter/16 - 1)]]_AXI]]
	set parent_intf_pin [get_bd_intf_pins -of_objects [get_bd_intf_nets $parent_intf_net] -filter {PATH !~ "*_AXI_*_Inter*"}]
	delete_bd_objs [get_bd_intf_nets $parent_intf_net]

	# Reconnect to new nested interconnect
	connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $parent_intf_pin] [get_bd_intf_pins $nested_inter/S00_AXI]

	# Connect nested interconnect to parent interconnect
	connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $parent_inter/S[format %02u [expr 15 - ($counter/16 - 1)]]_AXI] [get_bd_intf_pins $nested_inter/M00_AXI]

	incr counter
	save_bd_design
}

# Connects the IP to the host through the given port
proc connectToInterface {src intf role {num ""}} {
	upvar #0 board_interfaces intf_list interconOpt interconOpt

	if {$num ne ""} {
		set index [lsearch -regexp $intf_list ${role}_AXI_${intf}.*_${num}]
	} else {
		set index [lsearch -regexp $intf_list ${role}_AXI_${intf}(_[0-9])?]
	}
	set interface [lindex [lindex $intf_list $index] 0]
	set counter [lindex [lindex $intf_list $index] 1]
	set intf_list [lreplace $intf_list $index $index]

	# If interconnect already full, create a new nested one
	if {!($counter % 16) && ($counter > 0)} {
		if {$counter == 256} {
			# We already have filled 16 nested interconnects
			aitError "${intf} interface occupation is 100%"
		} else {
			createNestedInterconnect
		}
	}

	set inter [expr ($counter > 15) ? "{${interface}_Inter_[expr ($counter/16) - 1]}" : "{${interface}_Inter}"]

	set_property -dict [list CONFIG.NUM_${role}I [expr ($counter%16) + 1]] [get_bd_cells $inter]
	set_property -quiet -dict [list CONFIG.STRATEGY $interconOpt] [get_bd_cells $inter]
	connectClock [get_bd_pins $inter/${role}[format %02u [expr $counter%16]]_ACLK]
	connectRst [get_bd_pins $inter/${role}[format %02u [expr $counter%16]]_ARESETN] "peripheral"
	connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $src] [get_bd_intf_pins $inter/${role}[format %02u [expr $counter%16]]_AXI]

	incr counter
	lappend intf_list "$interface $counter"

	set intf_list [lsort -integer -index 1 -increasing $intf_list]
	return "$interface"
}

proc connectToMasterInterface {src {num ""}} {
	return [connectToInterface $src master M $num]
}

proc connectToDataInterface {src {num ""}} {
	upvar #0 dataInterfaces_map dataInterfaces_map
	upvar dataInterfaces_file dataInterfaces_file

	# If num is empty, look for $src in the dataInterfaces_map
	if {$num eq ""} {
		set index [lsearch -regexp $dataInterfaces_map $src]
		if {$index ne -1} {
			set port [lindex [lindex $dataInterfaces_map $index] 1]
			# port must be 'S_AXI_data_X' where X is the value we need for $num
			regsub {S_AXI_data_} $port "" num
		}
	}

	set interface [connectToInterface $src data S $num]

	# Add a line to datainterfaces.txt
	puts $dataInterfaces_file "$src\t$interface"

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
		set port [string trim [regsub -all {_Inter} $interconnect ""] "/"]
		upvar #0 board_interfaces intf_list
		set index [lsearch $intf_list "$port *"]
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
		set port [string trim [regsub -all {_Inter} $interconnect ""] "/"]
		set role [string trim [regsub -all {_AXI_.+$} $interconnect ""] "/"]
		set counter [expr [get_property CONFIG.NUM_${role}I $interconnect] - 1]
		if {$counter < 16} {
			lappend intf_list "${port} $counter"
			set intf_list [lsort -integer -index 1 -increasing $intf_list]
		}
	}
}

# If available, overwrite board-specific procedures
if {[file exists $path_Project/board/$board/procs.tcl]} {
	if {[catch {source -notrace $path_Project/board/$board/procs.tcl}]} {
		aitError "Failed overwritting board-specific procedures"
	}
}

# Compute addresses
# Lenght unit is 64-bit words
set bd_addr_segments [list \
	[dict create name cmdInQueue bd_seg_name Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $cmdInSubqueue_len*$num_accs*8]] \
	[dict create name cmdOutQueue bd_seg_name Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $cmdOutSubqueue_len*$num_accs*8]] \
	[dict create name hwruntime_rst bd_seg_name Hardware_Runtime/hwruntime_rst/S_AXI/Reg size 4096] \
]
if {$extended_hwruntime} {
	lappend bd_addr_segments [dict create name spawnInQueue bd_seg_name Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $spawnInQueue_len*8]]
	lappend bd_addr_segments [dict create name spawnOutQueue bd_seg_name Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0 size [expr $spawnOutQueue_len*8]]
}
if {$hwcounter || $hwinst} {
	lappend bd_addr_segments [dict create name hwcounter bd_seg_name HW_Counter/s_axi/reg0 size 4096]
}
# Sort the segments in decreasing size to minimize fragmentation when assigning addresses
set bd_addr_segments [lsort -decreasing -command comp_bd_addr_seg $bd_addr_segments]

set addr_hwruntime_spawnInQueue 0x0000000000000000
set addr_hwruntime_spawnOutQueue 0x0000000000000000
set addr_hwcounter 0x0000000000000000
if {!$extended_hwruntime} {
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
	} elseif {[expr ($size & ($size-1)) != 0]} { # Not power of 2
		set size_clog2 [expr int(ceil(log($size)/log(2)))]
		set size [expr int(pow(2, $size_clog2))]
	}
	if {[expr ($addr % $size) != 0]} {
		set addr [expr $addr + $size - ($addr % $size)]
	}
	set format_addr [format 0x%016x [expr $addr_base + $addr]]
	lset bd_addr_segments $i [dict replace $cur_dict addr $format_addr size $size]

	set name [dict get $cur_dict name]
	if {$name == "cmdInQueue"} {
		set addr_hwruntime_cmdInQueue $format_addr
	} elseif {$name == "cmdOutQueue"} {
		set addr_hwruntime_cmdOutQueue $format_addr
	} elseif {$name == "spawnInQueue"} {
		set addr_hwruntime_spawnInQueue $format_addr
	} elseif {$name == "spawnOutQueue"} {
		set addr_hwruntime_spawnOutQueue $format_addr
	} elseif {$name == "hwruntime_rst"} {
		set addr_hwruntime_rst $format_addr
	} elseif {$name == "hwcounter"} {
		set addr_hwcounter $format_addr
	}
	set addr [expr $addr + $size]
}

if {$arch_type == "soc"} {
	variable addr_bitInfo "0x0000000080020000"
} elseif {$arch_type == "fpga"} {
	variable addr_bitInfo [format 0x%016x [expr $addr_base + $bitInfo_offset]]
}

# Create project and set board files
create_project -force $name_Project $path_Project/$name_Project -part $chipPart
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
set_property ip_repo_paths $path_Repo [current_project]

# Add BSC auxiliary IPs
if {[file isdirectory $path_Project/IPs/]} {
	set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] $path_Project/IPs" [current_project]
	update_ip_catalog
	foreach {IP} [glob -nocomplain $path_Project/IPs/*.zip] {
		update_ip_catalog -add_ip $IP -repo_path $path_Project/IPs
	}
	foreach {IP} [glob -nocomplain $path_Project/IPs/*.{v,vhdl}] {
		import_files -norecurse $IP
	}
	update_ip_catalog
}

# If exists, add board IP repository
if {[file isdirectory $path_Project/board/$board/IPs/]} {
	set_property ip_repo_paths "[get_property ip_repo_paths [current_project]] $path_Project/board/$board/IPs" [current_project]
	update_ip_catalog
	foreach {IP} [glob -nocomplain $path_Project/board/$board/IPs/*.zip] {
		update_ip_catalog -add_ip $IP -repo_path $path_Project/board/$board/IPs
	}
}

# Update IP catalog
update_ip_catalog

# Generate Block Design from template
set argv $name_Project
if {[catch {source -notrace $path_Project/board/$board/baseDesign.tcl}]} {
	aitError "Failed sourcing board base design"
}

# Open Block Design
open_bd_design $path_Project/$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd

# Set synthesis by IP
set_property synth_checkpoint_mode Hierarchical [get_files $path_Project/$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd]

# Do not generate simulation scripts
set_property sim.ip.auto_export_scripts false [current_project]

# If enabled, set cache location
if {$IP_caching} {
	check_ip_cache -import_from_project -use_cache_location $path_CacheLocation
}

# If available, execute the user defined pre-design tcl script
if {[file exists $script_path/userPreDesign.tcl]} {
	if {[catch {source -notrace $script_path/userPreDesign.tcl}]} {
		aitError "Failed sourcing board pre base design"
	}
}

getInterfaceOccupation

# Add Smart OmpSs Manager template
if {$hwruntime == "som"} {
	if {[catch {source -notrace $path_Project/templates/Smart_OmpSs_Manager.tcl}]} {
		aitError "Failed sourcing Smart OmpSs Manager template"
	}

	variable name_hwruntime Smart_OmpSs_Manager

	if {$arch_type == "soc"} {
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

	if {$extended_hwruntime} {
		set hwruntime_max_acc_creators [expr max($num_acc_creators, 2)]
		set_property -dict [list CONFIG.MAX_ACC_CREATORS $hwruntime_max_acc_creators] [get_bd_cells Hardware_Runtime/$name_hwruntime]
		set_property -dict [list CONFIG.Write_Depth_A $spawnInQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnInQueue]
		set_property -dict [list CONFIG.Write_Depth_A $spawnOutQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnOutQueue]
		# Add the second port to bitInfo and connect it to SOM
		set_property -dict [list CONFIG.Memory_Type {Dual_Port_ROM} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false}] [get_bd_cells bitInfo]
		connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Hardware_Runtime/bitInfo] [get_bd_intf_pins bitInfo/BRAM_PORTB]
	}

	# Use managed reset for the accelerators reset signal
	variable name_ManagedRst Hardware_Runtime/managed_aresetn
} elseif {$hwruntime == "pom"} {
	if {[catch {source -notrace $path_Project/templates/Picos_OmpSs_Manager.tcl}]} {
		aitError "Failed sourcing Picos OmpSs Manager template"
	}

	variable name_hwruntime Picos_OmpSs_Manager

	if {$arch_type == "soc"} {
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
	set_property -dict [list CONFIG.MAX_ACCS $hwruntime_max_accs CONFIG.MAX_ACC_CREATORS $hwruntime_max_accs CONFIG.PICOS_ARGS $picos_args_hash] [get_bd_cells Hardware_Runtime/$name_hwruntime]

	if {$extended_hwruntime} {
		set hwruntime_max_acc_creators [expr max($num_acc_creators, 2)]
		set_property -dict [list CONFIG.MAX_ACC_CREATORS $hwruntime_max_acc_creators] [get_bd_cells Hardware_Runtime/$name_hwruntime]
		set_property -dict [list CONFIG.Write_Depth_A $spawnInQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnInQueue]
		set_property -dict [list CONFIG.Write_Depth_A $spawnOutQueue_len CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_bd_cells Hardware_Runtime/spawnOutQueue]

		# Add the second port to bitInfo and connect it to POM
		set_property -dict [list CONFIG.Memory_Type {Dual_Port_ROM} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false}] [get_bd_cells bitInfo]
		connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Hardware_Runtime/bitInfo] [get_bd_intf_pins bitInfo/BRAM_PORTB]
	}

	# Use managed reset for the accelerators reset signal
	variable name_ManagedRst Hardware_Runtime/managed_aresetn
}

set_property -dict [list CONFIG.MAX_ACC_TYPES [expr max([llength $accels], 2)]] [get_bd_cells Hardware_Runtime/$name_hwruntime]
set_property -dict [list CONFIG.CMDIN_SUBQUEUE_LEN $cmdInSubqueue_len CONFIG.CMDOUT_SUBQUEUE_LEN $cmdOutSubqueue_len] [get_bd_cells Hardware_Runtime/$name_hwruntime]
set num_common_hwruntime_intf 1
set num_acc_no_creators [expr $num_accs-$num_acc_creators]
if {$lock_hwruntime} {
	incr num_common_hwruntime_intf
	# Enable lock support if needed
	set_property -dict [list CONFIG.LOCK_SUPPORT {1}] [get_bd_cells Hardware_Runtime/$name_hwruntime]
}
if {$extended_hwruntime} {
	set_property -dict [list CONFIG.SPAWNIN_QUEUE_LEN $spawnInQueue_len CONFIG.SPAWNOUT_QUEUE_LEN $spawnOutQueue_len] [get_bd_cells Hardware_Runtime/$name_hwruntime]
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
if {$extended_hwruntime} {
	create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/spawn_in
	create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/taskwait_in
	create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/spawn_out
	create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/taskwait_out
}
if {$lock_hwruntime} {
	create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 $pi/lock_in
	create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 $po/lock_out
}

if {[catch {source -notrace $hwruntime_interconnect_script}]} {
	aitError "Failed sourcing $hwruntime_interconnect_script"
}

# Move the interconnects to the Hardware_Runtime hierarchy
move_bd_cells [get_bd_cells Hardware_Runtime] [get_bd_cells $pi]
move_bd_cells [get_bd_cells Hardware_Runtime] [get_bd_cells $po]

connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/cmdout_in] [get_bd_intf_pins Hardware_Runtime/$pi/cmdout_in]
connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/cmdin_out] [get_bd_intf_pins Hardware_Runtime/$po/cmdin_out]
if {$extended_hwruntime} {
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/spawn_in] [get_bd_intf_pins Hardware_Runtime/$pi/spawn_in]
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/spawn_out] [get_bd_intf_pins Hardware_Runtime/$po/spawn_out]
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/taskwait_in] [get_bd_intf_pins Hardware_Runtime/$pi/taskwait_in]
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/taskwait_out] [get_bd_intf_pins Hardware_Runtime/$po/taskwait_out]
}
if {$lock_hwruntime} {
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/lock_in] [get_bd_intf_pins Hardware_Runtime/$pi/lock_in]
	connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/$name_hwruntime/lock_out] [get_bd_intf_pins Hardware_Runtime/$po/lock_out]
}

# Set and get the actual PS frequency
set actFreq [setAndGetFreq $clockFreq]

save_bd_design

############# Start Block Design generation ############
#### User IPs
set accID 0

foreach acc $accels {
	lassign [split $acc ":"] accHash accNumInstances accName

	for {set j 0} {$j < $accNumInstances} {incr j} {

		if {[catch {source -notrace $path_Project/templates/dummy_acc.tcl}]} {
			aitError "Failed sourcing dummy acc template"
		}

		# Create dummy acc hierarchy and instantiate IP
		set_property name ${accName}_$j [get_bd_cells dummy_acc]
		create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper:1.0 ${accName}_$j/$accName

		# Replace dummy acc by IP instance and delete it
		replace_bd_cell -quiet ${accName}_$j/dummy_acc ${accName}_$j/$accName
		delete_bd_objs [get_bd_cells ${accName}_$j/dummy_acc]

		# Connect clk and rst pins
		connectClock [get_bd_pins ${accName}_$j/aclk]
		connect_bd_net [get_bd_pins ${accName}_$j/managed_aresetn] [get_bd_pins $name_ManagedRst]

		# If available, forward the outPort
		if {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_outPort_*] != ""} {
			# Create and connect the hsToStreamAdapter
			create_bd_cell -type module -reference hsToStreamAdapter ${accName}_$j/Adapter_outStream
			set_property -dict [list CONFIG.ACCID_WIDTH [expr max(int(ceil(log($num_accs)/log(2))), 1)]] [get_bd_cells ${accName}_$j/Adapter_outStream]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/in_hs_ap_vld] [get_bd_pins ${accName}_$j/$accName/mcxx_outPort_V_ap_vld]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/in_hs_ap_ack] [get_bd_pins ${accName}_$j/$accName/mcxx_outPort_V_ap_ack]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/in_hs] [get_bd_pins ${accName}_$j/$accName/mcxx_outPort_V]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/aclk] [get_bd_pins ${accName}_$j/aclk]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_outStream/accID] [get_bd_pins ${accName}_$j/accID/dout]
		}

		# If available, forward the inPort
		if {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_inPort_*] != ""} {
			# Create and connect the streamToHsAdapter
			create_bd_cell -type module -reference streamToHsAdapter ${accName}_$j/Adapter_inStream
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_inStream/out_hs_ap_vld] [get_bd_pins ${accName}_$j/$accName/mcxx_inPort_V_V_ap_vld]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_inStream/out_hs_ap_ack] [get_bd_pins ${accName}_$j/$accName/mcxx_inPort_V_V_ap_ack]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_inStream/out_hs] [get_bd_pins ${accName}_$j/$accName/mcxx_inPort_V_V]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_inStream/aclk] [get_bd_pins ${accName}_$j/aclk]
			connect_bd_net [get_bd_pins ${accName}_$j/Adapter_inStream/aresetn] [get_bd_pins ${accName}_$j/managed_aresetn]
		}

		connect_bd_intf_net [get_bd_intf_pins ${accName}_$j/inStream] [get_bd_intf_pins ${accName}_$j/Adapter_inStream/inStream]
		connect_bd_intf_net [get_bd_intf_pins ${accName}_$j/outStream] [get_bd_intf_pins ${accName}_$j/Adapter_outStream/outStream]

		# Get list of M_AXI ports
		# NOTE: Only handle the ports generated by mcxx, which start with the "mcxx_" prefix
		set listAccPorts [get_bd_intf_pins ${accName}_$j/$accName/m_axi_mcxx_*]

		# Connect each M_AXI port to an AXI interface
		foreach nameAccPort $listAccPorts {
			connectToDataInterface $nameAccPort
		}

		# If available, forward the instrumentation ports
		if {[expr {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_instr_*] != ""} || {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_hwcounterPort*] != ""}]} {

			# Create counter for the current accelerator
			create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary ${accName}_$j/hwinst_counter
			set_property -dict [list CONFIG.Output_Width {64}] [get_bd_cells ${accName}_$j/hwinst_counter]
			connect_bd_net [get_bd_pins ${accName}_$j/aclk] [get_bd_pins ${accName}_$j/hwinst_counter/CLK]

			if {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_instr_*] != ""} {

				# Create and connect the Adapter_instr
				create_bd_cell -type ip -vlnv bsc:ompss:Adapter_instr_wrapper:1.0 ${accName}_$j/Adapter_instr
				connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V_ap_vld] [get_bd_pins ${accName}_$j/$accName/mcxx_instr_V_ap_vld]
				connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V_ap_ack] [get_bd_pins ${accName}_$j/$accName/mcxx_instr_V_ap_ack]
				connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/in_V] [get_bd_pins ${accName}_$j/$accName/mcxx_instr_V]
				connectClock [get_bd_pins ${accName}_$j/Adapter_instr/ap_clk]
				connect_bd_net [get_bd_pins ${accName}_$j/Adapter_instr/ap_rst_n] [get_bd_pins ${accName}_$j/managed_aresetn]

				# Connect to hwinst_counter
				connect_bd_net [get_bd_pins ${accName}_$j/hwinst_counter/Q] [get_bd_pins ${accName}_$j/Adapter_instr/hwcounter]

				# Connect buffer port
				set accInstrBufferPort [get_bd_intf_pins -quiet ${accName}_$j/Adapter_instr/m_axi* -filter {NAME =~ "*instr_buffer"}]
				if {$accInstrBufferPort != ""} {
					connectToDataInterface $accInstrBufferPort
				}
			}

			if {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_hwcounterPort*] != ""} {
				connect_bd_net [get_bd_pins ${accName}_$j/hwinst_counter/Q] [get_bd_pins ${accName}_$j/$accName/mcxx_hwcounterPort*]
			}
		}

		# If available, forward the frequency port
		if {[get_bd_pins -quiet ${accName}_$j/$accName/mcxx_freqPort*] != ""} {
			# Create and connect constant with freq
			create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ${accName}_$j/accFreq
			set_property -dict [list CONFIG.CONST_VAL $actFreq CONFIG.CONST_WIDTH {10}] [get_bd_cells ${accName}_$j/accFreq]
			connect_bd_net [get_bd_pins ${accName}_$j/accFreq/dout] [get_bd_pins ${accName}_$j/$accName/mcxx_freqPort*]
		}

		connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/outStream] [get_bd_intf_pins Hardware_Runtime/$pi/S${accID}_AXIS]
		connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/inStream] [get_bd_intf_pins Hardware_Runtime/$po/M${accID}_AXIS]

		set_property -dict [list CONFIG.CONST_VAL $accID CONFIG.CONST_WIDTH [expr max(int(ceil(log($num_accs)/log(2))), 1)]] [get_bd_cells ${accName}_$j/accID]

		regenerate_bd_layout -hierarchy [get_bd_cell ${accName}_$j]

		save_bd_design

		# Increase global acc id
		incr accID

	}

}

# If enabled, add and connect hwcounter IP
if {$hwcounter || $hwinst} {
	create_bd_cell -type module -reference hwcounter HW_Counter

	if {$arch_type == "soc"} {
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

close $dataInterfaces_file

removeUnusedInter

file delete $path_Project/../${name_Project}.debuginterfaces.txt

# Mark AXI interfaces for debug
if {[expr {$debugInterfaces == "AXI"} || {$debugInterfaces == "both"}]} {
	# Create .debuginterfaces.txt file
	set debugInterfaces_file [open $path_Project/../${name_Project}.debuginterfaces.txt "w"]

	set axi_pin_list [get_bd_intf_pins -hierarchical -filter {PATH =~ *hls_automatic_mcxx*m_axi_mcxx*} -of_objects [get_bd_cells -hierarchical -filter {NAME =~ *_hls_automatic_mcxx}]]
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
if {[expr {$debugInterfaces == "stream"} || {$debugInterfaces == "both"}]} {
	# Open .debuginterfaces.txt file
	set debugInterfaces_file [open $path_Project/../${name_Project}.debuginterfaces.txt "a"]

	set stream_pin_list [get_bd_intf_pins -hierarchical -filter {VLNV =~ xilinx.com:interface:axis_rtl:* && PATH =~ *hls_automatic_mcxx*Adapter*Stream*} -of_objects [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:module_ref:hsToStreamAdapter:* || VLNV =~ xilinx.com:module_ref:streamToHsAdapter:*}]]
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
if {$debugInterfaces == "custom"} {
	# Open .debuginterfaces.txt file
	set debugInterfaces_file [open $path_Project/../${name_Project}.debuginterfaces.txt "w"]

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

assign_bd_address
set addr_list [get_bd_addr_segs -of_object [get_bd_addr_spaces bridge_to_host/Data]]
delete_bd_objs [get_bd_addr_segs *]
delete_bd_objs [get_bd_addr_segs -excluded *]

save_bd_design

# Create pl_ompss_fpga.dtsi file
set ompss_at_fpga_DeviceTree_file [open $path_Project/$name_Project/pl_ompss_at_fpga.dtsi "w"]
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

if {$extended_hwruntime} {
	set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<7]]
}

if {$hwruntime == "som"} {
	set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<8]]
} elseif {$hwruntime == "pom"} {
	set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<9]]
}
assign_bd_address [get_bd_addr_segs *bitInfo_BRAM_Ctrl*] -range 4K -offset $addr_bitInfo

configureAddressMap $addr_list $size_DDR

# Store real PS frequency in xtasks config file
set config_file [open $path_Project/../${name_Project}.xtasks.config "r"]
set newConfig_file [open $path_Project/../${name_Project}.xtasks.config.new "w"]
gets $config_file line
puts $newConfig_file "type\t#ins\tname\tfreq"
while { [gets $config_file line] >= 0 } {
	set line [string range $line 0 54]
	puts $newConfig_file "$line\t$actFreq"
}
close $config_file
close $newConfig_file
exec mv $path_Project/../${name_Project}.xtasks.config.new $path_Project/../${name_Project}.xtasks.config

# Generate xtasks.config binary string
set xtasks_bin_str ""
foreach acc $accels {
	lassign [split $acc ":"] accHash accNumInstances accName
	set bin_word [expr $accNumInstances | (($accHash & 0xFFFF) << 16)]
	append xtasks_bin_str [format "%08X\n" $bin_word]
	set bin_word [expr ($accHash >> 16) | ((($actFreq*1000) & 0xFF) << 24)]
	append xtasks_bin_str [format "%08X\n" $bin_word]
	set bin_word [expr ($actFreq*1000) >> 8]
	append xtasks_bin_str [format "%08X\n" $bin_word]
	# Remove suffix _hls_automatic_mcxx
	set accName [string range $accName 0 [expr [string length $accName]-[string length "_hls_automatic_mcxx"]-1]]
	if {[string length $accName] > 31} {
		set accName [string range $accName 0 30]
	}
	# Max length is 31 characters, but there are 8 padding bits at the end
	append accName [string repeat " " [expr 32-[string length $accName]]]
	# Convert ascii to hexadecimal string
	append xtasks_bin_str [ascii2hex $accName]
}

# Create bitInfo.coe file
set bitInfo_file [open $path_Project/$name_Project/bitInfo.coe "w"]
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
append bitInfo_coe "FFFFFFFF;"
# First two lines do not contain data
set data_length [expr [exec echo $bitInfo_coe | wc -l]-2]
puts $bitInfo_file $bitInfo_coe
close $bitInfo_file

set_property -dict [list CONFIG.Write_Depth_A $data_length CONFIG.Load_Init_File {true} CONFIG.Coe_File [pwd]/$path_Project/$name_Project/bitInfo.coe] [get_bd_cells bitInfo]

# Update outdated IPs
update_ip_catalog -rebuild -scan_changes
upgrade_ip -quiet [get_ips -filter UPGRADE_VERSIONS!={}]

# If exists, add constraints file
if {[file isdirectory $path_Project/board/$board/constraints/]} {
	add_files -fileset constrs_1 -norecurse $path_Project/board/$board/constraints/
}

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
} elseif {$interconRegSlice_ddr} {
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
