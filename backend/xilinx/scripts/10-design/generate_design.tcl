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

## AIT messages procedures
# Error
proc aitError {msg} {
	puts "\[AIT\] ERROR: $msg"
	exit 1
}

# Info
proc aitInfo {msg} {
	puts "\[AIT\] INFO: $msg"
}

# Configuration variables
set script_path [file dirname [file normalize [info script]]]
if {[catch {source -notrace $script_path/../projectVariables.tcl}]} {
	aitError "Failed sourcing project variables"
}

variable bitmap_bitInfo "0x00000000"
set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | ([expr $interconOpt - 1]<<2)]]
set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | ($interconLevel<<3)]]

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
	aitInfo "Using generic connectClock procedure"

	connect_bd_net -quiet [get_bd_pins $srcPin] [get_bd_pins clock_generator/clk_out1]
}

# Connects reset
proc connectRst {rst_source rst_name} {
	aitInfo "Using generic connectRst procedure"

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

		set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
		set_property -dict [ list \
			CONFIG.ARB_ON_MAX_XFERS {0} \
			CONFIG.ARB_ON_TLAST {1} \
			CONFIG.NUM_MI $nmasters \
			CONFIG.NUM_SI $num_si \
		] $inter

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

				set inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name ]
				set_property -dict [ list \
					CONFIG.ARB_ON_MAX_XFERS {0} \
					CONFIG.ARB_ON_TLAST {1} \
					CONFIG.M00_AXIS_BASETDEST {0x00000000} \
					CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
					CONFIG.NUM_MI {1} \
					CONFIG.NUM_SI $num_si \
				] $inter

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
					set master_inter_level [ expr $inter_level-1]
					if {$inter_level == 1} {
						set master_inf [ format %02u $m ]
						set master_inter ${stream_name}_lvl${master_inter_level}_$master_inter_num
					} else {
						set master_inf 00
						set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_$master_inter_num
					}
					set slave [ format %02u [ expr $j%16 ] ]
					connect_bd_intf_net -intf_net ${inter_name}_S${slave} [get_bd_intf_pins $master_inter/M${master_inf}_AXIS] [get_bd_intf_pins $inter_name/S${slave}_AXIS]
				}
			}
		}
		set prev_ninter $ninter
		set ninter [ expr int(ceil($ninter/16.)) ]
		incr inter_level
	}
	return $inter_level
}

# Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
proc create_outStream_Inter_tree { stream_name nslaves nmasters } {
	set ninter [expr int(ceil($nmasters/16.))]
	set prev_ninter $nmasters
	set inter_level 0
	set stride 1

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
		set inter_conf [ list \
			CONFIG.ARB_ON_MAX_XFERS {0} \
			CONFIG.ARB_ON_TLAST {1} \
			CONFIG.NUM_MI $num_mi \
			CONFIG.NUM_SI $nslaves \
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
					set slave_inter_level [ expr $inter_level-1]
					set master [ format %02u $j ]
					if {$inter_level == 1} {
						set slave_inf [format %02u $s]
						set slave_inter ${stream_name}_lvl${slave_inter_level}_$slave_inter_num
					} else {
						set slave_inf 00
						set slave_inter ${stream_name}_lvl${slave_inter_level}_s${s}_$slave_inter_num
					}
					connect_bd_intf_net -intf_net ${inter_name}_M$master [get_bd_intf_pins $slave_inter/S${slave_inf}_AXIS] [get_bd_intf_pins $inter_name/M${master}_AXIS]
				}
			}
		}
		set prev_ninter $ninter
		set ninter [ expr int(ceil($ninter/16.)) ]
		set stride [ expr $stride*16 ]
		incr inter_level
	}
	return $inter_level
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
			# port must be 'data_X' where X is the value we need for $num
			regsub {data_} $port "" num
		}
	}

	set portIndex [connectToInterface $src data S $num]

	# Add a line to datainterfaces.txt
	puts $dataInterfaces_file "$src\t$portIndex"

	return "$portIndex"
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
	set_property -dict [list CONFIG.ARB_ON_TLAST {1} CONFIG.ARB_ON_MAX_XFERS {0}] [get_bd_cells $name]

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
# TODO: Reorder address map to compact it
#variable addr_bitInfo          [format 0x%08x [expr $addr_base + 0x00000]] ;# 4kB
variable addr_hwruntime_cmdInQueue    [format 0x%08x [expr $addr_base + 0x04000]] ;# 16kB
variable addr_hwruntime_cmdOutQueue   [format 0x%08x [expr $addr_base + 0x08000]] ;# 16kB
variable addr_hwruntime_rst           [format 0x%08x [expr $addr_base + 0x0C000]] ;# 4kB
variable addr_hwcounter               [format 0x%08x [expr $addr_base + 0x10000]] ;# 4kB
variable addr_hwruntime_spawnOutQueue [format 0x%08x [expr $addr_base + 0x14000]] ;# 16kB
variable addr_hwruntime_spawnInQueue  [format 0x%08x [expr $addr_base + 0x18000]] ;# 16kB
if {$arch_type == "soc"} {
	variable addr_bitInfo "0x80020000"
} elseif {$arch_type == "fpga"} {
	variable addr_bitInfo [format 0x%08x [expr $addr_base + 0x20000]]
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
	set_property -dict [list CONFIG.MAX_ACCS $hwruntime_max_accs CONFIG.MAX_ACC_CREATORS $hwruntime_max_accs] [get_bd_cells Hardware_Runtime/$name_hwruntime]

	if {$extended_hwruntime} {
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
	set_property -dict [list CONFIG.MAX_ACCS $hwruntime_max_accs CONFIG.MAX_ACC_CREATORS $hwruntime_max_accs] [get_bd_cells Hardware_Runtime/$name_hwruntime]

	# Add the second port to bitInfo and connect it to SOM
	set_property -dict [list CONFIG.Memory_Type {Dual_Port_ROM} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false}] [get_bd_cells bitInfo]
	connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Hardware_Runtime/bitInfo] [get_bd_intf_pins bitInfo/BRAM_PORTB]

	# Use managed reset for the accelerators reset signal
	variable name_ManagedRst Hardware_Runtime/managed_aresetn
}

