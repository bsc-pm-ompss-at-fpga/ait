#------------------------------------------------------------------------#
#    (C) Copyright 2017-2024 Barcelona Supercomputing Center             #
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

# Load auxiliary procedures
if {[catch {source -notrace tcl/scripts/utils.tcl}]} {
    puts "\[AIT\] ERROR: Failed loading auxiliary procedures"
    exit 1
}

# Project variables
if {[catch {source -notrace tcl/projectVariables.tcl}]} {
    AIT::utils::error_msg "Failed sourcing project variables"
}

set num_jobs [lindex $argv 0]

# Open Vivado project
open_project ${::AIT::name_Project}/${::AIT::name_Project}.xpr

# Check if previous step finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs synth_1]]]} {
    AIT::utils::error_msg "Synthesis step did not finished correctly. Cannot start implementation step."
}

# Open Block Design
open_bd_design [get_files ${::AIT::name_Design}.bd]

# Generate .bin file for Zynq and ZynqMP boards
if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
    set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE {true} [get_runs impl_1]
} else {
    set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE {false} [get_runs impl_1]
}

AIT::utils::info_msg "Launching implementation run with $num_jobs jobs"

# Launch and wait for implementation
launch_runs impl_1 -jobs $num_jobs
wait_on_run impl_1

# Check if implementation finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs impl_1]]]} {
    if {[catch {exec exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/impl_1/runme.log}]} {
        AIT::utils::info_msg "Failed impl_1 implementation"
    } else {
        AIT::utils::info_msg "Failed impl_1 implementation: [exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/impl_1/runme.log]"
    }
    AIT::utils::error_msg "Hardware implementation failed."
}

