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
open_project [dict get ${AIT::vars::aitConfig} "name"]/[dict get ${AIT::vars::aitConfig} "name"].xpr

# Check if previous step finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs impl_1]]]} {
    AIT::utils::error_msg "Implementation step did not finished correctly. Cannot generate bitstream."
}

# Open and validate Block Design
open_bd_design [get_files [dict get ${AIT::vars::aitConfig} "name"]_design.bd]
validate_bd_design -quiet

# Generate .bin file for Zynq and ZynqMP boards
if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
    || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {

    set_property -dict [list \
        STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE {true} \
    ] [get_runs impl_1]
} else {
    set_property -dict [list \
        STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE {false} \
    ] [get_runs impl_1]
}

AIT::utils::info_msg "Launching bitstream run with ${numJobs} jobs"

# Write bitstream
reset_runs impl_1 -from_step write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs ${numJobs}

wait_on_runs impl_1

# Check if bitstream generation finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs impl_1]]]} {
    AIT::utils::error_msg "Bitstream generation failed."
}

file mkdir [dict get ${AIT::vars::aitConfig} "name"]/[dict get ${AIT::vars::aitConfig} "name"].sdk

if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
    || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {

    # Set basic platform properties
    set_property -dict [list \
        pfm_name [get_property board_part [current_project]] \
    ] [get_files [current_bd_design].bd]
    set_property -dict [list \
        PFM.CLOCK {clk_app {id "0" is_default "true" proc_sys_reset "system_reset" }} \
    ] [get_bd_cells clock_generator]

    # Generate xsa files
    write_hw_platform -force -fixed -unified -include_bit [dict get ${AIT::vars::aitConfig} "name"]/[dict get ${AIT::vars::aitConfig} "name"].sdk/[dict get ${AIT::vars::aitConfig} "name"]_design_wrapper.xsa
    validate_hw_platform [dict get ${AIT::vars::aitConfig} "name"]/[dict get ${AIT::vars::aitConfig} "name"].sdk/[dict get ${AIT::vars::aitConfig} "name"]_design_wrapper.xsa
}
