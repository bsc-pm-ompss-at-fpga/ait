
################################################################
# This is a generated script based on design: euroexa_maxilink_base_design
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
# source euroexa_maxilink_base_design_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# addrInterleaver

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu9p-fsgd2104-2-i
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
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:blk_mem_gen:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:clk_wiz:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:axi_gpio:*\
xilinx.com:ip:xlslice:*\
xilinx.com:ip:xlconcat:*\
xilinx.com:ip:util_vector_logic:*\
manchester.ac.uk:maxilink:maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz:*\
xilinx.com:ip:axi_register_slice:*\
xilinx.com:ip:jtag_axi:*\
xilinx.com:ip:ddr4:*\
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


# Hierarchical cell: DDR_3
proc create_hier_cell_DDR_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DDR_3() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_uDIMM


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_ui_clk
  create_bd_pin -dir I -type rst aux_reset_in
  create_bd_pin -dir O init_calib_complete
  create_bd_pin -dir I -type rst sys_rst

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 DDR ]
  set_property -dict [ list \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_AxiNarrowBurst {true} \
   CONFIG.C0.DDR4_CasLatency {11} \
   CONFIG.C0.DDR4_CasWriteLatency {11} \
   CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_InputClockPeriod {3334} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72AZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {UDIMMs} \
   CONFIG.C0.DDR4_TimePeriod {1250} \
 ] $DDR

  # Create instance: DDR_S_AXI_regslice, and set properties
  set DDR_S_AXI_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice DDR_S_AXI_regslice ]

  # Create instance: DDR_proc_sys_reset, and set properties
  set DDR_proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset DDR_proc_sys_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $DDR_proc_sys_reset

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_C0_DDR4 [get_bd_intf_pins DDR_uDIMM] [get_bd_intf_pins DDR/C0_DDR4]
  connect_bd_intf_net -intf_net DDR_SYS_CLK_1 [get_bd_intf_pins DDR_SYS_CLK] [get_bd_intf_pins DDR/C0_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_S_AXI_1 [get_bd_intf_pins DDR_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/S_AXI]
  connect_bd_intf_net -intf_net DDR_S_AXI_CTRL_1 [get_bd_intf_pins DDR_S_AXI_CTRL] [get_bd_intf_pins DDR/C0_DDR4_S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_S_AXI_regslice_M_AXI [get_bd_intf_pins DDR/C0_DDR4_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/M_AXI]

  # Create port connections
  connect_bd_net -net DDR_c0_ddr4_ui_clk [get_bd_pins DDR_ui_clk] [get_bd_pins DDR/c0_ddr4_ui_clk] [get_bd_pins DDR_S_AXI_regslice/aclk] [get_bd_pins DDR_proc_sys_reset/slowest_sync_clk]
  connect_bd_net -net DDR_c0_ddr4_ui_clk_sync_rst [get_bd_pins DDR/c0_ddr4_ui_clk_sync_rst] [get_bd_pins DDR_proc_sys_reset/ext_reset_in]
  connect_bd_net -net DDR_c0_init_calib_complete [get_bd_pins init_calib_complete] [get_bd_pins DDR/c0_init_calib_complete]
  connect_bd_net -net DDR_proc_sys_reset_peripheral_aresetn [get_bd_pins DDR_peripheral_aresetn] [get_bd_pins DDR/c0_ddr4_aresetn] [get_bd_pins DDR_S_AXI_regslice/aresetn] [get_bd_pins DDR_proc_sys_reset/peripheral_aresetn]
  connect_bd_net -net aux_reset_in_1 [get_bd_pins aux_reset_in] [get_bd_pins DDR_proc_sys_reset/aux_reset_in]
  connect_bd_net -net sys_rst_1 [get_bd_pins sys_rst] [get_bd_pins DDR/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DDR_2
proc create_hier_cell_DDR_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DDR_2() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_uDIMM


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_ui_clk
  create_bd_pin -dir I -type rst aux_reset_in
  create_bd_pin -dir O init_calib_complete
  create_bd_pin -dir I -type rst sys_rst

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 DDR ]
  set_property -dict [ list \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_AxiNarrowBurst {true} \
   CONFIG.C0.DDR4_CasLatency {11} \
   CONFIG.C0.DDR4_CasWriteLatency {11} \
   CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_InputClockPeriod {3334} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72AZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {UDIMMs} \
   CONFIG.C0.DDR4_TimePeriod {1250} \
 ] $DDR

  # Create instance: DDR_S_AXI_regslice, and set properties
  set DDR_S_AXI_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice DDR_S_AXI_regslice ]

  # Create instance: DDR_proc_sys_reset, and set properties
  set DDR_proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset DDR_proc_sys_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $DDR_proc_sys_reset

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_C0_DDR4 [get_bd_intf_pins DDR_uDIMM] [get_bd_intf_pins DDR/C0_DDR4]
  connect_bd_intf_net -intf_net DDR_SYS_CLK_1 [get_bd_intf_pins DDR_SYS_CLK] [get_bd_intf_pins DDR/C0_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_S_AXI_1 [get_bd_intf_pins DDR_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/S_AXI]
  connect_bd_intf_net -intf_net DDR_S_AXI_CTRL_1 [get_bd_intf_pins DDR_S_AXI_CTRL] [get_bd_intf_pins DDR/C0_DDR4_S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_S_AXI_regslice_M_AXI [get_bd_intf_pins DDR/C0_DDR4_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/M_AXI]

  # Create port connections
  connect_bd_net -net DDR_c0_ddr4_ui_clk [get_bd_pins DDR_ui_clk] [get_bd_pins DDR/c0_ddr4_ui_clk] [get_bd_pins DDR_S_AXI_regslice/aclk] [get_bd_pins DDR_proc_sys_reset/slowest_sync_clk]
  connect_bd_net -net DDR_c0_ddr4_ui_clk_sync_rst [get_bd_pins DDR/c0_ddr4_ui_clk_sync_rst] [get_bd_pins DDR_proc_sys_reset/ext_reset_in]
  connect_bd_net -net DDR_c0_init_calib_complete [get_bd_pins init_calib_complete] [get_bd_pins DDR/c0_init_calib_complete]
  connect_bd_net -net DDR_proc_sys_reset_peripheral_aresetn [get_bd_pins DDR_peripheral_aresetn] [get_bd_pins DDR/c0_ddr4_aresetn] [get_bd_pins DDR_S_AXI_regslice/aresetn] [get_bd_pins DDR_proc_sys_reset/peripheral_aresetn]
  connect_bd_net -net aux_reset_in_1 [get_bd_pins aux_reset_in] [get_bd_pins DDR_proc_sys_reset/aux_reset_in]
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_uDIMM


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_ui_clk
  create_bd_pin -dir I -type rst aux_reset_in
  create_bd_pin -dir O init_calib_complete
  create_bd_pin -dir I -type rst sys_rst

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 DDR ]
  set_property -dict [ list \
   CONFIG.C0.DDR4_AxiAddressWidth {34} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_AxiNarrowBurst {true} \
   CONFIG.C0.DDR4_CasLatency {11} \
   CONFIG.C0.DDR4_CasWriteLatency {11} \
   CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} \
   CONFIG.C0.DDR4_DataWidth {72} \
   CONFIG.C0.DDR4_InputClockPeriod {3334} \
   CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72AZ-2G3} \
   CONFIG.C0.DDR4_MemoryType {UDIMMs} \
   CONFIG.C0.DDR4_TimePeriod {1250} \
 ] $DDR

  # Create instance: DDR_S_AXI_regslice, and set properties
  set DDR_S_AXI_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice DDR_S_AXI_regslice ]

  # Create instance: DDR_proc_sys_reset, and set properties
  set DDR_proc_sys_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset DDR_proc_sys_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $DDR_proc_sys_reset

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_C0_DDR4 [get_bd_intf_pins DDR_uDIMM] [get_bd_intf_pins DDR/C0_DDR4]
  connect_bd_intf_net -intf_net DDR_SYS_CLK_1 [get_bd_intf_pins DDR_SYS_CLK] [get_bd_intf_pins DDR/C0_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_S_AXI_1 [get_bd_intf_pins DDR_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/S_AXI]
  connect_bd_intf_net -intf_net DDR_S_AXI_CTRL_1 [get_bd_intf_pins DDR_S_AXI_CTRL] [get_bd_intf_pins DDR/C0_DDR4_S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_S_AXI_regslice_M_AXI [get_bd_intf_pins DDR/C0_DDR4_S_AXI] [get_bd_intf_pins DDR_S_AXI_regslice/M_AXI]

  # Create port connections
  connect_bd_net -net DDR_c0_ddr4_ui_clk [get_bd_pins DDR_ui_clk] [get_bd_pins DDR/c0_ddr4_ui_clk] [get_bd_pins DDR_S_AXI_regslice/aclk] [get_bd_pins DDR_proc_sys_reset/slowest_sync_clk]
  connect_bd_net -net DDR_c0_ddr4_ui_clk_sync_rst [get_bd_pins DDR/c0_ddr4_ui_clk_sync_rst] [get_bd_pins DDR_proc_sys_reset/ext_reset_in]
  connect_bd_net -net DDR_c0_init_calib_complete [get_bd_pins init_calib_complete] [get_bd_pins DDR/c0_init_calib_complete]
  connect_bd_net -net DDR_proc_sys_reset_peripheral_aresetn [get_bd_pins DDR_peripheral_aresetn] [get_bd_pins DDR/c0_ddr4_aresetn] [get_bd_pins DDR_S_AXI_regslice/aresetn] [get_bd_pins DDR_proc_sys_reset/peripheral_aresetn]
  connect_bd_net -net aux_reset_in_1 [get_bd_pins aux_reset_in] [get_bd_pins DDR_proc_sys_reset/aux_reset_in]
  connect_bd_net -net sys_rst_1 [get_bd_pins sys_rst] [get_bd_pins DDR/sys_rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: peripherals
proc create_hier_cell_peripherals { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_peripherals() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_BRAM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_gpio


  # Create pins
  create_bd_pin -dir I -type clk BRAM_aclk
  create_bd_pin -dir I -type rst BRAM_aresetn
  create_bd_pin -dir I -from 0 -to 0 BUFG_GT_CEMASK
  create_bd_pin -dir I -from 0 -to 0 -type clk BUFG_GT_I
  create_bd_pin -dir O -from 0 -to 0 -type clk BUFG_GT_O
  create_bd_pin -dir I -from 3 -to 0 clk_glitch
  create_bd_pin -dir I -from 3 -to 0 clk_oor
  create_bd_pin -dir I -from 3 -to 0 clk_stop
  create_bd_pin -dir I -type clk gpio_aclk
  create_bd_pin -dir I -type rst gpio_aresetn
  create_bd_pin -dir I -type clk jtag_aclk
  create_bd_pin -dir I -type rst jtag_aresetn

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {13} \
 ] $axi_gpio_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.EN_SAFETY_CKT {false} \
 ] $blk_mem_gen_0

  # Create instance: clk_concat, and set properties
  set clk_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat clk_concat ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {4} \
   CONFIG.IN1_WIDTH {4} \
   CONFIG.IN2_WIDTH {4} \
   CONFIG.IN3_WIDTH {1} \
   CONFIG.NUM_PORTS {4} \
 ] $clk_concat

  # Create instance: const_0, and set properties
  set const_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $const_0

  # Create instance: const_000, and set properties
  set const_000 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_000 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {b000} \
   CONFIG.CONST_WIDTH {3} \
 ] $const_000

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0 ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {2} \
 ] $jtag_axi_0

  # Create instance: util_BUFG_GT_0, and set properties
  set util_BUFG_GT_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_BUFG_GT_0 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {BUFG_GT} \
 ] $util_BUFG_GT_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_BRAM_1 [get_bd_intf_pins S_AXI_BRAM] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net S_AXI_gpio_1 [get_bd_intf_pins S_AXI_gpio] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]

  # Create port connections
  connect_bd_net -net BRAM_aclk_1 [get_bd_pins BRAM_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net BRAM_aresetn_1 [get_bd_pins BRAM_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_bd_net -net IBUFDSGTE_225_IBUF_DS_ODIV2 [get_bd_pins BUFG_GT_I] [get_bd_pins util_BUFG_GT_0/BUFG_GT_I]
  connect_bd_net -net clk_concat_dout [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_pins clk_concat/dout]
  connect_bd_net -net clk_glitch_1 [get_bd_pins clk_glitch] [get_bd_pins clk_concat/In1]
  connect_bd_net -net clk_oor_1 [get_bd_pins clk_oor] [get_bd_pins clk_concat/In2]
  connect_bd_net -net clk_stop_1 [get_bd_pins clk_stop] [get_bd_pins clk_concat/In0]
  connect_bd_net -net const_000_dout [get_bd_pins const_000/dout] [get_bd_pins util_BUFG_GT_0/BUFG_GT_DIV]
  connect_bd_net -net const_0_dout [get_bd_pins const_0/dout] [get_bd_pins util_BUFG_GT_0/BUFG_GT_CLR]
  connect_bd_net -net const_1_dout [get_bd_pins BUFG_GT_CEMASK] [get_bd_pins clk_concat/In3] [get_bd_pins util_BUFG_GT_0/BUFG_GT_CE] [get_bd_pins util_BUFG_GT_0/BUFG_GT_CEMASK] [get_bd_pins util_BUFG_GT_0/BUFG_GT_CLRMASK]
  connect_bd_net -net gpio_aclk_1 [get_bd_pins gpio_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk]
  connect_bd_net -net gpio_aresetn_1 [get_bd_pins gpio_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn]
  connect_bd_net -net jtag_aclk_1 [get_bd_pins jtag_aclk] [get_bd_pins jtag_axi_0/aclk]
  connect_bd_net -net jtag_aresetn_1 [get_bd_pins jtag_aresetn] [get_bd_pins jtag_axi_0/aresetn]
  connect_bd_net -net util_BUFG_GT_0_BUFG_GT_O [get_bd_pins BUFG_GT_O] [get_bd_pins util_BUFG_GT_0/BUFG_GT_O]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: maxilink
proc create_hier_cell_maxilink { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_maxilink() - Empty argument(s)!"}
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


  # Create pins
  create_bd_pin -dir O -from 63 -to 0 M_AXI_araddr_1
  create_bd_pin -dir O -from 63 -to 0 M_AXI_awaddr_1
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type clk clk_300
  create_bd_pin -dir I -from 3 -to 0 gtyrxn_in_0
  create_bd_pin -dir I -from 3 -to 0 gtyrxp_in_0
  create_bd_pin -dir O -from 3 -to 0 gtytxn_out_0
  create_bd_pin -dir O -from 3 -to 0 gtytxp_out_0
  create_bd_pin -dir I -type clk mgtrefclk
  create_bd_pin -dir I -type rst rst
  create_bd_pin -dir I -type rst zu9_axi_rst_n
  create_bd_pin -dir I -type rst zu9_cci_rst_n

  # Create instance: maxilink, and set properties
  set maxilink [ create_bd_cell -type ip -vlnv manchester.ac.uk:maxilink:maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz maxilink ]
  set_property -dict [ list \
   CONFIG.CFGS_ID_WIDTH {5} \
   CONFIG.MAXI_APEVU9_ID_WIDTH {5} \
   CONFIG.MAXI_VU9M0_ID_WIDTH {5} \
   CONFIG.MAXI_VU9M1_ID_WIDTH {5} \
 ] $maxilink

  # Create instance: maxilink_addrInterleaver, and set properties
  set block_name addrInterleaver
  set block_cell_name maxilink_addrInterleaver
  if { [catch {set maxilink_addrInterleaver [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $maxilink_addrInterleaver eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: maxilink_regslice, and set properties
  set maxilink_regslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice maxilink_regslice ]

  # Create interface connections
  connect_bd_intf_net -intf_net maxilink_maxi_zu9m [get_bd_intf_pins maxilink/maxi_zu9m] [get_bd_intf_pins maxilink_regslice/S_AXI]
  connect_bd_intf_net -intf_net maxilink_regslice_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins maxilink_regslice/M_AXI]

  # Create port connections
  connect_bd_net -net clk_300_1 [get_bd_pins clk_300] [get_bd_pins maxilink/zu9_axi_clk] [get_bd_pins maxilink_regslice/aclk]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_150] [get_bd_pins maxilink/clk_freerun_in] [get_bd_pins maxilink/zu9_cci_clk]
  connect_bd_net -net gtyrxn_in_0_1 [get_bd_pins gtyrxn_in_0] [get_bd_pins maxilink/gtyrxn_in]
  connect_bd_net -net gtyrxp_in_0_1 [get_bd_pins gtyrxp_in_0] [get_bd_pins maxilink/gtyrxp_in]
  connect_bd_net -net maxilink_addrInterleaver_out_araddr [get_bd_pins M_AXI_araddr_1] [get_bd_pins maxilink_addrInterleaver/out_araddr]
  connect_bd_net -net maxilink_addrInterleaver_out_awaddr [get_bd_pins M_AXI_awaddr_1] [get_bd_pins maxilink_addrInterleaver/out_awaddr]
  connect_bd_net -net maxilink_regslice_m_axi_araddr [get_bd_pins maxilink_addrInterleaver/in_araddr] [get_bd_pins maxilink_regslice/m_axi_araddr]
  connect_bd_net -net maxilink_regslice_m_axi_awaddr [get_bd_pins maxilink_addrInterleaver/in_awaddr] [get_bd_pins maxilink_regslice/m_axi_awaddr]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxn_out [get_bd_pins gtytxn_out_0] [get_bd_pins maxilink/gtytxn_out]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxp_out [get_bd_pins gtytxp_out_0] [get_bd_pins maxilink/gtytxp_out]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins rst] [get_bd_pins maxilink/phy_rst_n]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins zu9_cci_rst_n] [get_bd_pins maxilink/zu9_cci_rst_n]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins zu9_axi_rst_n] [get_bd_pins maxilink/zu9_axi_rst_n] [get_bd_pins maxilink_regslice/aresetn]
  connect_bd_net -net util_ds_buf_1_IBUF_OUT [get_bd_pins mgtrefclk] [get_bd_pins maxilink/mgtrefclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DDR
proc create_hier_cell_DDR { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DDR() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_1_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_1_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_1_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_1_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_2_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_2_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_2_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_2_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_3_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_3_S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_3_S_AXI_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_3_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_aux_rst_gpio


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_1_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_1_ui_clk
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_2_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_2_ui_clk
  create_bd_pin -dir O -from 0 -to 0 -type rst DDR_3_peripheral_aresetn
  create_bd_pin -dir O -type clk DDR_3_ui_clk
  create_bd_pin -dir I -type clk aux_rst_gpio_aclk
  create_bd_pin -dir I -type rst aux_rst_gpio_aresetn
  create_bd_pin -dir I -from 0 -to 0 sys_rst

  # Create instance: DDR_1
  create_hier_cell_DDR_1 $hier_obj DDR_1

  # Create instance: DDR_2
  create_hier_cell_DDR_2 $hier_obj DDR_2

  # Create instance: DDR_3
  create_hier_cell_DDR_3 $hier_obj DDR_3

  # Create instance: DDR_aux_rst_gpio, and set properties
  set DDR_aux_rst_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio DDR_aux_rst_gpio ]
  set_property -dict [ list \
   CONFIG.C_DOUT_DEFAULT {0xFFFFFFFF} \
   CONFIG.C_GPIO_WIDTH {3} \
   CONFIG.C_INTERRUPT_PRESENT {0} \
 ] $DDR_aux_rst_gpio

  # Create instance: aux_rst_1_slice, and set properties
  set aux_rst_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice aux_rst_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {3} \
 ] $aux_rst_1_slice

  # Create instance: aux_rst_2_slice, and set properties
  set aux_rst_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice aux_rst_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {3} \
   CONFIG.DOUT_WIDTH {1} \
 ] $aux_rst_2_slice

  # Create instance: aux_rst_3_slice, and set properties
  set aux_rst_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice aux_rst_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {3} \
   CONFIG.DOUT_WIDTH {1} \
 ] $aux_rst_3_slice

  # Create instance: init_calib_complete_concat, and set properties
  set init_calib_complete_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat init_calib_complete_concat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {3} \
 ] $init_calib_complete_concat

  # Create instance: sys_rst_NOT, and set properties
  set sys_rst_NOT [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic sys_rst_NOT ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $sys_rst_NOT

  # Create interface connections
  connect_bd_intf_net -intf_net DDR_1_DDR_uDIMM [get_bd_intf_pins DDR_1_uDIMM] [get_bd_intf_pins DDR_1/DDR_uDIMM]
  connect_bd_intf_net -intf_net DDR_1_SYS_CLK_1 [get_bd_intf_pins DDR_1_SYS_CLK] [get_bd_intf_pins DDR_1/DDR_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_1 [get_bd_intf_pins DDR_1_S_AXI] [get_bd_intf_pins DDR_1/DDR_S_AXI]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_CTRL_1 [get_bd_intf_pins DDR_1_S_AXI_CTRL] [get_bd_intf_pins DDR_1/DDR_S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_2_DDR_uDIMM [get_bd_intf_pins DDR_2_uDIMM] [get_bd_intf_pins DDR_2/DDR_uDIMM]
  connect_bd_intf_net -intf_net DDR_2_SYS_CLK_1 [get_bd_intf_pins DDR_2_SYS_CLK] [get_bd_intf_pins DDR_2/DDR_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_2_S_AXI_1 [get_bd_intf_pins DDR_2_S_AXI] [get_bd_intf_pins DDR_2/DDR_S_AXI]
  connect_bd_intf_net -intf_net DDR_2_S_AXI_CTRL_1 [get_bd_intf_pins DDR_2_S_AXI_CTRL] [get_bd_intf_pins DDR_2/DDR_S_AXI_CTRL]
  connect_bd_intf_net -intf_net DDR_3_DDR_uDIMM [get_bd_intf_pins DDR_3_uDIMM] [get_bd_intf_pins DDR_3/DDR_uDIMM]
  connect_bd_intf_net -intf_net DDR_3_SYS_CLK_1 [get_bd_intf_pins DDR_3_SYS_CLK] [get_bd_intf_pins DDR_3/DDR_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_3_S_AXI_1 [get_bd_intf_pins DDR_3_S_AXI] [get_bd_intf_pins DDR_3/DDR_S_AXI]
  connect_bd_intf_net -intf_net DDR_3_S_AXI_CTRL_1 [get_bd_intf_pins DDR_3_S_AXI_CTRL] [get_bd_intf_pins DDR_3/DDR_S_AXI_CTRL]
  connect_bd_intf_net -intf_net S_AXI_aux_rst_gpio_1 [get_bd_intf_pins S_AXI_aux_rst_gpio] [get_bd_intf_pins DDR_aux_rst_gpio/S_AXI]

  # Create port connections
  connect_bd_net -net DDR_1_DDR_ui_clk [get_bd_pins DDR_1_ui_clk] [get_bd_pins DDR_1/DDR_ui_clk]
  connect_bd_net -net DDR_1_init_calib_complete [get_bd_pins DDR_1/init_calib_complete] [get_bd_pins init_calib_complete_concat/In0]
  connect_bd_net -net DDR_1_peripheral_aresetn [get_bd_pins DDR_1_peripheral_aresetn] [get_bd_pins DDR_1/DDR_peripheral_aresetn]
  connect_bd_net -net DDR_2_DDR_peripheral_aresetn [get_bd_pins DDR_2_peripheral_aresetn] [get_bd_pins DDR_2/DDR_peripheral_aresetn]
  connect_bd_net -net DDR_2_DDR_ui_clk [get_bd_pins DDR_2_ui_clk] [get_bd_pins DDR_2/DDR_ui_clk]
  connect_bd_net -net DDR_2_init_calib_complete [get_bd_pins DDR_2/init_calib_complete] [get_bd_pins init_calib_complete_concat/In1]
  connect_bd_net -net DDR_3_DDR_peripheral_aresetn [get_bd_pins DDR_3_peripheral_aresetn] [get_bd_pins DDR_3/DDR_peripheral_aresetn]
  connect_bd_net -net DDR_3_DDR_ui_clk [get_bd_pins DDR_3_ui_clk] [get_bd_pins DDR_3/DDR_ui_clk]
  connect_bd_net -net DDR_3_init_calib_complete [get_bd_pins DDR_3/init_calib_complete] [get_bd_pins init_calib_complete_concat/In2]
  connect_bd_net -net DDR_aux_rst_gpio_io_o [get_bd_pins DDR_aux_rst_gpio/gpio_io_o] [get_bd_pins aux_rst_1_slice/Din] [get_bd_pins aux_rst_2_slice/Din] [get_bd_pins aux_rst_3_slice/Din]
  connect_bd_net -net aux_rst_1_slice_Dout [get_bd_pins DDR_1/aux_reset_in] [get_bd_pins aux_rst_1_slice/Dout]
  connect_bd_net -net aux_rst_2_slice_Dout [get_bd_pins DDR_2/aux_reset_in] [get_bd_pins aux_rst_2_slice/Dout]
  connect_bd_net -net aux_rst_3_slice_Dout [get_bd_pins DDR_3/aux_reset_in] [get_bd_pins aux_rst_3_slice/Dout]
  connect_bd_net -net aux_rst_gpio_aclk_1 [get_bd_pins aux_rst_gpio_aclk] [get_bd_pins DDR_aux_rst_gpio/s_axi_aclk]
  connect_bd_net -net aux_rst_gpio_aresetn_1 [get_bd_pins aux_rst_gpio_aresetn] [get_bd_pins DDR_aux_rst_gpio/s_axi_aresetn]
  connect_bd_net -net init_calib_complete_concat_dout [get_bd_pins DDR_aux_rst_gpio/gpio_io_i] [get_bd_pins init_calib_complete_concat/dout]
  connect_bd_net -net sys_rst_2 [get_bd_pins sys_rst] [get_bd_pins sys_rst_NOT/Op1]
  connect_bd_net -net sys_rst_NOT_Res [get_bd_pins DDR_1/sys_rst] [get_bd_pins DDR_2/sys_rst] [get_bd_pins DDR_3/sys_rst] [get_bd_pins sys_rst_NOT/Res]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 JTAG_M_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 Q225_REFCLK0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_1_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_1_SYS_CLK

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_2_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_2_SYS_CLK

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR_3_uDIMM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR_3_SYS_CLK


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type clk BUFG_GT_O
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type clk clk_100
  create_bd_pin -dir I -type clk clk_150
  create_bd_pin -dir I -type clk clk_300
  create_bd_pin -dir I -from 3 -to 0 clk_glitch
  create_bd_pin -dir I -from 3 -to 0 clk_oor
  create_bd_pin -dir I -from 3 -to 0 clk_stop
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I -from 3 -to 0 gtyrxn_in_0
  create_bd_pin -dir I -from 3 -to 0 gtyrxp_in_0
  create_bd_pin -dir O -from 3 -to 0 gtytxn_out_0
  create_bd_pin -dir O -from 3 -to 0 gtytxp_out_0
  create_bd_pin -dir I -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 rst
  create_bd_pin -dir I -type clk vu9_board_clk_300
  create_bd_pin -dir I -type rst vu9_board_rst

  # Create instance: DDR
  create_hier_cell_DDR $hier_obj DDR

  # Create instance: DDR4_S_AXI_CTRL_Inter, and set properties
  set DDR4_S_AXI_CTRL_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect DDR4_S_AXI_CTRL_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $DDR4_S_AXI_CTRL_Inter

  # Create instance: DDR_S_AXI_Inter, and set properties
  set DDR_S_AXI_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect DDR_S_AXI_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {2} \
 ] $DDR_S_AXI_Inter

  # Create instance: IBUFDSGTE_225, and set properties
  set IBUFDSGTE_225 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf IBUFDSGTE_225 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $IBUFDSGTE_225

  # Create instance: const_1, and set properties
  set const_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $const_1

  # Create instance: maxilink
  create_hier_cell_maxilink $hier_obj maxilink

  # Create instance: maxilink_Inter, and set properties
  set maxilink_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect maxilink_Inter ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.M03_HAS_REGSLICE {4} \
   CONFIG.M04_HAS_REGSLICE {4} \
   CONFIG.M05_HAS_REGSLICE {4} \
   CONFIG.M06_HAS_REGSLICE {4} \
   CONFIG.M07_HAS_REGSLICE {4} \
   CONFIG.M08_HAS_REGSLICE {4} \
   CONFIG.M09_HAS_REGSLICE {4} \
   CONFIG.M10_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {6} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_DATA_FIFO {0} \
   CONFIG.S00_HAS_REGSLICE {4} \
   CONFIG.S01_HAS_REGSLICE {4} \
   CONFIG.S02_HAS_REGSLICE {4} \
   CONFIG.S03_HAS_REGSLICE {4} \
   CONFIG.S04_HAS_REGSLICE {4} \
   CONFIG.S05_HAS_REGSLICE {4} \
   CONFIG.S06_HAS_REGSLICE {4} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $maxilink_Inter

  # Create instance: peripherals
  create_hier_cell_peripherals $hier_obj peripherals

  # Create instance: proc_sys_reset_100, and set properties
  set proc_sys_reset_100 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_100 ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $proc_sys_reset_100

  # Create instance: proc_sys_reset_150, and set properties
  set proc_sys_reset_150 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_150 ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $proc_sys_reset_150

  # Create instance: proc_sys_reset_300, and set properties
  set proc_sys_reset_300 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_300 ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $proc_sys_reset_300

  # Create instance: proc_sys_reset_board_clock_300, and set properties
  set proc_sys_reset_board_clock_300 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_board_clock_300 ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $proc_sys_reset_board_clock_300

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_1 [get_bd_intf_pins Q225_REFCLK0] [get_bd_intf_pins IBUFDSGTE_225/CLK_IN_D]
  connect_bd_intf_net -intf_net DDR4_S_AXI_CTRL_Inter_M00_AXI [get_bd_intf_pins DDR/DDR_1_S_AXI_CTRL] [get_bd_intf_pins DDR4_S_AXI_CTRL_Inter/M00_AXI]
  connect_bd_intf_net -intf_net DDR4_S_AXI_CTRL_Inter_M01_AXI [get_bd_intf_pins DDR/DDR_2_S_AXI_CTRL] [get_bd_intf_pins DDR4_S_AXI_CTRL_Inter/M01_AXI]
  connect_bd_intf_net -intf_net DDR4_S_AXI_CTRL_Inter_M02_AXI [get_bd_intf_pins DDR/DDR_3_S_AXI_CTRL] [get_bd_intf_pins DDR4_S_AXI_CTRL_Inter/M02_AXI]
  connect_bd_intf_net -intf_net DDR_1_S_AXI_1 [get_bd_intf_pins DDR/DDR_1_S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/M00_AXI]
  connect_bd_intf_net -intf_net DDR_2_S_AXI_1 [get_bd_intf_pins DDR/DDR_2_S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/M01_AXI]
  connect_bd_intf_net -intf_net DDR_3_S_AXI_1 [get_bd_intf_pins DDR/DDR_3_S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/M02_AXI]
  connect_bd_intf_net -intf_net DDR_1_uDIMM_1 [get_bd_intf_pins DDR_1_uDIMM] [get_bd_intf_pins DDR/DDR_1_uDIMM]
  connect_bd_intf_net -intf_net DDR_2_uDIMM_1 [get_bd_intf_pins DDR_2_uDIMM] [get_bd_intf_pins DDR/DDR_2_uDIMM]
  connect_bd_intf_net -intf_net DDR_3_uDIMM_1 [get_bd_intf_pins DDR_3_uDIMM] [get_bd_intf_pins DDR/DDR_3_uDIMM]
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins DDR_S_AXI_Inter/S01_AXI]
  connect_bd_intf_net -intf_net S_AXI_BRAM_1 [get_bd_intf_pins maxilink_Inter/M04_AXI] [get_bd_intf_pins peripherals/S_AXI_BRAM]
  connect_bd_intf_net -intf_net S_AXI_gpio_1 [get_bd_intf_pins maxilink_Inter/M05_AXI] [get_bd_intf_pins peripherals/S_AXI_gpio]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins DDR4_S_AXI_CTRL_Inter/S00_AXI] [get_bd_intf_pins maxilink_Inter/M02_AXI]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins JTAG_M_AXI] [get_bd_intf_pins peripherals/M_AXI]
  connect_bd_intf_net -intf_net maxilink_Inter_M00_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins maxilink_Inter/M00_AXI]
  connect_bd_intf_net -intf_net maxilink_Inter_M01_AXI [get_bd_intf_pins DDR_S_AXI_Inter/S00_AXI] [get_bd_intf_pins maxilink_Inter/M01_AXI]
  connect_bd_intf_net -intf_net maxilink_Inter_M03_AXI [get_bd_intf_pins DDR/S_AXI_aux_rst_gpio] [get_bd_intf_pins maxilink_Inter/M03_AXI]
  connect_bd_intf_net -intf_net maxilink_xilinx_axi_0_maxi_zu9m [get_bd_intf_pins maxilink/M_AXI] [get_bd_intf_pins maxilink_Inter/S00_AXI]
  connect_bd_intf_net -intf_net DDR_1_SYS_CLK_1 [get_bd_intf_pins DDR_1_SYS_CLK] [get_bd_intf_pins DDR/DDR_1_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_2_SYS_CLK_1 [get_bd_intf_pins DDR_2_SYS_CLK] [get_bd_intf_pins DDR/DDR_2_SYS_CLK]
  connect_bd_intf_net -intf_net DDR_3_SYS_CLK_1 [get_bd_intf_pins DDR_3_SYS_CLK] [get_bd_intf_pins DDR/DDR_3_SYS_CLK]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins DDR_S_AXI_Inter/ARESETN] [get_bd_pins maxilink_Inter/ARESETN] [get_bd_pins proc_sys_reset_300/interconnect_aresetn]
  connect_bd_net -net DDR_DDR_2_peripheral_aresetn [get_bd_pins DDR/DDR_2_peripheral_aresetn] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M01_ARESETN] [get_bd_pins DDR_S_AXI_Inter/M01_ARESETN]
  connect_bd_net -net DDR_DDR_2_ui_clk [get_bd_pins DDR/DDR_2_ui_clk] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M01_ACLK] [get_bd_pins DDR_S_AXI_Inter/M01_ACLK]
  connect_bd_net -net DDR_DDR_3_peripheral_aresetn [get_bd_pins DDR/DDR_3_peripheral_aresetn] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M02_ARESETN] [get_bd_pins DDR_S_AXI_Inter/M02_ARESETN]
  connect_bd_net -net DDR_DDR_3_ui_clk [get_bd_pins DDR/DDR_3_ui_clk] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M02_ACLK] [get_bd_pins DDR_S_AXI_Inter/M02_ACLK]
  connect_bd_net -net IBUFDSGTE_225_IBUF_DS_ODIV2 [get_bd_pins IBUFDSGTE_225/IBUF_DS_ODIV2] [get_bd_pins peripherals/BUFG_GT_I]
  connect_bd_net -net M00_ACLK_1 [get_bd_pins DDR/DDR_1_ui_clk] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M00_ACLK] [get_bd_pins DDR_S_AXI_Inter/M00_ACLK]
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins DDR/DDR_1_peripheral_aresetn] [get_bd_pins DDR4_S_AXI_CTRL_Inter/M00_ARESETN] [get_bd_pins DDR_S_AXI_Inter/M00_ARESETN]
  connect_bd_net -net M08_ACLK_1 [get_bd_pins aclk] [get_bd_pins DDR_S_AXI_Inter/S00_ACLK] [get_bd_pins DDR_S_AXI_Inter/S01_ACLK] [get_bd_pins maxilink_Inter/M00_ACLK] [get_bd_pins maxilink_Inter/M01_ACLK]
  connect_bd_net -net M08_ARESETN_1 [get_bd_pins peripheral_aresetn] [get_bd_pins DDR_S_AXI_Inter/S00_ARESETN] [get_bd_pins DDR_S_AXI_Inter/S01_ARESETN] [get_bd_pins maxilink_Inter/M00_ARESETN] [get_bd_pins maxilink_Inter/M01_ARESETN]
  connect_bd_net -net addrInterleaver_0_out_araddr [get_bd_pins maxilink/M_AXI_araddr_1] [get_bd_pins maxilink_Inter/S00_AXI_araddr]
  connect_bd_net -net addrInterleaver_0_out_awaddr [get_bd_pins maxilink/M_AXI_awaddr_1] [get_bd_pins maxilink_Inter/S00_AXI_awaddr]
  connect_bd_net -net board_clk_300_1 [get_bd_pins vu9_board_clk_300] [get_bd_pins peripherals/jtag_aclk] [get_bd_pins proc_sys_reset_board_clock_300/slowest_sync_clk]
  connect_bd_net -net clk_100_1 [get_bd_pins clk_100] [get_bd_pins maxilink_Inter/M05_ACLK] [get_bd_pins peripherals/gpio_aclk] [get_bd_pins proc_sys_reset_100/slowest_sync_clk]
  connect_bd_net -net clk_300_1 [get_bd_pins clk_300] [get_bd_pins DDR_S_AXI_Inter/ACLK] [get_bd_pins maxilink/clk_300] [get_bd_pins maxilink_Inter/ACLK] [get_bd_pins maxilink_Inter/S00_ACLK] [get_bd_pins proc_sys_reset_300/slowest_sync_clk]
  connect_bd_net -net clk_glitch_1 [get_bd_pins clk_glitch] [get_bd_pins peripherals/clk_glitch]
  connect_bd_net -net clk_oor_1 [get_bd_pins clk_oor] [get_bd_pins peripherals/clk_oor]
  connect_bd_net -net clk_stop_1 [get_bd_pins clk_stop] [get_bd_pins peripherals/clk_stop]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_150] [get_bd_pins DDR/aux_rst_gpio_aclk] [get_bd_pins DDR4_S_AXI_CTRL_Inter/ACLK] [get_bd_pins DDR4_S_AXI_CTRL_Inter/S00_ACLK] [get_bd_pins maxilink/clk_150] [get_bd_pins maxilink_Inter/M02_ACLK] [get_bd_pins maxilink_Inter/M03_ACLK] [get_bd_pins maxilink_Inter/M04_ACLK] [get_bd_pins peripherals/BRAM_aclk] [get_bd_pins proc_sys_reset_150/slowest_sync_clk]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins dcm_locked] [get_bd_pins proc_sys_reset_100/dcm_locked] [get_bd_pins proc_sys_reset_150/dcm_locked] [get_bd_pins proc_sys_reset_300/dcm_locked]
  connect_bd_net -net const_1_dout [get_bd_pins const_1/dout] [get_bd_pins peripherals/BUFG_GT_CEMASK] [get_bd_pins proc_sys_reset_150/aux_reset_in] [get_bd_pins proc_sys_reset_300/aux_reset_in] [get_bd_pins proc_sys_reset_board_clock_300/aux_reset_in]
  connect_bd_net -net gtyrxn_in_0_1 [get_bd_pins gtyrxn_in_0] [get_bd_pins maxilink/gtyrxn_in_0]
  connect_bd_net -net gtyrxp_in_0_1 [get_bd_pins gtyrxp_in_0] [get_bd_pins maxilink/gtyrxp_in_0]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxn_out [get_bd_pins gtytxn_out_0] [get_bd_pins maxilink/gtytxn_out_0]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxp_out [get_bd_pins gtytxp_out_0] [get_bd_pins maxilink/gtytxp_out_0]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins rst] [get_bd_pins DDR/sys_rst] [get_bd_pins maxilink/rst] [get_bd_pins peripherals/jtag_aresetn] [get_bd_pins proc_sys_reset_100/ext_reset_in] [get_bd_pins proc_sys_reset_150/ext_reset_in] [get_bd_pins proc_sys_reset_300/ext_reset_in] [get_bd_pins proc_sys_reset_board_clock_300/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins DDR/aux_rst_gpio_aresetn] [get_bd_pins DDR4_S_AXI_CTRL_Inter/ARESETN] [get_bd_pins DDR4_S_AXI_CTRL_Inter/S00_ARESETN] [get_bd_pins maxilink/zu9_cci_rst_n] [get_bd_pins maxilink_Inter/M02_ARESETN] [get_bd_pins maxilink_Inter/M03_ARESETN] [get_bd_pins maxilink_Inter/M04_ARESETN] [get_bd_pins peripherals/BRAM_aresetn] [get_bd_pins proc_sys_reset_150/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_100_peripheral_aresetn [get_bd_pins maxilink_Inter/M05_ARESETN] [get_bd_pins peripherals/gpio_aresetn] [get_bd_pins proc_sys_reset_100/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins maxilink/zu9_axi_rst_n] [get_bd_pins maxilink_Inter/S00_ARESETN] [get_bd_pins proc_sys_reset_300/peripheral_aresetn]
  connect_bd_net -net util_BUFG_GT_0_BUFG_GT_O [get_bd_pins BUFG_GT_O] [get_bd_pins peripherals/BUFG_GT_O]
  connect_bd_net -net util_ds_buf_1_IBUF_OUT [get_bd_pins IBUFDSGTE_225/IBUF_OUT] [get_bd_pins maxilink/mgtrefclk]
  connect_bd_net -net vu9_board_rst_1 [get_bd_pins vu9_board_rst] [get_bd_pins proc_sys_reset_board_clock_300/ext_reset_in]

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
  set Q225_REFCLK0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 Q225_REFCLK0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $Q225_REFCLK0

  set uDIMM_DDR4_C1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 uDIMM_DDR4_C1 ]

  set uDIMM_DDR4_C1_REFCLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 uDIMM_DDR4_C1_REFCLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $uDIMM_DDR4_C1_REFCLK

  set uDIMM_DDR4_C2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 uDIMM_DDR4_C2 ]

  set uDIMM_DDR4_C2_REFCLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 uDIMM_DDR4_C2_REFCLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $uDIMM_DDR4_C2_REFCLK

  set uDIMM_DDR4_C3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 uDIMM_DDR4_C3 ]

  set uDIMM_DDR4_C3_REFCLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 uDIMM_DDR4_C3_REFCLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $uDIMM_DDR4_C3_REFCLK

  set vu9_logic_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 vu9_logic_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $vu9_logic_clock


  # Create ports
  set gtyrxn_in_0 [ create_bd_port -dir I -from 3 -to 0 gtyrxn_in_0 ]
  set gtyrxp_in_0 [ create_bd_port -dir I -from 3 -to 0 gtyrxp_in_0 ]
  set gtytxn_out_0 [ create_bd_port -dir O -from 3 -to 0 gtytxn_out_0 ]
  set gtytxp_out_0 [ create_bd_port -dir O -from 3 -to 0 gtytxp_out_0 ]
  set vu9_board_rst [ create_bd_port -dir I -type rst vu9_board_rst ]

  # Create instance: IBUFDS, and set properties
  set IBUFDS [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf IBUFDS ]

  # Create instance: M_AXI_master_Inter, and set properties
  set M_AXI_master_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect M_AXI_master_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $M_AXI_master_Inter

  # Create instance: S_AXI_data_control_coherent_Inter, and set properties
  set S_AXI_data_control_coherent_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect S_AXI_data_control_coherent_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $S_AXI_data_control_coherent_Inter

  # Create instance: bridge_to_host
  create_hier_cell_bridge_to_host [current_bd_instance .] bridge_to_host

  # Create instance: clock_generator, and set properties
  set clock_generator [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clock_generator ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
   CONFIG.CLKOUT1_DRIVES {Buffer} \
   CONFIG.CLKOUT1_JITTER {101.475} \
   CONFIG.CLKOUT1_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT2_DRIVES {Buffer} \
   CONFIG.CLKOUT2_JITTER {101.475} \
   CONFIG.CLKOUT2_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_DRIVES {Buffer} \
   CONFIG.CLKOUT3_JITTER {93.717} \
   CONFIG.CLKOUT3_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {150} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_DRIVES {Buffer} \
   CONFIG.CLKOUT4_JITTER {81.814} \
   CONFIG.CLKOUT4_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {300} \
   CONFIG.CLKOUT4_USED {true} \
   CONFIG.CLKOUT5_DRIVES {Buffer} \
   CONFIG.CLKOUT6_DRIVES {Buffer} \
   CONFIG.CLKOUT7_DRIVES {Buffer} \
   CONFIG.CLK_OUT1_PORT {clk_out1} \
   CONFIG.CLK_OUT2_PORT {clk_100} \
   CONFIG.CLK_OUT3_PORT {clk_150} \
   CONFIG.CLK_OUT4_PORT {clk_300} \
   CONFIG.ENABLE_CLOCK_MONITOR {true} \
   CONFIG.ENABLE_USER_CLOCK0 {true} \
   CONFIG.ENABLE_USER_CLOCK1 {true} \
   CONFIG.ENABLE_USER_CLOCK2 {true} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {4.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {3.333} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {12} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {8} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {4} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {4} \
   CONFIG.PRIMITIVE {MMCM} \
   CONFIG.PRIM_IN_FREQ {300.000} \
   CONFIG.REF_CLK_FREQ {300} \
   CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.USER_CLK_FREQ1 {156.25} \
   CONFIG.USER_CLK_FREQ2 {300.0} \
   CONFIG.USE_PHASE_ALIGNMENT {false} \
   CONFIG.USE_RESET {true} \
 ] $clock_generator

  # Create instance: processor_system_reset, and set properties
  set processor_system_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset processor_system_reset ]

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_1 [get_bd_intf_ports Q225_REFCLK0] [get_bd_intf_pins bridge_to_host/Q225_REFCLK0]
  connect_bd_intf_net -intf_net DDR_uDIMM_DDR4_C1 [get_bd_intf_ports uDIMM_DDR4_C1] [get_bd_intf_pins bridge_to_host/DDR_1_uDIMM]
  connect_bd_intf_net -intf_net DDR_uDIMM_DDR4_C2 [get_bd_intf_ports uDIMM_DDR4_C2] [get_bd_intf_pins bridge_to_host/DDR_2_uDIMM]
  connect_bd_intf_net -intf_net DDR_uDIMM_DDR4_C3 [get_bd_intf_ports uDIMM_DDR4_C3] [get_bd_intf_pins bridge_to_host/DDR_3_uDIMM]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins M_AXI_master_Inter/S00_AXI] [get_bd_intf_pins bridge_to_host/M_AXI]
  connect_bd_intf_net -intf_net S_AXI_data_control_coherent_Inter_M00_AXI [get_bd_intf_pins S_AXI_data_control_coherent_Inter/M00_AXI] [get_bd_intf_pins bridge_to_host/S_AXI]
  connect_bd_intf_net -intf_net bridge_to_host_JTAG_M_AXI [get_bd_intf_pins bridge_to_host/JTAG_M_AXI] [get_bd_intf_pins clock_generator/s_axi_lite]
  connect_bd_intf_net -intf_net uDIMM_DDR4_C1_REFCLK_1 [get_bd_intf_ports uDIMM_DDR4_C1_REFCLK] [get_bd_intf_pins bridge_to_host/DDR_1_SYS_CLK]
  connect_bd_intf_net -intf_net uDIMM_DDR4_C2_REFCLK_1 [get_bd_intf_ports uDIMM_DDR4_C2_REFCLK] [get_bd_intf_pins bridge_to_host/DDR_2_SYS_CLK]
  connect_bd_intf_net -intf_net uDIMM_DDR4_C3_REFCLK_1 [get_bd_intf_ports uDIMM_DDR4_C3_REFCLK] [get_bd_intf_pins bridge_to_host/DDR_3_SYS_CLK]
  connect_bd_intf_net -intf_net vu9_logic_clock_1 [get_bd_intf_ports vu9_logic_clock] [get_bd_intf_pins IBUFDS/CLK_IN_D]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins M_AXI_master_Inter/ARESETN] [get_bd_pins S_AXI_data_control_coherent_Inter/ARESETN] [get_bd_pins processor_system_reset/interconnect_aresetn]
  connect_bd_net -net bridge_to_host_BUFG_GT_O [get_bd_pins bridge_to_host/BUFG_GT_O] [get_bd_pins clock_generator/user_clk0] [get_bd_pins clock_generator/user_clk1]
  connect_bd_net -net bridge_to_host_IBUF_OUT [get_bd_pins IBUFDS/IBUF_OUT] [get_bd_pins bridge_to_host/vu9_board_clk_300] [get_bd_pins clock_generator/clk_in1] [get_bd_pins clock_generator/ref_clk] [get_bd_pins clock_generator/s_axi_aclk] [get_bd_pins clock_generator/user_clk2]
  connect_bd_net -net bridge_to_host_Res [get_bd_pins bridge_to_host/rst] [get_bd_pins clock_generator/s_axi_aresetn]
  connect_bd_net -net clock_generator_clk_100 [get_bd_pins bridge_to_host/clk_100] [get_bd_pins clock_generator/clk_100]
  connect_bd_net -net clock_generator_clk_150 [get_bd_pins bridge_to_host/clk_150] [get_bd_pins clock_generator/clk_150]
  connect_bd_net -net clock_generator_clk_300 [get_bd_pins bridge_to_host/clk_300] [get_bd_pins clock_generator/clk_300]
  connect_bd_net -net clock_generator_clk_glitch [get_bd_pins bridge_to_host/clk_glitch] [get_bd_pins clock_generator/clk_glitch]
  connect_bd_net -net clock_generator_clk_oor [get_bd_pins bridge_to_host/clk_oor] [get_bd_pins clock_generator/clk_oor]
  connect_bd_net -net clock_generator_clk_out1 [get_bd_pins M_AXI_master_Inter/ACLK] [get_bd_pins M_AXI_master_Inter/S00_ACLK] [get_bd_pins S_AXI_data_control_coherent_Inter/ACLK] [get_bd_pins S_AXI_data_control_coherent_Inter/M00_ACLK] [get_bd_pins bridge_to_host/aclk] [get_bd_pins clock_generator/clk_out1] [get_bd_pins processor_system_reset/slowest_sync_clk]
  connect_bd_net -net clock_generator_clk_stop [get_bd_pins bridge_to_host/clk_stop] [get_bd_pins clock_generator/clk_stop]
  connect_bd_net -net clock_generator_locked [get_bd_pins bridge_to_host/dcm_locked] [get_bd_pins clock_generator/locked] [get_bd_pins processor_system_reset/dcm_locked]
  connect_bd_net -net gtyrxn_in_0_1 [get_bd_ports gtyrxn_in_0] [get_bd_pins bridge_to_host/gtyrxn_in_0]
  connect_bd_net -net gtyrxp_in_0_1 [get_bd_ports gtyrxp_in_0] [get_bd_pins bridge_to_host/gtyrxp_in_0]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxn_out [get_bd_ports gtytxn_out_0] [get_bd_pins bridge_to_host/gtytxn_out_0]
  connect_bd_net -net maxilink_xilinx_axi_0_gtytxp_out [get_bd_ports gtytxp_out_0] [get_bd_pins bridge_to_host/gtytxp_out_0]
  connect_bd_net -net processor_system_reset_peripheral_aresetn [get_bd_pins M_AXI_master_Inter/S00_ARESETN] [get_bd_pins S_AXI_data_control_coherent_Inter/M00_ARESETN] [get_bd_pins bridge_to_host/peripheral_aresetn] [get_bd_pins processor_system_reset/peripheral_aresetn]
  connect_bd_net -net vu9_board_rst_1 [get_bd_ports vu9_board_rst] [get_bd_pins bridge_to_host/vu9_board_rst] [get_bd_pins processor_system_reset/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0x002000000000 -range 0x000400000000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_1/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x002400000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_2/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x002600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_3/DDR/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x003000100000 -range 0x00100000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_1/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG] -force
  assign_bd_address -offset 0x003000200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_2/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG] -force
  assign_bd_address -offset 0x003000300000 -range 0x00100000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_3/DDR/C0_DDR4_MEMORY_MAP_CTRL/C0_REG] -force
  assign_bd_address -offset 0x003000400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/DDR/DDR_aux_rst_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/peripherals/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/peripherals/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/peripherals/jtag_axi_0/Data] [get_bd_addr_segs clock_generator/s_axi_lite/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

