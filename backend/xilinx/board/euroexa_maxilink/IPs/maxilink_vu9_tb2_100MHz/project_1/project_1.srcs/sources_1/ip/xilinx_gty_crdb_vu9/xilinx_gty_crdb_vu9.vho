-- (c) Copyright 1995-2022 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:gtwizard_ultrascale:1.7
-- IP Revision: 8

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT xilinx_gty_crdb_vu9
  PORT (
    gtwiz_userclk_tx_reset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_active_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_reset_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_userclk_rx_active_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtwiz_reset_clk_freerun_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_all_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(383 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(383 DOWNTO 0);
    drpaddr_common_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    drpclk_common_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    drpdi_common_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    drpen_common_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    drpwe_common_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    gtrefclk00_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    drpdo_common_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    drprdy_common_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    qpll0outclk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    qpll0outrefclk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    drpaddr_in : IN STD_LOGIC_VECTOR(59 DOWNTO 0);
    drpclk_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    drpdi_in : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
    drpen_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    drpwe_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtyrxn_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtyrxp_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    rxslide_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    drpdo_out : OUT STD_LOGIC_VECTOR(95 DOWNTO 0);
    drprdy_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtpowergood_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtytxn_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    gtytxp_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : xilinx_gty_crdb_vu9
  PORT MAP (
    gtwiz_userclk_tx_reset_in => gtwiz_userclk_tx_reset_in,
    gtwiz_userclk_tx_srcclk_out => gtwiz_userclk_tx_srcclk_out,
    gtwiz_userclk_tx_usrclk_out => gtwiz_userclk_tx_usrclk_out,
    gtwiz_userclk_tx_usrclk2_out => gtwiz_userclk_tx_usrclk2_out,
    gtwiz_userclk_tx_active_out => gtwiz_userclk_tx_active_out,
    gtwiz_userclk_rx_reset_in => gtwiz_userclk_rx_reset_in,
    gtwiz_userclk_rx_srcclk_out => gtwiz_userclk_rx_srcclk_out,
    gtwiz_userclk_rx_usrclk_out => gtwiz_userclk_rx_usrclk_out,
    gtwiz_userclk_rx_usrclk2_out => gtwiz_userclk_rx_usrclk2_out,
    gtwiz_userclk_rx_active_out => gtwiz_userclk_rx_active_out,
    gtwiz_buffbypass_rx_reset_in => gtwiz_buffbypass_rx_reset_in,
    gtwiz_buffbypass_rx_start_user_in => gtwiz_buffbypass_rx_start_user_in,
    gtwiz_buffbypass_rx_done_out => gtwiz_buffbypass_rx_done_out,
    gtwiz_buffbypass_rx_error_out => gtwiz_buffbypass_rx_error_out,
    gtwiz_reset_clk_freerun_in => gtwiz_reset_clk_freerun_in,
    gtwiz_reset_all_in => gtwiz_reset_all_in,
    gtwiz_reset_tx_pll_and_datapath_in => gtwiz_reset_tx_pll_and_datapath_in,
    gtwiz_reset_tx_datapath_in => gtwiz_reset_tx_datapath_in,
    gtwiz_reset_rx_pll_and_datapath_in => gtwiz_reset_rx_pll_and_datapath_in,
    gtwiz_reset_rx_datapath_in => gtwiz_reset_rx_datapath_in,
    gtwiz_reset_rx_cdr_stable_out => gtwiz_reset_rx_cdr_stable_out,
    gtwiz_reset_tx_done_out => gtwiz_reset_tx_done_out,
    gtwiz_reset_rx_done_out => gtwiz_reset_rx_done_out,
    gtwiz_userdata_tx_in => gtwiz_userdata_tx_in,
    gtwiz_userdata_rx_out => gtwiz_userdata_rx_out,
    drpaddr_common_in => drpaddr_common_in,
    drpclk_common_in => drpclk_common_in,
    drpdi_common_in => drpdi_common_in,
    drpen_common_in => drpen_common_in,
    drpwe_common_in => drpwe_common_in,
    gtrefclk00_in => gtrefclk00_in,
    drpdo_common_out => drpdo_common_out,
    drprdy_common_out => drprdy_common_out,
    qpll0outclk_out => qpll0outclk_out,
    qpll0outrefclk_out => qpll0outrefclk_out,
    drpaddr_in => drpaddr_in,
    drpclk_in => drpclk_in,
    drpdi_in => drpdi_in,
    drpen_in => drpen_in,
    drpwe_in => drpwe_in,
    gtyrxn_in => gtyrxn_in,
    gtyrxp_in => gtyrxp_in,
    rxslide_in => rxslide_in,
    drpdo_out => drpdo_out,
    drprdy_out => drprdy_out,
    gtpowergood_out => gtpowergood_out,
    gtytxn_out => gtytxn_out,
    gtytxp_out => gtytxp_out,
    rxpmaresetdone_out => rxpmaresetdone_out,
    txpmaresetdone_out => txpmaresetdone_out
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file xilinx_gty_crdb_vu9.vhd when simulating
-- the core, xilinx_gty_crdb_vu9. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

