#------------------------------------------------------------------------#
#    (C) Copyright 2017-2023 Barcelona Supercomputing Center             #
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
    AIT::error_msg "Failed sourcing project variables"
}

# Open Vivado project
open_project ${::AIT::name_Project}/${::AIT::name_Project}.xpr

# Open Block Design
open_bd_design ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd

# Generate output products
generate_target all [get_files ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd]

AIT::info_msg "Launching synthesis run with ${::AIT::num_jobs} jobs"

# Launch synthesis
reset_run synth_1
reset_target all [get_files ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd]
export_ip_user_files -of_objects [get_files ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd] -sync -no_script -force -quiet
delete_ip_run [get_files -of_objects [get_fileset sources_1] ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd]
launch_runs synth_1 -jobs ${::AIT::num_jobs}

wait_on_run synth_1

# Check if synthesis finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *synth_1]]]} {
    foreach {index} [lsearch -all [get_property STATUS [get_runs *synth_1]] *ERROR*] {
        if {[catch {exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/[lindex [get_runs *synth_1] $index]/runme.log}]} {
            AIT::info_msg "Failed OOC synthesis [lindex [get_runs *synth_1] $index]"
        } else {
            AIT::info_msg "Failed OOC synthesis [lindex [get_runs *synth_1] $index]: [exec grep ^ERROR ${::AIT::name_Project}/${::AIT::name_Project}.runs/[lindex [get_runs *synth_1] $index]/runme.log]"
        }
    }
    AIT::error_msg "Hardware synthesis failed."
}
