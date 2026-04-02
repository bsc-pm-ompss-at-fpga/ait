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

namespace eval resets {
    # Connects srcRst to dstRst (pin or net) or to the default reset
    proc connect_reset {srcRst {dstRst ""}} {
        if {${dstRst} eq ""} {
            set dstRst [get_bd_pins /system_reset/clk_app_rstn]
        }
        if {![llength [get_bd_nets -quiet -of_objects ${srcRst}]]} {
            if {[get_property CLASS ${dstRst}] eq "bd_net"} {
                connect_bd_net ${srcRst} -net ${dstRst}
            } elseif {[get_property CLASS ${dstRst}] eq "bd_pin"} {
                connect_bd_net ${srcRst} ${dstRst}
            }
        }
        return ${dstRst}
    }

    proc create_reset {clkPinName {managed False} {rstBdInstance "/system_reset"}} {
        set oldBdInstance [current_bd_instance .]
        current_bd_instance ${rstBdInstance}

        set clkPin [get_bd_pins ${clkPinName}]
        set clkIP [get_bd_cells -of_objects ${clkPin}]
        set clkName [get_property NAME ${clkPin}]
        set rstName [regsub -all {(_clk$)} ${clkName} ""]

        if {${managed}} {
            append rstName "_managed"
        }

        # If the reset pin already exists, do nothing
        set rstPin [get_bd_pins -quiet ${rstName}_rstn]
        if {![llength ${rstPin}]} {
            set rstIP [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_${rstName}]
            set_property -dict [list \
                CONFIG.C_EXT_RST_WIDTH {1}
            ] ${rstIP}

            # We ignore errors, because the clock pin might already exist
            set clkHierPin [create_bd_pin -quiet -dir I -type clk ${clkName}]
            connect_bd_net -quiet ${clkPin} ${clkHierPin}

            # We ignore errors, because the locked pin might already exist
            set lockedHierPin [create_bd_pin -quiet -dir I [get_property NAME ${clkIP}]_locked]
            connect_bd_net -quiet [get_bd_pins ${clkIP}/locked] ${lockedHierPin}

            set rstPin [create_bd_pin -dir O -type reset ${rstName}_rstn]
            connect_bd_net ${clkHierPin} [get_bd_pins ${rstIP}/slowest_sync_clk]
            connect_bd_net ${rstPin} [get_bd_pins ${rstIP}/peripheral_aresetn]
            connect_bd_net [get_bd_pins [get_bd_cells -of_objects ${clkPin}]/locked] [get_bd_pins ${rstIP}/dcm_locked]

            if {${managed}} {
                connect_bd_net [get_bd_pins managed_reset_AND/Res] [get_bd_pins ${rstIP}/ext_reset_in]
            } else {
                connect_bd_net [get_bd_pins pcie_perstn] [get_bd_pins ${rstIP}/ext_reset_in]
            }
        }

        current_bd_instance ${oldBdInstance}

        return ${rstPin}
    }

    proc get_associated_rst_pin {clkPinName} {
        set clkPin [get_bd_pins ${clkPinName}]
        set clkIP [get_bd_cells -of_objects ${clkPin}]
        foreach rstPin [split [get_property CONFIG.ASSOCIATED_RESET ${clkPin}] {:}] {
            set rstPin [get_bd_pins -quiet ${clkIP}/${rstPin}]
            if {[llength ${rstPin}]} {
                return ${rstPin}
            }
        }
        AIT::utils::warning_msg "No associated reset pin found for clock ${clkPinName}"
    }

    proc get_synchronous_rst_pin {clkPinName} {
        set clkPin [get_bd_pins ${clkPinName}]
        foreach rstPin [get_associated_rst_pin ${clkPin}] {
            set srcRstPin [AIT::design::get_driver_pin ${rstPin}]
            if {[llength ${srcRstPin}]} {
                return ${srcRstPin}
            }
        }
        AIT::utils::warning_msg "No synchronous reset pin found for clock pin ${clkPinName}"
    }
}