if {[expr {$hwruntime == "som"} || {$hwruntime == "pom"}]} {
	set_property -dict [list CONFIG.MAX_ACC_TYPES [expr max([llength $accels], 2)]] [get_bd_cells Hardware_Runtime/$name_hwruntime]
	set num_hwruntime_intf 1
	if {$lock_hwruntime} {
		incr num_hwruntime_intf 1
		# Enable lock support if needed
		set_property -dict [list CONFIG.LOCK_SUPPORT {1}] [get_bd_cells Hardware_Runtime/$name_hwruntime]
	}
	if {$extended_hwruntime} {
		incr num_hwruntime_intf 2
	}
	# Create interconnect hierarchy to connect with accelerators
	create_inStream_Inter_tree Hardware_Runtime/inStream_Inter $num_hwruntime_intf $num_accs
	set max_level [create_outStream_Inter_tree Hardware_Runtime/outStream_Inter $num_hwruntime_intf $num_accs]
	set ninter [expr int(ceil($num_accs/16.))]
	for {set i 0} {$i < $ninter} {incr i} {
		set_property -dict [ list \
			CONFIG.M00_AXIS_BASETDEST {0x00000011} \
			CONFIG.M00_AXIS_HIGHTDEST {0x00000011} \
			CONFIG.M01_AXIS_BASETDEST {0x00000012} \
			CONFIG.M01_AXIS_HIGHTDEST {0x00000013} \
			CONFIG.M02_AXIS_BASETDEST {0x00000014} \
			CONFIG.M02_AXIS_HIGHTDEST {0x00000014} \
			CONFIG.M03_AXIS_BASETDEST {0x00000015} \
			CONFIG.M03_AXIS_HIGHTDEST {0x00000015} \
		] [ get_bd_cell Hardware_Runtime/inStream_Inter_lvl0_$i ]
	}
	set hwruntime_path Hardware_Runtime/$name_hwruntime
	set lock_intf_num [format %02u [expr $num_hwruntime_intf-1]]
	if {$max_level == 1} {
		connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/cmdout_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl0_0/M00_AXIS]
		connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/cmdin_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl0_0/S00_AXIS]
		if {$extended_hwruntime} {
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/spawn_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl0_0/M01_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/taskwait_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl0_0/M02_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/spawn_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl0_0/S01_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/taskwait_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl0_0/S02_AXIS]
		}
		if {$lock_hwruntime} {
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/lock_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl0_0/M${lock_intf_num}_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/lock_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl0_0/S${lock_intf_num}_AXIS]
		}
	} else {
		connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/cmdout_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl${max_level}_0/M00_AXIS]
		connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/cmdin_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl${max_level}_0/S00_AXIS]
		if {$extended_hwruntime} {
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/spawn_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl${max_level}_1/M00_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/taskwait_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl${max_level}_2/M00_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/spawn_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl${max_level}_1/S00_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/taskwait_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl${max_level}_2/S00_AXIS]
		}
		if {$lock_hwruntime} {
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/lock_in] [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl${max_level}_${lock_intf_num}/M00_AXIS]
			connect_bd_intf_net [get_bd_intf_pins $hwruntime_path/lock_out] [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl${max_level}_${lock_intf_num}/S00_AXIS]
		}
	}
	for {set i 0} {$i < $num_accs} {incr i} {
		set inStream_intf [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Hardware_Runtime/inStream_$i]
		set outStream_intf [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Hardware_Runtime/outStream_$i]
		set inter_i [expr int($i/16)]
		set intf_i [format %02u [expr $i%16]]
		connect_bd_intf_net $inStream_intf [get_bd_intf_pins Hardware_Runtime/inStream_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
		connect_bd_intf_net $outStream_intf [get_bd_intf_pins Hardware_Runtime/outStream_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
	}
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

		# Compute number of interfaces needed for the outStream interconnect
		set accNumInterfaces [expr {$hwruntime == "som"} || {$hwruntime == "pom"}]
		if {[expr $interconLevel == 2]} {
			incr accNumInterfaces [expr $num_accs - 1]
		} elseif {[expr $interconLevel == 1]} {
			incr accNumInterfaces [expr $accNumInstances - 1]
		}

		if {$accNumInterfaces > 1} {
			createAXISInterconnect ${accName}_${j}_outStream 1 $accNumInterfaces
			connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/outStream] [get_bd_intf_pins ${accName}_${j}_outStream/S00_AXIS]

			createAXISInterconnect ${accName}_${j}_inStream $accNumInterfaces 1
			set_property -quiet -dict [list CONFIG.M00_AXIS_BASETDEST 0x[format %X $accID] CONFIG.M00_AXIS_HIGHTDEST 0x[format %X $accID]] [get_bd_cells ${accName}_${j}_inStream]
			connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/inStream] [get_bd_intf_pins ${accName}_${j}_inStream/M00_AXIS]

			set interfaceNum 0
			set list_TDEST ""
		}

		set_property -dict [list CONFIG.CONST_VAL $accID CONFIG.CONST_WIDTH [expr max(int(ceil(log($num_accs)/log(2))), 1)]] [get_bd_cells ${accName}_$j/accID]

		if {[expr $interconLevel == 2]} {
			# Full interconnection. Connect accelerator with all the others
			foreach acc $accels {
				lassign [split $acc ":"] aux_accHash aux_accNumInstances aux_accName
				if {$aux_accName != $accName} {
					for {set ii 0} {$ii < $aux_accNumInstances} {incr ii} {
						if {$accNumInterfaces > 1} {
							connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}_outStream/M[format %02u $interfaceNum]_AXIS] [get_bd_intf_pins ${aux_accName}_${ii}_inStream/S[format %02u [expr $accID - 1]]_AXIS]
							connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${aux_accName}_${ii}_outStream/M[format %02u [expr $accID - 1]]_AXIS] [get_bd_intf_pins ${accName}_${j}_inStream/S[format %02u $interfaceNum]_AXIS]
							incr interfaceNum
						} else {
							connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/outStream] [get_bd_intf_pins ${aux_accName}_$ii/inStream]
							connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/inStream] [get_bd_intf_pins ${aux_accName}_$ii/outStream]
						}
					}
				} else {
					break
				}
			}
		}

		if {[expr $interconLevel >= 1]} {
			# Type interconnection. Connect accelerator with other accelerators of the same type
			if {[expr $interconLevel == 2]} {
				set aux_interfaceNum [expr $accID - 1]
			} elseif {[expr $interconLevel == 1]} {
				set aux_interfaceNum [expr $j - 1]
			}

			for {set ii 0} {$ii < $j} {incr ii} {
				if {$accNumInterfaces > 1} {
					connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}_outStream/M[format %02u $interfaceNum]_AXIS] [get_bd_intf_pins ${accName}_${ii}_inStream/S[format %02u $aux_interfaceNum]_AXIS]
					connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${ii}_outStream/M[format %02u $aux_interfaceNum]_AXIS] [get_bd_intf_pins ${accName}_${j}_inStream/S[format %02u $interfaceNum]_AXIS]
					incr interfaceNum
				} else {
					connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/outStream] [get_bd_intf_pins ${accName}_$ii/inStream]
					connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_$j/inStream] [get_bd_intf_pins ${accName}_$ii/outStream]
				}
			}
		}

		# Basic interconnection. Connect accelerator to hwruntime
		if {[expr {$hwruntime == "som"} || {$hwruntime == "pom"}]} {
			if {$accNumInterfaces > 1} {
				set TM_interfaceNum [expr [get_property CONFIG.NUM_MI [get_bd_cells ${accName}_${j}_outStream]] - 1]
				lappend list_TDEST CONFIG.M[format %02u $TM_interfaceNum]_AXIS_BASETDEST 0x[format %X 0x11] CONFIG.M[format %02u $TM_interfaceNum]_AXIS_HIGHTDEST 0x[format %X 0x14]
				connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}_outStream/M[format %02u $TM_interfaceNum]_AXIS] [get_bd_intf_pins Hardware_Runtime/inStream_$accID]
				connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}_inStream/S[format %02u $TM_interfaceNum]_AXIS] [get_bd_intf_pins Hardware_Runtime/outStream_$accID]
			} else {
				connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/outStream] [get_bd_intf_pins Hardware_Runtime/inStream_$accID]
				connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${accName}_${j}/inStream] [get_bd_intf_pins Hardware_Runtime/outStream_$accID]
			}

		}

		if {$accNumInterfaces > 1} {
			if {$interconLevel == 2} {
				for {set ii $accID} {$ii < [expr $num_accs - 1]} {incr ii} {
					lappend list_TDEST CONFIG.M[format %02u $ii]_AXIS_BASETDEST 0x[format %X [expr $ii + 1]] CONFIG.M[format %02u $ii]_AXIS_HIGHTDEST 0x[format %X [expr $ii + 1]]
				}
			} elseif {$interconLevel == 1} {
				for {set ii 0} {$ii < [expr $accNumInstances - 1]} {incr ii} {
					for {set ii 0} {$ii < $j} {incr ii} {
						lappend list_TDEST CONFIG.M[format %02u $ii]_AXIS_BASETDEST 0x[format %X [expr $accID - $j + $ii]] CONFIG.M[format %02u $ii]_AXIS_HIGHTDEST 0x[format %X [expr $accID - $j + $ii]]
					}
					for {set ii $j} {$ii < [expr $accNumInstances - 1]} {incr ii} {
						lappend list_TDEST CONFIG.M[format %02u $ii]_AXIS_BASETDEST 0x[format %X [expr $accID - $j + $ii + 1]] CONFIG.M[format %02u $ii]_AXIS_HIGHTDEST 0x[format %X [expr $accID - $j + $ii + 1]]
					}
				}
			}
			set_property -dict $list_TDEST [get_bd_cells ${accName}_${j}_outStream]
		}

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
		puts $debugInterfaces_file "DEBUG_AXI\t$axi_pin"
	}
	set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]
	close $debugInterfaces_file
}

