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

        proc get_available_data_ports {} {
            return 31
        }

        proc connect_to_data_interface {src {num ""}} {
            variable mem_port

            set QDMA_port 15

            set data_intf [expr ($mem_port*2)%32 + ($mem_port>15)]

            # AXI port used by QDMA, skipping it
            if {$data_intf eq $QDMA_port} {
                incr data_intf 2
                incr mem_port
            }

            set_property -dict [list CONFIG.USER_SAXI_[format %02u $data_intf] {true}] [get_bd_cells bridge_to_host/HBM/HBM]

            if {$mem_port eq 0} {

                set hier_cell [create_bd_cell -type hier bridge_to_host/HBM/S_AXI_${data_intf}]
                set hier_S_AXI_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 $hier_cell/S_AXI]
                set hier_M_AXI_port [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 $hier_cell/M_AXI]
                create_bd_pin -type clk -dir I $hier_cell/aclk
                create_bd_pin -type rst -dir I $hier_cell/aresetn

                # Add protocol converter or RAMA
                #set protocol_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:rama:* $hier_cell/HBM_RAMA]
                set protocol_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:* $hier_cell/HBM_protocol_converter]
                connect_bd_net [get_bd_pins $protocol_converter/aclk] [get_bd_pins $hier_cell/aclk]
                connect_bd_net [get_bd_pins $protocol_converter/aresetn] [get_bd_pins $hier_cell/aresetn]
                set int_S_AXI_port [get_bd_intf_pins $protocol_converter/S_AXI]
                set int_M_AXI_port [get_bd_intf_pins $protocol_converter/M_AXI]

                # Add width converter if memory port width is not 256b
                if {[get_property CONFIG.DATA_WIDTH [find_bd_objs -boundary_type lower -relation connected_to [get_bd_intf_pins $src]]] ne 256} {
                    set data_width_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:* $hier_cell/HBM_data_width_converter]
                    connect_bd_net [get_bd_pins $data_width_converter/s_axi_aclk] [get_bd_pins $hier_cell/aclk]
                    connect_bd_net [get_bd_pins $data_width_converter/s_axi_aresetn] [get_bd_pins $hier_cell/aresetn]
                    connect_bd_intf_net $int_S_AXI_port $data_width_converter/M_AXI
                    set int_S_AXI_port [get_bd_intf_pins $data_width_converter/S_AXI]
                }

                if {${::AIT::interleaving_stride} ne "None"} {
                    set awaddr_pin [create_bd_pin -dir I -from 63 -to 0 $hier_cell/S_AXI_intlv_awaddr]
                    set araddr_pin [create_bd_pin -dir I -from 63 -to 0 $hier_cell/S_AXI_intlv_araddr]
                    connect_bd_net $awaddr_pin [get_bd_pins ${int_S_AXI_port}_awaddr]
                    connect_bd_net $araddr_pin [get_bd_pins ${int_S_AXI_port}_araddr]
                }

                connect_bd_intf_net $int_M_AXI_port $hier_M_AXI_port
                connect_bd_intf_net $int_S_AXI_port $hier_S_AXI_port

            } else {
                copy_bd_objs bridge_to_host/HBM -prefix {copy_} [get_bd_cells bridge_to_host/HBM/S_AXI_0]
                set_property name S_AXI_${data_intf} [get_bd_cells bridge_to_host/HBM/copy_S_AXI_0]
                set hier_cell [get_bd_cells bridge_to_host/HBM/S_AXI_${data_intf}]
            }

            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 bridge_to_host/S_AXI_${data_intf}
            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 bridge_to_host/HBM/S_AXI_${data_intf}
            connect_bd_net [get_bd_pins bridge_to_host/HBM/aclk] [get_bd_pins $hier_cell/aclk] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ACLK]
            connect_bd_net [get_bd_pins bridge_to_host/HBM/peripheral_aresetn] [get_bd_pins $hier_cell/aresetn] [get_bd_pins bridge_to_host/HBM/HBM/AXI_[format %02u $data_intf]_ARESET_N]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}] [get_bd_intf_pins $hier_cell/S_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins bridge_to_host/HBM/HBM/SAXI_[format %02u $data_intf]] [get_bd_intf_pins $hier_cell/M_AXI]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins bridge_to_host/S_AXI_${data_intf}] [get_bd_intf_pins bridge_to_host/HBM/S_AXI_${data_intf}]
            connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $src] [get_bd_intf_pins bridge_to_host/S_AXI_${data_intf}]

            if {${::AIT::interleaving_stride} ne "None"} {
                set awaddr_pin [create_bd_pin -dir I -from 63 -to 0 bridge_to_host/HBM/S_AXI_${data_intf}_intlv_awaddr]
                set araddr_pin [create_bd_pin -dir I -from 63 -to 0 bridge_to_host/HBM/S_AXI_${data_intf}_intlv_araddr]
                connect_bd_net [get_bd_pins $awaddr_pin] [get_bd_pins $hier_cell/S_AXI_intlv_awaddr]
                connect_bd_net [get_bd_pins $araddr_pin] [get_bd_pins $hier_cell/S_AXI_intlv_araddr]
                connect_bd_net [get_bd_pins ${src}_awaddr] [get_bd_pins $hier_cell/S_AXI_intlv_awaddr]
                connect_bd_net [get_bd_pins ${src}_araddr] [get_bd_pins $hier_cell/S_AXI_intlv_araddr]
            }

            set interface [list "bridge_to_host/HBM/S_AXI_${data_intf}" "S_AXI"]

            # Add a line to datainterfaces.txt
            puts ${::dataInterfaces_file} "$src\t[lindex $interface 0]"

            incr mem_port

            save_bd_design

            return "$interface"
        }
    }
}
