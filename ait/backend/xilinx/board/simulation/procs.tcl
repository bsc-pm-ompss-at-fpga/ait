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

namespace eval AIT {
    namespace eval board {

        rename configure_address_map generic_configure_address_map

        proc configure_address_map {} {
            #assign_bd_address [get_bd_addr_segs {axi_stub_0/s_axi/reg0 }] -offset 0 -range 16E
        }

        # Connects source pin received as argument to the output of the clock generator IP
        proc connect_clock {src_clk {dst_clk ""}} {
            connect_bd_net -quiet [get_bd_pins $src_clk] [get_bd_pins /clk]
        }

        # Connects reset
        proc connect_reset {src_rst {dst_rst ""}} {
            connect_bd_net -quiet $src_rst [get_bd_pins /rstn]
        }

        proc set_and_get_freq {targetFreq} {
            return $targetFreq
        }

        proc get_base_freq {} {
            return 100
        }
    }
}
