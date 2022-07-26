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

# Create interconnect hierarchy to connect with accelerators
if {$extended_hwruntime} {
    # The extra masters redirect all cmdout_in and lock_in transfers from acc creators
    create_inStream_Inter_tree $pi/inS_common_Inter $num_common_hwruntime_intf [expr $num_acc_no_creators+1]
    # spawn_out + taskwait_out + cmdin_out and lock_out which are collapsed in the same master
    create_inStream_Inter_tree $pi/inS_ext_Inter 3 $num_acc_creators
    # spawn_out + taskwait_out + outS_common_Inter_M00 (cmdin_out + lock_out if available)
    set max_level_ext [create_outStream_Inter_tree $po/outS_ext_Inter 3 $num_acc_creators]
    # The extra master filters all transfers to acc creators
    set max_level_common [create_outStream_Inter_tree $po/outS_common_Inter $num_common_hwruntime_intf [expr $num_acc_no_creators+1]]
} else {
    create_inStream_Inter_tree $pi/inS_common_Inter $num_common_hwruntime_intf $num_accs
    set max_level_common [create_outStream_Inter_tree $po/outS_common_Inter $num_common_hwruntime_intf $num_accs]
}

set_property name interconnect_aresetn [get_bd_pins $pi/ARESETN]
set_property name peripheral_aresetn [get_bd_pins $pi/S00_AXIS_ARESETN]
set_property name interconnect_aresetn [get_bd_pins $po/ARESETN]
set_property name peripheral_aresetn [get_bd_pins $po/M00_AXIS_ARESETN]

set ninter [expr int(ceil($num_acc_no_creators/16.))]
for {set i 0} {$i < $ninter} {incr i} {
    if {$lock_hwruntime} {
        # Accelerator that do not create tasks never use the spawn_in/out nor the taskwait_in/out streams
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000000} \
            CONFIG.M01_AXIS_BASETDEST {0x00000001} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000001} \
        ] [get_bd_cell $pi/inS_common_Inter_lvl0_$i]
    } else {
        # There's no need to filter if there is only one master
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
        ] [get_bd_cell $pi/inS_common_Inter_lvl0_$i]
    }
}
if {$extended_hwruntime} {
    set ninter [expr int(ceil($num_acc_creators/16.))]
    for {set i 0} {$i < $ninter} {incr i} {
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
            CONFIG.M01_AXIS_BASETDEST {0x00000002} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
            CONFIG.M02_AXIS_BASETDEST {0x00000004} \
            CONFIG.M02_AXIS_HIGHTDEST {0x00000004} \
        ] [get_bd_cell $pi/inS_ext_Inter_lvl0_$i]
    }
}

