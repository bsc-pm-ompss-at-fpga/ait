set addr_width [AIT::utils::get_addr_width]
set mbuffer_prefix [expr 2**($addr_width-30)-1]

create_bd_cell -type hier ompif_message_receiver_0
create_bd_cell -type ip -vlnv bsc:ompif:message_receiver_wrapper ompif_message_receiver_0/ompif_message_receiver
set_property -dict [list \
    CONFIG.MAX_DEVICES {96} \
    CONFIG.AXI_ADDR_WIDTH $addr_width \
    CONFIG.AXI_DATA_WIDTH {512} \
    CONFIG.MSG_DATA_SIZE {8960} \
    CONFIG.MBUFFER_ADDR_WIDTH {30} \
    CONFIG.MBUFFER_ADDR_PREFIX $mbuffer_prefix \
    CONFIG.MAX_OUTSTANDING_WRITES {8} \
] [get_bd_cells ompif_message_receiver_0/ompif_message_receiver]

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter ompif_message_receiver_0/axis_clk_conv_in
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter ompif_message_receiver_0/axis_clk_conv_out

connect_bd_net [get_bd_pins cluster_size_slice/Dout] [get_bd_pins ompif_message_receiver_0/ompif_message_receiver/cluster_size]

connect_bd_intf_net [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/siCmd] [get_bd_intf_pins ompif_message_receiver_0/axis_clk_conv_in/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/soCmd] [get_bd_intf_pins ompif_message_receiver_0/axis_clk_conv_out/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_rs_dec/M_AXIS] [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/msg_in]

connect_bd_net [get_bd_pins ompif_message_receiver_0/ompif_message_receiver/clk] [get_bd_pins ${AIT::board::ompif_clk}] [get_bd_pins ompif_message_receiver_0/axis_clk_conv_in/m_axis_aclk] [get_bd_pins ompif_message_receiver_0/axis_clk_conv_out/s_axis_aclk]
connect_bd_net [get_bd_pins ompif_message_receiver_0/ompif_message_receiver/rstn] [get_bd_pins ${AIT::board::ompif_rstn}] [get_bd_pins ompif_message_receiver_0/axis_clk_conv_in/m_axis_aresetn] [get_bd_pins ompif_message_receiver_0/axis_clk_conv_out/s_axis_aresetn]
AIT::board::connect_clock [get_bd_pins ompif_message_receiver_0/axis_clk_conv_in/s_axis_aclk]
connect_bd_net [get_bd_pins ompif_message_receiver_0/axis_clk_conv_in/s_axis_aresetn] [get_bd_pins ompif_message_receiver_0/axis_clk_conv_out/m_axis_aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]
AIT::board::connect_clock [get_bd_pins ompif_message_receiver_0/axis_clk_conv_out/m_axis_aclk]

if {[dict get ${::AIT::address_map} "mem_type"] == "hbm"} {
    connect_bd_intf_net [get_bd_intf_pins axi_inter_msg_recv_bufwr/axi_register_slice_0/S_AXI] [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/bufwr]
    connect_bd_intf_net [get_bd_intf_pins axi_inter_msg_recv_memcpy/axi_register_slice_0/S_AXI] [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/memcpy]
} else {
    AIT::board::connect_to_axi_intf [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/bufwr] S "" [get_bd_pins $AIT::board::ompif_clk] [get_bd_pins $AIT::board::ompif_rstn]
    AIT::board::connect_to_axi_intf [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/memcpy] S "" [get_bd_pins $AIT::board::ompif_clk] [get_bd_pins $AIT::board::ompif_rstn]
}

AIT::board::connect_to_axi_intf [get_bd_intf_pins ompif_message_receiver_0/ompif_message_receiver/cntrl] M "" [get_bd_pins ${AIT::board::ompif_clk}] [get_bd_pins ${AIT::board::ompif_rstn}]

set accIDWidth [expr {max(int(ceil(log(${AIT::num_accs})/log(2))), 1)}]
# We need to insert accID to the new_task_spawner TID AXI-Stream signal
set tidSubsetConv [create_bd_cell -type module -reference bsc_axiu_axis_subset_converter ompif_message_receiver_0/TID_subset_converter]
AIT::board::connect_clock [get_bd_pins $tidSubsetConv/clk]
connect_bd_net [get_bd_pins $tidSubsetConv/aresetn] [get_bd_pins system_reset/clk_app_managed_rstn]

# Add accID as AXI-Stream TID signal
set_property -dict [list \
    CONFIG.ID_WIDTH $accIDWidth \
    CONFIG.ID $accID \
] $tidSubsetConv

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ompif_message_receiver_0/M_AXIS
connect_bd_intf_net [get_bd_intf_pins $tidSubsetConv/M_AXIS] [get_bd_intf_pins ompif_message_receiver_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins ompif_message_receiver_0/axis_clk_conv_out/M_AXIS] [get_bd_intf_pins $tidSubsetConv/S_AXIS]

