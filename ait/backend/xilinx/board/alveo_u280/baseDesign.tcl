
################################################################
# This is a generated script based on design: alveo_u280_base_design
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
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_msg_id "BD_TCL-1002" "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source alveo_u280_base_design_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# addrInterleaver

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu280-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:au280:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name ${argv}_design

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
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

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

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:blk_mem_gen:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:clk_wiz:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:ddr4:*\
xilinx.com:ip:util_vector_logic:*\
xilinx.com:ip:qdma:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:util_ds_buf:*\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
bsc_axiu_addrInterleaver\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: QDMA
proc create_hier_cell_QDMA { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_QDMA() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk

  # Create pins
  create_bd_pin -dir O -from 63 -to 0 QDMA_m_axi_araddr
  create_bd_pin -dir O -from 63 -to 0 QDMA_m_axi_awaddr
  create_bd_pin -dir O -type clk aclk
  create_bd_pin -dir O -type rst aresetn
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: QDMA, and set properties
  set QDMA [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma QDMA ]
  set_property -dict [ list \
   CONFIG.MAILBOX_ENABLE {true} \
   CONFIG.PF0_SRIOV_CAP_INITIAL_VF {4} \
   CONFIG.PF0_SRIOV_FIRST_VF_OFFSET {4} \
   CONFIG.PF1_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF1_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.PF2_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF2_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.PF3_SRIOV_CAP_INITIAL_VF {0} \
   CONFIG.PF3_SRIOV_FIRST_VF_OFFSET {0} \
   CONFIG.SRIOV_CAP_ENABLE {true} \
   CONFIG.SRIOV_FIRST_VF_OFFSET {4} \
   CONFIG.barlite_mb_pf0 {1} \
   CONFIG.barlite_mb_pf1 {0} \
   CONFIG.barlite_mb_pf2 {0} \
   CONFIG.barlite_mb_pf3 {0} \
   CONFIG.copy_pf0 {false} \
   CONFIG.copy_sriov_pf0 {false} \
   CONFIG.dma_intf_sel_qdma {AXI_MM} \
   CONFIG.en_axi_st_qdma {false} \
   CONFIG.en_bridge {false} \
   CONFIG.en_gt_selection {false} \
   CONFIG.flr_enable {true} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.pf0_ari_enabled {true} \
   CONFIG.pf0_bar0_prefetchable_qdma {true} \
   CONFIG.pf0_bar2_prefetchable_qdma {true} \
   CONFIG.pf0_bar2_scale_qdma {Megabytes} \
   CONFIG.pf0_bar2_size_qdma {2} \
   CONFIG.pf1_bar0_prefetchable_qdma {true} \
   CONFIG.pf1_bar2_prefetchable_qdma {true} \
   CONFIG.pf2_bar0_prefetchable_qdma {true} \
   CONFIG.pf2_bar2_prefetchable_qdma {true} \
   CONFIG.pf3_bar0_prefetchable_qdma {true} \
   CONFIG.pf3_bar2_prefetchable_qdma {true} \
   CONFIG.testname {mm} \
   CONFIG.tl_pf_enable_reg {1} \
 ] $QDMA

  # Create instance: const_1, and set properties
  set const_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1 ]

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf

  # Create interface connections
  connect_bd_intf_net -intf_net QDMA_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins QDMA/M_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE [get_bd_intf_pins M_AXI_LITE] [get_bd_intf_pins QDMA/M_AXI_LITE]
  connect_bd_intf_net -intf_net QDMA_pcie_mgt [get_bd_intf_pins pci_express_x8] [get_bd_intf_pins QDMA/pcie_mgt]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins util_ds_buf/CLK_IN_D]

  # Create port connections
  connect_bd_net -net QDMA_axi_aclk [get_bd_pins aclk] [get_bd_pins QDMA/axi_aclk]
  connect_bd_net -net QDMA_axi_aresetn [get_bd_pins aresetn] [get_bd_pins QDMA/axi_aresetn]
  connect_bd_net -net QDMA_m_axi_araddr [get_bd_pins QDMA_m_axi_araddr] [get_bd_pins QDMA/m_axi_araddr]
  connect_bd_net -net QDMA_m_axi_awaddr [get_bd_pins QDMA_m_axi_awaddr] [get_bd_pins QDMA/m_axi_awaddr]
  connect_bd_net -net const_1_dout [get_bd_pins QDMA/st_rx_msg_rdy] [get_bd_pins QDMA/tm_dsc_sts_rdy] [get_bd_pins const_1/dout]
  connect_bd_net -net pcie_perstn_1 [get_bd_pins pcie_perstn] [get_bd_pins QDMA/soft_reset_n] [get_bd_pins QDMA/sys_rst_n]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins QDMA/sys_clk] [get_bd_pins util_ds_buf/IBUF_DS_ODIV2]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins QDMA/sys_clk_gt] [get_bd_pins util_ds_buf/IBUF_OUT]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DDR_0
