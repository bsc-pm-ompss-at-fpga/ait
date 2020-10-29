
################################################################
# This is a generated script based on design: accDMA_design
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
set scripts_vivado_version 2017.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_msg_id "BD_TCL-1002" "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source acc_DMA_design_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
   set_property BOARD_PART digilentinc.com:zybo:part0:1.0 [current_project]
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

current_bd_design $design_name

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
xilinx.com:ip:axi_dma:*\
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

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: acc_DMA
proc create_hier_cell_acc_DMA { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_acc_DMA() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 DMA_inStream
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 DMA_outStream
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_ACP
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_GP

  # Create pins
  create_bd_pin -dir I -type clk DMA_aclk
  create_bd_pin -dir I -type rst DMA_interconnect_aresetn
  create_bd_pin -dir I -type rst DMA_peripheral_aresetn
  create_bd_pin -dir O -type intr mm2s_introut
  create_bd_pin -dir O -type intr s2mm_introut

  # Create instance: ACP_Inter, and set properties
  set ACP_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect ACP_Inter ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {3} \
   CONFIG.STRATEGY {1} \
 ] $ACP_Inter

  # Create instance: DMA, and set properties
  set DMA [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma DMA ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_m_axi_mm2s_data_width {64} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_burst_size {16} \
   CONFIG.c_sg_include_stscntrl_strm {0} \
   CONFIG.c_sg_length_width {23} \
 ] $DMA

  # Create interface connections
  connect_bd_intf_net -intf_net ACP_Inter_M00_AXI [get_bd_intf_pins M_AXI_ACP] [get_bd_intf_pins ACP_Inter/M00_AXI]
  connect_bd_intf_net -intf_net DMA_M_AXIS_MM2S [get_bd_intf_pins DMA_outStream] [get_bd_intf_pins DMA/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net DMA_M_AXI_MM2S [get_bd_intf_pins ACP_Inter/S00_AXI] [get_bd_intf_pins DMA/M_AXI_MM2S]
  connect_bd_intf_net -intf_net DMA_M_AXI_S2MM [get_bd_intf_pins ACP_Inter/S01_AXI] [get_bd_intf_pins DMA/M_AXI_S2MM]
  connect_bd_intf_net -intf_net DMA_M_AXI_SG [get_bd_intf_pins ACP_Inter/S02_AXI] [get_bd_intf_pins DMA/M_AXI_SG]
  connect_bd_intf_net -intf_net DMA_inStream_1 [get_bd_intf_pins DMA_inStream] [get_bd_intf_pins DMA/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net S_AXI_GP_1 [get_bd_intf_pins S_AXI_GP] [get_bd_intf_pins DMA/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net DMA_aresetn_1 [get_bd_pins DMA_peripheral_aresetn] [get_bd_pins ACP_Inter/M00_ARESETN] [get_bd_pins ACP_Inter/S00_ARESETN] [get_bd_pins ACP_Inter/S01_ARESETN] [get_bd_pins ACP_Inter/S02_ARESETN] [get_bd_pins DMA/axi_resetn]
  connect_bd_net -net DMA_clk_1 [get_bd_pins DMA_aclk] [get_bd_pins ACP_Inter/ACLK] [get_bd_pins ACP_Inter/M00_ACLK] [get_bd_pins ACP_Inter/S00_ACLK] [get_bd_pins ACP_Inter/S01_ACLK] [get_bd_pins ACP_Inter/S02_ACLK] [get_bd_pins DMA/m_axi_mm2s_aclk] [get_bd_pins DMA/m_axi_s2mm_aclk] [get_bd_pins DMA/m_axi_sg_aclk] [get_bd_pins DMA/s_axi_lite_aclk]
  connect_bd_net -net DMA_interconnect_aresetn_1 [get_bd_pins DMA_interconnect_aresetn] [get_bd_pins ACP_Inter/ARESETN]
  connect_bd_net -net DMA_mm2s_introut [get_bd_pins mm2s_introut] [get_bd_pins DMA/mm2s_introut]
  connect_bd_net -net DMA_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins DMA/s2mm_introut]

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

  # Create ports

  # Create instance: acc_DMA
  create_hier_cell_acc_DMA [current_bd_instance .] acc_DMA

  # Create port connections

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