# Mark AXI-Stream interfaces for debug
if {[expr {$debugInterfaces == "stream"} || {$debugInterfaces == "both"}]} {
	# Open .debuginterfaces.txt file
	set debugInterfaces_file [open $path_Project/../${name_Project}.debuginterfaces.txt "a"]

	set stream_pin_list [get_bd_intf_pins -hierarchical -filter {VLNV =~ xilinx.com:interface:axis_rtl:* && PATH =~ *hls_automatic_mcxx*mcxx_*} -of_objects [get_bd_cells -hierarchical -filter {NAME =~ *_hls_automatic_mcxx}]]
	foreach stream_pin $stream_pin_list {
		set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $stream_pin]]]
		apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $stream_pin]]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]

		# Add a line to debuginterfaces.txt
		puts $debugInterfaces_file "DEBUG_STREAM\t$stream_pin"
	}
	set_property -dict [list CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_bd_cells -hierarchical -filter {VLNV =~ xilinx.com:ip:system_ila*}]
	close $debugInterfaces_file
}

# Mark custom interfaces for debug
if {$debugInterfaces == "custom"} {
	# Open .debuginterfaces.txt file
	set debugInterfaces_file [open $path_Project/../${name_Project}.debuginterfaces.txt "w"]

	foreach element $debugInterfaces_list {
		foreach {type intf} $element {
			set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]]

			if {$type == "DEBUG_AXI"} {
				apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]] {AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]
			} elseif {$type == "DEBUG_STREAM"} {
				apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list [get_bd_intf_nets [get_bd_intf_nets -of_objects [get_bd_intf_pins $intf]]] {AXIS_SIGNALS "Data and Trigger" CLK_SRC clock_generator/clk_out1 SYSTEM_ILA "Auto" APC_EN "0" }]
			} else {
				aitError "Debug interface type $type not recognized"
			}

			# Add a line to debuginterfaces.txt
			puts $debugInterfaces_file "$type\t$intf"
		}
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

