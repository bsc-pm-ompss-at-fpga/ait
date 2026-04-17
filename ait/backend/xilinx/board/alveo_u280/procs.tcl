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

namespace eval AIT {
    namespace eval board {
        proc static_logic_register_slices {} {
            # DDR 0
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 0 "" "" bridge_to_host/memory/DDR_0] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            # DDR 1
            lassign [AIT::AXI::add_reg_slice S_AXI [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}
            lassign [AIT::AXI::add_reg_slice S_AXI_CTRL [dict get ${AIT::vars::board} "arch" "slr" "memory"] 1 "" "" bridge_to_host/memory/DDR_1] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            # Hardware Runtime
            lassign [AIT::AXI::add_reg_slice S_AXI_GP 0 [dict get ${AIT::vars::board} "arch" "slr" "hwruntime"] "" "" Hardware_Runtime] intfPin regSliceConstr
            append constrStr ${regSliceConstr}

            save_bd_design -quiet
        }

        proc add_power_monitor {} {
            AIT::templates::source_template "power_monitor"
        }

        proc add_thermal_monitor {} {
            AIT::templates::source_template "thermal_monitor"
        }
    }
}