if {$extended_hwruntime} {
    if {$max_level_ext == 0} {
        connect_bd_intf_net [get_bd_intf_pins $pi/inS_common_Inter_lvl0_0/S00_AXIS] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/spawn_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_0/M01_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/taskwait_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_0/M02_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/outS_common_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_0/S02_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/spawn_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/taskwait_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_0/S01_AXIS]
    } else {
        set max_level $max_level_ext
        connect_bd_intf_net [get_bd_intf_pins $pi/inS_common_Inter_lvl0_0/S00_AXIS] [get_bd_intf_pins $pi/inS_ext_Inter_lvl${max_level}_m0_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/spawn_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl${max_level}_m1_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/taskwait_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl${max_level}_m2_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/outS_common_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins $po/outS_ext_Inter_lvl${max_level}_s2_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/spawn_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl${max_level}_m0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/taskwait_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl${max_level}_m1_0/S00_AXIS]
    }
}
if {$max_level_common == 0} {
    connect_bd_intf_net [get_bd_intf_pins $pi/cmdout_in] [get_bd_intf_pins $pi/inS_common_Inter_lvl0_0/M00_AXIS]
    connect_bd_intf_net [get_bd_intf_pins $po/cmdin_out] [get_bd_intf_pins $po/outS_common_Inter_lvl0_0/S00_AXIS]
    if {$lock_hwruntime} {
        connect_bd_intf_net [get_bd_intf_pins $pi/lock_in] [get_bd_intf_pins $pi/inS_common_Inter_lvl0_0/M01_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/lock_out] [get_bd_intf_pins $po/outS_common_Inter_lvl0_0/S01_AXIS]
    }
} else {
    set max_level $max_level_common
    connect_bd_intf_net [get_bd_intf_pins $pi/cmdout_in] [get_bd_intf_pins $pi/inS_common_Inter_lvl${max_level}_m0_0/M00_AXIS]
    connect_bd_intf_net [get_bd_intf_pins $po/cmdin_out] [get_bd_intf_pins $po/outS_common_Inter_lvl${max_level}_s0_0/S00_AXIS]
    if {$lock_hwruntime} {
        connect_bd_intf_net [get_bd_intf_pins $pi/lock_in] [get_bd_intf_pins $pi/inS_common_Inter_lvl${max_level}_m1_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/lock_out] [get_bd_intf_pins $po/outS_common_Inter_lvl${max_level}_s1_0/S00_AXIS]
    }
}

set config_list [list CONFIG.M00_AXIS_BASETDEST {0x00000000} CONFIG.M00_AXIS_HIGHTDEST [format 0x%08X [expr $num_acc_creators-1]]]
set prev_inter_i 0
for {set i 0} {$i < $num_accs} {incr i} {
    set inStream_intf [get_bd_intf_pins $pi/S${i}_AXIS]
    set outStream_intf [get_bd_intf_pins $po/M${i}_AXIS]
    set inter_i [expr int($i/16)]
    set intf_i [format %02u [expr $i%16]]

    if {$i < $num_acc_creators} {
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net $outStream_intf [get_bd_intf_pins $po/outS_ext_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
    } elseif {$num_acc_creators == 0} {
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins $pi/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net $outStream_intf [get_bd_intf_pins $po/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
    } else {
        set inter_i [expr int(($i+1-$num_acc_creators)/16)]
        set intf_i [format %02u [expr ($i+1-$num_acc_creators)%16]]
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins $pi/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net $outStream_intf [get_bd_intf_pins $po/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
        if {$prev_inter_i != $inter_i} {
            set_property -dict $config_list [get_bd_cell $po/outS_common_Inter_lvl0_${prev_inter_i}]
            set prev_inter_i $inter_i
            set config_list {}
        }
        lappend config_list CONFIG.M${intf_i}_AXIS_BASETDEST [format 0x%08X $i] CONFIG.M${intf_i}_AXIS_HIGHTDEST [format 0x%08X $i]
    }
}
if {$extended_hwruntime} {
    set_property -dict $config_list [get_bd_cell $po/outS_common_Inter_lvl0_${prev_inter_i}]
}

if {[expr $interconRegSlice_hwruntime || $interconRegSlice_all]} {
    set inStream_interconnects [get_bd_cells $pi/inS_common_Inter_lvl0_*]
    lappend inStream_interconnects [get_bd_cells $pi/inS_ext_Inter_lvl0_*]
    set outStream_interconnects [get_bd_cells $po/outS_common_Inter_lvl0_*]
    lappend outStream_interconnects [get_bd_cells $po/outS_ext_Inter_lvl0_*]

    foreach inter $inStream_interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property -dict [list CONFIG.M[format %02u $i]_HAS_REGSLICE {1}] $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property -dict [list CONFIG.S[format %02u $i]_HAS_REGSLICE {1}] $inter
        }
    }
    foreach inter $outStream_interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property -dict [list CONFIG.M[format %02u $i]_HAS_REGSLICE {1}] $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property -dict [list CONFIG.S[format %02u $i]_HAS_REGSLICE {1}] $inter
        }
    }
}
