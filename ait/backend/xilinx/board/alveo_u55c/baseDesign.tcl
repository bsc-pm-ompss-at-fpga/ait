
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
# bsc_axiu_addrInterleaver

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu55c-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:au55c:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name ${argv}_design

variable num_banks
set num_banks 32
variable QDMA_port
set QDMA_port 15
variable ompif_msg_send_port
set ompif_msg_send_port 14
variable ompif_msg_recv_0_port
set ompif_msg_recv_0_port 30
variable ompif_msg_recv_1_port
set ompif_msg_recv_1_port 31

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
bsc_axiu_addrInterleaver\
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
   CONFIG.pl_link_cap_max_link_speed {16.0_GT/s} \
   CONFIG.testname {mm} \
   CONFIG.tl_pf_enable_reg {1} \
 ] $QDMA

  # Create instance: const_1, and set properties
  set const_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1 ]

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {Custom} \
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

# Hierarchical cell: memory
proc create_hier_cell_memory { parentCell nameHier } {

  variable script_folder
  variable num_banks
  variable QDMA_port
  variable ompif_msg_send_port
  variable ompif_msg_recv_0_port
  variable ompif_msg_recv_1_port

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S15_AXI
  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S[format %02u $i]_AXI
    }
  }

  # Create pins
  create_bd_pin -dir I -type clk APB_PCLK
  create_bd_pin -dir I -type rst APB_PCLK_rstn
  create_bd_pin -dir O -from 0 -to 0 HBM_CATTRIP
  create_bd_pin -dir I -type clk HBM_REF_CLK
  create_bd_pin -dir I -type clk QDMA_aclk
  create_bd_pin -dir I -type rst QDMA_aclk_rstn
  create_bd_pin -dir I -type clk clk_app
  create_bd_pin -dir I -type rst clk_app_rstn

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
   CONFIG.USER_HBM_DENSITY {16GB} \
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
   CONFIG.USER_SAXI_00 {true} \
   CONFIG.USER_SAXI_01 {true} \
   CONFIG.USER_SAXI_02 {true} \
   CONFIG.USER_SAXI_03 {true} \
   CONFIG.USER_SAXI_04 {true} \
   CONFIG.USER_SAXI_05 {true} \
   CONFIG.USER_SAXI_06 {true} \
   CONFIG.USER_SAXI_07 {true} \
   CONFIG.USER_SAXI_08 {true} \
   CONFIG.USER_SAXI_09 {true} \
   CONFIG.USER_SAXI_10 {true} \
   CONFIG.USER_SAXI_11 {true} \
   CONFIG.USER_SAXI_12 {true} \
   CONFIG.USER_SAXI_13 {true} \
   CONFIG.USER_SAXI_14 {true} \
   CONFIG.USER_SAXI_15 {true} \
   CONFIG.USER_SAXI_16 {true} \
   CONFIG.USER_SAXI_17 {true} \
   CONFIG.USER_SAXI_18 {true} \
   CONFIG.USER_SAXI_19 {true} \
   CONFIG.USER_SAXI_20 {true} \
   CONFIG.USER_SAXI_21 {true} \
   CONFIG.USER_SAXI_22 {true} \
   CONFIG.USER_SAXI_23 {true} \
   CONFIG.USER_SAXI_24 {true} \
   CONFIG.USER_SAXI_25 {true} \
   CONFIG.USER_SAXI_26 {true} \
   CONFIG.USER_SAXI_27 {true} \
   CONFIG.USER_SAXI_28 {true} \
   CONFIG.USER_SAXI_29 {true} \
   CONFIG.USER_SAXI_30 {true} \
   CONFIG.USER_SAXI_31 {true} \
   CONFIG.USER_SINGLE_STACK_SELECTION {LEFT} \
   CONFIG.USER_SWITCH_ENABLE_00 {TRUE} \
   CONFIG.USER_SWITCH_ENABLE_01 {TRUE} \
   CONFIG.USER_TEMP_POLL_CNT_0 {100000} \
   CONFIG.USER_TEMP_POLL_CNT_1 {100000} \
 ] $HBM

  # Create interface connections
  connect_bd_intf_net -intf_net HBM_SAXI_15_8HI_m_axi [get_bd_intf_pins HBM/SAXI_15_8HI] [get_bd_intf_pins S15_AXI]

  # Create port connections
  connect_bd_net -net APB_PCLK_1 [get_bd_pins APB_PCLK] [get_bd_pins HBM/APB_0_PCLK] [get_bd_pins HBM/APB_1_PCLK]
  connect_bd_net -net HBM_CATTRIP_OR_Res [get_bd_pins HBM_CATTRIP] [get_bd_pins HBM_CATTRIP_OR/Res]
  connect_bd_net -net HBM_DRAM_0_STAT_CATTRIP [get_bd_pins HBM_CATTRIP_OR/Op1] [get_bd_pins HBM/DRAM_0_STAT_CATTRIP]
  connect_bd_net -net HBM_DRAM_1_STAT_CATTRIP [get_bd_pins HBM_CATTRIP_OR/Op2] [get_bd_pins HBM/DRAM_1_STAT_CATTRIP]
  connect_bd_net -net HBM_REF_CLK_1 [get_bd_pins HBM_REF_CLK] [get_bd_pins HBM/HBM_REF_CLK_0] [get_bd_pins HBM/HBM_REF_CLK_1]
  connect_bd_net -net aclk_2 [get_bd_pins QDMA_aclk] [get_bd_pins HBM/AXI_15_ACLK]
  connect_bd_net -net APB_peripheral_aresetn [get_bd_pins APB_PCLK_rstn] [get_bd_pins HBM/APB_0_PRESET_N] [get_bd_pins HBM/APB_1_PRESET_N]
  connect_bd_net -net QDMA_peripheral_aresetn [get_bd_pins QDMA_aclk_rstn] [get_bd_pins HBM/AXI_15_ARESET_N]

  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      connect_bd_intf_net -intf_net SAXI_[format %02u $i]_8HI [get_bd_intf_pins S[format %02u $i]_AXI] [get_bd_intf_pins HBM/SAXI_[format %02u $i]_8HI]
      connect_bd_net [get_bd_pins clk_app_rstn] [get_bd_pins HBM/AXI_[format %02u $i]_ARESET_N]
      connect_bd_net -net aclk_1 [get_bd_pins clk_app] [get_bd_pins HBM/AXI_[format %02u $i]_ACLK]
    }
  }

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: bridge_to_host
proc create_hier_cell_bridge_to_host { parentCell nameHier } {

  variable script_folder
  variable num_banks
  variable QDMA_port
  variable ompif_msg_send_port
  variable ompif_msg_recv_0_port
  variable ompif_msg_recv_1_port

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
  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S[format %02u $i]_AXI
    }
  }
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir I -type clk APB_PCLK
  create_bd_pin -dir I -type rst APB_PCLK_rstn
  create_bd_pin -dir O -from 0 -to 0 HBM_CATTRIP
  create_bd_pin -dir I -type clk HBM_REF_CLK
  create_bd_pin -dir I -type clk clk_app
  create_bd_pin -dir I -type rst clk_app_rstn
  create_bd_pin -dir I -type rst pcie_perstn

  # Create instance: memory
  create_hier_cell_memory $hier_obj memory

  # Create instance: QDMA
  create_hier_cell_QDMA $hier_obj QDMA

  # Create instance: QDMA_M_AXI_Inter, and set properties
  set QDMA_M_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect QDMA_M_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $QDMA_M_AXI_Inter

  # Create instance: QDMA_sys_reset, and set properties
  set QDMA_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset QDMA_sys_reset ]

  # Create instance: bridge_to_host_araddrInterleaver, and set properties
  set block_name bsc_axiu_addrInterleaver
  set block_cell_name bridge_to_host_araddrInterleaver
  if { [catch {set bridge_to_host_araddrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bridge_to_host_araddrInterleaver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: bridge_to_host_awaddrInterleaver, and set properties
  set block_name bsc_axiu_addrInterleaver
  set block_cell_name bridge_to_host_awaddrInterleaver
  if { [catch {set bridge_to_host_awaddrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bridge_to_host_awaddrInterleaver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create interface connections
  connect_bd_intf_net -intf_net QDMA_M_AXI_Inter_M00_AXI [get_bd_intf_pins memory/S15_AXI] [get_bd_intf_pins QDMA_M_AXI_Inter/M00_AXI]
  connect_bd_intf_net -intf_net QDMA_M_AXI [get_bd_intf_pins QDMA/M_AXI] [get_bd_intf_pins QDMA_M_AXI_Inter/S00_AXI]
  connect_bd_intf_net -intf_net QDMA_pci_express_x8 [get_bd_intf_pins pci_express_x8] [get_bd_intf_pins QDMA/pci_express_x8]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins QDMA/pcie_refclk]
  connect_bd_intf_net [get_bd_intf_pins M_AXI_LITE] -boundary_type upper [get_bd_intf_pins QDMA/M_AXI_LITE]

  # Create port connections
  connect_bd_net -net APB_PCLK_1 [get_bd_pins APB_PCLK] [get_bd_pins memory/APB_PCLK]
  connect_bd_net -net APB_PCLK_RSTN_1 [get_bd_pins APB_PCLK_rstn] [get_bd_pins memory/APB_PCLK_rstn]
  connect_bd_net -net HBM_CATTRIP_OR_Res [get_bd_pins HBM_CATTRIP] [get_bd_pins memory/HBM_CATTRIP]
  connect_bd_net -net HBM_REF_CLK_1 [get_bd_pins HBM_REF_CLK] [get_bd_pins memory/HBM_REF_CLK]
  connect_bd_net -net QDMA_QDMA_m_axi_araddr [get_bd_pins QDMA/QDMA_m_axi_araddr] [get_bd_pins bridge_to_host_araddrInterleaver/in_addr]
  connect_bd_net -net QDMA_QDMA_m_axi_awaddr [get_bd_pins QDMA/QDMA_m_axi_awaddr] [get_bd_pins bridge_to_host_awaddrInterleaver/in_addr]
  connect_bd_net -net QDMA_aclk [get_bd_pins memory/QDMA_aclk] [get_bd_pins QDMA/aclk] [get_bd_pins QDMA_sys_reset/slowest_sync_clk] [get_bd_pins QDMA_M_AXI_Inter/ACLK] [get_bd_pins QDMA_M_AXI_Inter/S00_ACLK] [get_bd_pins QDMA_M_AXI_Inter/M00_ACLK]
  connect_bd_net -net QDMA_aresetn [get_bd_pins QDMA/aresetn] [get_bd_pins QDMA_sys_reset/ext_reset_in]
  connect_bd_net -net QDMA_sys_reset_peripheral [get_bd_pins QDMA_sys_reset/peripheral_aresetn] [get_bd_pins memory/QDMA_aclk_rstn] [get_bd_pins QDMA_M_AXI_Inter/S00_ARESETN] [get_bd_pins QDMA_M_AXI_Inter/M00_ARESETN]
  connect_bd_net -net QDMA_sys_reset_interconnect [get_bd_pins QDMA_sys_reset/interconnect_aresetn] [get_bd_pins QDMA_M_AXI_Inter/ARESETN]
  connect_bd_net -net QDMA_s_axi_araddr [get_bd_pins QDMA_M_AXI_Inter/S00_AXI_araddr] [get_bd_pins bridge_to_host_araddrInterleaver/out_addr]
  connect_bd_net -net QDMA_s_axi_awaddr [get_bd_pins QDMA_M_AXI_Inter/S00_AXI_awaddr] [get_bd_pins bridge_to_host_awaddrInterleaver/out_addr]
  connect_bd_net -net aclk_1 [get_bd_pins clk_app] [get_bd_pins memory/clk_app]
  connect_bd_net -net pcie_perstn_1 [get_bd_pins pcie_perstn] [get_bd_pins QDMA/pcie_perstn]
  connect_bd_net -net peripheral_aresetn_1 [get_bd_pins clk_app_rstn] [get_bd_pins memory/clk_app_rstn]

  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      connect_bd_intf_net -intf_net memory_S[format %02u $i]_AXI [get_bd_intf_pins S[format %02u $i]_AXI] [get_bd_intf_pins memory/S[format %02u $i]_AXI]
    }
  }

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
  create_bd_pin -dir I clk_gen_slr0_locked
  create_bd_pin -dir I clk_gen_locked
  create_bd_pin -dir I -type clk clk_app
  create_bd_pin -dir I -type clk clk_100_slr0
  create_bd_pin -dir O -type rst clk_app_rstn
  create_bd_pin -dir O -type rst clk_100_slr0_rstn

  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_clk_app
  set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] [get_bd_cells proc_sys_reset_clk_app]
  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_clk_100_slr0
  set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] [get_bd_cells proc_sys_reset_clk_100_slr0]

  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/slowest_sync_clk] [get_bd_pins clk_app]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_100_slr0/slowest_sync_clk] [get_bd_pins clk_100_slr0]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/peripheral_aresetn] [get_bd_pins clk_app_rstn]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_100_slr0/peripheral_aresetn] [get_bd_pins clk_100_slr0_rstn]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/ext_reset_in] [get_bd_pins proc_sys_reset_clk_100_slr0/ext_reset_in] [get_bd_pins pcie_perstn]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_100_slr0/dcm_locked] [get_bd_pins clk_gen_slr0_locked]
  connect_bd_net [get_bd_pins proc_sys_reset_clk_app/dcm_locked] [get_bd_pins clk_gen_locked]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name
  variable num_banks
  variable QDMA_port
  variable ompif_msg_send_port
  variable ompif_msg_recv_0_port
  variable ompif_msg_recv_1_port

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

  # Create instance: M_AXI_Inter, and set properties
  set M_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect M_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.STRATEGY {1} \
 ] $M_AXI_Inter

  # Create instance: S_AXI_XX_Inter, and set properties
  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      set S_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect S_AXI_[format %02u $i]_Inter ]
      set_property -dict [ list \
       CONFIG.NUM_MI {1} \
       CONFIG.NUM_SI {1} \
     ] $S_AXI_Inter
    }
  }

  # Create instance: bridge_to_host
  create_hier_cell_bridge_to_host [current_bd_instance .] bridge_to_host

  # Create instance: system_reset
  create_hier_cell_system_reset [current_bd_instance .] system_reset

  # Create instance: clock_generator, and set properties
  set clock_generator [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clock_generator ]
  set_property -dict [ list \
   CONFIG.CLK_IN1_BOARD_INTERFACE {slr1_freerun_clk} \
   CONFIG.CLK_OUT1_PORT {clk_app} \
   CONFIG.NUM_OUT_CLKS {1} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN true \
 ] $clock_generator

  set clk_gen_slr0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_gen_slr0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 100 \
   CONFIG.CLKOUT1_USED true \
   CONFIG.CLK_OUT1_PORT clk_100 \
   CONFIG.CLK_IN1_BOARD_INTERFACE slr0_freerun_clk \
   CONFIG.NUM_OUT_CLKS 1 \
   CONFIG.PRIM_SOURCE Differential_clock_capable_pin \
   CONFIG.RESET_PORT resetn \
   CONFIG.RESET_TYPE ACTIVE_LOW \
   CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN true \
  ] $clk_gen_slr0

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins M_AXI_Inter/S00_AXI] [get_bd_intf_pins bridge_to_host/M_AXI_LITE]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins bridge_to_host/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_pcie_mgt [get_bd_intf_ports pci_express_x8] [get_bd_intf_pins bridge_to_host/pci_express_x8]
  connect_bd_intf_net -intf_net sysclk0_1 [get_bd_intf_ports sysclk0] [get_bd_intf_pins clk_gen_slr0/CLK_IN1_D]
  connect_bd_intf_net -intf_net sysclk1_1 [get_bd_intf_ports sysclk1] [get_bd_intf_pins clock_generator/CLK_IN1_D]

  # Create port connections
  connect_bd_net -net bridge_to_host_HBM_CATTRIP [get_bd_ports HBM_CATTRIP] [get_bd_pins bridge_to_host/HBM_CATTRIP]
  connect_bd_net -net clock_generator_apb_clk [get_bd_pins bridge_to_host/APB_PCLK] [get_bd_pins clk_gen_slr0/clk_100]
  connect_bd_net -net clock_generator_clk_out1 [get_bd_pins bridge_to_host/clk_app] [get_bd_pins clock_generator/clk_app]
  connect_bd_net [get_bd_pins bridge_to_host/QDMA/aclk] [get_bd_pins M_AXI_Inter/ACLK] [get_bd_pins M_AXI_Inter/S00_ACLK]
  connect_bd_net [get_bd_pins bridge_to_host/QDMA/aresetn] [get_bd_pins M_AXI_Inter/ARESETN] [get_bd_pins M_AXI_Inter/S00_ARESETN]
  connect_bd_net -net pcie_perstn_1 [get_bd_ports pcie_perstn] [get_bd_pins bridge_to_host/pcie_perstn] [get_bd_pins clk_gen_slr0/resetn] [get_bd_pins clock_generator/resetn]
  connect_bd_net [get_bd_pins bridge_to_host/clk_app_rstn] [get_bd_pins system_reset/clk_app_rstn]
  connect_bd_net [get_bd_pins bridge_to_host/HBM_REF_CLK] [get_bd_pins clk_gen_slr0/clk_100]
  connect_bd_net [get_bd_pins system_reset/clk_100_slr0_rstn] [get_bd_pins bridge_to_host/APB_PCLK_rstn]
  connect_bd_net [get_bd_pins clk_gen_slr0/clk_100] [get_bd_pins system_reset/clk_100_slr0]
  connect_bd_net [get_bd_pins clk_gen_slr0/locked] [get_bd_pins system_reset/clk_gen_slr0_locked]
  connect_bd_net [get_bd_pins clock_generator/clk_app] [get_bd_pins system_reset/clk_app]
  connect_bd_net [get_bd_pins clock_generator/locked] [get_bd_pins system_reset/clk_gen_locked]
  connect_bd_net [get_bd_ports pcie_perstn] [get_bd_pins system_reset/pcie_perstn]

  for {set i 0} {$i < $num_banks} {incr i} {
    if {$i != $QDMA_port && (!$AIT::ompif || ($i != $ompif_msg_send_port && $i != $ompif_msg_recv_0_port && $i != $ompif_msg_recv_1_port))} {
      connect_bd_intf_net -intf_net S_AXI_[format %02u $i]_AXI [get_bd_intf_pins S_AXI_[format %02u $i]_Inter/M00_AXI] [get_bd_intf_pins bridge_to_host/S[format %02u $i]_AXI]
      connect_bd_net -net clock_generator_clk_out1 [get_bd_pins S_AXI_[format %02u $i]_Inter/ACLK] [get_bd_pins S_AXI_[format %02u $i]_Inter/M00_ACLK] [get_bd_pins S_AXI_[format %02u $i]_Inter/S00_ACLK] [get_bd_pins clock_generator/clk_app]
      connect_bd_net [get_bd_pins S_AXI_[format %02u $i]_Inter/ARESETN] [get_bd_pins system_reset/clk_app_rstn]
      connect_bd_net [get_bd_pins S_AXI_[format %02u $i]_Inter/M00_ARESETN] [get_bd_pins S_AXI_[format %02u $i]_Inter/S00_ARESETN] [get_bd_pins system_reset/clk_app_rstn]
    }
  }

  # Restore current instance
  current_bd_instance $oldCurInst

}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

