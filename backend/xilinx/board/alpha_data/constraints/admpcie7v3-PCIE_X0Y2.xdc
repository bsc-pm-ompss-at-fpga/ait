##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
## File       : vc709_pcie_x8_gen3-PCIE_X0Y1.xdc
## Version    : 2.0
#
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################

###############################################################################
# User Physical Constraints
###############################################################################

set_property PACKAGE_PIN W27 [get_ports perst_n]

set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

set_property PULLUP true [get_ports perst_n]

set_property PACKAGE_PIN F5 [get_ports pcie100_clk_n]

set_property PACKAGE_PIN AE29 [get_ports refclk200_clk_n]
set_property IOSTANDARD DIFF_HSTL_I [get_ports refclk200_clk_p]
set_property IOSTANDARD DIFF_HSTL_I [get_ports refclk200_clk_n]


set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]

###############################################################################
# End
###############################################################################


set_property IOSTANDARD LVCMOS18 [get_ports {model_inout[*]}]

#fl_sel_n
set_property PACKAGE_PIN AL33 [get_ports {model_inout[0]}]
#fl_oe_n
set_property PACKAGE_PIN AC25 [get_ports {model_inout[1]}]
#fl_we_n
set_property PACKAGE_PIN AD25 [get_ports {model_inout[2]}]
#fl_rst_n
set_property PACKAGE_PIN AJ34 [get_ports {model_inout[3]}]
#fl_adv_n
set_property PACKAGE_PIN AC29 [get_ports {model_inout[4]}]
#fl_wait_n
set_property PACKAGE_PIN AH34 [get_ports {model_inout[5]}]
#iic2_scl
set_property PACKAGE_PIN AB26 [get_ports {model_inout[6]}]
#iic2_sda
set_property PACKAGE_PIN AA26 [get_ports {model_inout[7]}]
#iic4_scl
set_property PACKAGE_PIN Y24 [get_ports {model_inout[8]}]
#iic4_sda
set_property PACKAGE_PIN AA25 [get_ports {model_inout[9]}]
#iic5_scl
set_property PACKAGE_PIN W25 [get_ports {model_inout[10]}]
#iic5_sda
set_property PACKAGE_PIN W24 [get_ports {model_inout[11]}]

#fl_a
set_property PACKAGE_PIN AP27 [get_ports {model_inout[12]}]
set_property PACKAGE_PIN AN27 [get_ports {model_inout[13]}]
set_property PACKAGE_PIN AP26 [get_ports {model_inout[14]}]
set_property PACKAGE_PIN AP25 [get_ports {model_inout[15]}]
set_property PACKAGE_PIN AN28 [get_ports {model_inout[16]}]
set_property PACKAGE_PIN AM28 [get_ports {model_inout[17]}]
set_property PACKAGE_PIN AN25 [get_ports {model_inout[18]}]
set_property PACKAGE_PIN AP29 [get_ports {model_inout[19]}]
set_property PACKAGE_PIN AN29 [get_ports {model_inout[20]}]
set_property PACKAGE_PIN AM27 [get_ports {model_inout[21]}]
set_property PACKAGE_PIN AM26 [get_ports {model_inout[22]}]
set_property PACKAGE_PIN AL26 [get_ports {model_inout[23]}]
set_property PACKAGE_PIN AL25 [get_ports {model_inout[24]}]
set_property PACKAGE_PIN AJ25 [get_ports {model_inout[25]}]
set_property PACKAGE_PIN AH24 [get_ports {model_inout[26]}]
set_property PACKAGE_PIN AH25 [get_ports {model_inout[27]}]
set_property PACKAGE_PIN AE24 [get_ports {model_inout[28]}]
set_property PACKAGE_PIN AE23 [get_ports {model_inout[29]}]
set_property PACKAGE_PIN AF26 [get_ports {model_inout[30]}]
set_property PACKAGE_PIN AG27 [get_ports {model_inout[31]}]
set_property PACKAGE_PIN AG26 [get_ports {model_inout[32]}]
set_property PACKAGE_PIN AD27 [get_ports {model_inout[33]}]
set_property PACKAGE_PIN AD26 [get_ports {model_inout[34]}]
set_property PACKAGE_PIN AH28 [get_ports {model_inout[35]}]
set_property PACKAGE_PIN AD24 [get_ports {model_inout[36]}]
set_property PACKAGE_PIN AC23 [get_ports {model_inout[37]}]
#fl_d
set_property PACKAGE_PIN AN33 [get_ports {model_inout[38]}]
set_property PACKAGE_PIN AN34 [get_ports {model_inout[39]}]
set_property PACKAGE_PIN AK34 [get_ports {model_inout[40]}]
set_property PACKAGE_PIN AL34 [get_ports {model_inout[41]}]
set_property PACKAGE_PIN AK32 [get_ports {model_inout[42]}]
set_property PACKAGE_PIN AK33 [get_ports {model_inout[43]}]
set_property PACKAGE_PIN AM32 [get_ports {model_inout[44]}]
set_property PACKAGE_PIN AN32 [get_ports {model_inout[45]}]
set_property PACKAGE_PIN AM33 [get_ports {model_inout[46]}]
set_property PACKAGE_PIN AP30 [get_ports {model_inout[47]}]
set_property PACKAGE_PIN AP31 [get_ports {model_inout[48]}]
set_property PACKAGE_PIN AJ30 [get_ports {model_inout[49]}]
set_property PACKAGE_PIN AK31 [get_ports {model_inout[50]}]
set_property PACKAGE_PIN AN30 [get_ports {model_inout[51]}]
set_property PACKAGE_PIN AJ29 [get_ports {model_inout[52]}]
set_property PACKAGE_PIN AK29 [get_ports {model_inout[53]}]

