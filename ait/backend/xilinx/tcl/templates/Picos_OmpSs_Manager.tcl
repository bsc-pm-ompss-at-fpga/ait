#------------------------------------------------------------------------#
#    (C) Copyright 2017-2025 Barcelona Supercomputing Center             #
#                            Centro Nacional de Supercomputacion         #
#                                                                        #
#    This file is part of OmpSs@FPGA toolchain.                          #
#                                                                        #
#    This code is free software; you can redistribute it and/or modify   #
#    it under the terms of the GNU Lesser General Public License as      #
#    published by the Free Software Foundation; either version 3 of      #
#    the License, or (at your option) any later version.                 #
#                                                                        #
#    OmpSs@FPGA toolchain is distributed in the hope that it will be     #
#    useful, but WITHOUT ANY WARRANTY; without even the implied          #
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    #
#    See the GNU Lesser General Public License for more details.         #
#                                                                        #
#    You should have received a copy of the GNU Lesser General Public    #
#    License along with this code. If not, see <www.gnu.org/licenses/>.  #
#------------------------------------------------------------------------#

proc create_Hardware_Runtime_hier {} {
    set oldBdInstance [current_bd_instance .]

    set hierObj [create_bd_cell -type hier Hardware_Runtime]
    current_bd_instance ${hierObj}
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_GP
    create_bd_pin -dir I -type clk clk
    create_bd_pin -dir I -type rst managed_rstn
    create_bd_pin -dir I -type rst rstn

    set hwrInStreamHier [create_hwr_inStream_hier]
    set hwrOutStreamHier [create_hwr_outStream_hier]

    #### Hardware_Runtime
    set GP_Inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect GP_Inter]
    set nmasters 2
    #  set GP_Inter_config [list CONFIG.M00_HAS_REGSLICE 4 CONFIG.M01_HAS_REGSLICE 4 CONFIG.S00_HAS_REGSLICE 4 CONFIG.STRATEGY 1]
    if {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]} {
      set spawn_out_m ${nmasters}
      incr nmasters
      set spawn_in_m ${nmasters}
      incr nmasters
    #    lappend GP_Inter_config CONFIG.M0${spawn_out_m}_HAS_REGSLICE 4 CONFIG.M0${spawn_in_m}_HAS_REGSLICE 4
    }
    if {[dict get ${AIT::vars::aitConfig} "enable_pom_axilite"]} {
      set pom_axilite_m ${nmasters}
      incr nmasters
    #    lappend GP_Inter_config CONFIG.M0${pom_axilite_m}_HAS_REGSLICE 4
    }
    lappend GP_Inter_config CONFIG.NUM_MI ${nmasters}
    set_property -dict ${GP_Inter_config} ${GP_Inter}

    # Create instance: axis_cmdin_TID, and set properties
    set axis_cmdin_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_cmdin_TID]
    set_property -dict [list \
     CONFIG.M_TID_WIDTH.VALUE_SRC USER \
     CONFIG.M_TID_WIDTH {1} \
     CONFIG.TID_REMAP "1'b0"
    ] ${axis_cmdin_TID}

    if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
      # Create instance: axis_spawn_TID, and set properties
      set axis_spawn_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_spawn_TID]
      set_property -dict [list \
       CONFIG.M_TID_WIDTH.VALUE_SRC USER \
       CONFIG.M_TID_WIDTH {1} \
       CONFIG.TID_REMAP "1'b1" \
      ] ${axis_spawn_TID}

      # Create instance: axis_taskwait_TID, and set properties
      set axis_taskwait_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_taskwait_TID]
      set_property -dict [list \
       CONFIG.M_TID_WIDTH.VALUE_SRC USER \
       CONFIG.M_TID_WIDTH {1} \
       CONFIG.TID_REMAP "1'b1" \
      ] ${axis_taskwait_TID}
    }

    if {[dict get ${AIT::vars::aitConfig} "lock_hwruntime"]} {
      # Create instance: axis_lock_TID, and set properties
      set axis_lock_TID [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_lock_TID]
      set_property -dict [list \
       CONFIG.M_TID_WIDTH.VALUE_SRC USER \
       CONFIG.M_TID_WIDTH {1} \
       CONFIG.TID_REMAP "1'b0"
      ] ${axis_lock_TID}
    }

    # Create instance: Picos_OmpSs_Manager, and set properties
    set PicosOmpSsManagerIP [create_bd_cell -type ip -vlnv bsc:ompss:picos_ompss_manager Picos_OmpSs_Manager]
    set POM_Config [list \
      CONFIG.AXILITE_INTF [dict get ${AIT::vars::aitConfig} "enable_pom_axilite"] \
      CONFIG.CMDIN_SUBQUEUE_LEN [dict get ${AIT::vars::aitConfig} "cmdin_subqueue_len"] \
      CONFIG.CMDOUT_SUBQUEUE_LEN [dict get ${AIT::vars::aitConfig} "cmdout_subqueue_len"] \
      CONFIG.ENABLE_SPAWN_QUEUES [expr {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]}] \
      CONFIG.ENABLE_TASK_CREATION [dict get ${AIT::vars::aitConfig} "task_creation"] \
      CONFIG.LOCK_SUPPORT [dict get ${AIT::vars::aitConfig} "lock_hwruntime"] \
      CONFIG.MAX_ACCS [expr {max([dict get ${AIT::vars::aitConfig} "num_instances"], 2)}] \
      CONFIG.MAX_ACC_CREATORS [expr {max([dict get ${AIT::vars::aitConfig} "num_acc_creators"], 2)}] \
      CONFIG.MAX_ACC_TYPES [expr {max([dict size [dict get ${AIT::vars::accs}]] + ([dict get ${AIT::vars::aitConfig} "ompif"] ? 2 : 0), 2)}] \
      CONFIG.MAX_ARGS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_args_per_task"] \
      CONFIG.MAX_COPS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_copies_per_task"] \
      CONFIG.MAX_DEPS_PER_TASK [dict get ${AIT::vars::aitConfig} "max_deps_per_task"] \
    ]

    if {[dict get ${AIT::vars::aitConfig} "enable_pom_axilite"]} {
      lappend POM_Config CONFIG.DBG_AVAIL_COUNT_EN true CONFIG.DBG_AVAIL_COUNT_W 40
    }

    if {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]} {
      lappend POM_Config \
        CONFIG.SPAWNIN_QUEUE_LEN [dict get ${AIT::vars::aitConfig} "spawnin_queue_len"] \
        CONFIG.SPAWNOUT_QUEUE_LEN [dict get ${AIT::vars::aitConfig} "spawnout_queue_len"] \
    }

    if {[dict get ${AIT::vars::aitConfig} "task_creation"] && [dict get ${AIT::vars::aitConfig} "deps_hwruntime"]} {
      lappend POM_Config \
        CONFIG.DM_DS [dict get ${AIT::vars::aitConfig} "picos_dm_ds"] \
        CONFIG.DM_HASH [dict get ${AIT::vars::aitConfig} "picos_dm_hash"] \
        CONFIG.DM_SIZE [dict get ${AIT::vars::aitConfig} "picos_dm_size"] \
        CONFIG.ENABLE_DEPS [dict get ${AIT::vars::aitConfig} "deps_hwruntime"] \
        CONFIG.HASH_T_SIZE [dict get ${AIT::vars::aitConfig} "picos_hash_t_size"] \
        CONFIG.NUM_DCTS [dict get ${AIT::vars::aitConfig} "picos_num_dcts"] \
        CONFIG.TM_SIZE [dict get ${AIT::vars::aitConfig} "picos_tm_size"] \
        CONFIG.VM_SIZE [dict get ${AIT::vars::aitConfig} "picos_vm_size"] \
    }

    set_property -dict ${POM_Config} ${PicosOmpSsManagerIP}

    # Create instance: cmdInQueue, and set properties
    set cmdInQueue [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen cmdInQueue]
    set_property -dict [list \
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
      CONFIG.Write_Depth_A [expr {[dict get ${AIT::vars::aitConfig} "cmdin_subqueue_len"]*max([dict get ${AIT::vars::aitConfig} "num_instances"], 2)}] \
      CONFIG.Write_Width_A {64} \
      CONFIG.Write_Width_B {32} \
      CONFIG.use_bram_block {Stand_Alone} \
    ] ${cmdInQueue}

    # Create instance: cmdInQueue_BRAM_Ctrl, and set properties
    set cmdInQueue_BRAM_Ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdInQueue_BRAM_Ctrl]
    set_property -dict [list \
      CONFIG.PROTOCOL {AXI4LITE} \
      CONFIG.SINGLE_PORT_BRAM {1} \
    ] ${cmdInQueue_BRAM_Ctrl}

    # Create instance: cmdOutQueue, and set properties
    set cmdOutQueue [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen cmdOutQueue]
    set_property -dict [list \
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
     CONFIG.Write_Depth_A [expr {[dict get ${AIT::vars::aitConfig} "cmdout_subqueue_len"]*max([dict get ${AIT::vars::aitConfig} "num_instances"], 2)}] \
     CONFIG.Write_Width_A {64} \
     CONFIG.Write_Width_B {32} \
     CONFIG.use_bram_block {Stand_Alone} \
    ] ${cmdOutQueue}

    # Create instance: cmdOutQueue_BRAM_Ctrl, and set properties
    set cmdOutQueue_BRAM_Ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl cmdOutQueue_BRAM_Ctrl]
    set_property -dict [list \
     CONFIG.PROTOCOL {AXI4LITE} \
     CONFIG.SINGLE_PORT_BRAM {1} \
     ] ${cmdOutQueue_BRAM_Ctrl}

    if  {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]} {
      # Create instance: spawnInQueue, and set properties
      set spawnInQueue [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen spawnInQueue]
      set_property -dict [list \
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
          CONFIG.Write_Depth_A [dict get ${AIT::vars::aitConfig} "spawnin_queue_len"] \
          CONFIG.Write_Width_A {64} \
          CONFIG.Write_Width_B {32} \
          CONFIG.use_bram_block {Stand_Alone} \
      ] ${spawnInQueue}

      # Create instance: spawnInQueue_BRAM_Ctrl, and set properties
      set spawnInQueue_BRAM_Ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl spawnInQueue_BRAM_Ctrl]
      set_property -dict [list \
          CONFIG.PROTOCOL {AXI4LITE} \
          CONFIG.SINGLE_PORT_BRAM {1} \
      ] ${spawnInQueue_BRAM_Ctrl}

      # Create instance: spawnOutQueue, and set properties
      set spawnOutQueue [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen spawnOutQueue]
      set_property -dict [list \
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
          CONFIG.Write_Depth_A [dict get ${AIT::vars::aitConfig} "spawnout_queue_len"] \
          CONFIG.Write_Width_A {64} \
          CONFIG.Write_Width_B {32} \
          CONFIG.use_bram_block {Stand_Alone} \
      ] ${spawnOutQueue}

      # Create instance: spawnOutQueue_BRAM_Ctrl, and set properties
      set spawnOutQueue_BRAM_Ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl spawnOutQueue_BRAM_Ctrl]
      set_property -dict [list \
          CONFIG.PROTOCOL {AXI4LITE} \
          CONFIG.SINGLE_PORT_BRAM {1} \
      ] ${spawnOutQueue_BRAM_Ctrl}
    }

    # Create interface connections
    connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/cmdout_in] [get_bd_intf_pins ${hwrInStreamHier}/cmdout_in]
    connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${hwrOutStreamHier}/cmdin_out] [get_bd_intf_pins axis_cmdin_TID/M_AXIS]

    if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/spawn_in] [get_bd_intf_pins ${hwrInStreamHier}/spawn_in]
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/spawn_out] [get_bd_intf_pins axis_spawn_TID/S_AXIS]
      connect_bd_intf_net [get_bd_intf_pins ${hwrOutStreamHier}/spawn_out] [get_bd_intf_pins axis_spawn_TID/M_AXIS]
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/taskwait_in] [get_bd_intf_pins ${hwrInStreamHier}/taskwait_in]
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/taskwait_out] [get_bd_intf_pins axis_taskwait_TID/S_AXIS]
      connect_bd_intf_net [get_bd_intf_pins ${hwrOutStreamHier}/taskwait_out] [get_bd_intf_pins axis_taskwait_TID/M_AXIS]
    }
    if {[dict get ${AIT::vars::aitConfig} "lock_hwruntime"]} {
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/lock_in] [get_bd_intf_pins ${hwrInStreamHier}/lock_in]
      connect_bd_intf_net [get_bd_intf_pins ${PicosOmpSsManagerIP}/lock_out] [get_bd_intf_pins axis_lock_TID/S_AXIS]
      connect_bd_intf_net [get_bd_intf_pins ${hwrOutStreamHier}/lock_out] [get_bd_intf_pins axis_lock_TID/M_AXIS]
    }
    connect_bd_intf_net -intf_net GP_Inter_M00_AXI [get_bd_intf_pins GP_Inter/M00_AXI] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/S_AXI]
    connect_bd_intf_net -intf_net GP_Inter_M01_AXI [get_bd_intf_pins GP_Inter/M01_AXI] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/S_AXI]
    connect_bd_intf_net -intf_net Picos_OmpSs_Manager_cmdInQueue [get_bd_intf_pins ${PicosOmpSsManagerIP}/cmdin_queue] [get_bd_intf_pins cmdInQueue/BRAM_PORTA]
    connect_bd_intf_net -intf_net Picos_OmpSs_Manager_cmdOutQueue [get_bd_intf_pins ${PicosOmpSsManagerIP}/cmdout_queue] [get_bd_intf_pins cmdOutQueue/BRAM_PORTA]
    connect_bd_intf_net -intf_net S_AXI_GP_1 [get_bd_intf_pins S_AXI_GP] [get_bd_intf_pins GP_Inter/S00_AXI]
    connect_bd_intf_net -intf_net cmdInQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdInQueue/BRAM_PORTB] [get_bd_intf_pins cmdInQueue_BRAM_Ctrl/BRAM_PORTA]
    connect_bd_intf_net -intf_net cmdOutQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins cmdOutQueue/BRAM_PORTB] [get_bd_intf_pins cmdOutQueue_BRAM_Ctrl/BRAM_PORTA]

    if {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]} {
      connect_bd_intf_net -intf_net Picos_OmpSs_Manager_spawnInQueue [get_bd_intf_pins ${PicosOmpSsManagerIP}/spawnin_queue] [get_bd_intf_pins spawnInQueue/BRAM_PORTA]
      connect_bd_intf_net -intf_net Picos_OmpSs_Manager_spawnOutQueue [get_bd_intf_pins ${PicosOmpSsManagerIP}/spawnout_queue] [get_bd_intf_pins spawnOutQueue/BRAM_PORTA]
      connect_bd_intf_net -intf_net spawnInQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins spawnInQueue/BRAM_PORTB] [get_bd_intf_pins spawnInQueue_BRAM_Ctrl/BRAM_PORTA]
      connect_bd_intf_net -intf_net spawnOutQueue_BRAM_Ctrl_BRAM_PORTA [get_bd_intf_pins spawnOutQueue/BRAM_PORTB] [get_bd_intf_pins spawnOutQueue_BRAM_Ctrl/BRAM_PORTA]
      connect_bd_intf_net -intf_net GP_Inter_spawn_out [get_bd_intf_pins GP_Inter/M0${spawn_out_m}_AXI] [get_bd_intf_pins spawnOutQueue_BRAM_Ctrl/S_AXI]
      connect_bd_intf_net -intf_net GP_Inter_spawn_in [get_bd_intf_pins GP_Inter/M0${spawn_in_m}_AXI] [get_bd_intf_pins spawnInQueue_BRAM_Ctrl/S_AXI]
      connect_bd_net [get_bd_pins clk] [get_bd_pins spawnInQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins spawnOutQueue_BRAM_Ctrl/s_axi_aclk]
      connect_bd_net [get_bd_pins rstn] [get_bd_pins spawnInQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins spawnOutQueue_BRAM_Ctrl/s_axi_aresetn]
    }
    if {[dict get ${AIT::vars::aitConfig} "enable_pom_axilite"]} {
      connect_bd_intf_net -intf_net GP_Inter_pom_axilite [get_bd_intf_pins GP_Inter/M0${pom_axilite_m}_AXI] [get_bd_intf_pins ${PicosOmpSsManagerIP}/axilite]
    }

    # Create port connections
    connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/ACLK] [get_bd_pins GP_Inter/M00_ACLK] [get_bd_pins GP_Inter/M01_ACLK] [get_bd_pins GP_Inter/S00_ACLK] [get_bd_pins ${PicosOmpSsManagerIP}/clk] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aclk] [get_bd_pins ${hwrInStreamHier}/clk] [get_bd_pins ${hwrOutStreamHier}/clk] [get_bd_pins axis_cmdin_TID/aclk]
    connect_bd_net [get_bd_pins rstn] [get_bd_pins GP_Inter/ARESETN] [get_bd_pins ${hwrInStreamHier}/rstn] [get_bd_pins ${hwrOutStreamHier}/rstn]
    connect_bd_net [get_bd_pins rstn] [get_bd_pins GP_Inter/M00_ARESETN] [get_bd_pins GP_Inter/M01_ARESETN] [get_bd_pins GP_Inter/S00_ARESETN] [get_bd_pins cmdInQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins cmdOutQueue_BRAM_Ctrl/s_axi_aresetn] [get_bd_pins ${hwrInStreamHier}/rstn] [get_bd_pins ${hwrOutStreamHier}/rstn]
    connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins ${PicosOmpSsManagerIP}/rstn] [get_bd_pins axis_cmdin_TID/aresetn]

    if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
      connect_bd_net [get_bd_pins clk] [get_bd_pins axis_spawn_TID/aclk] [get_bd_pins axis_taskwait_TID/aclk]
      connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins axis_spawn_TID/aresetn] [get_bd_pins axis_taskwait_TID/aresetn]
    }
    if {![dict get ${AIT::vars::aitConfig} "disable_spawn_queues"]} {
      connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/M0${spawn_out_m}_ACLK] [get_bd_pins GP_Inter/M0${spawn_in_m}_ACLK]
      connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins GP_Inter/M0${spawn_out_m}_ARESETN] [get_bd_pins GP_Inter/M0${spawn_in_m}_ARESETN]
    }
    if {[dict get ${AIT::vars::aitConfig} "enable_pom_axilite"]} {
      connect_bd_net [get_bd_pins clk] [get_bd_pins GP_Inter/M0${pom_axilite_m}_ACLK]
      connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins GP_Inter/M0${pom_axilite_m}_ARESETN]
    }
    if {[dict get ${AIT::vars::aitConfig} "lock_hwruntime"]} {
      connect_bd_net [get_bd_pins clk] [get_bd_pins axis_lock_TID/aclk]
      connect_bd_net [get_bd_pins managed_rstn] [get_bd_pins axis_lock_TID/aresetn]
    }

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

