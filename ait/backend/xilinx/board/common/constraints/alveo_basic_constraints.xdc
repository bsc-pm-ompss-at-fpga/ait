# Set bitstream user ID
set_property BITSTREAM.CONFIG.USERID BITSTREAM_USERID [current_design]

# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Enable automatic over temperature shutdown
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

# OMPIF ports false path
set_false_path -through [get_pins */jtag_gpio/gpio2_io_o[*]]
set_false_path -from [get_pins */ethernet_subsystem/eth_100G_controller_0/inst/eth_100G_controller_I/eth_cntrl_axilite_I/mac_addr_reg[*]/C]
set_false_path -from [get_pins */ethernet_subsystem/eth_100G_controller_0/inst/eth_100G_controller_I/eth_cntrl_axilite_I/ip_addr_reg[*]/C]