#cable_present
set_property PACKAGE_PIN Y32 [get_ports {model_inout[54]}]

#fl_a25_input_rs1
set_property PACKAGE_PIN AC24 [get_ports {model_inout[55]}]

set_power_opt -cell_types { none  }


set_property PACKAGE_PIN AJ15 [get_ports refclk400m0_n]
set_property PACKAGE_PIN G31 [get_ports refclk400m1_n]

set_property IOSTANDARD DIFF_HSTL_I [get_ports refclk400m?_?]
#set_property DIFF_TERM true [get_ports refclk400m?_?]
set_max_delay -from [get_ports refclk400m?_?] 100.000
create_clock -period 2.500 -name refclk400m0_p [get_ports refclk400m0_p]
create_clock -period 2.500 -name refclk400m1_p [get_ports refclk400m1_p]
#create_clock -period 5.000 -name ref_clk [get_ports refclk200_clk_p]

set_property PACKAGE_PIN AH10 [get_ports {c0_ddr3_dm[0]}]
set_property PACKAGE_PIN AF9 [get_ports {c0_ddr3_dm[1]}]
set_property PACKAGE_PIN AM13 [get_ports {c0_ddr3_dm[2]}]
set_property PACKAGE_PIN AL10 [get_ports {c0_ddr3_dm[3]}]
set_property PACKAGE_PIN AL20 [get_ports {c0_ddr3_dm[4]}]
set_property PACKAGE_PIN AJ24 [get_ports {c0_ddr3_dm[5]}]
set_property PACKAGE_PIN AD22 [get_ports {c0_ddr3_dm[6]}]
set_property PACKAGE_PIN AD15 [get_ports {c0_ddr3_dm[7]}]
set_property PACKAGE_PIN AM23 [get_ports {c0_ddr3_dm[8]}]

set_property VCCAUX_IO NORMAL [get_ports {c0_ddr3_dm[*]}]
set_property SLEW FAST [get_ports {c0_ddr3_dm[*]}]
set_property IOSTANDARD SSTL15 [get_ports {c0_ddr3_dm[*]}]


set_property PACKAGE_PIN B32 [get_ports {c1_ddr3_dm[0]}]
set_property PACKAGE_PIN A30 [get_ports {c1_ddr3_dm[1]}]
set_property PACKAGE_PIN E24 [get_ports {c1_ddr3_dm[2]}]
set_property PACKAGE_PIN B26 [get_ports {c1_ddr3_dm[3]}]
set_property PACKAGE_PIN U31 [get_ports {c1_ddr3_dm[4]}]
set_property PACKAGE_PIN R29 [get_ports {c1_ddr3_dm[5]}]
set_property PACKAGE_PIN K34 [get_ports {c1_ddr3_dm[6]}]
set_property PACKAGE_PIN N34 [get_ports {c1_ddr3_dm[7]}]
set_property PACKAGE_PIN P25 [get_ports {c1_ddr3_dm[8]}]

set_property VCCAUX_IO NORMAL [get_ports {c1_ddr3_dm[*]}]
set_property SLEW FAST [get_ports {c1_ddr3_dm[*]}]
set_property IOSTANDARD SSTL15 [get_ports {c1_ddr3_dm[*]}]

set_property IOSTANDARD LVCMOS18 [get_ports {usr_led[*]}]
set_property PACKAGE_PIN AC33 [get_ports {usr_led[0]}]
set_property PACKAGE_PIN V32 [get_ports {usr_led[1]}]
set_property PACKAGE_PIN V33 [get_ports {usr_led[2]}]
set_property PACKAGE_PIN AB31 [get_ports {usr_led[3]}]
set_property PACKAGE_PIN AB32 [get_ports {usr_led[4]}]
set_property PACKAGE_PIN U30 [get_ports {usr_led[5]}]


# DDR3 SDRAM
set_property PACKAGE_PIN AA24 [get_ports dram_0_on]
set_property IOSTANDARD LVCMOS18 [get_ports dram_0_on]

set_property PACKAGE_PIN AB25 [get_ports dram_1_on]
set_property IOSTANDARD LVCMOS18 [get_ports dram_1_on]



set_false_path -from [get_clocks I] -to [get_clocks userclk2]
set_false_path -from [get_clocks clk_out1_admpcie7v3_axi4_demo_clk_wiz_0_0] -to [get_clocks I]
set_false_path -from [get_clocks userclk2] -to [get_clocks I]

set_max_delay -from [get_clocks I] -to [get_clocks userclk2] 4.000
set_max_delay -from [get_clocks clk_out1_admpcie7v3_axi4_demo_clk_wiz_0_0] -to [get_clocks I] 5.000
set_max_delay -from [get_clocks userclk2] -to [get_clocks I] 4.000

set_false_path -from [get_clocks I] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks I] -to [get_clocks clk_pll_i]

set_false_path -from [get_pins -hier -filter {NAME =~*adb3_core_bridge_1/pcie_rst_held*/C}]
