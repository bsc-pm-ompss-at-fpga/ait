## Ethernet subsystem
### Ethernet pins in SLR2
create_pblock eth_subsys
resize_pblock [get_pblocks eth_subsys] -add {CLOCKREGION_X4Y12:CLOCKREGION_X5Y10}
add_cells_to_pblock [get_pblocks eth_subsys] [get_cells */ethernet_subsystem/eth_100G_controller_0]
add_cells_to_pblock [get_pblocks eth_subsys] [get_cells */ethernet_subsystem/eth_100G_rx_wrapper_0]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp .*/eth_encoder_rs/.*slr_master]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp .*/eth_decoder_rs/.*slr_slave]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp .*/eth_encoder_rs/.*slr_slave]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp .*/eth_decoder_rs/.*slr_master]

## OMPIF
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierachical OMPIF]
set_false_path -through [get_pins */jtag_gpio/gpio2_io_o[*]]
set_false_path -from [get_pins */ethernet_subsystem/eth_100G_controller_0/inst/eth_100G_controller_I/eth_cntrl_axilite_I/mac_addr_reg[*]/C]
set_false_path -from [get_pins */ethernet_subsystem/eth_100G_controller_0/inst/eth_100G_controller_I/eth_cntrl_axilite_I/ip_addr_reg[*]/C]