# Connect Hardware Runtime to accelerators and map queues to address space
if {[expr {$hwruntime == "som"} || {$hwruntime == "pom"}]} {

	set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<6]]

	# Map cmdInQueue to address space
	assign_bd_address [get_bd_addr_segs Hardware_Runtime/cmdInQueue_BRAM_Ctrl/S_AXI/Mem0] -range 8K -offset $addr_hwruntime_cmdInQueue

	# Map cmdOutQueue to address space
	assign_bd_address [get_bd_addr_segs Hardware_Runtime/cmdOutQueue_BRAM_Ctrl/S_AXI/Mem0] -range 8K -offset $addr_hwruntime_cmdOutQueue

	# Map hwruntime_rst to address space
	assign_bd_address [get_bd_addr_segs Hardware_Runtime/hwruntime_rst/S_AXI/Reg] -range 4K -offset $addr_hwruntime_rst

	# If exist, map SpawnIn and SpawnOut queues to address space
	if {$extended_hwruntime} {
		assign_bd_address [get_bd_addr_segs Hardware_Runtime/spawnOutQueue_BRAM_Ctrl/S_AXI/Mem0] -range 8K -offset $addr_hwruntime_spawnOutQueue
		assign_bd_address [get_bd_addr_segs Hardware_Runtime/spawnInQueue_BRAM_Ctrl/S_AXI/Mem0] -range 8K -offset $addr_hwruntime_spawnInQueue
	}

	# Generate device-tree node
	append ompss_at_fpga_node "\t\thwruntime-rst = <&Hardware_Runtime_hwruntime_rst>;\n"
	append ompss_at_fpga_node "\t\thwruntime-cmdinqueue = <&Hardware_Runtime_cmdInQueue_BRAM_Ctrl>;\n"
	append ompss_at_fpga_node "\t\thwruntime-cmdoutqueue = <&Hardware_Runtime_cmdOutQueue_BRAM_Ctrl>;\n"
	if {$extended_hwruntime} {
		append ompss_at_fpga_node "\t\thwruntime-spawnoutqueue = <&Hardware_Runtime_spawnOutQueue_BRAM_Ctrl>;\n"
		append ompss_at_fpga_node "\t\thwruntime-spawninqueue = <&Hardware_Runtime_spawnInQueue_BRAM_Ctrl>;\n"
		set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<7]]
	}

	if {$hwruntime == "som"} {
		set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<8]]
	}
}

