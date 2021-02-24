#------------------------------------------------------------------------#
#    (C) Copyright 2017-2021 Barcelona Supercomputing Center             #
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

proc configureAddressMap {addr_list size_DDR} {
	assign_bd_address [get_bd_addr_segs -regexp ".*c1.*memaddr"]
	assign_bd_address -quiet $addr_list
	set_property offset 0x0 [get_bd_addr_segs -regexp ".*c1.*memaddr"]
	set_property range $size_DDR [get_bd_addr_segs -regexp ".*c1.*memaddr"]
}

proc generateWrapper {} {
	upvar #0 name_Design name_Design path_Project path_Project

	set_property target_language VHDL [current_project]

	exec sed -i "s|MCXX_DESIGN_WRAPPER|${name_Design}|g" $path_Project/board/alpha_data/sources/top_design.vhd
	exec sed -i "s|MCXX_TOP_DESIGN|${name_Design}_top|g" $path_Project/board/alpha_data/sources/top_design.vhd

	set design_name [get_bd_designs]
	
	make_wrapper -files [get_files $design_name.bd] -top
	
	add_files -norecurse -scan_for_includes $path_Project/board/alpha_data/sources/top_design.vhd
	
	set_property top top_design [current_fileset]
}
