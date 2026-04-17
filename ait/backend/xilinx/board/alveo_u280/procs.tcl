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
    namespace eval board {
        proc static_logic_register_slices {} {
            # DDR 0
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            # DDR 1
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            # Hardware Runtime
            lassign [AIT::AXI::add_reg_slice S_AXI_GP 0 [dict get ${AIT::vars::board} "arch" "slr" "hwruntime"] "" "" Hardware_Runtime] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            save_bd_design -quiet
        }

        proc add_power_monitor {} {
            AIT::templates::source_template "power_monitor"
        }

        proc add_thermal_monitor {} {
            # Add System Management and its system reset
            create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz system_management
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset thermal_monitor_sys_rst

            # Add an additional 100MHz clock for System Management
            set num_out_clocks [get_property CONFIG.NUM_OUT_CLKS [get_bd_cells clock_generator]]
            incr num_out_clocks
            set_property -dict [list \
              CONFIG.NUM_OUT_CLKS $num_out_clocks \
              CONFIG.CLKOUT${num_out_clocks}_USED {true} \
              CONFIG.CLKOUT${num_out_clocks}_REQUESTED_OUT_FREQ {100} \
              CONFIG.CLK_OUT${num_out_clocks}_PORT {thermal_monitor_clk}
            ] [get_bd_cells clock_generator]

            # Connect System Management clock and reset
            AIT::clocks::connect_clock [get_bd_pins thermal_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clock_generator/thermal_monitor_clk]
            AIT::resets::connect_reset [get_bd_pins thermal_monitor_sys_rst/ext_reset_in] [get_bd_pins processor_system_reset/ext_reset_in]

            # Connect System Management to the M_AXI interconnect
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins system_management/S_AXI_LITE] "" [get_bd_pins clock_generator/thermal_monitor_clk] [get_bd_pins thermal_monitor_sys_rst/peripheral_aresetn]
        }
    }
}
