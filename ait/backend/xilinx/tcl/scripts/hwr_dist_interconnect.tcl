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

AIT::board::create_inStream_Inter_tree Hardware_Runtime/hwr_inStream/inS_common_Inter $num_common_hwruntime_intf ${::AIT::num_accs} $pi_clk $pi_inter_rstn $pi_peri_rstn
set max_level_common [AIT::board::create_outStream_Inter_tree Hardware_Runtime/hwr_outStream/outS_common_Inter $num_common_hwruntime_intf ${::AIT::num_accs} $po_clk $po_inter_rstn $po_peri_rstn]
if {${::AIT::advanced_hwruntime}} {
    # spawn + taskwait
    AIT::board::create_inStream_Inter_tree Hardware_Runtime/hwr_inStream/inS_ext_Inter 2 ${::AIT::num_acc_creators} $pi_clk $pi_inter_rstn $pi_peri_rstn
    set max_level_ext [AIT::board::create_outStream_Inter_tree Hardware_Runtime/hwr_outStream/outS_ext_Inter 2 ${::AIT::num_acc_creators} $po_clk $po_inter_rstn $po_peri_rstn]
}

set ninter [expr {int(ceil(${::AIT::num_accs}/16.))}]
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

if {${::AIT::advanced_hwruntime}} {
    set ninter [expr {int(ceil(${::AIT::num_acc_creators}/16.))}]
    for {set i 0} {$i < $ninter} {incr i} {
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000002} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000002} \
            CONFIG.M01_AXIS_BASETDEST {0x00000003} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
         ] [get_bd_cells Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_$i]
    }
}

for {set i 0} {$i < ${::AIT::num_accs}} {incr i} {
    set inter_i [expr {int($i/16)}]
    set intf_i [format %02u [expr {$i%16}]]

    if {$i < ${::AIT::num_acc_creators}} {
        set inter_name Hardware_Runtime/hwr_outStream/outS_extacc_Inter_${i}
        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
        set_property -dict [list \
            CONFIG.ARB_ON_MAX_XFERS {0} \
            CONFIG.ARB_ON_TLAST {1} \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
            CONFIG.NUM_MI {1} \
            CONFIG.NUM_SI {2} \
         ] $inter
        connect_bd_net $po_clk [get_bd_pins $inter/ACLK] [get_bd_pins $inter/S00_AXIS_ACLK] [get_bd_pins $inter/S01_AXIS_ACLK] [get_bd_pins $inter/M00_AXIS_ACLK]
        connect_bd_net $po_inter_rstn [get_bd_pins $inter/ARESETN]
        connect_bd_net $po_peri_rstn [get_bd_pins $inter/S00_AXIS_ARESETN] [get_bd_pins $inter/S01_AXIS_ARESETN] [get_bd_pins $inter/M00_AXIS_ARESETN]

        set inter_name Hardware_Runtime/hwr_inStream/inS_extacc_Inter_${i}
        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
        set_property -dict [list \
            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
            CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
            CONFIG.M01_AXIS_BASETDEST {0x00000002} \
            CONFIG.M01_AXIS_HIGHTDEST {0x00000003} \
            CONFIG.NUM_MI {2} \
            CONFIG.NUM_SI {1} \
         ] $inter
        connect_bd_net $pi_clk [get_bd_pins $inter/ACLK] [get_bd_pins $inter/M00_AXIS_ACLK] [get_bd_pins $inter/M01_AXIS_ACLK] [get_bd_pins $inter/S00_AXIS_ACLK]
        connect_bd_net $pi_inter_rstn [get_bd_pins $inter/ARESETN]
        connect_bd_net $pi_peri_rstn [get_bd_pins $inter/M00_AXIS_ARESETN] [get_bd_pins $inter/M01_AXIS_ARESETN] [get_bd_pins $inter/S00_AXIS_ARESETN]

        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_extacc_Inter_${i}/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_extacc_Inter_${i}/M01_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_extacc_Inter_${i}/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_${inter_i}/M${intf_i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_extacc_Inter_${i}/S01_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_extacc_Inter_${i}/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_extacc_Inter_${i}/M00_AXIS]
    } else {
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/S${i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_${inter_i}/S${intf_i}_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/M${i}_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_${inter_i}/M${intf_i}_AXIS]
    }
}

if {${::AIT::advanced_hwruntime}} {
    if {$max_level_ext == 0} {
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/spawn_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl0_0/M01_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/taskwait_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/spawn_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/taskwait_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl0_0/S01_AXIS]
    } else {
        set max_level $max_level_ext
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl${max_level}_m0_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/spawn_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_inStream/inS_ext_Inter_lvl${max_level}_m1_0/M00_AXIS] [get_bd_intf_pins Hardware_Runtime/hwr_inStream/taskwait_in]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/spawn_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl${max_level}_s0_0/S00_AXIS]
        connect_bd_intf_net [get_bd_intf_pins Hardware_Runtime/hwr_outStream/taskwait_out] [get_bd_intf_pins Hardware_Runtime/hwr_outStream/outS_ext_Inter_lvl${max_level}_s1_0/S00_AXIS]
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

if {${::AIT::interconRegSlice_hwruntime} || ${::AIT::interconRegSlice_all}} {
    set inStream_interconnects [get_bd_cells Hardware_Runtime/hwr_inStream/inS_common_Inter_lvl0_*]
    set outStream_interconnects [get_bd_cells Hardware_Runtime/hwr_outStream/outS_common_Inter_lvl0_*]
    if {${::AIT::advanced_hwruntime}} {
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

