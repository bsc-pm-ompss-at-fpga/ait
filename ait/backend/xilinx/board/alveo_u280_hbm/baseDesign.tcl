
################################################################
# This is a generated script based on design: alveo_u280_hbm_base_design
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
set scripts_vivado_version 2020.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source alveo_u280_hbm_base_design_script.tcl


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
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:util_vector_logic:*\
xilinx.com:ip:hbm:*\
xilinx.com:ip:qdma:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:axi_dwidth_converter:*\
xilinx.com:ip:axi_protocol_converter:*\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
addrInterleaver\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: S_AXI_QDMA
proc create_hier_cell_S_AXI_QDMA { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_S_AXI_QDMA() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI


  # Create pins
  create_bd_pin -dir I -type clk QDMA_aclk
  create_bd_pin -dir I -type rst QDMA_peripheral_aresetn
  create_bd_pin -dir I -from 63 -to 0 S_AXI_QDMA_araddr
  create_bd_pin -dir I -from 63 -to 0 S_AXI_QDMA_awaddr

  # Create instance: HBM_data_width_converter, and set properties
  set HBM_data_width_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter HBM_data_width_converter ]

  # Create instance: HBM_protocol_converter, and set properties
  set HBM_protocol_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter HBM_protocol_converter ]

  # Create interface connections
  connect_bd_intf_net -intf_net HBM_data_width_converter_M_AXI [get_bd_intf_pins HBM_data_width_converter/M_AXI] [get_bd_intf_pins HBM_protocol_converter/S_AXI]
  connect_bd_intf_net -intf_net HBM_protocol_converter_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins HBM_protocol_converter/M_AXI]
  connect_bd_intf_net -intf_net S_AXI_QDMA [get_bd_intf_pins S_AXI] [get_bd_intf_pins HBM_data_width_converter/S_AXI]

  # Create port connections
  connect_bd_net -net S_AXI_QDMA_araddr_2 [get_bd_pins S_AXI_QDMA_araddr] [get_bd_pins HBM_data_width_converter/s_axi_araddr]
  connect_bd_net -net S_AXI_QDMA_awaddr_2 [get_bd_pins S_AXI_QDMA_awaddr] [get_bd_pins HBM_data_width_converter/s_axi_awaddr]
  connect_bd_net -net aclk_2 [get_bd_pins QDMA_aclk] [get_bd_pins HBM_data_width_converter/s_axi_aclk] [get_bd_pins HBM_protocol_converter/aclk]
  connect_bd_net -net peripheral_aresetn_2 [get_bd_pins QDMA_peripheral_aresetn] [get_bd_pins HBM_data_width_converter/s_axi_aresetn] [get_bd_pins HBM_protocol_converter/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: QDMA
proc create_hier_cell_QDMA { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_QDMA() - Empty argument(s)!"}
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
  connect_bd_net -net const_1_dout [get_bd_pins QDMA/tm_dsc_sts_rdy] [get_bd_pins const_1/dout]
  connect_bd_net -net pcie_perstn_1 [get_bd_pins pcie_perstn] [get_bd_pins QDMA/soft_reset_n] [get_bd_pins QDMA/sys_rst_n]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins QDMA/sys_clk] [get_bd_pins util_ds_buf/IBUF_DS_ODIV2]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins QDMA/sys_clk_gt] [get_bd_pins util_ds_buf/IBUF_OUT]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: HBM
