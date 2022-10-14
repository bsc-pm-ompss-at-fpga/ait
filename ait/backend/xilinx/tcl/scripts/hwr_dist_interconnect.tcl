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

set pi_clk [get_bd_pins $pi/clk]
set pi_inter_rstn [get_bd_pins $pi/interconnect_aresetn]
set pi_peri_rstn [get_bd_pins $pi/peripheral_aresetn]
set po_clk [get_bd_pins $po/clk]
set po_inter_rstn [get_bd_pins $po/interconnect_aresetn]
set po_peri_rstn [get_bd_pins $po/peripheral_aresetn]

create_inStream_Inter_tree $pi/inS_common_Inter $num_common_hwruntime_intf $num_accs $pi_clk $pi_inter_rstn $pi_peri_rstn
set max_level_common [create_outStream_Inter_tree $po/outS_common_Inter $num_common_hwruntime_intf $num_accs $po_clk $po_inter_rstn $po_peri_rstn]
if {$advanced_hwruntime} {
    # spawn + taskwait
    create_inStream_Inter_tree $pi/inS_ext_Inter 2 $num_acc_creators $pi_clk $pi_inter_rstn $pi_peri_rstn
    set max_level_ext [create_outStream_Inter_tree $po/outS_ext_Inter 2 $num_acc_creators $po_clk $po_inter_rstn $po_peri_rstn]
}

set ninter [expr int(ceil($num_accs/16.))]
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

if {$advanced_hwruntime} {
    set ninter [expr int(ceil($num_acc_creators/16.))]
    for {set i 0} {$i < $ninter} {incr i} {
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000002} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000002} \
            CONFIG.M01_AXIS_BASETDEST {0x00000003} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
        ] [get_bd_cell $pi/inS_ext_Inter_lvl0_$i]
    }
}

for {set i 0} {$i < $num_accs} {incr i} {
    set inter_i [expr int($i/16)]
    set intf_i [format %02u [expr $i%16]]

    if {$i < $num_acc_creators} {
        set inter_name $po/outS_extacc_Inter_${i}
        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
        set_property -dict [list \
            CONFIG.ARB_ON_MAX_XFERS {0} \
            CONFIG.ARB_ON_TLAST {1} \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
            CONFIG.NUM_MI {1} \
            CONFIG.NUM_SI {2} \
        ] $inter
        connect_bd_net $po_clk [get_bd_pins $inter_name/ACLK] [get_bd_pins $inter_name/S00_AXIS_ACLK] [get_bd_pins $inter_name/S01_AXIS_ACLK] [get_bd_pins $inter_name/M00_AXIS_ACLK]
        connect_bd_net $po_inter_rstn [get_bd_pins $inter_name/ARESETN] "interconnect"
        connect_bd_net $po_peri_rstn [get_bd_pins $inter_name/S00_AXIS_ARESETN] [get_bd_pins $inter_name/S01_AXIS_ARESETN] [get_bd_pins $inter_name/M00_AXIS_ARESETN]

        set inter_name $pi/inS_extacc_Inter_${i}
        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
            CONFIG.M01_AXIS_BASETDEST {0x00000002} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
            CONFIG.NUM_MI {2} \
            CONFIG.NUM_SI {1} \
        ] $inter
        connect_bd_net $pi_clk [get_bd_pins $inter_name/ACLK] [get_bd_pins $inter_name/M00_AXIS_ACLK] [get_bd_pins $inter_name/M01_AXIS_ACLK] [get_bd_pins $inter_name/S00_AXIS_ACLK]
        connect_bd_net $pi_inter_rstn [get_bd_pins $inter_name/ARESETN]
        connect_bd_net $pi_peri_rstn [get_bd_pins $inter_name/M00_AXIS_ARESETN] [get_bd_pins $inter_name/M01_AXIS_ARESETN] [get_bd_pins $inter_name/S00_AXIS_ARESETN]

        connect_bd_intf_net [get_bd_intf_pins $pi/inS_extacc_Inter_${i}/M00_AXIS] [get_bd_intf_pins $pi/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/inS_extacc_Inter_${i}/M01_AXIS] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/outS_extacc_Inter_${i}/S00_AXIS] [get_bd_intf_pins $po/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/outS_extacc_Inter_${i}/S01_AXIS] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/S${i}_AXIS] [get_bd_intf_pins $pi/inS_extacc_Inter_${i}/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/M${i}_AXIS] [get_bd_intf_pins $po/outS_extacc_Inter_${i}/M00_AXIS]
    } else {
        connect_bd_intf_net [get_bd_intf_pins $pi/S${i}_AXIS] [get_bd_intf_pins $pi/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/M${i}_AXIS] [get_bd_intf_pins $po/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
    }
}

if {$advanced_hwruntime} {
    if {$max_level_ext == 0} {
        connect_bd_intf_net [get_bd_intf_pins $pi/spawn_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/taskwait_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl0_0/M01_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/spawn_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/taskwait_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl0_0/S01_AXIS]
    } else {
        set max_level $max_level_ext
        connect_bd_intf_net [get_bd_intf_pins $pi/spawn_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl${max_level}_m0_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $pi/taskwait_in] [get_bd_intf_pins $pi/inS_ext_Inter_lvl${max_level}_m1_0/M00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/spawn_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl${max_level}_s0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins $po/taskwait_out] [get_bd_intf_pins $po/outS_ext_Inter_lvl${max_level}_s1_0/S00_AXIS]
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

if {[expr $interconRegSlice_hwruntime || $interconRegSlice_all]} {
    set inStream_interconnects [get_bd_cells $pi/inS_common_Inter_lvl0_*]
    set outStream_interconnects [get_bd_cells $po/outS_common_Inter_lvl0_*]
    if {$advanced_hwruntime} {
        lappend inStream_interconnects [get_bd_cells $pi/inS_ext_Inter_lvl0_*]
        lappend outStream_interconnects [get_bd_cells $po/outS_ext_Inter_lvl0_*]
    }

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

