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
        variable ompif_clk clock_generator/clk_200
        variable ompif_rstn system_reset/clk_200_managed_rstn

        proc static_logic_register_slices {} {
            # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
            # num_pipelines format: master:middle:slave
            # Pass unused optional arguments as ""

            # DDR 0
            AIT::AXI::add_reg_slice DDR_0 S_AXI ${::AIT::board_memory_slr} 0 "" "" static_
            AIT::AXI::add_reg_slice DDR_0 S_AXI_CTRL ${::AIT::board_memory_slr} 0 "" "" static_

            # DDR 1
            AIT::AXI::add_reg_slice DDR_1 S_AXI ${::AIT::board_memory_slr} 1 "" "" static_
            AIT::AXI::add_reg_slice DDR_1 S_AXI_CTRL ${::AIT::board_memory_slr} 1 "" "" static_

            # DDR 2
            AIT::AXI::add_reg_slice DDR_2 S_AXI ${::AIT::board_memory_slr} 1 "" "" static_
            AIT::AXI::add_reg_slice DDR_2 S_AXI_CTRL ${::AIT::board_memory_slr} 1 "" "" static_

            # DDR 3
            AIT::AXI::add_reg_slice DDR_3 S_AXI ${::AIT::board_memory_slr} 2 "" "" static_
            AIT::AXI::add_reg_slice DDR_3 S_AXI_CTRL ${::AIT::board_memory_slr} 2 "" "" static_

            # Hardware Runtime
            AIT::AXI::add_reg_slice Hardware_Runtime S_AXI_GP ${::AIT::board_hwruntime_slr} 1 "" "" static_

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

        proc add_ethernet_subsystem {} {
            if {[catch {source -notrace tcl/templates/eth_subsys.tcl}]} {
                AIT::utils::error_msg "Failed sourcing ethernet subsystem template"
            }
            set_property -dict [list CONFIG.DIFFCLK_BOARD_INTERFACE qsfp1_156mhz CONFIG.ETHERNET_BOARD_INTERFACE qsfp1_4x CONFIG.RX_FLOW_CONTROL 0 CONFIG.TX_FLOW_CONTROL 0 CONFIG.USER_INTERFACE AXIS CONFIG.GT_DRP_CLK 50] [get_bd_cells eth100gb]
            set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_ports QSFP_CLK]
            validate_bd_design
            save_bd_design
            current_bd_design ${::AIT::name_Project}_design
            create_bd_cell -type container -reference ethernet_subsystem ethernet_subsystem

            create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 QSFP_CLK
            set_property CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_intf_pins ethernet_subsystem/QSFP_CLK]] [get_bd_intf_ports QSFP_CLK]
            create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 QSFP_X4

            connect_bd_intf_net -boundary_type upper [get_bd_intf_ports QSFP_CLK] [get_bd_intf_pins ethernet_subsystem/QSFP_CLK]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_ports QSFP_X4] [get_bd_intf_pins ethernet_subsystem/QSFP_X4]

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
            ] [get_bd_cells clock_generator]

            create_bd_pin -dir I -type rst system_reset/jtag_rstn
            create_bd_pin -dir O -type rst system_reset/eth_subsys_rst
            create_bd_pin -dir O -type rst system_reset/eth_cntrl_rst
            create_bd_pin -dir O -type rst system_reset/clk_50_rstn
            create_bd_pin -dir O -type rst system_reset/clk_100_rstn
            create_bd_pin -dir O -type rst system_reset/clk_200_rstn
            create_bd_pin -dir O -type rst system_reset/clk_200_managed_rstn
            create_bd_pin -dir I -type clk system_reset/clk_50
            create_bd_pin -dir I -type clk system_reset/clk_100
            create_bd_pin -dir I -type clk system_reset/clk_200

            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_50
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_50]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_100
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_100]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_200
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_200]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_200_managed
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_200_managed]

            connect_bd_net [get_bd_pins system_reset/managed_reset] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/ext_reset_in]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/peripheral_aresetn] [get_bd_pins system_reset/clk_200_managed_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/slowest_sync_clk] [get_bd_pins system_reset/clk_200] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/slowest_sync_clk]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_50/slowest_sync_clk] [get_bd_pins system_reset/clk_50]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_100/slowest_sync_clk] [get_bd_pins system_reset/clk_100]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_50/peripheral_aresetn] [get_bd_pins system_reset/clk_50_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_100/peripheral_aresetn] [get_bd_pins system_reset/clk_100_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/peripheral_aresetn] [get_bd_pins system_reset/clk_200_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_50/ext_reset_in] [get_bd_pins system_reset/proc_sys_reset_clk_100/ext_reset_in] [get_bd_pins system_reset/proc_sys_reset_clk_200/ext_reset_in] [get_bd_pins system_reset/pcie_perstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_50/dcm_locked] [get_bd_pins system_reset/proc_sys_reset_clk_100/dcm_locked] [get_bd_pins system_reset/proc_sys_reset_clk_200/dcm_locked] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/dcm_locked] [get_bd_pins system_reset/clk_gen_locked]

            connect_bd_net [get_bd_pins clock_generator/clk_50] [get_bd_pins system_reset/clk_50]
            connect_bd_net [get_bd_pins clock_generator/clk_100] [get_bd_pins system_reset/clk_100]
            connect_bd_net [get_bd_pins clock_generator/clk_200] [get_bd_pins system_reset/clk_200]

            create_bd_cell -type ip -vlnv bsc:ompif:packet_decoder_wrapper meep_packet_decoder
            set_property -dict [list CONFIG.DATA_WIDTH 512 CONFIG.MAX_CLUSTER_SIZE 96] [get_bd_cells meep_packet_decoder]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch axis_inter_eth_tx
            set_property CONFIG.HAS_TLAST.VALUE_SRC USER [get_bd_cells axis_inter_eth_tx]
            set_property -dict [list CONFIG.HAS_TLAST 1 CONFIG.ARB_ON_MAX_XFERS 0 CONFIG.ARB_ON_TLAST 1 CONFIG.M00_AXIS_HIGHTDEST 0xFFFFFFFF] [get_bd_cells axis_inter_eth_tx]
            create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0
            set_property CONFIG.PROTOCOL 2 [get_bd_cells jtag_axi_0]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio jtag_gpio
            set_property -dict [list CONFIG.C_GPIO_WIDTH 2 CONFIG.C_GPIO2_WIDTH 16 CONFIG.C_IS_DUAL 1 CONFIG.C_DOUT_DEFAULT 0x00000002 CONFIG.C_ALL_OUTPUTS 1 CONFIG.C_ALL_OUTPUTS_2 1] [get_bd_cells jtag_gpio]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_eth_subsys
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_eth_subsys]
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice cluster_size_slice
            set_property -dict [list CONFIG.DIN_FROM 7 CONFIG.DIN_WIDTH 16 CONFIG.DOUT_WIDTH 8] [get_bd_cells cluster_size_slice]
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice cluster_rank_slice
            set_property -dict [list CONFIG.DIN_FROM 15 CONFIG.DIN_TO 8 CONFIG.DIN_WIDTH 16 CONFIG.DOUT_WIDTH 8] [get_bd_cells cluster_rank_slice]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar jtag_axi_xbar
            set_property -dict [list CONFIG.NUM_SI 2 CONFIG.STRATEGY 1] [get_bd_cells jtag_axi_xbar]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch axis_sw_dec
            set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI 2 CONFIG.DECODER_REG 1] [get_bd_cells axis_sw_dec]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice axis_rs_dec

            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice system_reset/slice_eth_subsys
            set_property -dict [list CONFIG.DIN_WIDTH 2 CONFIG.DIN_FROM 0 CONFIG.DIN_TO 0 CONFIG.DOUT_WIDTH 1] [get_bd_cells system_reset/slice_eth_subsys]
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice system_reset/slice_eth_cntrl
            set_property -dict [list CONFIG.DIN_WIDTH 2 CONFIG.DIN_FROM 1 CONFIG.DIN_TO 1 CONFIG.DOUT_WIDTH 1] [get_bd_cells system_reset/slice_eth_cntrl]

            connect_bd_net [get_bd_pins system_reset/jtag_rstn] [get_bd_pins system_reset/slice_eth_cntrl/Din]
            connect_bd_net [get_bd_pins system_reset/slice_eth_cntrl/Dout] [get_bd_pins system_reset/eth_cntrl_rst]
            connect_bd_net [get_bd_pins clock_generator/clk_100] [get_bd_pins ethernet_subsystem/clk_100]
            connect_bd_net [get_bd_pins system_reset/clk_100_rstn] [get_bd_pins ethernet_subsystem/clk_100_rstn]
            connect_bd_net [get_bd_pins system_reset/clk_200_rstn] [get_bd_pins axis_rs_dec/aresetn] [get_bd_pins ethernet_subsystem/clk_200_rstn] [get_bd_pins axis_inter_eth_tx/aresetn] [get_bd_pins axis_sw_dec/aresetn]
            connect_bd_net [get_bd_pins system_reset/jtag_rstn] [get_bd_pins system_reset/slice_eth_subsys/Din]
            connect_bd_net [get_bd_pins system_reset/slice_eth_subsys/Dout] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/ext_reset_in]
            connect_bd_net [get_bd_pins system_reset/clk_50] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/slowest_sync_clk] [get_bd_pins ethernet_subsystem/init_clk]
            connect_bd_net [get_bd_pins system_reset/eth_subsys_rst] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/peripheral_reset]
            connect_bd_net [get_bd_pins system_reset/clk_gen_locked] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/dcm_locked]
            connect_bd_net [get_bd_pins jtag_gpio/gpio_io_o] [get_bd_pins system_reset/jtag_rstn]
            connect_bd_net [get_bd_pins axis_rs_dec/aclk] [get_bd_pins meep_packet_decoder/clk] [get_bd_pins clock_generator/clk_200] [get_bd_pins axis_inter_eth_tx/aclk] [get_bd_pins ethernet_subsystem/clk_200] [get_bd_pins axis_sw_dec/aclk]
            connect_bd_net [get_bd_pins meep_packet_decoder/rstn] [get_bd_pins system_reset/clk_200_managed_rstn]
            connect_bd_net [get_bd_pins jtag_axi_0/aclk] [get_bd_pins clock_generator/clk_100] [get_bd_pins jtag_axi_xbar/aclk] [get_bd_pins jtag_gpio/s_axi_aclk]
            connect_bd_net [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins system_reset/clk_100_rstn] [get_bd_pins jtag_axi_xbar/aresetn] [get_bd_pins jtag_gpio/s_axi_aresetn]
            connect_bd_net [get_bd_pins jtag_gpio/gpio2_io_o] [get_bd_pins cluster_size_slice/Din] [get_bd_pins cluster_rank_slice/Din]
            connect_bd_net [get_bd_pins ethernet_subsystem/eth_subsys_rst] [get_bd_pins system_reset/eth_subsys_rst]
            connect_bd_net [get_bd_pins system_reset/eth_cntrl_rst] [get_bd_pins ethernet_subsystem/eth_cntrl_rst]

            connect_bd_intf_net [get_bd_intf_pins meep_packet_decoder/si] -boundary_type upper [get_bd_intf_pins ethernet_subsystem/msg_rx]
            connect_bd_intf_net [get_bd_intf_pins meep_packet_decoder/soEnc] -boundary_type upper [get_bd_intf_pins axis_inter_eth_tx/S00_AXIS]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axis_inter_eth_tx/M00_AXIS] [get_bd_intf_pins ethernet_subsystem/S_AXIS]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins jtag_axi_0/M_AXI] [get_bd_intf_pins jtag_axi_xbar/S00_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ethernet_subsystem/S_AXI] [get_bd_intf_pins jtag_axi_xbar/M01_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins jtag_gpio/S_AXI] [get_bd_intf_pins jtag_axi_xbar/M00_AXI]
            connect_bd_intf_net [get_bd_intf_pins meep_packet_decoder/soRole] [get_bd_intf_pins axis_sw_dec/S00_AXIS]
            connect_bd_intf_net [get_bd_intf_pins axis_rs_dec/S_AXIS] [get_bd_intf_pins axis_sw_dec/M00_AXIS]

            connect_to_axi_intf [get_bd_intf_pins jtag_axi_xbar/S01_AXI] M "" [get_bd_pins clock_generator/clk_100] [get_bd_pins system_reset/clk_100_rstn]
        }
    }
}
