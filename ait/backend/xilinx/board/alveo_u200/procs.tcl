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

namespace eval board {
    proc static_logic_register_slices {} {
        ## DDR 0
        lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::project::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
        append constrStr ${regSliceConstr}
        lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::project::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        ## DDR 1
        lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::project::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
        append constrStr ${regSliceConstr}
        lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::project::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        ## DDR 2
        lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::project::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_2] intfPin regSliceConstr
        append constrStr ${regSliceConstr}
        lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::project::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_2] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        ## DDR 3
        lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::project::board} "arch" "slr" "memory"] 2 "" "" bridge_to_host/memory/DDR_3] intfPin regSliceConstr
        append constrStr ${regSliceConstr}
        lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::project::board} "arch" "slr" "memory"] 2 "" "" bridge_to_host/memory/DDR_3] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        ## Hardware Runtime
        lassign [AIT::AXI::add_reg_slice S_AXI_GP [dict get ${AIT::project::board} "arch" "slr" "hwruntime"] 1 "" "" Hardware_Runtime] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        save_bd_design -quiet

        return ${constrStr}
    }

    proc add_power_monitor {} {
        AIT::templates::source_template "power_monitor"

        for {set i 0} {$i < 2} {incr i} {
            # Output ports
            set qsfp_lpmode [create_bd_port -dir O -from 0 -to 0 qsfp${i}_lpmode]
            set qsfp_modsel_l [create_bd_port -dir O -from 0 -to 0 qsfp${i}_modsel_l]
            set qsfp_reset_l [create_bd_port -dir O -from 0 -to 0 qsfp${i}_reset_l]
            connect_bd_net [get_bd_pins ${AIT::templates::powerMonitor::cmsIP}/qsfp${i}_lpmode] ${qsfp_lpmode}
            connect_bd_net [get_bd_pins ${AIT::templates::powerMonitor::cmsIP}/qsfp${i}_modsel_l] ${qsfp_modsel_l}
            connect_bd_net [get_bd_pins ${AIT::templates::powerMonitor::cmsIP}/qsfp${i}_reset_l] ${qsfp_reset_l}

            # Input ports
            set qsfp_int_l [create_bd_port -dir I -from 0 -to 0 qsfp${i}_int_l]
            set qsfp_modprs_l [create_bd_port -dir I -from 0 -to 0 qsfp${i}_modprs_l]
            connect_bd_net ${qsfp_int_l} [get_bd_pins ${AIT::templates::powerMonitor::cmsIP}/qsfp${i}_int_l]
            connect_bd_net ${qsfp_modprs_l} [get_bd_pins ${AIT::templates::powerMonitor::cmsIP}/qsfp${i}_modprs_l]
        }
    }

    proc add_thermal_monitor {} {
        AIT::templates::source_template "thermal_monitor"
    }

    proc configure_ethernet_subsystem {} {
        set_property -dict [list \
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_156mhz} \
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp1_4x} \
            CONFIG.RX_FLOW_CONTROL {0} \
            CONFIG.TX_FLOW_CONTROL {0} \
            CONFIG.USER_INTERFACE {AXIS} \
            CONFIG.GT_DRP_CLK {50} \
        ] ${AIT::templates::ethSubsys::eth100gbIP}
        set_property CONFIG.FREQ_HZ {156250000} [get_bd_intf_ports QSFP_CLK]
    }

    proc instantiate_ethernet_subsystem {} {
        set 50ClkPin [AIT::clocks::create_clock 50]
        set 100ClkPin [AIT::clocks::create_clock 100]
        set 200ClkPin [AIT::clocks::create_clock 200]

        set 100ClkRstPin [AIT::resets::create_reset ${100ClkPin}]
        set 200ClkRstPin [AIT::resets::create_reset ${200ClkPin}]

        connect_bd_net ${100ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_100]
        connect_bd_net ${100ClkRstPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_100_rstn]
        connect_bd_net ${200ClkRstPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_200_rstn]
        connect_bd_net ${50ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/init_clk]
        connect_bd_net ${200ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_200]
        connect_bd_net [get_bd_pins ${AIT::templates::ethSubsys::jtagAxiIP}/aclk] ${100ClkPin}
        connect_bd_net [get_bd_pins ${AIT::templates::ethSubsys::jtagAxiIP}/aresetn] ${100ClkRstPin}

        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${AIT::templates::ethSubsys::jtagAxiXbarIP}/S01_AXI] "" ${100ClkPin} ${100ClkRstPin}
    }
}
