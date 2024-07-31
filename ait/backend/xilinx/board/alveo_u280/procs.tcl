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

namespace eval AIT {
    namespace eval board {
        proc static_logic_register_slices {} {
            # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
            # num_pipelines format: master:middle:slave
            # Pass unused optional arguments as ""

            # Hardware Runtime
            AIT::AXI::add_reg_slice Hardware_Runtime S_AXI_GP 0 ${::AIT::board_hwruntime_slr} "" "" static_

            # DDR 0
            AIT::AXI::add_reg_slice DDR_0 S_AXI ${::AIT::board_memory_slr} 0 "" "" static_
            AIT::AXI::add_reg_slice DDR_0 S_AXI_CTRL ${::AIT::board_memory_slr} 0 "" "" static_

            # DDR 1
            AIT::AXI::add_reg_slice DDR_1 S_AXI ${::AIT::board_memory_slr} 1 "" "" static_
            AIT::AXI::add_reg_slice DDR_1 S_AXI_CTRL ${::AIT::board_memory_slr} 1 "" "" static_

            save_bd_design
        }

        proc add_power_monitor {} {
            # Add CMS subsystem and its system reset
            create_bd_cell -type ip -vlnv xilinx.com:ip:cms_subsystem cms_subsystem
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset power_monitor_sys_rst

            # Add an additional 50MHz clock for the CMS subsystem
            set num_out_clocks [get_property CONFIG.NUM_OUT_CLKS [get_bd_cells clock_generator]]
            incr num_out_clocks
            set_property -dict [list \
              CONFIG.NUM_OUT_CLKS $num_out_clocks \
              CONFIG.CLKOUT${num_out_clocks}_USED {true} \
              CONFIG.CLKOUT${num_out_clocks}_REQUESTED_OUT_FREQ {50} \
              CONFIG.CLK_OUT${num_out_clocks}_PORT {power_monitor_clk}
            ] [get_bd_cells clock_generator]

            # Connect CMS clock and reset
            connect_clock [get_bd_pins power_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clock_generator/power_monitor_clk]
            connect_reset [get_bd_pins power_monitor_sys_rst/ext_reset_in] [get_bd_pins processor_system_reset/ext_reset_in]

            # Add and connect external ports
            set satellite_uart [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 satellite_uart]
            set satellite_gpio [create_bd_port -dir I -from 3 -to 0 -type intr satellite_gpio]
            set_property CONFIG.SENSITIVITY {EDGE_RISING} $satellite_gpio
            connect_bd_intf_net $satellite_uart [get_bd_intf_pins cms_subsystem/satellite_uart]
            connect_bd_net $satellite_gpio [get_bd_pins cms_subsystem/satellite_gpio]

            # Connect CMS to the M_AXI interconnect
            connect_to_axi_intf [get_bd_intf_pins cms_subsystem/s_axi_ctrl] M "" [get_bd_pins clock_generator/power_monitor_clk] [get_bd_pins power_monitor_sys_rst/peripheral_aresetn]
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
            connect_clock [get_bd_pins thermal_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clock_generator/thermal_monitor_clk]
            connect_reset [get_bd_pins thermal_monitor_sys_rst/ext_reset_in] [get_bd_pins processor_system_reset/ext_reset_in]

            # Connect System Management to the M_AXI interconnect
            connect_to_axi_intf [get_bd_intf_pins system_management/S_AXI_LITE] M "" [get_bd_pins clock_generator/thermal_monitor_clk] [get_bd_pins thermal_monitor_sys_rst/peripheral_aresetn]
        }
    }
}