proc create_hier_cell_HBM { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_HBM() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_QDMA


  # Create pins
  create_bd_pin -dir I -type clk APB_PCLK
  create_bd_pin -dir O -from 0 -to 0 HBM_CATTRIP
  create_bd_pin -dir I -type clk HBM_REF_CLK
  create_bd_pin -dir I -type clk QDMA_aclk
  create_bd_pin -dir I -type rst QDMA_peripheral_aresetn
  create_bd_pin -dir I -from 63 -to 0 S_AXI_QDMA_araddr
  create_bd_pin -dir I -from 63 -to 0 S_AXI_QDMA_awaddr
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst peripheral_aresetn

  # Create instance: HBM_CATTRIP_OR, and set properties
  set HBM_CATTRIP_OR [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic HBM_CATTRIP_OR ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $HBM_CATTRIP_OR

  # Create instance: HBM, and set properties
  set HBM [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm HBM ]
  set_property -dict [ list \
   CONFIG.USER_APB_EN {false} \
   CONFIG.USER_APB_PCLK_0 {100} \
   CONFIG.USER_APB_PCLK_1 {100} \
   CONFIG.USER_APB_PCLK_PERIOD_0 {10.0} \
   CONFIG.USER_APB_PCLK_PERIOD_1 {10.0} \
   CONFIG.USER_HBM_CP_0 {6} \
   CONFIG.USER_HBM_CP_1 {6} \
   CONFIG.USER_HBM_DENSITY {8GB} \
   CONFIG.USER_HBM_FBDIV_0 {36} \
   CONFIG.USER_HBM_FBDIV_1 {36} \
   CONFIG.USER_HBM_HEX_CP_RES_0 {0x0000A600} \
   CONFIG.USER_HBM_HEX_CP_RES_1 {0x0000A600} \
   CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_0 {0x00000902} \
   CONFIG.USER_HBM_HEX_FBDIV_CLKOUTDIV_1 {0x00000902} \
   CONFIG.USER_HBM_HEX_LOCK_FB_REF_DLY_1 {0x00001f1f} \
   CONFIG.USER_HBM_LOCK_FB_DLY_1 {31} \
   CONFIG.USER_HBM_LOCK_REF_DLY_1 {31} \
   CONFIG.USER_HBM_REF_CLK_0 {100} \
   CONFIG.USER_HBM_REF_CLK_1 {100} \
   CONFIG.USER_HBM_REF_CLK_PS_0 {5000.00} \
   CONFIG.USER_HBM_REF_CLK_PS_1 {5000.00} \
   CONFIG.USER_HBM_REF_CLK_XDC_0 {10.00} \
   CONFIG.USER_HBM_REF_CLK_XDC_1 {10.00} \
   CONFIG.USER_HBM_RES_1 {10} \
   CONFIG.USER_HBM_STACK {2} \
   CONFIG.USER_MC0_EN_DATA_MASK {true} \
   CONFIG.USER_MC0_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC0_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC10_EN_DATA_MASK {true} \
   CONFIG.USER_MC10_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC10_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC11_EN_DATA_MASK {true} \
   CONFIG.USER_MC11_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC11_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC12_EN_DATA_MASK {true} \
   CONFIG.USER_MC12_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC12_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC13_EN_DATA_MASK {true} \
   CONFIG.USER_MC13_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC13_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC14_EN_DATA_MASK {true} \
   CONFIG.USER_MC14_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC14_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC15_EN_DATA_MASK {true} \
   CONFIG.USER_MC15_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC15_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC1_EN_DATA_MASK {true} \
   CONFIG.USER_MC1_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC1_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC2_EN_DATA_MASK {true} \
   CONFIG.USER_MC2_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC2_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC3_EN_DATA_MASK {true} \
   CONFIG.USER_MC3_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC3_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC4_EN_DATA_MASK {true} \
   CONFIG.USER_MC4_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC4_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC5_EN_DATA_MASK {true} \
   CONFIG.USER_MC5_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC5_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC6_EN_DATA_MASK {true} \
   CONFIG.USER_MC6_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC6_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC7_EN_DATA_MASK {true} \
   CONFIG.USER_MC7_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC7_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC8_EN_DATA_MASK {true} \
   CONFIG.USER_MC8_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC8_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC9_EN_DATA_MASK {true} \
   CONFIG.USER_MC9_MAINTAIN_COHERENCY {true} \
   CONFIG.USER_MC9_TRAFFIC_OPTION {Linear} \
   CONFIG.USER_MC_ENABLE_08 {TRUE} \
   CONFIG.USER_MC_ENABLE_09 {TRUE} \
   CONFIG.USER_MC_ENABLE_10 {TRUE} \
   CONFIG.USER_MC_ENABLE_11 {TRUE} \
   CONFIG.USER_MC_ENABLE_12 {TRUE} \
   CONFIG.USER_MC_ENABLE_13 {TRUE} \
   CONFIG.USER_MC_ENABLE_14 {TRUE} \
   CONFIG.USER_MC_ENABLE_15 {TRUE} \
   CONFIG.USER_MC_ENABLE_APB_01 {TRUE} \
   CONFIG.USER_MEMORY_DISPLAY {8192} \
   CONFIG.USER_PHY_ENABLE_08 {TRUE} \
   CONFIG.USER_PHY_ENABLE_09 {TRUE} \
   CONFIG.USER_PHY_ENABLE_10 {TRUE} \
   CONFIG.USER_PHY_ENABLE_11 {TRUE} \
   CONFIG.USER_PHY_ENABLE_12 {TRUE} \
   CONFIG.USER_PHY_ENABLE_13 {TRUE} \
   CONFIG.USER_PHY_ENABLE_14 {TRUE} \
   CONFIG.USER_PHY_ENABLE_15 {TRUE} \
   CONFIG.USER_SAXI_00 {false} \
   CONFIG.USER_SAXI_01 {false} \
   CONFIG.USER_SAXI_02 {false} \
   CONFIG.USER_SAXI_03 {false} \
   CONFIG.USER_SAXI_04 {false} \
   CONFIG.USER_SAXI_05 {false} \
   CONFIG.USER_SAXI_06 {false} \
   CONFIG.USER_SAXI_07 {false} \
   CONFIG.USER_SAXI_08 {false} \
   CONFIG.USER_SAXI_09 {false} \
   CONFIG.USER_SAXI_10 {false} \
   CONFIG.USER_SAXI_11 {false} \
   CONFIG.USER_SAXI_12 {false} \
   CONFIG.USER_SAXI_13 {false} \
   CONFIG.USER_SAXI_14 {false} \
   CONFIG.USER_SAXI_15 {true} \
   CONFIG.USER_SAXI_16 {false} \
   CONFIG.USER_SAXI_17 {false} \
   CONFIG.USER_SAXI_18 {false} \
   CONFIG.USER_SAXI_19 {false} \
   CONFIG.USER_SAXI_20 {false} \
   CONFIG.USER_SAXI_21 {false} \
   CONFIG.USER_SAXI_22 {false} \
   CONFIG.USER_SAXI_23 {false} \
   CONFIG.USER_SAXI_24 {false} \
   CONFIG.USER_SAXI_25 {false} \
   CONFIG.USER_SAXI_26 {false} \
   CONFIG.USER_SAXI_27 {false} \
   CONFIG.USER_SAXI_28 {false} \
   CONFIG.USER_SAXI_29 {false} \
   CONFIG.USER_SAXI_30 {false} \
   CONFIG.USER_SAXI_31 {false} \
   CONFIG.USER_SINGLE_STACK_SELECTION {LEFT} \
   CONFIG.USER_SWITCH_ENABLE_00 {TRUE} \
   CONFIG.USER_SWITCH_ENABLE_01 {TRUE} \
   CONFIG.USER_TEMP_POLL_CNT_0 {100000} \
   CONFIG.USER_TEMP_POLL_CNT_1 {100000} \
 ] $HBM

  # Create instance: S_AXI_QDMA
  create_hier_cell_S_AXI_QDMA $hier_obj S_AXI_QDMA

  # Create interface connections
  connect_bd_intf_net -intf_net HBM_RAMA_m_axi [get_bd_intf_pins HBM/SAXI_15] [get_bd_intf_pins S_AXI_QDMA/M_AXI]
  connect_bd_intf_net -intf_net S_AXI_QDMA [get_bd_intf_pins S_AXI_QDMA] [get_bd_intf_pins S_AXI_QDMA/S_AXI]

  # Create port connections
  connect_bd_net -net APB_PCLK_1 [get_bd_pins APB_PCLK] [get_bd_pins HBM/APB_0_PCLK] [get_bd_pins HBM/APB_1_PCLK]
  connect_bd_net -net HBM_CATTRIP_OR_Res [get_bd_pins HBM_CATTRIP] [get_bd_pins HBM_CATTRIP_OR/Res]
  connect_bd_net -net HBM_DRAM_0_STAT_CATTRIP [get_bd_pins HBM_CATTRIP_OR/Op1] [get_bd_pins HBM/DRAM_0_STAT_CATTRIP]
  connect_bd_net -net HBM_DRAM_1_STAT_CATTRIP [get_bd_pins HBM_CATTRIP_OR/Op2] [get_bd_pins HBM/DRAM_1_STAT_CATTRIP]
  connect_bd_net -net HBM_REF_CLK_1 [get_bd_pins HBM_REF_CLK] [get_bd_pins HBM/HBM_REF_CLK_0] [get_bd_pins HBM/HBM_REF_CLK_1]
  connect_bd_net -net S_AXI_QDMA_araddr_2 [get_bd_pins S_AXI_QDMA_araddr] [get_bd_pins S_AXI_QDMA/S_AXI_QDMA_araddr]
  connect_bd_net -net S_AXI_QDMA_awaddr_2 [get_bd_pins S_AXI_QDMA_awaddr] [get_bd_pins S_AXI_QDMA/S_AXI_QDMA_awaddr]
  connect_bd_net -net aclk_2 [get_bd_pins QDMA_aclk] [get_bd_pins HBM/AXI_15_ACLK] [get_bd_pins S_AXI_QDMA/QDMA_aclk]
  connect_bd_net -net peripheral_aresetn_1 [get_bd_pins peripheral_aresetn] [get_bd_pins HBM/APB_0_PRESET_N] [get_bd_pins HBM/APB_1_PRESET_N]
  connect_bd_net -net peripheral_aresetn_2 [get_bd_pins QDMA_peripheral_aresetn] [get_bd_pins HBM/AXI_15_ARESET_N] [get_bd_pins S_AXI_QDMA/QDMA_peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: bridge_to_host
proc create_hier_cell_bridge_to_host { parentCell nameHier } {

  variable script_folder

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

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LITE

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir I -type clk APB_PCLK
  create_bd_pin -dir O -from 0 -to 0 HBM_CATTRIP
  create_bd_pin -dir I -type clk HBM_REF_CLK
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst interconnect_aresetn
  create_bd_pin -dir I -type rst pcie_perstn
  create_bd_pin -dir I -type rst peripheral_aresetn

  # Create instance: HBM
  create_hier_cell_HBM $hier_obj HBM

  # Create instance: QDMA
  create_hier_cell_QDMA $hier_obj QDMA

  # Create instance: QDMA_M_AXI_LITE_Inter, and set properties
  set QDMA_M_AXI_LITE_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect QDMA_M_AXI_LITE_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $QDMA_M_AXI_LITE_Inter

  # Create instance: bridge_to_host_addrInterleaver, and set properties
  set block_name addrInterleaver
  set block_cell_name bridge_to_host_addrInterleaver
  if { [catch {set bridge_to_host_addrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bridge_to_host_addrInterleaver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create interface connections
  connect_bd_intf_net -intf_net QDMA_M_AXI [get_bd_intf_pins HBM/S_AXI_QDMA] [get_bd_intf_pins QDMA/M_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI_LITE_Inter_M00_AXI [get_bd_intf_pins M_AXI_LITE] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/M00_AXI]
  connect_bd_intf_net -intf_net QDMA_pci_express_x8 [get_bd_intf_pins pci_express_x8] [get_bd_intf_pins QDMA/pci_express_x8]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins QDMA/M_AXI_LITE] [get_bd_intf_pins QDMA_M_AXI_LITE_Inter/S00_AXI]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins QDMA/pcie_refclk]

  # Create port connections
  connect_bd_net -net APB_PCLK_1 [get_bd_pins APB_PCLK] [get_bd_pins HBM/APB_PCLK]
  connect_bd_net -net HBM_CATTRIP_OR_Res [get_bd_pins HBM_CATTRIP] [get_bd_pins HBM/HBM_CATTRIP]
  connect_bd_net -net HBM_REF_CLK_1 [get_bd_pins HBM_REF_CLK] [get_bd_pins HBM/HBM_REF_CLK]
  connect_bd_net -net QDMA_QDMA_m_axi_araddr [get_bd_pins QDMA/QDMA_m_axi_araddr] [get_bd_pins bridge_to_host_addrInterleaver/in_araddr]
  connect_bd_net -net QDMA_QDMA_m_axi_awaddr [get_bd_pins QDMA/QDMA_m_axi_awaddr] [get_bd_pins bridge_to_host_addrInterleaver/in_awaddr]
  connect_bd_net -net QDMA_aclk [get_bd_pins HBM/QDMA_aclk] [get_bd_pins QDMA/aclk] [get_bd_pins QDMA_M_AXI_LITE_Inter/S00_ACLK]
  connect_bd_net -net QDMA_aresetn [get_bd_pins HBM/QDMA_peripheral_aresetn] [get_bd_pins QDMA/aresetn] [get_bd_pins QDMA_M_AXI_LITE_Inter/S00_ARESETN]
  connect_bd_net -net QDMA_s_axi_araddr [get_bd_pins HBM/S_AXI_QDMA_araddr] [get_bd_pins bridge_to_host_addrInterleaver/out_araddr]
  connect_bd_net -net QDMA_s_axi_awaddr [get_bd_pins HBM/S_AXI_QDMA_awaddr] [get_bd_pins bridge_to_host_addrInterleaver/out_awaddr]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins HBM/aclk] [get_bd_pins QDMA_M_AXI_LITE_Inter/ACLK] [get_bd_pins QDMA_M_AXI_LITE_Inter/M00_ACLK]
  connect_bd_net -net interconnect_aresetn_1 [get_bd_pins interconnect_aresetn] [get_bd_pins QDMA_M_AXI_LITE_Inter/ARESETN]
  connect_bd_net -net pcie_perstn_1 [get_bd_pins pcie_perstn] [get_bd_pins QDMA/pcie_perstn]
  connect_bd_net -net peripheral_aresetn_1 [get_bd_pins peripheral_aresetn] [get_bd_pins HBM/peripheral_aresetn] [get_bd_pins QDMA_M_AXI_LITE_Inter/M00_ARESETN]

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
  set pci_express_x8 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8 ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk

  set sysclk0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sysclk0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $sysclk0

  set sysclk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sysclk1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $sysclk1


  # Create ports
  set HBM_CATTRIP [ create_bd_port -dir O -from 0 -to 0 HBM_CATTRIP ]
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn

  # Create instance: M_AXI_master_Inter, and set properties
  set M_AXI_master_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect M_AXI_master_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.STRATEGY {1} \
 ] $M_AXI_master_Inter

  # Create instance: bridge_to_host
  create_hier_cell_bridge_to_host [current_bd_instance .] bridge_to_host

  # Create instance: clock_generator, and set properties
  set clock_generator [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clock_generator ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
   CONFIG.CLKOUT1_JITTER {115.831} \
   CONFIG.CLKOUT1_PHASE_ERROR {87.180} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
   CONFIG.CLKOUT2_JITTER {132.683} \
   CONFIG.CLKOUT2_PHASE_ERROR {87.180} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sysclk0} \
   CONFIG.CLK_OUT2_PORT {apb_clk} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {24} \
   CONFIG.NUM_OUT_CLKS {2} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.RESET_BOARD_INTERFACE {resetn} \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
 ] $clock_generator

  # Create instance: processor_system_reset, and set properties
  set processor_system_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset processor_system_reset ]

  # Create instance: sysclk1_ds_buf, and set properties
  set sysclk1_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf sysclk1_ds_buf ]

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins M_AXI_master_Inter/S00_AXI] [get_bd_intf_pins bridge_to_host/M_AXI_LITE]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins bridge_to_host/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_ports pci_express_x8] [get_bd_intf_pins bridge_to_host/pci_express_x8]
  connect_bd_intf_net -intf_net sysclk0_1 [get_bd_intf_ports sysclk0] [get_bd_intf_pins clock_generator/CLK_IN1_D]
  connect_bd_intf_net -intf_net sysclk1_1 [get_bd_intf_ports sysclk1] [get_bd_intf_pins sysclk1_ds_buf/CLK_IN_D]

  # Create port connections
  connect_bd_net -net bridge_to_host_HBM_CATTRIP [get_bd_ports HBM_CATTRIP] [get_bd_pins bridge_to_host/HBM_CATTRIP]
  connect_bd_net -net clock_generator_apb_clk [get_bd_pins bridge_to_host/APB_PCLK] [get_bd_pins clock_generator/apb_clk]
  connect_bd_net -net clock_generator_clk_out1 [get_bd_pins M_AXI_master_Inter/ACLK] [get_bd_pins M_AXI_master_Inter/S00_ACLK] [get_bd_pins bridge_to_host/aclk] [get_bd_pins clock_generator/clk_out1] [get_bd_pins processor_system_reset/slowest_sync_clk]
  connect_bd_net -net clock_generator_locked [get_bd_pins clock_generator/locked] [get_bd_pins processor_system_reset/dcm_locked]
  connect_bd_net -net pcie_perstn_1 [get_bd_ports pcie_perstn] [get_bd_pins bridge_to_host/pcie_perstn] [get_bd_pins clock_generator/resetn] [get_bd_pins processor_system_reset/ext_reset_in]
  connect_bd_net -net processor_system_reset_interconnect_aresetn [get_bd_pins M_AXI_master_Inter/ARESETN] [get_bd_pins bridge_to_host/interconnect_aresetn] [get_bd_pins processor_system_reset/interconnect_aresetn]
  connect_bd_net -net processor_system_reset_peripheral_aresetn [get_bd_pins M_AXI_master_Inter/S00_ARESETN] [get_bd_pins bridge_to_host/peripheral_aresetn] [get_bd_pins processor_system_reset/peripheral_aresetn]
  connect_bd_net -net sysclk1_ds_buf_IBUF_OUT [get_bd_pins bridge_to_host/HBM_REF_CLK] [get_bd_pins sysclk1_ds_buf/IBUF_OUT]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM00] -force
  assign_bd_address -offset 0x10000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM01] -force
  assign_bd_address -offset 0x20000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM02] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM03] -force
  assign_bd_address -offset 0x40000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM04] -force
  assign_bd_address -offset 0x50000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM05] -force
  assign_bd_address -offset 0x60000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM06] -force
  assign_bd_address -offset 0x70000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM07] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM08] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM09] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM10] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM11] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM12] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM13] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM14] -force
  assign_bd_address -offset 0xF0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM15] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM16] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM17] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM18] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM19] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM20] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM21] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM22] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM23] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM24] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM25] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM26] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM27] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM28] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM29] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM30] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces bridge_to_host/QDMA/QDMA/M_AXI] [get_bd_addr_segs bridge_to_host/HBM/HBM/SAXI_15/HBM_MEM31] -force


  # Restore current instance
  current_bd_instance $oldCurInst

}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

