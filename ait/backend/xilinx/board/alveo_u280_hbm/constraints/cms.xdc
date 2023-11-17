# Satellite UART
set_property PACKAGE_PIN D29                     [get_ports satellite_uart_txd]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_uart_txd]
set_property PACKAGE_PIN E28                     [get_ports satellite_uart_rxd]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_uart_rxd]

# Satellite GPIO
set_property PACKAGE_PIN K28                     [get_ports satellite_gpio[0]]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_gpio[0]]
set_property PACKAGE_PIN J29                     [get_ports satellite_gpio[1]]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_gpio[1]]
set_property PACKAGE_PIN K29                     [get_ports satellite_gpio[2]]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_gpio[2]]
set_property PACKAGE_PIN J31                     [get_ports satellite_gpio[3]]
set_property IOSTANDARD  LVCMOS18                [get_ports satellite_gpio[3]]
