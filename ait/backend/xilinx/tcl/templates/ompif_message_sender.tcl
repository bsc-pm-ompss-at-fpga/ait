create_bd_cell -type hier ompif_message_sender_0
create_bd_cell -type ip -vlnv bsc:ompif:message_sender_wrapper ompif_message_sender_0/ompif_message_sender
set_property -dict [list \
    CONFIG.MAX_DEVICES {96} \
    CONFIG.MAX_TIMEOUT {1000000} \
    CONFIG.MAX_TIMEOUT_RAND_RANGE {1000000} \
    CONFIG.DEF_TIMEOUT {100000} CONFIG.DEBUG {1} \
    CONFIG.CONTROL_INTF {1} \
    CONFIG.TOTAL_LAT_WIDTH {40} \
    CONFIG.AXI_ADDR_WIDTH [AIT::utils::get_addr_width] \
    CONFIG.AXI_DATA_WIDTH {512} \
    CONFIG.MSG_DATA_SIZE {8960} \
] [get_bd_cells ompif_message_sender_0/ompif_message_sender]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter ompif_message_sender_0/axis_clk_conv_in
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter ompif_message_sender_0/axis_clk_conv_out

connect_bd_net [get_bd_pins cluster_size_slice/Dout] [get_bd_pins ompif_message_sender_0/ompif_message_sender/cluster_size]
connect_bd_net [get_bd_pins cluster_rank_slice/Dout] [get_bd_pins ompif_message_sender_0/ompif_message_sender/cluster_rank]

connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/siCmd] [get_bd_intf_pins ompif_message_sender_0/axis_clk_conv_in/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/soCmd] [get_bd_intf_pins ompif_message_sender_0/axis_clk_conv_out/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/soMsg] [get_bd_intf_pins axis_inter_eth_tx/S01_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_sw_dec/M01_AXIS] [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/siAck]

connect_bd_net [get_bd_pins ompif_message_sender_0/ompif_message_sender/clk] [get_bd_pins ${AIT::board::ompif_clk}] [get_bd_pins ompif_message_sender_0/axis_clk_conv_in/m_axis_aclk] [get_bd_pins ompif_message_sender_0/axis_clk_conv_out/s_axis_aclk]
connect_bd_net [get_bd_pins ompif_message_sender_0/ompif_message_sender/rstn] [get_bd_pins ${AIT::board::ompif_rstn}] [get_bd_pins ompif_message_sender_0/axis_clk_conv_in/m_axis_aresetn] [get_bd_pins ompif_message_sender_0/axis_clk_conv_out/s_axis_aresetn]
AIT::board::connect_clock [get_bd_pins ompif_message_sender_0/axis_clk_conv_in/s_axis_aclk]
connect_bd_net [get_bd_pins ompif_message_sender_0/axis_clk_conv_in/s_axis_aresetn] [get_bd_pins ompif_message_sender_0/axis_clk_conv_out/m_axis_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]
AIT::board::connect_clock [get_bd_pins ompif_message_sender_0/axis_clk_conv_out/m_axis_aclk]

AIT::board::connect_to_axi_intf [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/cntrl] M "" [get_bd_pins ${AIT::board::ompif_clk}] [get_bd_pins ${AIT::board::ompif_rstn}]

if {[dict get ${::AIT::address_map} "mem_type"] == "hbm"} {
    connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/moMEM] [get_bd_intf_pins axi_inter_msg_send/axi_register_slice_0/S_AXI]
} else {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins ompif_message_sender_0/ompif_message_sender/moMEM] S "" [get_bd_pins $AIT::board::ompif_clk] [get_bd_pins $AIT::board::ompif_rstn]
}

set accIDWidth [expr {max(int(ceil(log(${AIT::num_accs})/log(2))), 1)}]
# We need to insert accID to the new_task_spawner TID AXI-Stream signal
set tidSubsetConv [create_bd_cell -type module -reference bsc_axiu_axis_subset_converter ompif_message_sender_0/TID_subset_converter]
AIT::board::connect_clock [get_bd_pins $tidSubsetConv/clk]
connect_bd_net [get_bd_pins $tidSubsetConv/aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]

 # Add accID as AXI-Stream TID signal
set_property -dict [list \
    CONFIG.ID_WIDTH $accIDWidth \
    CONFIG.ID $accID \
] $tidSubsetConv

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ompif_message_sender_0/M_AXIS
connect_bd_intf_net [get_bd_intf_pins $tidSubsetConv/M_AXIS] [get_bd_intf_pins ompif_message_sender_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins ompif_message_sender_0/axis_clk_conv_out/M_AXIS] [get_bd_intf_pins $tidSubsetConv/S_AXIS]