proc create_hier_cell_DDR_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DDR_0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 SDRAM


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type rst rst
  create_bd_pin -dir I -type rst sys_rst
  create_bd_pin -dir O -type clk ui_clk

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 DDR ]
  set_property -dict [list \
   CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
   CONFIG.C0.DDR4_AUTO_AP_COL_A3 {true} \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_CLKFBOUT_MULT {15} \
   CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} \
   CONFIG.C0.DDR4_CasLatency {17} \
   CONFIG.C0.DDR4_CasWriteLatency {12} \
   CONFIG.C0.DDR4_DataMask {NONE} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_Ecc {true} \
   CONFIG.C0.DDR4_InputClockPeriod {9996} \
   CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK_INTLV} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72PZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {RDIMMs} \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {sysclk0} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c0} \
   CONFIG.RESET_BOARD_INTERFACE {pcie_perstn} \
  ] $DDR


  # Create instance: proc_sys_reset, and set properties
  set proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset ]

  # Create interface connections
  connect_bd_intf_net -intf_net C0_DDR4_S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins DDR/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net C0_DDR4_S_AXI_CTRL_1 [get_bd_intf_pins S_AXI_CTRL] [get_bd_intf_pins DDR/C0_DDR4_S_AXI_CTRL]
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_pins SYS_CLK] [get_bd_intf_pins DDR/C0_SYS_CLK]
  connect_bd_intf_net -intf_net C0_DDR4_1 [get_bd_intf_pins SDRAM] [get_bd_intf_pins DDR/C0_DDR4]

  # Create port connections
  connect_bd_net -net c0_ddr4_ui_clk_1 [get_bd_pins ui_clk] [get_bd_pins DDR/c0_ddr4_ui_clk] [get_bd_pins proc_sys_reset/slowest_sync_clk]
  connect_bd_net -net proc_sys_reset_peripheral_aresetn_1 [get_bd_pins peripheral_aresetn] [get_bd_pins DDR/c0_ddr4_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]
  connect_bd_net -net rst_1 [get_bd_pins rst] [get_bd_pins proc_sys_reset/ext_reset_in]
  connect_bd_net -net sys_rst_1 [get_bd_pins sys_rst] [get_bd_pins DDR/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DDR_1
proc create_hier_cell_DDR_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DDR_1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 SDRAM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 SYS_CLK


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type rst rst
  create_bd_pin -dir I -type rst sys_rst
  create_bd_pin -dir O -type clk ui_clk

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 DDR ]
  set_property -dict [list \
   CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
   CONFIG.C0.DDR4_AUTO_AP_COL_A3 {true} \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_CLKFBOUT_MULT {15} \
   CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} \
   CONFIG.C0.DDR4_CasLatency {17} \
   CONFIG.C0.DDR4_CasWriteLatency {12} \
   CONFIG.C0.DDR4_DataMask {NONE} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_Ecc {true} \
   CONFIG.C0.DDR4_InputClockPeriod {9996} \
   CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK_INTLV} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72PZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {RDIMMs} \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {sysclk1} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1} \
   CONFIG.RESET_BOARD_INTERFACE {pcie_perstn} \
  ] $DDR


  # Create instance: proc_sys_reset, and set properties
  set proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset ]

  # Create interface connections
  connect_bd_intf_net -intf_net C0_DDR4_S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins DDR/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net C0_DDR4_S_AXI_CTRL_1 [get_bd_intf_pins S_AXI_CTRL] [get_bd_intf_pins DDR/C0_DDR4_S_AXI_CTRL]
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_pins SYS_CLK] [get_bd_intf_pins DDR/C0_SYS_CLK]
  connect_bd_intf_net -intf_net C0_DDR4_1 [get_bd_intf_pins SDRAM] [get_bd_intf_pins DDR/C0_DDR4]

  # Create port connections
  connect_bd_net -net c0_ddr4_ui_clk_1 [get_bd_pins ui_clk] [get_bd_pins DDR/c0_ddr4_ui_clk] [get_bd_pins proc_sys_reset/slowest_sync_clk]
  connect_bd_net -net proc_sys_reset_peripheral_aresetn_1 [get_bd_pins peripheral_aresetn] [get_bd_pins DDR/c0_ddr4_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]
  connect_bd_net -net rst_1 [get_bd_pins rst] [get_bd_pins proc_sys_reset/ext_reset_in]
  connect_bd_net -net sys_rst_1 [get_bd_pins sys_rst] [get_bd_pins DDR/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: memory
proc create_hier_cell_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_memory() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_0_S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_1_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_0_S_AXI_CTRL
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_1_S_AXI_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_0_SYS_CLK
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_1_SYS_CLK

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_0_SDRAM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_1_SDRAM

  # Create pins
  create_bd_pin -dir O -type clk DDR_0_ui_clk
  create_bd_pin -dir O -type clk DDR_1_ui_clk

  create_bd_pin -dir O -type rst DDR_0_peripheral_aresetn
  create_bd_pin -dir O -type rst DDR_1_peripheral_aresetn

  create_bd_pin -dir I -type rst DDR_rst

  # Create instance: DDR_0
  create_hier_cell_DDR_0 $hier_obj DDR_0

  # Create instance: DDR_1
  create_hier_cell_DDR_1 $hier_obj DDR_1

  # Create instance: sys_rst_NOT, and set properties
  set sys_rst_NOT [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic sys_rst_NOT ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $sys_rst_NOT

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_0_SDRAM [get_bd_intf_pins DDR_0_SDRAM] [get_bd_intf_pins DDR_0/SDRAM]
  connect_bd_intf_net -intf_net DDR_0_SYS_CLK_1 [get_bd_intf_pins DDR_0_SYS_CLK] [get_bd_intf_pins DDR_0/SYS_CLK]
  connect_bd_intf_net -intf_net DDR_0_S_AXI_1 [get_bd_intf_pins DDR_0_S_AXI] [get_bd_intf_pins DDR_0/S_AXI]
  connect_bd_intf_net -intf_net DDR_0_S_AXI_CTRL_1 [get_bd_intf_pins DDR_0_S_AXI_CTRL] [get_bd_intf_pins DDR_0/S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_1_SDRAM [get_bd_intf_pins DDR_1_SDRAM] [get_bd_intf_pins DDR_1/SDRAM]
  connect_bd_intf_net -intf_net DDR_1_SYS_CLK_1 [get_bd_intf_pins DDR_1_SYS_CLK] [get_bd_intf_pins DDR_1/SYS_CLK]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_1 [get_bd_intf_pins DDR_1_S_AXI] [get_bd_intf_pins DDR_1/S_AXI]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_CTRL_1 [get_bd_intf_pins DDR_1_S_AXI_CTRL] [get_bd_intf_pins DDR_1/S_AXI_CTRL]

  # Create port connections
  connect_bd_net -net DDR_0_peripheral_aresetn [get_bd_pins DDR_0_peripheral_aresetn] [get_bd_pins DDR_0/peripheral_aresetn]
  connect_bd_net -net DDR_0_ui_clk1 [get_bd_pins DDR_0_ui_clk] [get_bd_pins DDR_0/ui_clk]
  connect_bd_net -net DDR_1_peripheral_aresetn [get_bd_pins DDR_1_peripheral_aresetn] [get_bd_pins DDR_1/peripheral_aresetn]
  connect_bd_net -net DDR_1_ui_clk [get_bd_pins DDR_1_ui_clk] [get_bd_pins DDR_1/ui_clk]
  connect_bd_net -net DDR_rst_1 [get_bd_pins DDR_rst] [get_bd_pins DDR_0/rst] [get_bd_pins DDR_1/rst] [get_bd_pins sys_rst_NOT/Op1]
  connect_bd_net -net sys_rst_NOT_Res [get_bd_pins DDR_0/sys_rst] [get_bd_pins DDR_1/sys_rst] [get_bd_pins sys_rst_NOT/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: bridge_to_host
proc create_hier_cell_bridge_to_host { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bridge_to_host() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_0_SDRAM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_1_SDRAM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_0_SYS_CLK
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_1_SYS_CLK
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk

  # Create pins
  create_bd_pin -dir O -type clk ui_clk
  create_bd_pin -dir I -type clk clk_app
  create_bd_pin -dir I -type rst clk_app_rstn
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: memory
  create_hier_cell_memory $hier_obj memory

  # Create instance: DDR_S_AXI_Inter, and set properties
  set DDR_S_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect DDR_S_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.NUM_SI {2} \
 ] $DDR_S_AXI_Inter

  # Create instance: QDMA
  create_hier_cell_QDMA $hier_obj QDMA

  # Create instance: QDMA_M_AXI_LITE_Inter, and set properties
  set QDMA_M_AXI_LITE_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect QDMA_M_AXI_LITE_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
 ] $QDMA_M_AXI_LITE_Inter

  # Create instance: bridge_to_host_araddrInterleaver, and set properties
  set block_name bsc_axiu_addrInterleaver
  set block_cell_name bridge_to_host_araddrInterleaver
  if { [catch {set bridge_to_host_araddrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bridge_to_host_araddrInterleaver eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: bridge_to_host_awaddrInterleaver, and set properties
  set block_name bsc_axiu_addrInterleaver
  set block_cell_name bridge_to_host_awaddrInterleaver
  if { [catch {set bridge_to_host_awaddrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bridge_to_host_awaddrInterleaver eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_0_S_AXI_1 [get_bd_intf_pins memory/DDR_0_S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/M00_AXI]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_1 [get_bd_intf_pins memory/DDR_1_S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/M01_AXI]
  connect_bd_intf_net -intf_net memory_DDR_0_SDRAM [get_bd_intf_pins DDR_0_SDRAM] [get_bd_intf_pins memory/DDR_0_SDRAM]
  connect_bd_intf_net -intf_net memory_DDR_1_SDRAM [get_bd_intf_pins DDR_1_SDRAM] [get_bd_intf_pins memory/DDR_1_SDRAM]
  connect_bd_intf_net -intf_net QDMA_M_AXI [get_bd_intf_pins DDR_S_AXI_Inter/S00_AXI] [get_bd_intf_pins QDMA/M_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE [get_bd_intf_pins QDMA/M_AXI_LITE] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/S00_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE_Inter_M00_AXI [get_bd_intf_pins memory/DDR_0_S_AXI_CTRL] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/M00_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE_Inter_M01_AXI [get_bd_intf_pins memory/DDR_1_S_AXI_CTRL] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/M01_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE_Inter_M02_AXI [get_bd_intf_pins M_AXI_LITE] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/M02_AXI]
  connect_bd_intf_net -intf_net DDR_0_SYS_CLK_1 [get_bd_intf_pins DDR_0_SYS_CLK] [get_bd_intf_pins memory/DDR_0_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_1_SYS_CLK_1 [get_bd_intf_pins DDR_1_SYS_CLK] [get_bd_intf_pins memory/DDR_1_SYS_CLK]
  connect_bd_intf_net -intf_net QDMA_pci_express_x8 [get_bd_intf_pins pci_express_x8] [get_bd_intf_pins QDMA/pci_express_x8]
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/S01_AXI]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins QDMA/pcie_refclk]

  # Create port connections
  connect_bd_net [get_bd_pins memory/DDR_0_peripheral_aresetn] [get_bd_pins DDR_S_AXI_Inter/M00_ARESETN] [get_bd_pins QDMA_M_AXI_LITE_Inter/M00_ARESETN]
  connect_bd_net [get_bd_pins ui_clk] [get_bd_pins memory/DDR_0_ui_clk] [get_bd_pins DDR_S_AXI_Inter/M00_ACLK] [get_bd_pins QDMA_M_AXI_LITE_Inter/M00_ACLK]
  connect_bd_net [get_bd_pins memory/DDR_1_peripheral_aresetn] [get_bd_pins DDR_S_AXI_Inter/M01_ARESETN] [get_bd_pins QDMA_M_AXI_LITE_Inter/M01_ARESETN]
  connect_bd_net [get_bd_pins memory/DDR_1_ui_clk] [get_bd_pins DDR_S_AXI_Inter/M01_ACLK] [get_bd_pins QDMA_M_AXI_LITE_Inter/M01_ACLK]
  connect_bd_net [get_bd_pins QDMA/QDMA_m_axi_araddr] [get_bd_pins bridge_to_host_araddrInterleaver/in_addr]
  connect_bd_net [get_bd_pins QDMA/QDMA_m_axi_awaddr] [get_bd_pins bridge_to_host_awaddrInterleaver/in_addr]
  connect_bd_net [get_bd_pins DDR_S_AXI_Inter/S00_ACLK] [get_bd_pins QDMA/aclk] [get_bd_pins QDMA_M_AXI_LITE_Inter/S00_ACLK]
  connect_bd_net [get_bd_pins DDR_S_AXI_Inter/S00_ARESETN] [get_bd_pins QDMA/aresetn] [get_bd_pins QDMA_M_AXI_LITE_Inter/S00_ARESETN]
  connect_bd_net [get_bd_pins DDR_S_AXI_Inter/S00_AXI_araddr] [get_bd_pins bridge_to_host_araddrInterleaver/out_addr]
  connect_bd_net [get_bd_pins DDR_S_AXI_Inter/S00_AXI_awaddr] [get_bd_pins bridge_to_host_awaddrInterleaver/out_addr]
  connect_bd_net [get_bd_pins clk_app] [get_bd_pins DDR_S_AXI_Inter/ACLK] [get_bd_pins DDR_S_AXI_Inter/S01_ACLK] [get_bd_pins QDMA_M_AXI_LITE_Inter/ACLK] [get_bd_pins QDMA_M_AXI_LITE_Inter/M02_ACLK]
  connect_bd_net [get_bd_pins clk_app_rstn] [get_bd_pins DDR_S_AXI_Inter/ARESETN] [get_bd_pins QDMA_M_AXI_LITE_Inter/ARESETN]
  connect_bd_net [get_bd_pins pcie_perstn] [get_bd_pins memory/DDR_rst] [get_bd_pins QDMA/pcie_perstn]
  connect_bd_net [get_bd_pins clk_app_rstn] [get_bd_pins DDR_S_AXI_Inter/S01_ARESETN] [get_bd_pins QDMA_M_AXI_LITE_Inter/M02_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: system_reset
proc create_hier_cell_system_reset { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_bridge_to_host() - Empty argument(s)!"}
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

  create_bd_pin -dir I -type rst pcie_perstn
  create_bd_pin -dir I clk_gen_locked
  create_bd_pin -dir I -type clk clk_app
  create_bd_pin -dir O -type rst clk_app_rstn

  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_clk_app
  set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] [get_bd_cells proc_sys_reset_clk_app]

  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/slowest_sync_clk] [get_bd_pins clk_app]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/peripheral_aresetn] [get_bd_pins clk_app_rstn]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/ext_reset_in] [get_bd_pins pcie_perstn]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/dcm_locked] [get_bd_pins clk_gen_locked]

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
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ddr4_sdram_c0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c0 ]
  set ddr4_sdram_c1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1 ]
  set sysclk0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sysclk0 ]
  set sysclk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sysclk1 ]
  set pci_express_x8 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8 ]
  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk

  # Create ports
  set HBM_CATTRIP [ create_bd_port -dir O -from 0 -to 0 HBM_CATTRIP ]
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn

  # Create instance: M_AXI_Inter, and set properties
  set M_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect M_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $M_AXI_Inter

  # Create instance: S_AXI_Inter, and set properties
  set S_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect S_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $S_AXI_Inter

  # Create instance: bridge_to_host
  create_hier_cell_bridge_to_host [current_bd_instance .] bridge_to_host

  # Create instance: system_reset
  create_hier_cell_system_reset [current_bd_instance .] system_reset

  # Create instance: clock_generator, and set properties
  set clock_generator [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clock_generator ]
  set_property -dict [ list \
   CONFIG.CLK_OUT1_PORT {clk_app} \
   CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
   CONFIG.CLKOUT1_JITTER {101.475} \
   CONFIG.CLKOUT1_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} \
   CONFIG.RESET_BOARD_INTERFACE {resetn} \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
 ] $clock_generator

  # Create instance: HBM_CATTRIP_constant, and set properties
  set HBM_CATTRIP_constant [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant HBM_CATTRIP_constant ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $HBM_CATTRIP_constant

  # Create interface connections
  connect_bd_intf_net -intf_net sysclk0_1 [get_bd_intf_ports sysclk0] [get_bd_intf_pins bridge_to_host/DDR_0_SYS_CLK]
  connect_bd_intf_net -intf_net sysclk1_1 [get_bd_intf_ports sysclk1] [get_bd_intf_pins bridge_to_host/DDR_1_SYS_CLK]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins M_AXI_Inter/S00_AXI] [get_bd_intf_pins bridge_to_host/M_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_Inter_M00_AXI [get_bd_intf_pins S_AXI_Inter/M00_AXI] [get_bd_intf_pins bridge_to_host/S_AXI]
  connect_bd_intf_net -intf_net bridge_to_host_ddr4_sdram_c0 [get_bd_intf_ports ddr4_sdram_c0] [get_bd_intf_pins bridge_to_host/DDR_0_SDRAM]
  connect_bd_intf_net -intf_net bridge_to_host_ddr4_sdram_c1 [get_bd_intf_ports ddr4_sdram_c1] [get_bd_intf_pins bridge_to_host/DDR_1_SDRAM]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins bridge_to_host/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_ports pci_express_x8] [get_bd_intf_pins bridge_to_host/pci_express_x8]

  # Create port connections
  connect_bd_net [get_bd_pins bridge_to_host/ui_clk] [get_bd_pins clock_generator/clk_in1]
  connect_bd_net [get_bd_pins M_AXI_Inter/ACLK] [get_bd_pins M_AXI_Inter/M00_ACLK] [get_bd_pins M_AXI_Inter/S00_ACLK] [get_bd_pins S_AXI_Inter/ACLK] [get_bd_pins S_AXI_Inter/M00_ACLK] [get_bd_pins S_AXI_Inter/S00_ACLK] [get_bd_pins bridge_to_host/clk_app] [get_bd_pins clock_generator/clk_app] [get_bd_pins system_reset/clk_app]
  connect_bd_net [get_bd_pins clock_generator/locked] [get_bd_pins system_reset/clk_gen_locked]
  connect_bd_net [get_bd_ports HBM_CATTRIP] [get_bd_pins HBM_CATTRIP_constant/dout]
  connect_bd_net [get_bd_ports pcie_perstn] [get_bd_pins bridge_to_host/pcie_perstn] [get_bd_pins clock_generator/resetn] [get_bd_pins system_reset/pcie_perstn]
  connect_bd_net [get_bd_pins M_AXI_Inter/ARESETN] [get_bd_pins S_AXI_Inter/ARESETN] [get_bd_pins system_reset/clk_app_rstn]
  connect_bd_net [get_bd_pins M_AXI_Inter/M00_ARESETN] [get_bd_pins M_AXI_Inter/S00_ARESETN] [get_bd_pins S_AXI_Inter/M00_ARESETN] [get_bd_pins S_AXI_Inter/S00_ARESETN] [get_bd_pins bridge_to_host/clk_app_rstn] [get_bd_pins system_reset/clk_app_rstn]

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

