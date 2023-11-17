namespace eval AIT {
    namespace eval board {
        proc static_logic_register_slices {} {
            # AIT::AXI::add_reg_slice ip_name intf_name slr_master slr_slave {intf_pin} {num_pipelines} {prefix}
            # num_pipelines format: master:middle:slave
            # Pass unused optional arguments as ""

            # Hardware Runtime
            AIT::AXI::add_reg_slice Hardware_Runtime S_AXI_GP 0 ${::AIT::board_hwruntime_slr} "" "" static_

            save_bd_design
        }
    }
}
