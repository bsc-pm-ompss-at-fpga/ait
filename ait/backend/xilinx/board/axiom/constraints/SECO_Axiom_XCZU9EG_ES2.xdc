# User LED AXI_GPIO

set_property PACKAGE_PIN J10 [get_ports {user_gpio_tri_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_gpio_tri_io[0]}]

# I2C0 EMIO

set_property PACKAGE_PIN K13 [get_ports iic_0_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_0_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_0_sda_io]
set_property PACKAGE_PIN F10 [get_ports iic_0_sda_io]

# Display port EMIO

set_property PACKAGE_PIN F12 [get_ports DP_AUX_IN]
set_property IOSTANDARD LVCMOS33 [get_ports DP_AUX_IN]
set_property IOSTANDARD LVCMOS33 [get_ports DP_HPD]
set_property IOSTANDARD LVCMOS33 [get_ports {DP_OE[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports DPAUX_OUT]
set_property PACKAGE_PIN D10 [get_ports DP_HPD]
set_property PACKAGE_PIN G10 [get_ports {DP_OE[0]}]
set_property PACKAGE_PIN F11 [get_ports DPAUX_OUT]

# TRACE PORT EMIO

set_property PACKAGE_PIN Y4 [get_ports {TRACE_DATA[0]}]
set_property PACKAGE_PIN Y3 [get_ports {TRACE_DATA[1]}]
set_property PACKAGE_PIN Y2 [get_ports {TRACE_DATA[2]}]
set_property PACKAGE_PIN Y1 [get_ports {TRACE_DATA[3]}]
set_property PACKAGE_PIN W2 [get_ports {TRACE_DATA[4]}]
set_property PACKAGE_PIN V1 [get_ports {TRACE_DATA[5]}]
set_property PACKAGE_PIN U2 [get_ports {TRACE_DATA[6]}]
set_property PACKAGE_PIN U3 [get_ports {TRACE_DATA[7]}]
set_property PACKAGE_PIN T1 [get_ports {TRACE_DATA[8]}]
set_property PACKAGE_PIN U1 [get_ports {TRACE_DATA[9]}]
set_property PACKAGE_PIN Y7 [get_ports {TRACE_DATA[10]}]
set_property PACKAGE_PIN W5 [get_ports {TRACE_DATA[11]}]
set_property PACKAGE_PIN Y5 [get_ports {TRACE_DATA[12]}]
set_property PACKAGE_PIN V4 [get_ports {TRACE_DATA[13]}]
set_property PACKAGE_PIN W4 [get_ports {TRACE_DATA[14]}]
set_property PACKAGE_PIN U5 [get_ports {TRACE_DATA[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[14]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[12]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {TRACE_DATA[0]}]

set_property PACKAGE_PIN W1 [get_ports TRACE_CLK]
set_property IOSTANDARD LVCMOS18 [get_ports TRACE_CLK]

# Watchdog trigger

set_property PACKAGE_PIN E12 [get_ports {user_gpio_tri_io[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_gpio_tri_io[1]}]

# LEDs for debug purpose, LED0 are used to see whether trace data is currently being transmitted, while LED1 is used to verify that 250 MHz trace clock is running

set_property PACKAGE_PIN J12 [get_ports LED0]
set_property IOSTANDARD LVCMOS33 [get_ports LED0]
set_property PACKAGE_PIN H11 [get_ports LED1]
set_property IOSTANDARD LVCMOS33 [get_ports LED1]

# Compress bitstream

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

