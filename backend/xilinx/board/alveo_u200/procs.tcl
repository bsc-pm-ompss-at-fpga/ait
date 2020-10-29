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

set addr_base 0x0

proc configureDMAIntr {} {
	error "DMA is not available for the alveo_u200 board"
}

proc configureAddressMap {addr_list size_DDR} {
	assign_bd_address [get_bd_addr_segs -regexp ".*_DDR4_ADDRESS_BLOCK"]
	assign_bd_address -quiet $addr_list
	set_property offset 0x0 [get_bd_addr_segs -regexp ".*_DDR4_ADDRESS_BLOCK"]
	set_property range $size_DDR [get_bd_addr_segs -regexp ".*_DDR4_ADDRESS_BLOCK"]
}
