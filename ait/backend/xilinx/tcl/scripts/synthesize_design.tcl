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

# Open Block Design
open_bd_design [get_files ${::AIT::name_Design}.bd]

# Generate OOC synthesis runs sequentially to avoid Vivado aborting when checking the IPCACHE
generate_target {synthesis implementation} [get_files [current_bd_design].bd]
foreach ooc_ip [get_ips -all] {
    config_ip_cache -quiet -export $ooc_ip
}
export_ip_user_files -of_objects [get_files [current_bd_design].bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_filesets sources_1] [current_bd_design].bd]

AIT::utils::info_msg "Launching synthesis run with $num_jobs jobs"

# Launch and wait for synthesis
launch_runs synth_1 -jobs $num_jobs
wait_on_run synth_1

# Check if synthesis finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *synth_1]]]} {
    foreach {index} [lsearch -all [get_property STATUS [get_runs *synth_1]] *ERROR*] {
        if {[catch {exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/[lindex [get_runs *synth_1] $index]/runme.log}]} {
            AIT::utils::info_msg "Failed OOC synthesis [lindex [get_runs *synth_1] $index]"
        } else {
            AIT::utils::info_msg "Failed OOC synthesis [lindex [get_runs *synth_1] $index]: [exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/[lindex [get_runs *synth_1] $index]/runme.log]"
        }
    }
    AIT::utils::error_msg "Hardware synthesis failed."
}
