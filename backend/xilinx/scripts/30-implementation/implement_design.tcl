#------------------------------------------------------------------------#
#    (C) Copyright 2017-2020 Barcelona Supercomputing Center             #
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
source -notrace $script_path/../projectVariables.tcl

# Open Vivado project
open_project $path_Project/$name_Project/${name_Project}.xpr

# Check if previous step finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *synth_1]]]} {
	error "\[AIT\] ERROR: Synthesis step did not finished correctly. Cannot start implementation step."
}

# Open Block Design
open_bd_design $path_Project/$name_Project/$name_Project.srcs/sources_1/bd/$name_Design/$name_Design.bd

# Generate .bin file
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Launch implementation
reset_run impl_1
launch_runs impl_1 -jobs $num_jobs

wait_on_run impl_1

# Check if implementation finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *impl_1]]]} {
	error "\[AIT\] ERROR: Hardware implementation failed."
}