# Map hwcounter to address space
if {[get_bd_cells -quiet HW_Counter] != ""} {
	assign_bd_address [get_bd_addr_segs HW_Counter/s_axi/reg0]
	set_property range 4K [get_bd_addr_segs *SEG_HW_Counter_reg0]
	set_property offset $addr_hwcounter [get_bd_addr_segs *SEG_HW_Counter_reg0]

	# Add hwcounter to pl_ompss_at_fpga.dtsi file
	append ompss_at_fpga_node "\t\thwcounter = <&HW_Counter>;\n"

	set bitmap_bitInfo [format 0x%08x [expr $bitmap_bitInfo | 0x1<<0]]
}

assign_bd_address [get_bd_addr_segs *bitInfo_BRAM_Ctrl*] -range 4K -offset $addr_bitInfo

configureAddressMap $addr_list $size_DDR

append ompss_at_fpga_node "\t};\n};"
puts $ompss_at_fpga_DeviceTree_file $ompss_at_fpga_node
close $ompss_at_fpga_DeviceTree_file

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

# Create bitInfo.coe file
set bitInfo_file [open $path_Project/$name_Project/bitInfo.coe "w"]
set bitInfo_coe "memory_initialization_radix=16;\nmemory_initialization_vector=\n"

append bitInfo_coe [format %08x $version_bitInfo]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [format %08x $num_accs]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [exec od -A n -t x4 -w4 -v --endian=little $path_Project/../${name_Project}.xtasks.config]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [format %08x $bitmap_bitInfo]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [exec echo $ait_call | od -A n -t x4 -w4 --endian=little]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [format %08x [expr $version_major_ait<<16 | $version_minor_ait]]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [format %08x $version_wrapper]
if {$hwruntime != "None"} {
	set hwruntime_vlnv [get_property VLNV [get_bd_cells /Hardware_Runtime/$name_hwruntime]]
} else {
	set hwruntime_vlnv "none"
}
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [exec echo $hwruntime_vlnv | od -A n -t x4 -w4 --endian=little]
append bitInfo_coe "\nFFFFFFFF\n"
append bitInfo_coe [format %08x [getBaseFreq]]
append bitInfo_coe "\nFFFFFFFF\nFFFFFFFF"
set data_length [exec echo $bitInfo_coe | wc -l]
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

if {[expr ($interconRegSlice_hwruntime || $interconRegSlice_all) && ( {$hwruntime == "pom"} || {$hwruntime == "som"} )]} {
	set inStream_interconnects [get_bd_cells Hardware_Runtime/inStream_Inter_lvl0_*]
	set outStream_interconnects [get_bd_cells Hardware_Runtime/outStream_Inter_lvl0_*]

	foreach inter $inStream_interconnects {
		for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
			set_property -dict [list CONFIG.S[format %02u $i]_HAS_REGSLICE {1}] $inter
		}
	}
	foreach inter $outStream_interconnects {
		for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
			set_property -dict [list CONFIG.M[format %02u $i]_HAS_REGSLICE {1}] $inter
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
