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

set numJobs [lindex ${argv} 0]

# Open Vivado project
open_project [dict get ${AIT::project::aitConfig} "name"]/[dict get ${AIT::project::aitConfig} "name"].xpr

# Open Block Design
open_bd_design [get_files [dict get ${AIT::project::aitConfig} "name"]_design.bd]

# Generate OOC synthesis runs sequentially to avoid Vivado aborting when checking the IPCACHE
generate_target {synthesis implementation} [get_files [current_bd_design].bd]

foreach IP [get_ips -all] {
    config_ip_cache -quiet -export ${IP}
}
export_ip_user_files -of_objects [get_files [current_bd_design].bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_filesets sources_1] [current_bd_design].bd]

AIT::utils::info_msg "Launching synthesis run with ${numJobs} jobs"

# Launch and wait for synthesis
# We have to ignore wait_on_runs return status because the command fails when a run fails
launch_runs synth_1 -jobs ${numJobs}
wait_on_runs -quiet synth_1

# Check if synthesis finished correctly
if [llength [get_runs -quiet -filter {STATUS =~ *ERROR*} *synth_1]] {
    AIT::utils::warning_msg "Failed synthesis runs:"
    foreach failedRun [get_runs -filter {STATUS =~ *ERROR*} *synth_1] {
        AIT::utils::warning_msg "\t[get_property NAME ${failedRun}]:"
        foreach runError [fileutil::grep ^ERROR [get_property DIRECTORY ${failedRun}]/runme.log] {
            AIT::utils::warning_msg "\t\t[regsub [get_property DIRECTORY ${failedRun}]/runme.log:\[0-9\]*: ${runError} ""]"
        }
    }
    AIT::utils::error_msg "Hardware synthesis failed."
}
