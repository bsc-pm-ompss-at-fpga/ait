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
        # Hardware Runtime
        lassign [AIT::AXI::add_reg_slice S_AXI_GP 0 [dict get ${AIT::project::board} "arch" "slr" "hwruntime"] "" "" Hardware_Runtime] intfPin regSliceConstr
        append constrStr ${regSliceConstr}

        if {[dict get ${AIT::project::aitConfig} "ompif"]} {
            lassign [AIT::AXIS::add_reg_slice siCmd 1 0 "" sender_siCmd OMPIF/message_sender] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXIS::add_reg_slice siCmd 1 0 "" receiver_siCmd OMPIF/message_receiver] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXIS::add_reg_slice soCmd 0 1 "" sender_soCmd OMPIF/message_sender] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXIS::add_reg_slice soCmd 0 1 "" receiver_soCmd OMPIF/message_receiver] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
        }

        save_bd_design -quiet

        return ${constrStr}
    }

    proc add_power_monitor {} {
        AIT::templates::source_template "power_monitor"
    }

    proc add_thermal_monitor {} {
        AIT::templates::source_template "thermal_monitor"
    }

    proc configure_ethernet_subsystem {} {
        # Manually set the constraints because u55c board files don't work
        set_property -dict [list \
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y3} \
            CONFIG.GT_GROUP_SELECT {X0Y24~X0Y27} \
            CONFIG.GT_REF_CLK_FREQ {161.1328125} \
            CONFIG.GT_DRP_CLK {50}
        ] ${AIT::templates::ethSubsys::eth100gbIP}
        set_property CONFIG.FREQ_HZ {161132812} [get_bd_intf_ports QSFP_CLK]
    }

    proc instantiate_ethernet_subsystem {} {
        set 50ClkPin [AIT::clocks::create_clock 50]
        set 100SLR0ClkPin [AIT::clocks::create_clock 100 "freq_100_slr0" "clk_gen_slr0"]
        set 200SLR0ClkPin [AIT::clocks::create_clock 200 "freq_200_slr0" "clk_gen_slr0"]

        set 50ClkRstPin [AIT::resets::create_reset ${50ClkPin}]
        set 100SLR0ClkRstPin [AIT::resets::create_reset ${100SLR0ClkPin}]
        set 200SLR0ClkManagedRstPin [AIT::resets::create_reset ${200SLR0ClkPin} True]
        set 200SLR0ClkRstPin [AIT::resets::create_reset ${200SLR0ClkPin}]

        set_property NAME {QSFP0_CLK} ${AIT::templates::ethSubsys::qsfpClkPort}

        connect_bd_net ${100SLR0ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_100]
        connect_bd_net ${100SLR0ClkRstPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_100_rstn]
        connect_bd_net ${200SLR0ClkRstPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_200_rstn]
        connect_bd_net ${50ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/init_clk]
        connect_bd_net ${200SLR0ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::container}/clk_200]
        connect_bd_net ${100SLR0ClkPin} [get_bd_pins ${AIT::templates::ethSubsys::jtagAxiIP}/aclk]
        connect_bd_net ${100SLR0ClkRstPin} [get_bd_pins ${AIT::templates::ethSubsys::jtagAxiIP}/aresetn]

        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${AIT::templates::ethSubsys::jtagAxiXbarIP}/S01_AXI] "" ${100SLR0ClkPin} ${100SLR0ClkRstPin}
    }

    # This is done after acc instantiation because the HBM memory IP changes automatically the switch clock when connecting other AXI slaves
    proc after_acc_configuration {} {
        if {![dict get ${AIT::project::aitConfig} "ompif"]} {
            return
        }
        # Set switch 0 to 400Mhz clock to avoid bandwidth loss
        set_property CONFIG.USER_CLK_SEL_LIST0 AXI_31_ACLK [get_bd_cells bridge_to_host/memory/HBM]
    }
}
