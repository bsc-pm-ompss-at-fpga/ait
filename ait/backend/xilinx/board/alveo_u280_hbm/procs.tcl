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

namespace eval AIT {
    namespace eval board {

        set mem_port 0

        rename configure_address_map generic_configure_address_map

        proc configure_address_map {} {
            generic_configure_address_map
            if {(${::AIT::memory_bonding}) && ([llength [get_bd_addr_segs -regexp .*_mem_channel_bonding/S_AXI/reg0]])} {
                assign_bd_address [get_bd_addr_segs -regexp .*_mem_channel_bonding/S_AXI/reg0]
                include_bd_addr_seg [get_bd_addr_segs -excluded -regexp .*_mem_channel_bonding_reg0]
            }
        }

        proc get_available_data_ports {} {
            if {${::AIT::memory_bonding}} {
                return 15
            }
            return 31
        }

        proc connect_to_data_interface {src {num ""}} {
            variable mem_port

            set QDMA_port 15

            if {${::AIT::memory_bonding}} {
                set QDMA_port 7
            }

            set data_intf [expr ($mem_port*2)%32 + ($mem_port>15)]

            # AXI port used by QDMA, skipping it
            if {$data_intf eq $QDMA_port} {
                incr data_intf 2
                incr mem_port
            }

            set_property -dict [list CONFIG.USER_SAXI_[format %02u $data_intf] {true}] [get_bd_cells bridge_to_host/HBM/HBM]
            copy_bd_objs bridge_to_host/HBM [get_bd_cells -regexp bridge_to_host/HBM/S_AXI_QDMA(_0)?]
            set_property name S_AXI_${data_intf} [get_bd_cells -regexp bridge_to_host/HBM/S_AXI_QDMA(1|_2)]
            set_property name aclk [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/QDMA_aclk]
            set_property name aresetn [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/QDMA_peripheral_aresetn]

            connect_bd_net [get_bd_pins bridge_to_host/HBM/aclk] [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/aclk] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ACLK]
            connect_bd_net [get_bd_pins bridge_to_host/HBM/peripheral_aresetn] [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/aresetn] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ARESET_N]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins bridge_to_host/HBM/HBM/SAXI_[format %02u $data_intf]] [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/M_AXI]

            set interface [list "bridge_to_host/HBM/S_AXI_${data_intf}" "S_AXI"]

            if {${::AIT::memory_bonding}} {
                incr data_intf

                set_property -dict [list CONFIG.USER_SAXI_[format %02u $data_intf] {true}] [get_bd_cells bridge_to_host/HBM/HBM]
                copy_bd_objs bridge_to_host/HBM [get_bd_cells {bridge_to_host/HBM/S_AXI_QDMA_0}]
                set_property name S_AXI_${data_intf} [get_bd_cells bridge_to_host/HBM/S_AXI_QDMA_2]
                set_property name aclk [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/QDMA_aclk]
                set_property name aresetn [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/QDMA_peripheral_aresetn]

                connect_bd_net [get_bd_pins bridge_to_host/HBM/aclk] [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/aclk] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ACLK]
                connect_bd_net [get_bd_pins bridge_to_host/HBM/peripheral_aresetn] [get_bd_pins bridge_to_host/HBM/S_AXI_${data_intf}/aresetn] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ARESET_N]
                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins bridge_to_host/HBM/HBM/SAXI_[format %02u $data_intf]] [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/M_AXI]

                set interface [list "bridge_to_host/HBM/S_AXI_${data_intf}/HBM_data_width_converter" "S_AXI"]

                # Remove width converter if memory port width is 256b
                if {[get_property CONFIG.DATA_WIDTH [find_bd_objs -boundary_type lower -relation connected_to [get_bd_intf_pins $src]]] eq 256} {
                    delete_bd_objs [get_bd_cells bridge_to_host/HBM/S_AXI_${data_intf}/HBM_data_width_converter]
                    connect_bd_intf_net [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/S_AXI] [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/HBM_protocol_converter/S_AXI]
                    set interface [list "bridge_to_host/HBM/S_AXI_${data_intf}/HBM_protocol_converter" "S_AXI"]
                }

                incr data_intf -1

                set mem_channel_bonding [create_bd_cell -type ip -vlnv bsc:ompss:memory_channel_bonding:* bridge_to_host/HBM/S_AXI_${data_intf}_mem_channel_bonding]
                set_property -dict [list CONFIG.AXI_ID_WIDTH {4} CONFIG.AXI_ADDR_WIDTH {64} CONFIG.AXI_MASTER_DATA_WIDTH {256} CONFIG.WIDE_BANK_BITS {28} CONFIG.NARROW_BANK_CAPACITY {268435456}] $mem_channel_bonding
                connect_bd_intf_net [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/S_AXI] [get_bd_intf_pins $mem_channel_bonding/m0_axi]
                connect_bd_intf_net [get_bd_intf_pins bridge_to_host/HBM/S_AXI_[expr $data_intf + 1]/S_AXI] [get_bd_intf_pins $mem_channel_bonding/m1_axi]
                connect_bd_net [get_bd_pins $mem_channel_bonding/clk] [get_bd_pins bridge_to_host/HBM/aclk]
                connect_bd_net [get_bd_pins $mem_channel_bonding/rstn] [get_bd_pins bridge_to_host/HBM/peripheral_aresetn]

                set interface [list "$mem_channel_bonding" "S_AXI"]

                if {[get_property CONFIG.DATA_WIDTH [find_bd_objs -boundary_type lower -relation connected_to [get_bd_intf_pins $src]]] ne 512} {
                    set width_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:* bridge_to_host/HBM/S_AXI_${data_intf}_width_converter]
                    connect_bd_intf_net [get_bd_intf_pins $width_converter/M_AXI] [get_bd_intf_pins $mem_channel_bonding/s_axi]
                    connect_bd_net [get_bd_pins $width_converter/s_axi_aclk] [get_bd_pins bridge_to_host/HBM/aclk]
                    connect_bd_net [get_bd_pins $width_converter/s_axi_aresetn] [get_bd_pins bridge_to_host/HBM/peripheral_aresetn]

                    set interface [list "$width_converter" "S_AXI"]
                }
            }

            # Remove width converter if memory port width is 256b
            if {[get_property CONFIG.DATA_WIDTH [find_bd_objs -boundary_type lower -relation connected_to [get_bd_intf_pins $src]]] eq 256} {
                delete_bd_objs [get_bd_cells bridge_to_host/HBM/S_AXI_${data_intf}/HBM_data_width_converter]
                connect_bd_intf_net [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/S_AXI] [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}/HBM_protocol_converter/S_AXI]
                set interface [list "bridge_to_host/HBM/S_AXI_${data_intf}" "S_AXI"]
            }

            if {${::AIT::interleaving_stride} ne "None"} {
                create_bd_pin -dir I -from 63 -to 0 bridge_to_host/S_AXI_${data_intf}_intlv_awaddr
                connect_bd_net [get_bd_pins bridge_to_host/S_AXI_${data_intf}_intlv_awaddr] [get_bd_pins [lindex $interface 0]/[lindex $interface 1]_awaddr]
                connect_bd_net [get_bd_pins ${src}_awaddr] [get_bd_pins bridge_to_host/S_AXI_${data_intf}_intlv_awaddr]
                create_bd_pin -dir I -from 63 -to 0 bridge_to_host/S_AXI_${data_intf}_intlv_araddr
                connect_bd_net [get_bd_pins bridge_to_host/S_AXI_${data_intf}_intlv_araddr] [get_bd_pins [lindex $interface 0]/[lindex $interface 1]_araddr]
                connect_bd_net [get_bd_pins ${src}_araddr] [get_bd_pins bridge_to_host/S_AXI_${data_intf}_intlv_araddr]
            }

            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 bridge_to_host/S_AXI_${data_intf}
            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 bridge_to_host/HBM/S_AXI_${data_intf}
            connect_bd_intf_net [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}] -boundary_type upper [get_bd_intf_pins [lindex $interface 0]/[lindex $interface 1]]
            connect_bd_intf_net [get_bd_intf_pins bridge_to_host/S_AXI_${data_intf}] -boundary_type upper [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $src] [get_bd_intf_pins bridge_to_host/S_AXI_${data_intf}]

            # Add a line to datainterfaces.txt
            puts ${::dataInterfaces_file} "$src\t[lindex $interface 0]"

            incr mem_port

            save_bd_design

            return "$interface"
        }
    }
}
