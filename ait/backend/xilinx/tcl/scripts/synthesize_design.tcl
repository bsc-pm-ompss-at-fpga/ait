#------------------------------------------------------------------------#
#    (C) Copyright 2017-2022 Barcelona Supercomputing Center             #
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

# Configuration variables
set script_path [file dirname [file normalize [info script]]]
if {[catch {source -notrace $script_path/../projectVariables.tcl}]} {
    puts "\[AIT\] ERROR: Failed sourcing project variables"
    exit 1
}

# Open Vivado project
open_project ./$name_Project/${name_Project}.xpr

# Open Block Design
open_bd_design ./$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd

# Generate output products
generate_target all [get_files ./$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd]

# Launch synthesis
reset_run synth_1
reset_target all [get_files ./$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd]
export_ip_user_files -of_objects [get_files ./$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd] -sync -no_script -force -quiet
delete_ip_run [get_files -of_objects [get_fileset sources_1] ./$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd]
launch_runs synth_1 -jobs $num_jobs

wait_on_run synth_1

# Check if synthesis finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *synth_1]]]} {
    foreach {index} [lsearch -all [get_property STATUS [get_runs *synth_1]] *ERROR*] {
        if {[catch {exec grep ERROR ./$name_Project/$name_Project.runs/[lindex [get_runs *synth_1] $index]/runme.log}]} {
            aitInfo "Failed OOC synthesis [lindex [get_runs *synth_1] $index]"
        } else {
            aitInfo "Failed OOC synthesis [lindex [get_runs *synth_1] $index]: [exec grep ERROR ./$name_Project/$name_Project.runs/[lindex [get_runs *synth_1] $index]/runme.log]"
        }
    }
    aitError "Hardware synthesis failed."
}
