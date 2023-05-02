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

namespace eval AIT {
    namespace eval board {

        rename configure_address_map generic_configure_address_map

        proc configure_address_map {} {
            generic_configure_address_map

            # Assign rest of peripherals
            create_bd_addr_seg -range 0x00010000 -offset 0x80000000 [get_bd_addr_spaces bridge_to_host/Data] [get_bd_addr_segs peri/axi_gpio_control/S_AXI/Reg] SEG_axi_gpio_control_Reg
        }
    }
}
