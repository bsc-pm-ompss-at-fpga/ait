
################################################################
# This is a generated script based on design: SOM
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
# source SOM_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu9eg-ffvb1156-2-e
   set_property BOARD_PART xilinx.com:zcu102:part0:3.2 [current_project]
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
bsc:ompss:fastompssmanager:*\
xilinx.com:ip:blk_mem_gen:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:axi_gpio:*\
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

# Hierarchical cell: hwr_inStream
proc create_hier_cell_hwr_inStream { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_hwr_inStream() - Empty argument(s)!"}
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
  for {set i 0} {$i < ${::AIT::num_accs}} {incr i} {
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S${i}_AXIS
  }
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 cmdout_in

  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst interconnect_aresetn
  create_bd_pin -dir I -type rst peripheral_aresetn

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: hwr_outStream
proc create_hier_cell_hwr_outStream { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_hwr_outStream() - Empty argument(s)!"}
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
  for {set i 0} {$i < ${::AIT::num_accs}} {incr i} {
      create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M${i}_AXIS
  }
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 cmdin_out

  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst interconnect_aresetn
  create_bd_pin -dir I -type rst peripheral_aresetn

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: Hardware_Runtime
proc create_hier_cell_Hardware_Runtime { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Hardware_Runtime() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_GP

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst interconnect_aresetn
  create_bd_pin -dir O managed_aresetn
  create_bd_pin -dir I -type rst peripheral_aresetn

  # Create instance: hwr_inStream
  create_hier_cell_hwr_inStream [current_bd_instance .] hwr_inStream

  # Create instance: hwr_outStream
  create_hier_cell_hwr_outStream [current_bd_instance .] hwr_outStream

  # Create instance: GP_Inter, and set properties
  set GP_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect GP_Inter ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {3} \
   CONFIG.S00_HAS_REGSLICE {4} \
   CONFIG.STRATEGY {1} \
 ] $GP_Inter

  # Create instance: axis_cmdin_TID, and set properties
  set axis_cmdin_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_cmdin_TID]
  set_property -dict [ list \
   CONFIG.M_TID_WIDTH.VALUE_SRC USER \
   CONFIG.M_TID_WIDTH {1} \
   #CONFIG.TID_REMAP "1'b1"
  ] $axis_cmdin_TID

  # Create instance: Fast_OmpSs_Manager, and set properties
  set Fast_OmpSs_Manager [ create_bd_cell -type ip -vlnv bsc:ompss:fastompssmanager Fast_OmpSs_Manager ]
  set_property -dict [ list \
   CONFIG.MAX_ACCS [expr max(${::AIT::num_accs}, 2)] \
   CONFIG.MAX_ACC_TYPES [expr max([llength ${::AIT::accs}], 2)] \
   CONFIG.CMDIN_SUBQUEUE_LEN ${::AIT::cmdInSubqueue_len} \
   CONFIG.CMDOUT_SUBQUEUE_LEN ${::AIT::cmdOutSubqueue_len} \
  ] $Fast_OmpSs_Manager

  # Create instance: cmdInQueue, and set properties
  set cmdInQueue [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen cmdInQueue ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {true} \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Operating_Mode_A {READ_FIRST} \
   CONFIG.Operating_Mode_B {READ_FIRST} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Read_Width_A {64} \
   CONFIG.Read_Width_B {32} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.Write_Depth_A [expr ${::AIT::cmdInSubqueue_len}*max(${::AIT::num_accs}, 2)] \
   CONFIG.Write_Width_A {64} \
   CONFIG.Write_Width_B {32} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $cmdInQueue

  # Create instance: cmdInQueue_BRAM_Ctrl, and set properties
  set cmdInQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdInQueue_BRAM_Ctrl ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $cmdInQueue_BRAM_Ctrl

  # Create instance: cmdOutQueue, and set properties
  set cmdOutQueue [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen cmdOutQueue ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {true} \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Operating_Mode_A {READ_FIRST} \
   CONFIG.Operating_Mode_B {READ_FIRST} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Read_Width_A {64} \
   CONFIG.Read_Width_B {32} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.Write_Depth_A [expr ${::AIT::cmdOutSubqueue_len}*max(${::AIT::num_accs}, 2)] \
   CONFIG.Write_Width_A {64} \
   CONFIG.Write_Width_B {32} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $cmdOutQueue

  # Create instance: cmdOutQueue_BRAM_Ctrl, and set properties
  set cmdOutQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdOutQueue_BRAM_Ctrl ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $cmdOutQueue_BRAM_Ctrl

  # Create instance: hwruntime_rst, and set properties
  set hwruntime_rst [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio hwruntime_rst ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_DOUT_DEFAULT {0x00000000} \
   CONFIG.C_GPIO_WIDTH {1} \
 ] $hwruntime_rst

  # Create interface connections
  connect_bd_intf_net [get_bd_intf_pins Fast_OmpSs_Manager/cmdout_in] [get_bd_intf_pins hwr_inStream/cmdout_in]
  connect_bd_intf_net [get_bd_intf_pins Fast_OmpSs_Manager/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins hwr_outStream/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/M_AXIS]
  connect_bd_intf_net -intf_net GP_Inter_M00_AXI [get_bd_intf_pins GP_Inter/M00_AXI] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/S_AXI]
  connect_bd_intf_net -intf_net GP_Inter_M01_AXI [get_bd_intf_pins GP_Inter/M01_AXI] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/S_AXI]
  connect_bd_intf_net -intf_net GP_Inter_M02_AXI [get_bd_intf_pins GP_Inter/M02_AXI] [get_bd_intf_pins hwruntime_rst/S_AXI]
  connect_bd_intf_net -intf_net S_AXI_GP_1 [get_bd_intf_pins S_AXI_GP] [get_bd_intf_pins GP_Inter/S00_AXI]
  connect_bd_intf_net -intf_net Fast_OmpSs_Manager_cmdInQueue [get_bd_intf_pins Fast_OmpSs_Manager/cmdin_queue] [get_bd_intf_pins cmdInQueue/BRAM_PORTA]
  connect_bd_intf_net -intf_net Fast_OmpSs_Manager_cmdOutQueue [get_bd_intf_pins Fast_OmpSs_Manager/cmdout_queue] [get_bd_intf_pins cmdOutQueue/BRAM_PORTA]
  connect_bd_intf_net -intf_net cmdInQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdInQueue/BRAM_PORTB] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net cmdOutQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdOutQueue/BRAM_PORTB] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net Fast_OmpSs_Manager_managed_aresetn [get_bd_pins managed_aresetn] [get_bd_pins Fast_OmpSs_Manager/managed_aresetn] [get_bd_pins axis_cmdin_TID/aresetn]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins GP_Inter/ACLK] [get_bd_pins GP_Inter/M00_ACLK] [get_bd_pins GP_Inter/M01_ACLK] [get_bd_pins GP_Inter/M02_ACLK] [get_bd_pins GP_Inter/S00_ACLK] [get_bd_pins Fast_OmpSs_Manager/aclk] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins hwruntime_rst/s_axi_aclk] [get_bd_pins axis_cmdin_TID/aclk] [get_bd_pins hwr_inStream/clk] [get_bd_pins hwr_outStream/clk]
  connect_bd_net -net hwruntime_rst_gpio_io_o [get_bd_pins Fast_OmpSs_Manager/ps_rst] [get_bd_pins hwruntime_rst/gpio_io_o]
  connect_bd_net -net interconnect_aresetn_1 [get_bd_pins interconnect_aresetn] [get_bd_pins GP_Inter/ARESETN] [get_bd_pins Fast_OmpSs_Manager/interconnect_aresetn] [get_bd_pins hwr_inStream/interconnect_aresetn] [get_bd_pins hwr_outStream/interconnect_aresetn]
  connect_bd_net -net peripheral_aresetn_1 [get_bd_pins peripheral_aresetn] [get_bd_pins GP_Inter/M00_ARESETN] [get_bd_pins GP_Inter/M01_ARESETN] [get_bd_pins GP_Inter/M02_ARESETN] [get_bd_pins GP_Inter/S00_ARESETN] [get_bd_pins Fast_OmpSs_Manager/peripheral_aresetn] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins hwruntime_rst/s_axi_aresetn] [get_bd_pins hwr_inStream/peripheral_aresetn] [get_bd_pins hwr_outStream/peripheral_aresetn]

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

  # Create instance: Hardware_Runtime
  create_hier_cell_Hardware_Runtime [current_bd_instance .] Hardware_Runtime

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


