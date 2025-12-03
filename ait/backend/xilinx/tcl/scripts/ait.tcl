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

set scriptDir [file dirname [file normalize [info script]]]

# Load AIT utils
if {[catch {source -notrace ${scriptDir}/utils.tcl}]} {
	puts "\[AIT\] ERROR: Failed loading auxiliary procedures"
	exit 1
}

# Load design procedures
AIT::utils::info_msg "Loading design procedures"
if {[catch {source -notrace ${scriptDir}/design.tcl}]} {
	AIT::utils::error_msg "Failed loading design procedures"
}

# Load board procedures
AIT::utils::info_msg "Loading board procedures"
if {[catch {source -notrace ${scriptDir}/board.tcl}]} {
	AIT::utils::error_msg "Failed loading board procedures"
}

# Load templates procedures
AIT::utils::info_msg "Loading templates procedures"
if {[catch {source -notrace ${scriptDir}/templates.tcl}]} {
	AIT::utils::error_msg "Failed loading templates procedures"
}

# Load AXI utils procedures
AIT::utils::info_msg "Loading AXI utils procedures"
if {[catch {source -notrace ${scriptDir}/axi_utils.tcl}]} {
	AIT::utils::error_msg "Failed loading AXI utils procedures"
}

# Load AXI-Stream utils procedures
AIT::utils::info_msg "Loading AXI-Stream utils procedures"
if {[catch {source -notrace ${scriptDir}/axis_utils.tcl}]} {
	AIT::utils::error_msg "Failed loading AXI-Stream utils procedures"
}

# If available, overwrite board-specific procedures
if {[file exists ${scriptDir}/../../board/procs.tcl]} {
	AIT::utils::info_msg "Loading board-specific procedures"
	if {[catch {source -notrace ${scriptDir}/../../board/procs.tcl}]} {
		AIT::utils::error_msg "Failed overwriting board-specific procedures"
	}
}