proc create_hwr_inStream_hier {} {
    set oldBdInstance [current_bd_instance .]

    # Create cell and set as current instance
    set hierObj [create_bd_cell -type hier hwr_inStream]
    current_bd_instance ${hierObj}

    # Create interface pins
    for {set i 0} {${i} < [dict get ${AIT::vars::aitConfig} "num_instances"]} {incr i} {
        create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S${i}_AXIS
    }
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 cmdout_in
    if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
        create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 spawn_in
        create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 taskwait_in
    }
    if {[dict get ${AIT::vars::aitConfig} "lock_hwruntime"]} {
        create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 lock_in
    }

    # Create pins
    create_bd_pin -dir I -type clk clk
    create_bd_pin -dir I -type rst rstn

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

proc create_hwr_outStream_hier {} {
    set oldBdInstance [current_bd_instance .]

    ### hwr_outStream
    set hierObj [create_bd_cell -type hier hwr_outStream]
    current_bd_instance ${hierObj}

    # Create interface pins
    for {set i 0} {${i} < [dict get ${AIT::vars::aitConfig} "num_instances"]} {incr i} {
        create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M${i}_AXIS
    }
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 cmdin_out
    if {[dict get ${AIT::vars::aitConfig} "task_creation"]} {
        create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 spawn_out
        create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 taskwait_out
    }
    if {[dict get ${AIT::vars::aitConfig} "lock_hwruntime"]} {
        create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 lock_out
    }

    # Create pins
    create_bd_pin -dir I -type clk clk
    create_bd_pin -dir I -type rst rstn

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

set oldBdInstance [current_bd_instance .]

set retObj [create_Hardware_Runtime_hier]

save_bd_design

current_bd_instance ${oldBdInstance}

return ${retObj}
