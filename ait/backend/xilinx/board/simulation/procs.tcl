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

# Connects source pin received as argument to the output of the clock generator IP
proc AIT::connect_clock {srcPin} {
    connect_bd_net -quiet [get_bd_pins $srcPin] [get_bd_pins /clk]
}

# Connects reset
proc AIT::connect_reset {rst_source rst_name} {
    connect_bd_net -quiet $rst_source [get_bd_pins /rstn]
}

proc AIT::set_and_get_freq {targetFreq} {
    return $targetFreq
}

proc AIT::configure_address_map {} {
    #assign_bd_address [get_bd_addr_segs {axi_stub_0/s_axi/reg0 }] -offset 0 -range 16E
}

proc AIT::get_base_freq {} {
    return 100
}
