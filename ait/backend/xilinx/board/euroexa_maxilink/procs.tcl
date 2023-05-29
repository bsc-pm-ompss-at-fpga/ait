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

            set base_addr [dict get ${::AIT::address_map} "mem_base_addr"]
            set bank_size [dict get ${::AIT::address_map} "mem_bank_size"]
            set num_banks [dict get ${::AIT::address_map} "mem_num_banks"]

            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_1.*_DDR4_ADDRESS_BLOCK"] -range 16G -offset $base_addr
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_1.*/C0_DDR4_MEMORY_MAP_CTRL/C0_REG"] -offset [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + 0x100000] -range 1M
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_2.*_DDR4_ADDRESS_BLOCK"] -range 8G -offset [expr $base_addr + $bank_size*2]
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_2.*/C0_DDR4_MEMORY_MAP_CTRL/C0_REG"] -offset [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + 0x100000*2] -range 1M
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_3.*_DDR4_ADDRESS_BLOCK"] -range 8G -offset [expr $base_addr + $bank_size*3]
            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_3.*/C0_DDR4_MEMORY_MAP_CTRL/C0_REG"] -offset [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + 0x100000*3] -range 1M

            assign_bd_address [get_bd_addr_segs "*DDR_aux_rst_gpio/S_AXI/Reg"] -offset [expr [dict get ${::AIT::address_map} "ompss_base_addr"] + [expr 0x100000*$num_banks]] -range 64K

            # Assign rest of peripherals
            assign_bd_address -offset 0x003000400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/memory/DDR_aux_rst_gpio/S_AXI/Reg] -force
            assign_bd_address -offset 0xC0000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/peripherals/axi_bram_ctrl_0/S_AXI/Mem0] -force
            assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/maxilink/maxilink/maxi_zu9m] [get_bd_addr_segs bridge_to_host/peripherals/axi_gpio_0/S_AXI/Reg] -force
            assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces bridge_to_host/peripherals/jtag_axi_0/Data] [get_bd_addr_segs clock_generator/s_axi_lite/Reg] -force
        }
    }
}
