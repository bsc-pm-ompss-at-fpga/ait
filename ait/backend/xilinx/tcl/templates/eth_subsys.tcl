
################################################################
# This is a generated script based on design: ethernet_subsystem
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been changes to the IP between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the functionality and configuration of the design."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source ethernet_subsystem_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu55c-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:au55c:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name ethernet_subsystem

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: eth_reset_logic
proc create_hier_cell_eth_reset_logic { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_eth_reset_logic() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk gt_txusrclk2
  create_bd_pin -dir O -from 0 -to 0 -type rst eth_subsys_rstn
  create_bd_pin -dir I eth_cntrl_rst

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
  set_property -dict [list \
    CONFIG.C_AUX_RST_WIDTH {1} \
    CONFIG.C_EXT_RST_WIDTH {1} \
  ] $proc_sys_reset_0


  # Create port connections
  connect_bd_net -net eth100gb_gt_txusrclk2 [get_bd_pins gt_txusrclk2] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net eth_cntrl_rst_1 [get_bd_pins eth_cntrl_rst] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins eth_subsys_rstn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set QSFP_CLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 QSFP_CLK ]

  set QSFP_X4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 QSFP_X4 ]

  set S_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI

  set S_AXIS [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {8} \
   CONFIG.TID_WIDTH {3} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS

  set msg_rx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 msg_rx ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $msg_rx


  # Create ports
  set clk_100 [ create_bd_port -dir I -type clk -freq_hz 100000000 clk_100 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXI} \
   CONFIG.ASSOCIATED_RESET {clk_100_rstn:eth_cntrl_rst} \
 ] $clk_100
  set clk_100_rstn [ create_bd_port -dir I -type rst clk_100_rstn ]
  set clk_200 [ create_bd_port -dir I -type clk -freq_hz 200000000 clk_200 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXIS:msg_rx} \
   CONFIG.ASSOCIATED_RESET {clk_200_rstn} \
 ] $clk_200
  set clk_200_rstn [ create_bd_port -dir I -type rst clk_200_rstn ]
  set eth_subsys_rst [ create_bd_port -dir I -type rst eth_subsys_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $eth_subsys_rst
  set init_clk [ create_bd_port -dir I -type clk -freq_hz 50000000 init_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {eth_subsys_rst} \
 ] $init_clk
  set eth_cntrl_rst [ create_bd_port -dir I -type rst eth_cntrl_rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $eth_cntrl_rst

  # Create instance: axi_clock_converter_0, and set properties
  set axi_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter axi_clock_converter_0 ]

  # Create instance: axi_crossbar_1, and set properties
  set axi_crossbar_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar axi_crossbar_1 ]
  set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.R_REGISTER {0} \
    CONFIG.S01_SINGLE_THREAD {1} \
    CONFIG.STRATEGY {1} \
  ] $axi_crossbar_1


  # Create instance: axis_clock_converter_0, and set properties
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clock_converter_0 ]

  # Create instance: axis_clock_converter_1, and set properties
  set axis_clock_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clock_converter_1 ]

  # Create instance: axis_tx_regslice, and set properties
  set axis_tx_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice axis_tx_regslice ]
  set_property CONFIG.REG_CONFIG {8} $axis_tx_regslice


  # Create instance: const_gndx12, and set properties
  set const_gndx12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_gndx12 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {12} \
  ] $const_gndx12


  # Create instance: const_gndx56, and set properties
  set const_gndx56 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_gndx56 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {56} \
  ] $const_gndx56


  # Create instance: eth100gb, and set properties
  set eth100gb [ create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus eth100gb ]
  set_property -dict [list \
    CONFIG.CMAC_CAUI4_MODE {1} \
    CONFIG.NUM_LANES {4x25} \
    CONFIG.RX_FLOW_CONTROL {0} \
    CONFIG.TX_FLOW_CONTROL {0} \
    CONFIG.USER_INTERFACE {AXIS} \
  ] $eth100gb


  # Create instance: eth_100G_controller_0, and set properties
  set eth_100G_controller_0 [ create_bd_cell -type ip -vlnv bsc:ompif:eth_100G_controller_wrapper eth_100G_controller_0 ]
  set_property -dict [list \
    CONFIG.FRAMEQ_DATA_LEN {512} \
    CONFIG.FRAMEQ_META_LEN {32} \
    CONFIG.MAX_CLUSTER_SIZE {96} \
  ] $eth_100G_controller_0


  # Create instance: eth_100G_rx_wrapper_0, and set properties
  set eth_100G_rx_wrapper_0 [ create_bd_cell -type ip -vlnv bsc:ompif:eth_100G_rx_wrapper eth_100G_rx_wrapper_0 ]
  set_property -dict [list \
    CONFIG.FRAME_QUEUE_LEN {512} \
    CONFIG.MAX_CLUSTER_SIZE {96} \
  ] $eth_100G_rx_wrapper_0


  # Create instance: eth_decoder_rs, and set properties
  set eth_decoder_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice eth_decoder_rs ]
  set_property -dict [list \
    CONFIG.NUM_SLR_CROSSINGS {1} \
    CONFIG.REG_CONFIG {15} \
  ] $eth_decoder_rs


  # Create instance: eth_encoder_rs, and set properties
  set eth_encoder_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice eth_encoder_rs ]
  set_property -dict [list \
    CONFIG.NUM_SLR_CROSSINGS {1} \
    CONFIG.REG_CONFIG {15} \
  ] $eth_encoder_rs


  # Create instance: eth_reset_logic
  create_hier_cell_eth_reset_logic [current_bd_instance .] eth_reset_logic

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_0


  # Create instance: axis_rx_regslice, and set properties
  set axis_rx_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice axis_rx_regslice ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_ports S_AXIS] [get_bd_intf_pins eth_encoder_rs/S_AXIS]
  connect_bd_intf_net -intf_net axi_clock_converter_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins axi_crossbar_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M01_AXI [get_bd_intf_ports S_AXI] [get_bd_intf_pins axi_clock_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_1_M00_AXI [get_bd_intf_pins axi_crossbar_1/M00_AXI] [get_bd_intf_pins eth_100G_controller_0/s_axi]
  connect_bd_intf_net -intf_net axi_crossbar_1_M01_AXI [get_bd_intf_pins axi_crossbar_1/M01_AXI] [get_bd_intf_pins eth_100G_rx_wrapper_0/s_axi]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/M_AXIS] [get_bd_intf_pins eth_decoder_rs/S_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_1_M_AXIS [get_bd_intf_pins axis_clock_converter_1/M_AXIS] [get_bd_intf_pins eth_100G_controller_0/si]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_rx_regslice/M_AXIS] [get_bd_intf_pins eth_100G_rx_wrapper_0/rx]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_ports msg_rx] [get_bd_intf_pins eth_decoder_rs/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS1 [get_bd_intf_pins axis_clock_converter_1/S_AXIS] [get_bd_intf_pins eth_encoder_rs/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS2 [get_bd_intf_pins eth100gb/axis_tx] [get_bd_intf_pins axis_tx_regslice/M_AXIS]
  connect_bd_intf_net -intf_net eth100gb_axis_rx [get_bd_intf_pins eth100gb/axis_rx] [get_bd_intf_pins axis_rx_regslice/S_AXIS]
  connect_bd_intf_net -intf_net eth100gb_gt_serial_port [get_bd_intf_ports QSFP_X4] [get_bd_intf_pins eth100gb/gt_serial_port]
  connect_bd_intf_net -intf_net eth_100G_controller_0_eth_tx [get_bd_intf_pins eth_100G_controller_0/eth_tx] [get_bd_intf_pins axis_tx_regslice/S_AXIS]
  connect_bd_intf_net -intf_net eth_100G_rx_wrapper_0_so [get_bd_intf_pins axis_clock_converter_0/S_AXIS] [get_bd_intf_pins eth_100G_rx_wrapper_0/so]
  connect_bd_intf_net -intf_net gt_ref_clk_0_1 [get_bd_intf_ports QSFP_CLK] [get_bd_intf_pins eth100gb/gt_ref_clk]

  # Create port connections
  connect_bd_net -net clk_100_1 [get_bd_ports clk_100] [get_bd_pins axi_clock_converter_0/s_axi_aclk]
  connect_bd_net -net clk_100_rstn_1 [get_bd_ports clk_100_rstn] [get_bd_pins axi_clock_converter_0/s_axi_aresetn]
  connect_bd_net -net const_gndx56_dout [get_bd_pins const_gndx56/dout] [get_bd_pins eth100gb/tx_preamblein]
  connect_bd_net -net eth100gb_gt_powergoodout [get_bd_pins eth100gb/gt_powergoodout] [get_bd_pins eth_100G_controller_0/gt_powergoodout]
  connect_bd_net -net eth100gb_gt_txusrclk2 [get_bd_pins eth100gb/gt_txusrclk2] [get_bd_pins axis_tx_regslice/aclk] [get_bd_pins axi_clock_converter_0/m_axi_aclk] [get_bd_pins axi_crossbar_1/aclk] [get_bd_pins axis_clock_converter_0/s_axis_aclk] [get_bd_pins axis_clock_converter_1/m_axis_aclk] [get_bd_pins eth100gb/rx_clk] [get_bd_pins eth_reset_logic/gt_txusrclk2] [get_bd_pins eth_100G_rx_wrapper_0/clk] [get_bd_pins eth_100G_controller_0/clk] [get_bd_pins axis_rx_regslice/aclk]
  connect_bd_net -net eth100gb_stat_rx_aligned [get_bd_pins eth100gb/stat_rx_aligned] [get_bd_pins eth_100G_controller_0/stat_rx_aligned]
  connect_bd_net -net eth100gb_stat_rx_aligned_err [get_bd_pins eth100gb/stat_rx_aligned_err] [get_bd_pins eth_100G_controller_0/stat_rx_aligned_err]
  connect_bd_net -net eth100gb_stat_rx_bad_code [get_bd_pins eth100gb/stat_rx_bad_code] [get_bd_pins eth_100G_controller_0/stat_rx_bad_code]
  connect_bd_net -net eth100gb_stat_rx_bip_err_0 [get_bd_pins eth100gb/stat_rx_bip_err_0] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_0]
  connect_bd_net -net eth100gb_stat_rx_bip_err_1 [get_bd_pins eth100gb/stat_rx_bip_err_1] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_1]
  connect_bd_net -net eth100gb_stat_rx_bip_err_2 [get_bd_pins eth100gb/stat_rx_bip_err_2] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_2]
  connect_bd_net -net eth100gb_stat_rx_bip_err_3 [get_bd_pins eth100gb/stat_rx_bip_err_3] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_3]
  connect_bd_net -net eth100gb_stat_rx_bip_err_4 [get_bd_pins eth100gb/stat_rx_bip_err_4] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_4]
  connect_bd_net -net eth100gb_stat_rx_bip_err_5 [get_bd_pins eth100gb/stat_rx_bip_err_5] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_5]
  connect_bd_net -net eth100gb_stat_rx_bip_err_6 [get_bd_pins eth100gb/stat_rx_bip_err_6] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_6]
  connect_bd_net -net eth100gb_stat_rx_bip_err_7 [get_bd_pins eth100gb/stat_rx_bip_err_7] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_7]
  connect_bd_net -net eth100gb_stat_rx_bip_err_8 [get_bd_pins eth100gb/stat_rx_bip_err_8] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_8]
  connect_bd_net -net eth100gb_stat_rx_bip_err_9 [get_bd_pins eth100gb/stat_rx_bip_err_9] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_9]
  connect_bd_net -net eth100gb_stat_rx_bip_err_10 [get_bd_pins eth100gb/stat_rx_bip_err_10] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_10]
  connect_bd_net -net eth100gb_stat_rx_bip_err_11 [get_bd_pins eth100gb/stat_rx_bip_err_11] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_11]
  connect_bd_net -net eth100gb_stat_rx_bip_err_12 [get_bd_pins eth100gb/stat_rx_bip_err_12] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_12]
  connect_bd_net -net eth100gb_stat_rx_bip_err_13 [get_bd_pins eth100gb/stat_rx_bip_err_13] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_13]
  connect_bd_net -net eth100gb_stat_rx_bip_err_14 [get_bd_pins eth100gb/stat_rx_bip_err_14] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_14]
  connect_bd_net -net eth100gb_stat_rx_bip_err_15 [get_bd_pins eth100gb/stat_rx_bip_err_15] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_15]
  connect_bd_net -net eth100gb_stat_rx_bip_err_16 [get_bd_pins eth100gb/stat_rx_bip_err_16] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_16]
  connect_bd_net -net eth100gb_stat_rx_bip_err_17 [get_bd_pins eth100gb/stat_rx_bip_err_17] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_17]
  connect_bd_net -net eth100gb_stat_rx_bip_err_18 [get_bd_pins eth100gb/stat_rx_bip_err_18] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_18]
  connect_bd_net -net eth100gb_stat_rx_bip_err_19 [get_bd_pins eth100gb/stat_rx_bip_err_19] [get_bd_pins eth_100G_controller_0/stat_rx_bip_err_19]
  connect_bd_net -net eth100gb_stat_rx_hi_ber [get_bd_pins eth100gb/stat_rx_hi_ber] [get_bd_pins eth_100G_controller_0/stat_rx_hi_ber]
  connect_bd_net -net eth100gb_stat_rx_internal_local_fault [get_bd_pins eth100gb/stat_rx_internal_local_fault] [get_bd_pins eth_100G_controller_0/stat_rx_internal_local_fault]
  connect_bd_net -net eth100gb_stat_rx_misaligned [get_bd_pins eth100gb/stat_rx_misaligned] [get_bd_pins eth_100G_controller_0/stat_rx_misaligned]
  connect_bd_net -net eth100gb_stat_rx_synced_err [get_bd_pins eth100gb/stat_rx_synced_err] [get_bd_pins eth_100G_controller_0/stat_rx_synced_err]
  connect_bd_net -net eth100gb_usr_rx_reset [get_bd_pins eth100gb/usr_rx_reset] [get_bd_pins eth_100G_controller_0/usr_rx_reset]
  connect_bd_net -net eth100gb_usr_tx_reset [get_bd_pins eth100gb/usr_tx_reset] [get_bd_pins eth_100G_controller_0/usr_tx_reset]
  connect_bd_net -net eth_100G_controller_0_ctl_rx_enable [get_bd_pins eth_100G_controller_0/ctl_rx_enable] [get_bd_pins eth100gb/ctl_rx_enable]
  connect_bd_net -net eth_100G_controller_0_ctl_tx_enable [get_bd_pins eth_100G_controller_0/ctl_tx_enable] [get_bd_pins eth100gb/ctl_tx_enable]
  connect_bd_net -net eth_100G_controller_0_ctl_tx_send_rfi [get_bd_pins eth_100G_controller_0/ctl_tx_send_rfi] [get_bd_pins eth100gb/ctl_tx_send_rfi]
  connect_bd_net -net eth_100G_controller_0_mac_addr [get_bd_pins eth_100G_controller_0/mac_addr] [get_bd_pins eth_100G_rx_wrapper_0/mac_addr]
  connect_bd_net -net eth_cntrl_rst_1 [get_bd_ports eth_cntrl_rst] [get_bd_pins eth_reset_logic/eth_cntrl_rst]
  connect_bd_net -net eth_reset_logic_eth_cntrl_rstn [get_bd_pins eth_reset_logic/eth_subsys_rstn] [get_bd_pins eth_100G_controller_0/rstn] [get_bd_pins axi_clock_converter_0/m_axi_aresetn] [get_bd_pins axi_crossbar_1/aresetn] [get_bd_pins axis_clock_converter_1/m_axis_aresetn] [get_bd_pins axis_tx_regslice/aresetn] [get_bd_pins axis_rx_regslice/aresetn] [get_bd_pins eth_100G_rx_wrapper_0/rstn] [get_bd_pins axis_clock_converter_0/s_axis_aresetn]
  connect_bd_net -net init_clk_1 [get_bd_ports init_clk] [get_bd_pins eth100gb/init_clk]
  connect_bd_net -net processor_system_reset_peripheral_aresetn [get_bd_ports clk_200_rstn] [get_bd_pins axis_clock_converter_0/m_axis_aresetn] [get_bd_pins axis_clock_converter_1/s_axis_aresetn] [get_bd_pins eth_decoder_rs/aresetn] [get_bd_pins eth_encoder_rs/aresetn]
  connect_bd_net -net sys_clk [get_bd_ports clk_200] [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins axis_clock_converter_1/s_axis_aclk] [get_bd_pins eth_decoder_rs/aclk] [get_bd_pins eth_encoder_rs/aclk]
  connect_bd_net -net sys_reset_logic_peripheral_reset [get_bd_ports eth_subsys_rst] [get_bd_pins eth100gb/core_rx_reset] [get_bd_pins eth100gb/core_tx_reset] [get_bd_pins eth100gb/gtwiz_reset_rx_datapath] [get_bd_pins eth100gb/gtwiz_reset_tx_datapath] [get_bd_pins eth100gb/sys_reset]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins const_gndx12/dout] [get_bd_pins eth100gb/gt_loopback_in]
  connect_bd_net -net xlconstant_0_dout1 [get_bd_pins xlconstant_0/dout] [get_bd_pins eth100gb/drp_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs eth_100G_controller_0/s_axi/reg0] -force
  assign_bd_address -offset 0x00004000 -range 0x00004000 -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs eth_100G_rx_wrapper_0/s_axi/reg0] -force
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


