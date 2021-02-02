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

proc configureDMAIntr {} {
	if {[get_bd_cells -hierarchical *PCIe_inStream_Inter*] == ""} {

    	# Create instance: PCIe_inStream_Inter, and set properties
    	set PCIe_inStream_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect PCIe_inStream_Inter ]
    	set_property -dict [ list \
    	 CONFIG.ARB_ON_MAX_XFERS {0} \
    	 CONFIG.ARB_ON_TLAST {0} \
    	 CONFIG.M00_AXIS_HIGHTDEST {0x000000FF} \
    	 CONFIG.NUM_MI {1} \
    	 CONFIG.NUM_SI {1} \
 		]   $PCIe_inStream_Inter

    	# Create instance: PCIe_outStream_Inter, and set properties
    	set PCIe_outStream_Inter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect PCIe_outStream_Inter ]
    	set_property -dict [ list \
    	 CONFIG.NUM_MI {1} \
 		]   $PCIe_outStream_Inter

    	#create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 inStream
    	#create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 outStream

    	# Create instance: PCIe_packet_decoder, and set properties
    	set PCIe_packet_decoder [ create_bd_cell -type ip -vlnv bsc:ompss:PCIe_packet_decoder PCIe_packet_decoder ]

    	# Create instance: PCIe_packet_encoder, and set properties
    	set PCIe_packet_encoder [ create_bd_cell -type ip -vlnv bsc:ompss:PCIe_packet_encoder PCIe_packet_encoder ]

		set bridge_to_host [get_bd_cells -hierarchical *bridge_to_host*]

    	set_property -dict [ list \
    	   CONFIG.dma_engine1_config {4} \
    	   CONFIG.dma_engine2_config {3} \
    	   CONFIG.number_of_dma_engines {4} \
    	 ] $bridge_to_host

    	connect_bd_intf_net [get_bd_intf_pins PCIe_packet_decoder/inStream_V_V] [get_bd_intf_pins $bridge_to_host/dma1_m_axis]
    	connect_bd_intf_net [get_bd_intf_pins PCIe_packet_encoder/outStream_V_V] [get_bd_intf_pins $bridge_to_host/dma2_s_axis]
    	connect_bd_intf_net [get_bd_intf_pins $PCIe_inStream_Inter/M00_AXIS] [get_bd_intf_pins PCIe_packet_encoder/inStream]
    	connect_bd_intf_net [get_bd_intf_pins $PCIe_outStream_Inter/S00_AXIS] [get_bd_intf_pins PCIe_packet_decoder/outStream]

    	connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins PCIe_packet_decoder/ap_clk] [get_bd_pins PCIe_packet_encoder/ap_clk]
    	connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins PCIe_packet_decoder/ap_rst_n] [get_bd_pins PCIe_packet_encoder/ap_rst_n]

    	#connect_bd_intf_net [get_bd_intf_pins inStream] [get_bd_intf_pins PCIe/inStream]
    	#connect_bd_intf_net [get_bd_intf_pins outStream] [get_bd_intf_pins PCIe/outStream]

    	#connect_bd_intf_net [get_bd_intf_pins PCIe_inStream_Inter/M00_AXIS] [get_bd_intf_pins alpha_data_mem_PCIe/inStream]
    	#connect_bd_intf_net [get_bd_intf_pins PCIe_outStream_Inter/S00_AXIS] [get_bd_intf_pins alpha_data_mem_PCIe/outStream]

    	connect_bd_net -net ARESETN_2 [get_bd_pins $PCIe_inStream_Inter/ARESETN] [get_bd_pins $PCIe_outStream_Inter/ARESETN]
    	connect_bd_net -net aclk_1 [get_bd_pins $PCIe_inStream_Inter/M00_AXIS_ACLK] [get_bd_pins $PCIe_outStream_Inter/S00_AXIS_ACLK]
    	connect_bd_net -net aresetn_1 [get_bd_pins $PCIe_inStream_Inter/M00_AXIS_ARESETN] [get_bd_pins $PCIe_outStream_Inter/S00_AXIS_ARESETN]
    	connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins $PCIe_inStream_Inter/ACLK] [get_bd_pins $PCIe_inStream_Inter/S00_AXIS_ACLK] [get_bd_pins $PCIe_outStream_Inter/ACLK] [get_bd_pins $PCIe_outStream_Inter/M00_AXIS_ACLK]

    	connect_bd_net -net rst_admpcie7v3_axi4_demo_200M_peripheral_aresetn [get_bd_pins $PCIe_inStream_Inter/S00_AXIS_ARESETN] [get_bd_pins $PCIe_outStream_Inter/M00_AXIS_ARESETN]
	}
}


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
