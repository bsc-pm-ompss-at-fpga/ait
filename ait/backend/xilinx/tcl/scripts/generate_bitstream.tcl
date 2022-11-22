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

# Check if previous step finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *impl_1]]]} {
    AIT::error_msg "Implementation step did not finished correctly. Cannot generate bitstream."
}

# Open and validate Block Design
open_bd_design ${::AIT::name_Project}/${::AIT::name_Project}.srcs/sources_1/bd/${::AIT::name_Design}/${::AIT::name_Design}.bd
validate_bd_design

# Generate .bin file for Zynq and ZynqMP boards
if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
    set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
} else {
    set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE false [get_runs impl_1]
}

AIT::info_msg "Launching bitstream run with ${::AIT::num_jobs} jobs"

# Write bitstream
reset_run impl_1 -from_step write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs ${::AIT::num_jobs}

wait_on_run impl_1

# Check if bitstream generation finished correctly
if {[string match "*ERROR*" [get_property STATUS [get_runs *impl_1]]]} {
    AIT::error_msg "Bitstream generation failed."
}

file mkdir ${::AIT::name_Project}/${::AIT::name_Project}.sdk

if {[version -short] >= 2019.2} {
    # Generate hdf file (to use in petalinux 2018.3 and 2019.1)
    write_hwdef -force -file ${::AIT::name_Project}/${::AIT::name_Project}.sdk/${::AIT::name_Project}_design_wrapper.hdf

    # Set basic platform properties
    set_property pfm_name [get_property board_part [current_project]] [get_files *.bd]
    set_property PFM.CLOCK {clk_out1 {id "0" is_default "true" proc_sys_reset "processor_system_reset" }} [get_bd_cells clock_generator]

    # Generate xsa files (to use in petalinux 2019.2+)
    write_hw_platform -force -fixed -unified -include_bit ${::AIT::name_Project}/${::AIT::name_Project}.sdk/${::AIT::name_Project}_design_wrapper.xsa
    validate_hw_platform ${::AIT::name_Project}/${::AIT::name_Project}.sdk/${::AIT::name_Project}_design_wrapper.xsa
} else {
    set files [exec ls ${::AIT::name_Project}/${::AIT::name_Project}.runs/impl_1/]
    file copy -force ${::AIT::name_Project}/${::AIT::name_Project}.runs/impl_1/[lindex $files [lsearch $files *.sysdef]] ${::AIT::name_Project}/${::AIT::name_Project}.sdk/${::AIT::name_Project}_design_wrapper.hdf
}

