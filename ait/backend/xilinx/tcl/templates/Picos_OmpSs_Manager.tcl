
################################################################
# This is a generated script based on design: POM
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
# source POM_script.tcl

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
bsc:ompss:picos_ompss_manager:*\
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
  if {${::AIT::task_creation}} {
      create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 spawn_in
      create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 taskwait_in
  }
  if {${::AIT::lock_hwruntime}} {
      create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 lock_in
  }

  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rstn

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
  if {${::AIT::task_creation}} {
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 spawn_out
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 taskwait_out
  }
  if {${::AIT::lock_hwruntime}} {
      create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 lock_out
  }

  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rstn

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
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst managed_rstn
  create_bd_pin -dir I -type rst rstn

  # Create instance: hwr_inStream
  create_hier_cell_hwr_inStream [current_bd_instance .] hwr_inStream

  # Create instance: hwr_outStream
  create_hier_cell_hwr_outStream [current_bd_instance .] hwr_outStream

  # Create instance: GP_Inter, and set properties
  set GP_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect GP_Inter ]
  set nmasters 2
  set GP_Inter_config [list CONFIG.M00_HAS_REGSLICE 4 CONFIG.M01_HAS_REGSLICE 4 CONFIG.S00_HAS_REGSLICE 4 CONFIG.STRATEGY 1]
  if {${::AIT::enable_spawn_queues}} {
    set spawn_out_m $nmasters
    incr nmasters
    set spawn_in_m $nmasters
    incr nmasters
    lappend GP_Inter_config CONFIG.M0${spawn_out_m}_HAS_REGSLICE 4 CONFIG.M0${spawn_in_m}_HAS_REGSLICE 4
  }
  if {${::AIT::enable_pom_axilite}} {
    set pom_axilite_m $nmasters
    incr nmasters
    lappend GP_Inter_config CONFIG.M0${pom_axilite_m}_HAS_REGSLICE 4
  }
  lappend GP_Inter_config CONFIG.NUM_MI $nmasters
  set_property -dict $GP_Inter_config $GP_Inter

  # Create instance: axis_cmdin_TID, and set properties
  set axis_cmdin_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_cmdin_TID]
  set_property -dict [ list \
   CONFIG.M_TID_WIDTH.VALUE_SRC USER \
   CONFIG.M_TID_WIDTH {1} \
   CONFIG.TID_REMAP "1'b0"
  ] $axis_cmdin_TID

  if {${::AIT::task_creation}} {
    # Create instance: axis_spawn_TID, and set properties
    set axis_spawn_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_spawn_TID]
    set_property -dict [ list \
     CONFIG.M_TID_WIDTH.VALUE_SRC USER \
     CONFIG.M_TID_WIDTH {1} \
     CONFIG.TID_REMAP "1'b1" \
    ] $axis_spawn_TID

    # Create instance: axis_taskwait_TID, and set properties
    set axis_taskwait_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_taskwait_TID]
    set_property -dict [ list \
     CONFIG.M_TID_WIDTH.VALUE_SRC USER \
     CONFIG.M_TID_WIDTH {1} \
     CONFIG.TID_REMAP "1'b1" \
    ] $axis_taskwait_TID
  }

  if {${::AIT::lock_hwruntime}} {
    # Create instance: axis_lock_TID, and set properties
    set axis_lock_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_lock_TID]
    set_property -dict [ list \
     CONFIG.M_TID_WIDTH.VALUE_SRC USER \
     CONFIG.M_TID_WIDTH {1} \
     CONFIG.TID_REMAP "1'b0"
    ] $axis_lock_TID
  }

  # Create instance: Picos_OmpSs_Manager, and set properties
  set Picos_OmpSs_Manager [ create_bd_cell -type ip -vlnv bsc:ompss:picos_ompss_manager Picos_OmpSs_Manager ]
  set POM_Config [list \
    CONFIG.AXILITE_INTF ${::AIT::enable_pom_axilite} \
    CONFIG.CMDIN_SUBQUEUE_LEN ${::AIT::cmdInSubqueue_len} \
    CONFIG.CMDOUT_SUBQUEUE_LEN ${::AIT::cmdOutSubqueue_len} \
    CONFIG.ENABLE_SPAWN_QUEUES ${::AIT::enable_spawn_queues} \
    CONFIG.ENABLE_TASK_CREATION ${::AIT::task_creation} \
    CONFIG.LOCK_SUPPORT ${::AIT::lock_hwruntime} \
    CONFIG.MAX_ACCS [expr {max(${::AIT::num_accs}, 2)}] \
    CONFIG.MAX_ACC_CREATORS [expr {max(${::AIT::num_acc_creators}, 2)}] \
    CONFIG.MAX_ACC_TYPES [expr {max([llength ${::AIT::accs}], 2)}] \
    CONFIG.MAX_ARGS_PER_TASK ${::AIT::max_args_per_task} \
    CONFIG.MAX_COPS_PER_TASK ${::AIT::max_copies_per_task} \
    CONFIG.MAX_DEPS_PER_TASK ${::AIT::max_deps_per_task} \
  ]

  if {${::AIT::enable_pom_axilite}} {
    lappend POM_Config CONFIG.DBG_AVAIL_COUNT_EN true CONFIG.DBG_AVAIL_COUNT_W 40
  }

  if {${::AIT::enable_spawn_queues}} {
    lappend POM_Config \
      CONFIG.SPAWNIN_QUEUE_LEN ${::AIT::spawnInQueue_len} \
      CONFIG.SPAWNOUT_QUEUE_LEN ${::AIT::spawnOutQueue_len} \
  }

  if {${::AIT::task_creation} && ${::AIT::deps_hwruntime}} {
    lappend POM_Config \
      CONFIG.DM_DS ${::AIT::picos_dm_ds} \
      CONFIG.DM_HASH ${::AIT::picos_dm_hash} \
      CONFIG.DM_SIZE ${::AIT::picos_dm_size} \
      CONFIG.ENABLE_DEPS ${::AIT::deps_hwruntime} \
      CONFIG.HASH_T_SIZE ${::AIT::picos_hash_t_size} \
      CONFIG.NUM_DCTS ${::AIT::picos_num_dcts} \
      CONFIG.TM_SIZE ${::AIT::picos_tm_size} \
      CONFIG.VM_SIZE ${::AIT::picos_vm_size} \
  }

  set_property -dict $POM_Config $Picos_OmpSs_Manager

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
   CONFIG.Write_Depth_A [expr {${::AIT::cmdInSubqueue_len}*max(${::AIT::num_accs}, 2)}] \
   CONFIG.Write_Width_A {64} \
   CONFIG.Write_Width_B {32} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $cmdInQueue

  # Create instance: cmdInQueue_BRAM_Ctrl, and set properties
  set cmdInQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdInQueue_BRAM_Ctrl ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
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
   CONFIG.Write_Depth_A [expr {${::AIT::cmdOutSubqueue_len}*max(${::AIT::num_accs}, 2)}] \
   CONFIG.Write_Width_A {64} \
   CONFIG.Write_Width_B {32} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $cmdOutQueue

  # Create instance: cmdOutQueue_BRAM_Ctrl, and set properties
  set cmdOutQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdOutQueue_BRAM_Ctrl ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $cmdOutQueue_BRAM_Ctrl

