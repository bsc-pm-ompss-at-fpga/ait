namespace eval AIT {
    namespace eval board {
        proc static_logic_register_slices {} {
            # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
            # num_pipelines format: master:middle:slave
            # Pass unused optional arguments as ""

            # DDR 0
            AIT::AXI::add_reg_slice DDR_0 S_AXI ${::AIT::board_memory_slr} 0 "" "" static_
            AIT::AXI::add_reg_slice DDR_0 S_AXI_CTRL ${::AIT::board_memory_slr} 0 "" "" static_

            # DDR 1
            AIT::AXI::add_reg_slice DDR_1 S_AXI ${::AIT::board_memory_slr} 1 "" "" static_
            AIT::AXI::add_reg_slice DDR_1 S_AXI_CTRL ${::AIT::board_memory_slr} 1 "" "" static_

            # DDR 2
            AIT::AXI::add_reg_slice DDR_2 S_AXI ${::AIT::board_memory_slr} 1 "" "" static_
            AIT::AXI::add_reg_slice DDR_2 S_AXI_CTRL ${::AIT::board_memory_slr} 1 "" "" static_

            # DDR 3
            AIT::AXI::add_reg_slice DDR_3 S_AXI ${::AIT::board_memory_slr} 2 "" "" static_
            AIT::AXI::add_reg_slice DDR_3 S_AXI_CTRL ${::AIT::board_memory_slr} 2 "" "" static_

            # Hardware Runtime
            AIT::AXI::add_reg_slice Hardware_Runtime S_AXI_GP ${::AIT::board_hwruntime_slr} 1 "" "" static_

            save_bd_design
        }
    }
}
