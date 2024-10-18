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

set pi_clk [get_bd_pins Hardware_Runtime/hwr_inStream/clk]
set pi_inter_rstn [get_bd_pins Hardware_Runtime/hwr_inStream/rstn]
set pi_peri_rstn [get_bd_pins Hardware_Runtime/hwr_inStream/rstn]
set po_clk [get_bd_pins Hardware_Runtime/hwr_outStream/clk]
set po_inter_rstn [get_bd_pins Hardware_Runtime/hwr_outStream/rstn]
set po_peri_rstn [get_bd_pins Hardware_Runtime/hwr_outStream/rstn]

set num_common_hwruntime_intf 1
set num_acc_no_creators [expr {${::AIT::num_accs} - ${::AIT::num_acc_creators}}]
if {${::AIT::lock_hwruntime}} {
    incr num_common_hwruntime_intf
}

# Create interconnect hierarchy to connect with accelerators
if {${::AIT::task_creation}} {
    # The extra masters redirect all cmdout_in and lock_in transfers from acc creators
    AIT::board::create_inStream_Inter_tree Hardware_Runtime/hwr_inStream/inS_common_Inter $num_common_hwruntime_intf [expr {$num_acc_no_creators + 1}] $pi_clk $pi_inter_rstn $pi_peri_rstn
    # spawn_out + taskwait_out + cmdin_out and lock_out which are collapsed in the same master
    AIT::board::create_inStream_Inter_tree Hardware_Runtime/hwr_inStream/inS_ext_Inter 3 ${::AIT::num_acc_creators} $pi_clk $pi_inter_rstn $pi_peri_rstn
    # spawn_out + taskwait_out + outS_common_Inter_M00 (cmdin_out + lock_out if available)
    set max_level_ext [AIT::board::create_outStream_Inter_tree Hardware_Runtime/hwr_outStream/outS_ext_Inter 3 ${::AIT::num_acc_creators} $po_clk $po_inter_rstn $po_peri_rstn]
    # The extra master filters all transfers to acc creators
    set max_level_common [AIT::board::create_outStream_Inter_tree Hardware_Runtime/hwr_outStream/outS_common_Inter $num_common_hwruntime_intf [expr {$num_acc_no_creators + 1}] $po_clk $po_inter_rstn $po_peri_rstn]
} else {
    AIT::board::create_inStream_Inter_tree Hardware_Runtime/hwr_inStream/inS_common_Inter $num_common_hwruntime_intf ${::AIT::num_accs} $pi_clk $pi_inter_rstn $pi_peri_rstn
    set max_level_common [AIT::board::create_outStream_Inter_tree Hardware_Runtime/hwr_outStream/outS_common_Inter $num_common_hwruntime_intf ${::AIT::num_accs} $po_clk $po_inter_rstn $po_peri_rstn]
}

set ninter [expr {int(ceil($num_acc_no_creators/16.))}]
for {set i 0} {$i < $ninter} {incr i} {
    if {${::AIT::lock_hwruntime}} {
        # Accelerator that do not create tasks never use the spawn_in/out nor the taskwait_in/out streams
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000000} \
            CONFIG.M01_AXIS_BASETDEST {0x00000001} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000001} \
         ] [get_bd_cells Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_$i]
    } else {
        # There's no need to filter if there is only one master
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
         ] [get_bd_cells Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_$i]
    }
}
if {${::AIT::task_creation}} {
    set ninter [expr {int(ceil(${::AIT::num_acc_creators}/16.))}]
    for {set i 0} {$i < $ninter} {incr i} {
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
            CONFIG.M01_AXIS_BASETDEST {0x00000002} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000002} \
            CONFIG.M02_AXIS_BASETDEST {0x00000003} \
            CONFIG.M02_AXIS_HIGHTDEST {0x00000003} \
         ] [get_bd_cells Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_$i]
    }
}

if {${::AIT::task_creation}} {
    if {$max_level_ext == 0} {
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_0/M01_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/spawn_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_0/M02_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/taskwait_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_0/S02_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/spawn_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/taskwait_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_0/S01_AXIS]
    } else {
        set max_level $max_level_ext
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl${max_level}_m0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl${max_level}_m1_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/spawn_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl${max_level}_m2_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/taskwait_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl${max_level}_s2_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/spawn_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl${max_level}_m0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/taskwait_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl${max_level}_m1_0/S00_AXIS]
    }
}
if {$max_level_common == 0} {
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/cmdout_in]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/cmdin_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_0/S00_AXIS]
    if {${::AIT::lock_hwruntime}} {
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_0/M01_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/lock_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/lock_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_0/S01_AXIS]
    }
} else {
    set max_level $max_level_common
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl${max_level}_m0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/cmdout_in]
    connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/cmdin_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl${max_level}_s0_0/S00_AXIS]
    if {${::AIT::lock_hwruntime}} {
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl${max_level}_m1_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/lock_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/lock_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl${max_level}_s1_0/S00_AXIS]
    }
}

set config_list [list CONFIG.M00_AXIS_BASETDEST {0x00000000} CONFIG.M00_AXIS_HIGHTDEST [format 0x%08X [expr {${::AIT::num_acc_creators} - 1}]]]
set prev_inter_i 0
for {set i 0} {$i < ${::AIT::num_accs}} {incr i} {
    set inStream_intf [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${i}_AXIS]
    set outStream_intf [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${i}_AXIS]
    set inter_i [expr {int($i/16)}]
    set intf_i [format %02u [expr {$i%16}]]

    if {$i < ${::AIT::num_acc_creators}} {
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_${inter_i}/M${intf_i}_AXIS] $outStream_intf
    } elseif {${::AIT::num_acc_creators} == 0} {
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS] $outStream_intf
    } else {
        set inter_i [expr {int(($i+1-${::AIT::num_acc_creators})/16)}]
        set intf_i [format %02u [expr {($i + 1 - ${::AIT::num_acc_creators})%16}]]
        connect_bd_intf_net $inStream_intf [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS] $outStream_intf
        if {$prev_inter_i != $inter_i} {
            set_property -dict $config_list [get_bd_cells Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${prev_inter_i}]
            set prev_inter_i $inter_i
            set config_list {}
        }
        lappend config_list CONFIG.M${intf_i}_AXIS_BASETDEST [format 0x%08X $i] CONFIG.M${intf_i}_AXIS_HIGHTDEST [format 0x%08X $i]
    }
}
if {${::AIT::task_creation}} {
    set_property -dict $config_list [get_bd_cells Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${prev_inter_i}]
}

if {${::AIT::interconRegSlice_hwruntime} || ${::AIT::interconRegSlice_all}} {
    set inStream_interconnects [get_bd_cells Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_*]
    set outStream_interconnects [get_bd_cells Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_*]

    if {${::AIT::task_creation}} {
        lappend inStream_interconnects [get_bd_cells Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_*]
        lappend outStream_interconnects [get_bd_cells Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_*]
    }

    foreach inter $inStream_interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property CONFIG.M[format %02u $i]_HAS_REGSLICE {1} $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property CONFIG.S[format %02u $i]_HAS_REGSLICE {1} $inter
        }
    }
    foreach inter $outStream_interconnects {
        for {set i 0} {$i < [get_property CONFIG.NUM_MI $inter]} {incr i} {
            set_property CONFIG.M[format %02u $i]_HAS_REGSLICE {1} $inter
        }
        for {set i 0} {$i < [get_property CONFIG.NUM_SI $inter]} {incr i} {
            set_property CONFIG.S[format %02u $i]_HAS_REGSLICE {1} $inter
        }
    }
}
