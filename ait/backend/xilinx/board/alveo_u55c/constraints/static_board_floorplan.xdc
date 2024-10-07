# Bridge to host
# These should be placed near PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp { \
    .*/bridge_to_host/QDMA_M_AXI_LITE_Inter \
    .*/bridge_to_host/QDMA \
}]

# Hardware Runtime
# Place in center SLR in order to minimize SLR crossings
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells */Hardware_Runtime]

# Interconnection to HBM
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -regexp { \
    .*/S_AXI_[0-9]{2}_Inter \
}]

# Misc.
# These are placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical { \
    M_AXI_Inter \
    bitInfo \
    bitInfo_BRAM_Ctrl \
    managed_reset \
}]

## Memory
#HBM
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells */bridge_to_host/memory]

# Improve QDMA floorplanning
create_pblock qdma_pcie
resize_pblock [get_pblocks qdma_pcie] -add {CLOCKREGION_X7Y3:CLOCKREGION_X7Y0}
add_cells_to_pblock [get_pblocks qdma_pcie] [get_cells */bridge_to_host/QDMA/QDMA/inst/pcie4c_ip_i]

# Ethernet subsystem and OMPIF
create_pblock eth_subsys
resize_pblock [get_pblocks eth_subsys] -add {CLOCKREGION_X0Y7:CLOCKREGION_X1Y4}

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp .*/eth_decoder_rs/.*slr_master]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp .*/eth_decoder_rs/.*slr_slave]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells */meep_packet_decoder]
add_cells_to_pblock [get_pblocks eth_subsys] [get_cells */ethernet_subsystem/eth_100G_controller_0]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells {*/ompif_message_sender_0/ompif_message_sender */ompif_message_sender_0/axis_clk_conv_in */ompif_message_sender_0/axis_clk_conv_out}]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells {*/ompif_message_receiver_0/ompif_message_receiver */ompif_message_receiver_0/axis_clk_conv_in */ompif_message_receiver_0/axis_clk_conv_out}]

add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp .*/eth_encoder_rs/.*slr_master]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp .*/eth_encoder_rs/.*slr_slave]
add_cells_to_pblock [get_pblocks eth_subsys] [get_cells */ethernet_subsystem/eth_100G_rx_wrapper_0]