if {${::AIT::enable_spawn_queues}} {
    # Create instance: spawnInQueue, and set properties
    set spawnInQueue [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen spawnInQueue ]
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
        CONFIG.Write_Depth_A ${::AIT::spawnInQueue_len} \
        CONFIG.Write_Width_A {64} \
        CONFIG.Write_Width_B {32} \
        CONFIG.use_bram_block {Stand_Alone} \
    ] $spawnInQueue

    # Create instance: spawnInQueue_BRAM_Ctrl, and set properties
    set spawnInQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl spawnInQueue_BRAM_Ctrl ]
    set_property -dict [ list \
        CONFIG.PROTOCOL {AXI4LITE} \
        CONFIG.SINGLE_PORT_BRAM {1} \
    ] $spawnInQueue_BRAM_Ctrl

    # Create instance: spawnOutQueue, and set properties
    set spawnOutQueue [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen spawnOutQueue ]
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
        CONFIG.Write_Depth_A ${::AIT::spawnOutQueue_len} \
        CONFIG.Write_Width_A {64} \
        CONFIG.Write_Width_B {32} \
        CONFIG.use_bram_block {Stand_Alone} \
    ] $spawnOutQueue

    # Create instance: spawnOutQueue_BRAM_Ctrl, and set properties
    set spawnOutQueue_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl spawnOutQueue_BRAM_Ctrl ]
    set_property -dict [ list \
        CONFIG.PROTOCOL {AXI4LITE} \
        CONFIG.SINGLE_PORT_BRAM {1} \
    ] $spawnOutQueue_BRAM_Ctrl
}

  # Create interface connections
  connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/cmdout_in] [get_bd_intf_pins hwr_inStream/cmdout_in]
  connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins hwr_outStream/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/M_AXIS]
  if {${::AIT::task_creation}} {
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/spawn_in] [get_bd_intf_pins hwr_inStream/spawn_in]
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/spawn_out] [get_bd_intf_pins axis_spawn_TID/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins hwr_outStream/spawn_out] [get_bd_intf_pins axis_spawn_TID/M_AXIS]
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/taskwait_in] [get_bd_intf_pins hwr_inStream/taskwait_in]
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/taskwait_out] [get_bd_intf_pins axis_taskwait_TID/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins hwr_outStream/taskwait_out] [get_bd_intf_pins axis_taskwait_TID/M_AXIS]
  }
  if {${::AIT::lock_hwruntime}} {
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/lock_in] [get_bd_intf_pins hwr_inStream/lock_in]
    connect_bd_intf_net [get_bd_intf_pins Picos_OmpSs_Manager/lock_out] [get_bd_intf_pins axis_lock_TID/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins hwr_outStream/lock_out] [get_bd_intf_pins axis_lock_TID/M_AXIS]
  }
  connect_bd_intf_net -intf_net GP_Inter_M00_AXI [get_bd_intf_pins GP_Inter/M00_AXI] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/S_AXI]
  connect_bd_intf_net -intf_net GP_Inter_M01_AXI [get_bd_intf_pins GP_Inter/M01_AXI] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/S_AXI]
  connect_bd_intf_net -intf_net Picos_OmpSs_Manager_cmdInQueue [get_bd_intf_pins Picos_OmpSs_Manager/cmdin_queue] [get_bd_intf_pins cmdInQueue/BRAM_PORTA]
  connect_bd_intf_net -intf_net Picos_OmpSs_Manager_cmdOutQueue [get_bd_intf_pins Picos_OmpSs_Manager/cmdout_queue] [get_bd_intf_pins cmdOutQueue/BRAM_PORTA]
  connect_bd_intf_net -intf_net S_AXI_GP_1 [get_bd_intf_pins S_AXI_GP] [get_bd_intf_pins GP_Inter/S00_AXI]
  connect_bd_intf_net -intf_net cmdInQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdInQueue/BRAM_PORTB] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net cmdOutQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdOutQueue/BRAM_PORTB] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/BRAM_PORTA]
  if {${::AIT::enable_spawn_queues}} {
    connect_bd_intf_net -intf_net Picos_OmpSs_Manager_spawnInQueue [get_bd_intf_pins Picos_OmpSs_Manager/spawnin_queue] [get_bd_intf_pins spawnInQueue/BRAM_PORTA]
    connect_bd_intf_net -intf_net Picos_OmpSs_Manager_spawnOutQueue [get_bd_intf_pins Picos_OmpSs_Manager/spawnout_queue] [get_bd_intf_pins spawnOutQueue/BRAM_PORTA]
    connect_bd_intf_net -intf_net spawnInQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins spawnInQueue/BRAM_PORTB] [get_bd_intf_pins spawnInQueue_BRAM_Ctrl/BRAM_PORTA]
    connect_bd_intf_net -intf_net spawnOutQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins spawnOutQueue/BRAM_PORTB] [get_bd_intf_pins spawnOutQueue_BRAM_Ctrl/BRAM_PORTA]
    connect_bd_intf_net -intf_net GP_Inter_spawn_out [get_bd_intf_pins GP_Inter/M0${spawn_out_m}_AXI] [get_bd_intf_pins spawnOutQueue_BRAM_Ctrl/S_AXI]
    connect_bd_intf_net -intf_net GP_Inter_spawn_in [get_bd_intf_pins GP_Inter/M0${spawn_in_m}_AXI] [get_bd_intf_pins spawnInQueue_BRAM_Ctrl/S_AXI]
    connect_bd_net [get_bd_pins clk] [get_bd_pins spawnInQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins spawnOutQueue_BRAM_Ctrl/s_axi_aclk]
    connect_bd_net [get_bd_pins rstn] [get_bd_pins spawnInQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins spawnOutQueue_BRAM_Ctrl/s_axi_aresetn]
  }
  if {${::AIT::enable_pom_axilite}} {
    connect_bd_intf_net -intf_net GP_Inter_pom_axilite [get_bd_intf_pins GP_Inter/M0${pom_axilite_m}_AXI] [get_bd_intf_pins Picos_OmpSs_Manager/axilite]
  }

  # Create port connections
  connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/ACLK] [get_bd_pins GP_Inter/M00_ACLK] [get_bd_pins GP_Inter/M01_ACLK] [get_bd_pins GP_Inter/S00_ACLK] [get_bd_pins Picos_OmpSs_Manager/clk] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins hwr_inStream/clk] [get_bd_pins hwr_outStream/clk] [get_bd_pins axis_cmdin_TID/aclk]
  connect_bd_net [get_bd_pins rstn] [get_bd_pins GP_Inter/ARESETN] [get_bd_pins hwr_inStream/rstn] [get_bd_pins hwr_outStream/rstn]
  connect_bd_net [get_bd_pins rstn] [get_bd_pins GP_Inter/M00_ARESETN] [get_bd_pins GP_Inter/M01_ARESETN] [get_bd_pins GP_Inter/S00_ARESETN] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins hwr_inStream/rstn] [get_bd_pins hwr_outStream/rstn]
  connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins Picos_OmpSs_Manager/rstn] [get_bd_pins axis_cmdin_TID/aresetn]

  if {${::AIT::task_creation}} {
    connect_bd_net [get_bd_pins clk] [get_bd_pins axis_spawn_TID/aclk] [get_bd_pins axis_taskwait_TID/aclk]
    connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins axis_spawn_TID/aresetn] [get_bd_pins axis_taskwait_TID/aresetn]
  }
  if {${::AIT::enable_spawn_queues}} {
    connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/M0${spawn_out_m}_ACLK] [get_bd_pins GP_Inter/M0${spawn_in_m}_ACLK]
    connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins GP_Inter/M0${spawn_out_m}_ARESETN] [get_bd_pins GP_Inter/M0${spawn_in_m}_ARESETN]
  }
  if {${::AIT::enable_pom_axilite}} {
    connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/M0${pom_axilite_m}_ACLK]
    connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins GP_Inter/M0${pom_axilite_m}_ARESETN]
  }
  if {${::AIT::lock_hwruntime}} {
    connect_bd_net [get_bd_pins clk] [get_bd_pins axis_lock_TID/aclk]
    connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins axis_lock_TID/aresetn]
  }

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


