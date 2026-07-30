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

set scriptDir [file dirname [file normalize [info script]]]
set projectRootDir ${scriptDir}/../..
set numJobs [lindex ${argv} 0]

# Open Vivado project
open_project [dict get ${AIT::project::aitConfig} "name"]/[dict get ${AIT::project::aitConfig} "name"].xpr

# Check if previous step finished correctly
if [string match "*ERROR*" [get_property STATUS [get_runs synth_1]]] {
    AIT::utils::error_msg "Synthesis step did not finished correctly. Cannot start implementation step."
}

# Open Block Design
open_bd_design [get_files [dict get ${AIT::project::aitConfig} "name"]_design.bd]

AIT::utils::info_msg "Launching implementation run with ${numJobs} jobs"

# Launch implementation run
launch_runs impl_1 -jobs ${numJobs}

# Check if implementation finished correctly
if [catch {wait_on_runs impl_1}] {
    AIT::utils::warning_msg "Failed implementation run:"
    AIT::utils::warning_msg "\t- [get_property NAME [get_runs impl_1]]"
    foreach runError [fileutil::grep ^ERROR [get_property DIRECTORY [get_runs impl_1]]/runme.log] {
        AIT::utils::warning_msg "\t\t[regsub [get_property DIRECTORY [get_runs impl_1]]/runme.log:\[0-9\]*: ${runError} ""]"
    }
    AIT::utils::error_msg "Hardware implementation failed."
}

if {![dict get ${AIT::project::aitConfig} "disable_vivado_reports"]} {
    # Generate implementation reports
    AIT::utils::info_msg "Generating implementation reports..."
    open_run impl_1
    report_utilization -hierarchical -hierarchical_percentages -hierarchical_depth 4 -file "${projectRootDir}/../products/reports/[dict get ${AIT::project::aitConfig} "name"].implementation.hier-utilization.txt"
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 12 -input_pins -routable_nets -name timing_1 -file "${projectRootDir}/../products/reports/[dict get ${AIT::project::aitConfig} "name"].implementation.timing-summary.txt"
    if [dict exists ${AIT::project::board} "arch" "slr"] {
        report_utilization -slr -file "${projectRootDir}/../products/reports/[dict get ${AIT::project::aitConfig} "name"].implementation.slr-utilization.txt"
    }
}
