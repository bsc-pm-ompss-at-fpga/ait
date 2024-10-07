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
        variable ompif_clk clk_gen_slr0/clk_200
        variable ompif_rstn system_reset/clk_200_managed_rstn

        proc static_logic_register_slices {} {
            # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
            # num_pipelines format: master:middle:slave
            # Pass unused optional arguments as ""

            # Hardware Runtime
            AIT::AXI::add_reg_slice Hardware_Runtime S_AXI_GP 0 ${::AIT::board_hwruntime_slr} "" "" static_

            if {${AIT::ompif}} {
                AIT::AXIS::add_reg_slice ompif_message_sender_0 S_AXIS 1 0 "" "" static_
                AIT::AXIS::add_reg_slice ompif_message_receiver_0 S_AXIS 1 0 "" "" static_
                AIT::AXIS::add_reg_slice ompif_message_sender_0 M_AXIS 0 1 "" "" static_
                AIT::AXIS::add_reg_slice ompif_message_receiver_0 M_AXIS 0 1 "" "" static_
            }
        }

        proc add_power_monitor {} {
            # Add CMS subsystem and its system reset
            create_bd_cell -type ip -vlnv xilinx.com:ip:cms_subsystem cms_subsystem

            # If ompif is not enabled, add 50MHz clock
            if {!$AIT::ompif} {
                set_property -dict [list \
                    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 50 \
                    CONFIG.CLKOUT2_USED true \
                    CONFIG.CLK_OUT2_PORT clk_50 \
                    CONFIG.NUM_OUT_CLKS 2 \
                ] [get_bd_cells clock_generator]
            }

            # Add 50Mhz reset
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_50
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_50]
            create_bd_pin -dir O -type reset system_reset/clk_50_rstn
            connect_bd_net [get_bd_pins system_reset/clk_50] [get_bd_pins system_reset/proc_sys_reset_clk_50/slowest_sync_clk]
            connect_bd_net [get_bd_pins system_reset/pcie_perstn] [get_bd_pins system_reset/proc_sys_reset_clk_50/ext_reset_in]
            connect_bd_net [get_bd_pins system_reset/clk_50_rstn] [get_bd_pins system_reset/proc_sys_reset_clk_50/peripheral_aresetn]
            connect_bd_net [get_bd_pins system_reset/clk_gen_locked] [get_bd_pins system_reset/proc_sys_reset_clk_50/dcm_locked]
            connect_bd_net [get_bd_pins clock_generator/clk_50] [get_bd_pins cms_subsystem/aclk_ctrl]
            connect_bd_net [get_bd_pins system_reset/clk_50_rstn] [get_bd_pins cms_subsystem/aresetn_ctrl]

            # Add and connect external ports
            set satellite_uart [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 satellite_uart]
            set satellite_gpio [create_bd_port -dir I -from 3 -to 0 -type intr satellite_gpio]
            set_property CONFIG.SENSITIVITY {EDGE_RISING} $satellite_gpio
            connect_bd_intf_net $satellite_uart [get_bd_intf_pins cms_subsystem/satellite_uart]
            connect_bd_net $satellite_gpio [get_bd_pins cms_subsystem/satellite_gpio]

            # Connect CMS to the M_AXI interconnect
            connect_to_axi_intf [get_bd_intf_pins cms_subsystem/s_axi_ctrl] M "" [get_bd_pins clock_generator/clk_50] [get_bd_pins system_reset/clk_50_rstn]

            connect_bd_net [get_bd_pins bridge_to_host/memory/HBM/DRAM_1_STAT_TEMP] [get_bd_pins cms_subsystem/hbm_temp_2]
            connect_bd_net [get_bd_pins bridge_to_host/memory/HBM/DRAM_0_STAT_TEMP] [get_bd_pins cms_subsystem/hbm_temp_1]
            connect_bd_net [get_bd_pins bridge_to_host/HBM_CATTRIP] [get_bd_pins cms_subsystem/interrupt_hbm_cattrip]
        }

        proc add_thermal_monitor {} {
            # Add System Management and its system reset
            create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz system_management
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset thermal_monitor_sys_rst

            # Connect System Management clock and reset
            connect_clock [get_bd_pins thermal_monitor_sys_rst/slowest_sync_clk] [get_bd_pins clk_gen_slr0/clk_100]
            connect_reset [get_bd_pins thermal_monitor_sys_rst/ext_reset_in] [get_bd_pins system_reset/clk_100_slr0_rstn]

            # Connect System Management to the M_AXI interconnect
            connect_to_axi_intf [get_bd_intf_pins system_management/S_AXI_LITE] M "" [get_bd_pins clock_generator/thermal_monitor_clk] [get_bd_pins thermal_monitor_sys_rst/peripheral_aresetn]
        }

        # Create a custom AXI interconnect from a 512-bit 200MHz clock to a 256-bit 400MHz clock
        # because Xilinx interconnects don't give good timing results
        proc add_custom_axi_interconnect {hier_name rw_mode} {
            create_bd_cell -type hier $hier_name
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice $hier_name/axi_register_slice_0
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter $hier_name/axi_clock_converter_0
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice $hier_name/axi_register_slice_1
            create_bd_cell -type ip -vlnv bsc:axiu:axiu_dwidth_downsizer_vwrapper $hier_name/axiu_dwidth_downsize_0
            set_property -dict [list CONFIG.AXI_ADDR_WIDTH 34 CONFIG.AXI_SLV_DATA_WIDTH 512 CONFIG.AXI_MST_DATA_WIDTH 256] [get_bd_cells $hier_name/axiu_dwidth_downsize_0]
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice $hier_name/axi_register_slice_2
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter $hier_name/axi_protocol_convert_0

            if {$rw_mode == "read"} {
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_clock_converter_0]
                set_property CONFIG.READ_WRITE_MODE READ_ONLY [get_bd_cells $hier_name/axi_clock_converter_0]
                set_property -dict [list CONFIG.READ 1 CONFIG.WRITE 0] [get_bd_cells $hier_name/axiu_dwidth_downsize_0]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_0]
                set_property -dict [list CONFIG.READ_WRITE_MODE READ_ONLY CONFIG.REG_AR 1] [get_bd_cells $hier_name/axi_register_slice_0]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_1]
                set_property -dict [list CONFIG.READ_WRITE_MODE READ_ONLY CONFIG.REG_AR 1] [get_bd_cells $hier_name/axi_register_slice_1]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_2]
                set_property -dict [list CONFIG.READ_WRITE_MODE READ_ONLY CONFIG.REG_AR 1] [get_bd_cells $hier_name/axi_register_slice_2]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_protocol_convert_0]
                set_property CONFIG.READ_WRITE_MODE READ_ONLY [get_bd_cells $hier_name/axi_protocol_convert_0]
            } elseif {$rw_mode == "write"} {
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_clock_converter_0]
                set_property CONFIG.READ_WRITE_MODE WRITE_ONLY [get_bd_cells $hier_name/axi_clock_converter_0]
                set_property -dict [list CONFIG.READ 0 CONFIG.WRITE 1] [get_bd_cells $hier_name/axiu_dwidth_downsize_0]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_0]
                set_property -dict [list CONFIG.READ_WRITE_MODE WRITE_ONLY CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_0]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_1]
                set_property -dict [list CONFIG.READ_WRITE_MODE WRITE_ONLY CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_1]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_register_slice_2]
                set_property -dict [list CONFIG.READ_WRITE_MODE WRITE_ONLY CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_2]
                set_property CONFIG.READ_WRITE_MODE.VALUE_SRC USER [get_bd_cells $hier_name/axi_protocol_convert_0]
                set_property CONFIG.READ_WRITE_MODE WRITE_ONLY [get_bd_cells $hier_name/axi_protocol_convert_0]
            } else {
                set_property -dict [list CONFIG.READ 1 CONFIG.WRITE 1] [get_bd_cells $hier_name/axiu_dwidth_downsize_0]
                set_property -dict [list CONFIG.REG_AR 1 CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_0]
                set_property -dict [list CONFIG.REG_AR 1 CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_1]
                set_property -dict [list CONFIG.REG_AR 1 CONFIG.REG_AW 1 CONFIG.REG_B 1] [get_bd_cells $hier_name/axi_register_slice_2]
            }

            connect_bd_intf_net [get_bd_intf_pins $hier_name/axi_register_slice_0/M_AXI] [get_bd_intf_pins $hier_name/axi_clock_converter_0/S_AXI]
            connect_bd_intf_net [get_bd_intf_pins $hier_name/axi_clock_converter_0/M_AXI] [get_bd_intf_pins $hier_name/axi_register_slice_1/S_AXI]
            connect_bd_intf_net [get_bd_intf_pins $hier_name/axi_register_slice_1/M_AXI] [get_bd_intf_pins $hier_name/axiu_dwidth_downsize_0/slv]
            connect_bd_intf_net [get_bd_intf_pins $hier_name/axiu_dwidth_downsize_0/mst] [get_bd_intf_pins $hier_name/axi_register_slice_2/S_AXI]
            connect_bd_intf_net [get_bd_intf_pins $hier_name/axi_register_slice_2/M_AXI] [get_bd_intf_pins $hier_name/axi_protocol_convert_0/S_AXI]

            connect_bd_net [get_bd_pins clk_gen_slr0/clk_200] [get_bd_pins $hier_name/axi_register_slice_0/aclk] [get_bd_pins $hier_name/axi_clock_converter_0/s_axi_aclk]
            connect_bd_net [get_bd_pins system_reset/clk_200_rstn] [get_bd_pins $hier_name/axi_register_slice_0/aresetn] [get_bd_pins $hier_name/axi_clock_converter_0/s_axi_aresetn]
            connect_bd_net [get_bd_pins clk_gen_slr0/clk_400] [get_bd_pins $hier_name/axi_clock_converter_0/m_axi_aclk] [get_bd_pins $hier_name/axi_register_slice_1/aclk] [get_bd_pins $hier_name/axiu_dwidth_downsize_0/clk] [get_bd_pins $hier_name/axi_register_slice_2/aclk] [get_bd_pins $hier_name/axi_protocol_convert_0/aclk]
            connect_bd_net [get_bd_pins system_reset/clk_400_rstn] [get_bd_pins $hier_name/axi_clock_converter_0/m_axi_aresetn] [get_bd_pins $hier_name/axi_register_slice_1/aresetn] [get_bd_pins $hier_name/axiu_dwidth_downsize_0/rstn] [get_bd_pins $hier_name/axi_register_slice_2/aresetn] [get_bd_pins $hier_name/axi_protocol_convert_0/aresetn]
        }

        proc add_ethernet_subsystem {} {
            if {[catch {source -notrace tcl/templates/eth_subsys.tcl}]} {
                AIT::utils::error_msg "Failed sourcing ethernet subsystem template"
            }
            # Set manually the constraints because u55c board files don't work
            set_property -dict [list CONFIG.CMAC_CORE_SELECT CMACE4_X0Y3 CONFIG.GT_GROUP_SELECT X0Y24~X0Y27 CONFIG.GT_REF_CLK_FREQ 161.1328125 CONFIG.GT_DRP_CLK 50] [get_bd_cells eth100gb]
            set_property CONFIG.FREQ_HZ 161132812 [get_bd_intf_ports QSFP_CLK]
            validate_bd_design
            save_bd_design
            current_bd_design ${::AIT::name_Project}_design
            create_bd_cell -type container -reference ethernet_subsystem ethernet_subsystem

            create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 QSFP0_CLK
            set_property CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_intf_pins ethernet_subsystem/QSFP_CLK]] [get_bd_intf_ports QSFP0_CLK]
            create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 QSFP0_X4

            connect_bd_intf_net -boundary_type upper [get_bd_intf_ports QSFP0_CLK] [get_bd_intf_pins ethernet_subsystem/QSFP_CLK]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_ports QSFP0_X4] [get_bd_intf_pins ethernet_subsystem/QSFP_X4]

            set_property -dict [list \
                CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 200 \
                CONFIG.CLKOUT2_USED true \
                CONFIG.CLK_OUT2_PORT clk_200 \
                CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 400 \
                CONFIG.CLKOUT3_USED true \
                CONFIG.CLK_OUT3_PORT clk_400 \
                CONFIG.NUM_OUT_CLKS 3 \
            ] [get_bd_cells clk_gen_slr0]

            set_property -dict [list \
                CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 50 \
                CONFIG.CLKOUT2_USED true \
                CONFIG.CLK_OUT2_PORT clk_50 \
                CONFIG.NUM_OUT_CLKS 2 \
            ] [get_bd_cells clock_generator]

            create_bd_pin -dir I -type rst system_reset/jtag_rstn
            create_bd_pin -dir O -type rst system_reset/eth_subsys_rst
            create_bd_pin -dir O -type rst system_reset/eth_cntrl_rst
            create_bd_pin -dir O -type rst system_reset/clk_200_rstn
            create_bd_pin -dir O -type rst system_reset/clk_200_managed_rstn
            create_bd_pin -dir O -type rst system_reset/clk_400_rstn
            create_bd_pin -dir I -type clk system_reset/clk_200
            create_bd_pin -dir I -type clk system_reset/clk_400
            create_bd_pin -dir I -type clk system_reset/clk_50

            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_200
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_200]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_200_managed
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_200_managed]
            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset system_reset/proc_sys_reset_clk_400
            set_property CONFIG.C_EXT_RST_WIDTH 1 [get_bd_cells system_reset/proc_sys_reset_clk_400]

            connect_bd_net [get_bd_pins system_reset/managed_reset] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/ext_reset_in]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/peripheral_aresetn] [get_bd_pins system_reset/clk_200_managed_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/slowest_sync_clk] [get_bd_pins system_reset/clk_200] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/slowest_sync_clk]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_400/slowest_sync_clk] [get_bd_pins system_reset/clk_400]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/peripheral_aresetn] [get_bd_pins system_reset/clk_200_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_400/peripheral_aresetn] [get_bd_pins system_reset/clk_400_rstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/ext_reset_in] [get_bd_pins system_reset/proc_sys_reset_clk_400/ext_reset_in] [get_bd_pins system_reset/pcie_perstn]
            connect_bd_net [get_bd_pins system_reset/proc_sys_reset_clk_200/dcm_locked] [get_bd_pins system_reset/proc_sys_reset_clk_200_managed/dcm_locked] [get_bd_pins system_reset/proc_sys_reset_clk_400/dcm_locked] [get_bd_pins system_reset/clk_gen_slr0_locked]

            connect_bd_net [get_bd_pins clk_gen_slr0/clk_200] [get_bd_pins system_reset/clk_200]
            connect_bd_net [get_bd_pins clk_gen_slr0/clk_400] [get_bd_pins system_reset/clk_400]
            connect_bd_net [get_bd_pins clock_generator/clk_50] [get_bd_pins system_reset/clk_50]

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
            connect_bd_net [get_bd_pins clk_gen_slr0/clk_100] [get_bd_pins ethernet_subsystem/clk_100]
            connect_bd_net [get_bd_pins system_reset/clk_100_slr0_rstn] [get_bd_pins ethernet_subsystem/clk_100_rstn]
            connect_bd_net [get_bd_pins system_reset/clk_200_rstn] [get_bd_pins axis_rs_dec/aresetn] [get_bd_pins ethernet_subsystem/clk_200_rstn] [get_bd_pins axis_inter_eth_tx/aresetn] [get_bd_pins axis_sw_dec/aresetn]
            connect_bd_net [get_bd_pins system_reset/jtag_rstn] [get_bd_pins system_reset/slice_eth_subsys/Din]
            connect_bd_net [get_bd_pins system_reset/slice_eth_subsys/Dout] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/ext_reset_in]
            connect_bd_net [get_bd_pins system_reset/clk_50] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/slowest_sync_clk] [get_bd_pins ethernet_subsystem/init_clk]
            connect_bd_net [get_bd_pins system_reset/eth_subsys_rst] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/peripheral_reset]
            connect_bd_net [get_bd_pins system_reset/clk_gen_slr0_locked] [get_bd_pins system_reset/proc_sys_reset_eth_subsys/dcm_locked]
            connect_bd_net [get_bd_pins jtag_gpio/gpio_io_o] [get_bd_pins system_reset/jtag_rstn]
            connect_bd_net [get_bd_pins axis_rs_dec/aclk] [get_bd_pins meep_packet_decoder/clk] [get_bd_pins clk_gen_slr0/clk_200] [get_bd_pins axis_inter_eth_tx/aclk] [get_bd_pins ethernet_subsystem/clk_200] [get_bd_pins axis_sw_dec/aclk]
            connect_bd_net [get_bd_pins meep_packet_decoder/rstn] [get_bd_pins system_reset/clk_200_managed_rstn]
            connect_bd_net [get_bd_pins jtag_axi_0/aclk] [get_bd_pins clk_gen_slr0/clk_100] [get_bd_pins jtag_axi_xbar/aclk] [get_bd_pins jtag_gpio/s_axi_aclk]
            connect_bd_net [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins system_reset/clk_100_slr0_rstn] [get_bd_pins jtag_axi_xbar/aresetn] [get_bd_pins jtag_gpio/s_axi_aresetn]
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

            connect_to_axi_intf [get_bd_intf_pins jtag_axi_xbar/S01_AXI] M "" [get_bd_pins clk_gen_slr0/clk_100] [get_bd_pins system_reset/clk_100_slr0_rstn]

            add_custom_axi_interconnect axi_inter_msg_send read
            add_custom_axi_interconnect axi_inter_msg_recv_bufwr write
            add_custom_axi_interconnect axi_inter_msg_recv_memcpy read_write

            create_bd_pin -dir I -type clk bridge_to_host/memory/clk_400
            create_bd_pin -dir I -type rst bridge_to_host/memory/clk_400_rstn

            connect_bd_net [get_bd_pins bridge_to_host/memory/clk_400] [get_bd_pins bridge_to_host/memory/HBM/AXI_14_ACLK] [get_bd_pins bridge_to_host/memory/HBM/AXI_30_ACLK] [get_bd_pins bridge_to_host/memory/HBM/AXI_31_ACLK]
            connect_bd_net [get_bd_pins bridge_to_host/memory/clk_400_rstn] [get_bd_pins bridge_to_host/memory/HBM/AXI_14_ARESET_N] [get_bd_pins bridge_to_host/memory/HBM/AXI_30_ARESET_N] [get_bd_pins bridge_to_host/memory/HBM/AXI_31_ARESET_N]

            create_bd_pin -dir I -type clk bridge_to_host/clk_400
            create_bd_pin -dir I -type rst bridge_to_host/clk_400_rstn

            connect_bd_net [get_bd_pins bridge_to_host/clk_400] [get_bd_pins bridge_to_host/memory/clk_400]
            connect_bd_net [get_bd_pins bridge_to_host/clk_400_rstn] [get_bd_pins bridge_to_host/memory/clk_400_rstn]
            connect_bd_net [get_bd_pins clk_gen_slr0/clk_400] [get_bd_pins bridge_to_host/clk_400]
            connect_bd_net [get_bd_pins system_reset/clk_400_rstn] [get_bd_pins bridge_to_host/clk_400_rstn]

            connect_bd_intf_net [get_bd_intf_pins axi_inter_msg_send/axi_protocol_convert_0/M_AXI] [get_bd_intf_pins bridge_to_host/memory/HBM/SAXI_14_8HI]
            connect_bd_intf_net [get_bd_intf_pins axi_inter_msg_recv_memcpy/axi_protocol_convert_0/M_AXI] [get_bd_intf_pins bridge_to_host/memory/HBM/SAXI_30_8HI]
            connect_bd_intf_net [get_bd_intf_pins axi_inter_msg_recv_bufwr/axi_protocol_convert_0/M_AXI] [get_bd_intf_pins bridge_to_host/memory/HBM/SAXI_31_8HI]
        }

        # This is done after acc instantiation because the HBM memory IP changes automatically the switch clock when connecting other AXI slaves
        proc after_acc_configuration {} {
            if {!$AIT::ompif} {
                return
            }
            # Set switch 0 to 400Mhz clock to avoid bandwidth loss
            set_property CONFIG.USER_CLK_SEL_LIST0 AXI_14_ACLK [get_bd_cells bridge_to_host/memory/HBM]
        }
    }
}
