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

package require json
package require fileutil

namespace eval AIT {
    variable scriptDir [file dirname [file normalize [info script]]]

    # Load AIT utils
    if {[catch {source -notrace ${scriptDir}/scripts/utils.tcl}]} {
        puts "\[AIT\] ERROR: Failed loading auxiliary procedures"
        exit 1
    }

    AIT::utils::info_msg "Loading AIT procedures..."

    # Design procedures
    if {[catch {source -notrace ${scriptDir}/scripts/design.tcl}]} {
        AIT::utils::error_msg "Failed loading design procedures"
    }

    # Board procedures
    if {[catch {source -notrace ${scriptDir}/scripts/board.tcl}]} {
        AIT::utils::error_msg "Failed loading board procedures"
    }

    # Templates procedures
    if {[catch {source -notrace ${scriptDir}/scripts/templates.tcl}]} {
        AIT::utils::error_msg "Failed loading templates procedures"
    }

    # AXI utils procedures
    if {[catch {source -notrace ${scriptDir}/scripts/axi_utils.tcl}]} {
        AIT::utils::error_msg "Failed loading AXI utils procedures"
    }

    # AXI-Stream utils procedures
    if {[catch {source -notrace ${scriptDir}/scripts/axis_utils.tcl}]} {
        AIT::utils::error_msg "Failed loading AXI-Stream utils procedures"
    }

    # Clocks procedures
    if {[catch {source -notrace ${scriptDir}/scripts/clocks.tcl}]} {
        AIT::utils::error_msg "Failed loading clocks procedures"
    }

    # Resets procedures
    if {[catch {source -notrace ${scriptDir}/scripts/resets.tcl}]} {
        AIT::utils::error_msg "Failed loading resets procedures"
    }

    # If available, overwrite board-specific procedures
    if {[file exists ${scriptDir}/../board/procs.tcl]} {
        if {[catch {source -notrace ${scriptDir}/../board/procs.tcl}]} {
            AIT::utils::error_msg "Failed overwriting board-specific procedures"
        }
    }

    # If available, load project variables
    if {[file exists ${scriptDir}/project.tcl]} {
        if {[catch {source -notrace ${scriptDir}/project.tcl}]} {
            AIT::utils::error_msg "Failed loading project variables"
        }
    }
}
