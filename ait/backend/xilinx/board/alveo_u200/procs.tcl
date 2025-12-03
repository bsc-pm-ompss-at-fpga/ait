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
            ## DDR 0
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            ## DDR 1
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            ## DDR 2
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_2] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_2] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            ## DDR 3
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 2 "" "" bridge_to_host/memory/DDR_3] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 2 "" "" bridge_to_host/memory/DDR_3] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            ## Hardware Runtime
            lassign [AIT::AXI::add_reg_slice S_AXI_GP [dict get ${AIT::vars::board} "arch" "slr" "hwruntime"] 1 "" "" Hardware_Runtime] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            save_bd_design -quiet

            return ${constrStr}
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
            AIT::design::connect_clock [get_bd_pins power_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clock_generator/power_monitor_clk]
            AIT::design::connect_reset [get_bd_pins power_monitor_sys_rst/ext_reset_in] [get_bd_pins system_reset/ext_reset_in]

            # Add and connect external ports
            set satellite_uart [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 satellite_uart]
            set satellite_gpio [create_bd_port -dir I -from 3 -to 0 -type intr satellite_gpio]
            set_property CONFIG.SENSITIVITY {EDGE_RISING} $satellite_gpio
            connect_bd_intf_net $satellite_uart [get_bd_intf_pins cms_subsystem/satellite_uart]
            connect_bd_net $satellite_gpio [get_bd_pins cms_subsystem/satellite_gpio]
            for {set i 0} {$i < 2} {incr i} {
                # Output ports
                set qsfp_lpmode [create_bd_port -dir O -from 0 -to 0 qsfp${i}_lpmode]
                set qsfp_modsel_l [create_bd_port -dir O -from 0 -to 0 qsfp${i}_modsel_l]
                set qsfp_reset_l [create_bd_port -dir O -from 0 -to 0 qsfp${i}_reset_l]
                connect_bd_net [get_bd_pins cms_subsystem/qsfp${i}_lpmode] $qsfp_lpmode
                connect_bd_net [get_bd_pins cms_subsystem/qsfp${i}_modsel_l] $qsfp_modsel_l
                connect_bd_net [get_bd_pins cms_subsystem/qsfp${i}_reset_l] $qsfp_reset_l

                # Input ports
                set qsfp_int_l [create_bd_port -dir I -from 0 -to 0 qsfp${i}_int_l]
                set qsfp_modprs_l [create_bd_port -dir I -from 0 -to 0 qsfp${i}_modprs_l]
                connect_bd_net $qsfp_int_l [get_bd_pins cms_subsystem/qsfp${i}_int_l]
                connect_bd_net $qsfp_modprs_l [get_bd_pins cms_subsystem/qsfp${i}_modprs_l]
            }

            # Connect CMS to the M_AXI interconnect
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins cms_subsystem/s_axi_ctrl] "" [get_bd_pins clock_generator/power_monitor_clk] [get_bd_pins power_monitor_sys_rst/peripheral_aresetn]
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
            AIT::design::connect_clock [get_bd_pins thermal_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clock_generator/thermal_monitor_clk]
            AIT::design::connect_reset [get_bd_pins thermal_monitor_sys_rst/ext_reset_in] [get_bd_pins system_reset/ext_reset_in]

            # Connect System Management to the M_AXI interconnect
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins system_management/S_AXI_LITE] "" [get_bd_pins clock_generator/thermal_monitor_clk] [get_bd_pins thermal_monitor_sys_rst/peripheral_aresetn]
        }

        proc configure_ethernet_subsystem {} {
            set_property -dict [list \
                CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_156mhz} \
                CONFIG.ETHERNET_BOARD_INTERFACE {qsfp1_4x} \
                CONFIG.RX_FLOW_CONTROL {0} \
                CONFIG.TX_FLOW_CONTROL {0} \
                CONFIG.USER_INTERFACE {AXIS} \
                CONFIG.GT_DRP_CLK {50} \
            ] [get_bd_cells eth100gb]
            set_property CONFIG.FREQ_HZ {156250000} [get_bd_intf_ports QSFP_CLK]
        }

        proc instantiate_ethernet_subsystem {} {
            set ethSubsysIP [create_bd_cell -type container -reference ethernet_subsystem ethernet_subsystem]

            set qsfpClkPort [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 QSFP_CLK]
            set_property CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_intf_pins ${ethSubsysIP}/QSFP_CLK]] ${qsfpClkPort}
            create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 QSFP_X4

            connect_bd_intf_net -boundary_type upper ${qsfpClkPort} [get_bd_intf_pins ${ethSubsysIP}/QSFP_CLK]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_ports QSFP_X4] [get_bd_intf_pins ${ethSubsysIP}/QSFP_X4]

            set clkGenIP [get_bd_cells clock_generator]
            set_property -dict [list \
                CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 50 \
                CONFIG.CLKOUT2_USED true \
                CONFIG.CLK_OUT2_PORT clk_50 \
                CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 100 \
                CONFIG.CLKOUT3_USED true \
                CONFIG.CLK_OUT3_PORT clk_100 \
                CONFIG.CLKOUT4_REQUESTED_OUT_FREQ 200 \
                CONFIG.CLKOUT4_USED true \
                CONFIG.CLK_OUT4_PORT clk_200 \
                CONFIG.NUM_OUT_CLKS 4 \
            ] ${clkGenIP}

            set sysRstHier [get_bd_cells system_reset]

            create_bd_pin -dir I -type rst ${sysRstHier}/jtag_rstn
            create_bd_pin -dir O -type rst ${sysRstHier}/eth_subsys_rst
            create_bd_pin -dir O -type rst ${sysRstHier}/eth_cntrl_rst
            create_bd_pin -dir O -type rst ${sysRstHier}/clk_50_rstn
            create_bd_pin -dir O -type rst ${sysRstHier}/clk_100_rstn
            create_bd_pin -dir O -type rst ${sysRstHier}/clk_200_rstn
            create_bd_pin -dir O -type rst ${sysRstHier}/clk_200_managed_rstn
            create_bd_pin -dir I -type clk ${sysRstHier}/clk_50
            create_bd_pin -dir I -type clk ${sysRstHier}/clk_100
            create_bd_pin -dir I -type clk ${sysRstHier}/clk_200

            set clk50RstIP [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset ${sysRstHier}/proc_sys_reset_clk_50]
            set_property CONFIG.C_EXT_RST_WIDTH {1} ${clk50RstIP}
            set clk100RstIP [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset ${sysRstHier}/proc_sys_reset_clk_100]
            set_property CONFIG.C_EXT_RST_WIDTH {1} ${clk100RstIP}
            set clk200RstIP [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset ${sysRstHier}/proc_sys_reset_clk_200]
            set_property CONFIG.C_EXT_RST_WIDTH {1} ${clk200RstIP}
            set clk200ManagedRstIP [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset ${sysRstHier}/proc_sys_reset_clk_200_managed]
            set_property CONFIG.C_EXT_RST_WIDTH {1} ${clk200ManagedRstIP}

            connect_bd_net [get_bd_pins ${sysRstHier}/managed_reset] [get_bd_pins ${clk200ManagedRstIP}/ext_reset_in]
            connect_bd_net [get_bd_pins ${clk200ManagedRstIP}/peripheral_aresetn] [get_bd_pins ${sysRstHier}/clk_200_managed_rstn]
            connect_bd_net [get_bd_pins ${clk200RstIP}/slowest_sync_clk] [get_bd_pins ${sysRstHier}/clk_200] [get_bd_pins ${clk200ManagedRstIP}/slowest_sync_clk]
            connect_bd_net [get_bd_pins ${clk50RstIP}/slowest_sync_clk] [get_bd_pins ${sysRstHier}/clk_50]
            connect_bd_net [get_bd_pins ${clk100RstIP}/slowest_sync_clk] [get_bd_pins ${sysRstHier}/clk_100]
            connect_bd_net [get_bd_pins ${clk50RstIP}/peripheral_aresetn] [get_bd_pins ${sysRstHier}/clk_50_rstn]
            connect_bd_net [get_bd_pins ${clk100RstIP}/peripheral_aresetn] [get_bd_pins ${sysRstHier}/clk_100_rstn]
            connect_bd_net [get_bd_pins ${clk200RstIP}/peripheral_aresetn] [get_bd_pins ${sysRstHier}/clk_200_rstn]
            connect_bd_net [get_bd_pins ${clk50RstIP}/ext_reset_in] [get_bd_pins ${clk100RstIP}/ext_reset_in] [get_bd_pins ${clk200RstIP}/ext_reset_in] [get_bd_pins ${sysRstHier}/pcie_perstn]
            connect_bd_net [get_bd_pins ${clk50RstIP}/dcm_locked] [get_bd_pins ${clk100RstIP}/dcm_locked] [get_bd_pins ${clk200RstIP}/dcm_locked] [get_bd_pins ${clk200ManagedRstIP}/dcm_locked] [get_bd_pins ${sysRstHier}/clk_gen_locked]

            connect_bd_net [get_bd_pins ${clkGenIP}/clk_50] [get_bd_pins ${sysRstHier}/clk_50]
            connect_bd_net [get_bd_pins ${clkGenIP}/clk_100] [get_bd_pins ${sysRstHier}/clk_100]
            connect_bd_net [get_bd_pins ${clkGenIP}/clk_200] [get_bd_pins ${sysRstHier}/clk_200]

            create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0
            set_property CONFIG.PROTOCOL 2 [get_bd_cells jtag_axi_0]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio jtag_gpio
            set_property -dict [list CONFIG.C_GPIO_WIDTH 2 CONFIG.C_GPIO2_WIDTH 16 CONFIG.C_IS_DUAL 1 CONFIG.C_DOUT_DEFAULT 0x00000002 CONFIG.C_ALL_OUTPUTS 1 CONFIG.C_ALL_OUTPUTS_2 1] [get_bd_cells jtag_gpio]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset ${sysRstHier}/proc_sys_reset_eth_subsys
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells ${sysRstHier}/proc_sys_reset_eth_subsys]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar jtag_axi_xbar
            set_property -dict [list CONFIG.NUM_SI 2 CONFIG.STRATEGY 1] [get_bd_cells jtag_axi_xbar]

            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice ${sysRstHier}/slice_eth_subsys
            set_property -dict [list CONFIG.DIN_WIDTH 2 CONFIG.DIN_FROM 0 CONFIG.DIN_TO 0 CONFIG.DOUT_WIDTH 1] [get_bd_cells ${sysRstHier}/slice_eth_subsys]
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice ${sysRstHier}/slice_eth_cntrl
            set_property -dict [list CONFIG.DIN_WIDTH 2 CONFIG.DIN_FROM 1 CONFIG.DIN_TO 1 CONFIG.DOUT_WIDTH 1] [get_bd_cells ${sysRstHier}/slice_eth_cntrl]

            connect_bd_net [get_bd_pins ${sysRstHier}/jtag_rstn] [get_bd_pins ${sysRstHier}/slice_eth_cntrl/Din]
            connect_bd_net [get_bd_pins ${sysRstHier}/slice_eth_cntrl/Dout] [get_bd_pins ${sysRstHier}/eth_cntrl_rst]
            connect_bd_net [get_bd_pins ${clkGenIP}/clk_100] [get_bd_pins ${ethSubsysIP}/clk_100]
            connect_bd_net [get_bd_pins ${sysRstHier}/clk_100_rstn] [get_bd_pins ${ethSubsysIP}/clk_100_rstn]
            connect_bd_net [get_bd_pins ${sysRstHier}/clk_200_rstn] [get_bd_pins ${ethSubsysIP}/clk_200_rstn]
            connect_bd_net [get_bd_pins ${sysRstHier}/jtag_rstn] [get_bd_pins ${sysRstHier}/slice_eth_subsys/Din]
            connect_bd_net [get_bd_pins ${sysRstHier}/slice_eth_subsys/Dout] [get_bd_pins ${sysRstHier}/proc_sys_reset_eth_subsys/ext_reset_in]
            connect_bd_net [get_bd_pins ${sysRstHier}/clk_50] [get_bd_pins ${sysRstHier}/proc_sys_reset_eth_subsys/slowest_sync_clk] [get_bd_pins ${ethSubsysIP}/init_clk]
            connect_bd_net [get_bd_pins ${sysRstHier}/eth_subsys_rst] [get_bd_pins ${sysRstHier}/proc_sys_reset_eth_subsys/peripheral_reset]
            connect_bd_net [get_bd_pins ${sysRstHier}/clk_gen_locked] [get_bd_pins ${sysRstHier}/proc_sys_reset_eth_subsys/dcm_locked]
            connect_bd_net [get_bd_pins jtag_gpio/gpio_io_o] [get_bd_pins ${sysRstHier}/jtag_rstn]
            connect_bd_net [get_bd_pins ${clkGenIP}/clk_200] [get_bd_pins ${ethSubsysIP}/clk_200]
            connect_bd_net [get_bd_pins jtag_axi_0/aclk] [get_bd_pins ${clkGenIP}/clk_100] [get_bd_pins jtag_axi_xbar/aclk] [get_bd_pins jtag_gpio/s_axi_aclk]
            connect_bd_net [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins ${sysRstHier}/clk_100_rstn] [get_bd_pins jtag_axi_xbar/aresetn] [get_bd_pins jtag_gpio/s_axi_aresetn]
            connect_bd_net [get_bd_pins ${ethSubsysIP}/eth_subsys_rst] [get_bd_pins ${sysRstHier}/eth_subsys_rst]
            connect_bd_net [get_bd_pins ${sysRstHier}/eth_cntrl_rst] [get_bd_pins ${ethSubsysIP}/eth_cntrl_rst]

            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins jtag_axi_0/M_AXI] [get_bd_intf_pins jtag_axi_xbar/S00_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ${ethSubsysIP}/S_AXI] [get_bd_intf_pins jtag_axi_xbar/M01_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins jtag_gpio/S_AXI] [get_bd_intf_pins jtag_axi_xbar/M00_AXI]

            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins jtag_axi_xbar/S01_AXI] "" [get_bd_pins ${clkGenIP}/clk_100] [get_bd_pins ${sysRstHier}/clk_100_rstn]
        }
    }
}
