########## DDR CLOCKS #########
set_property PACKAGE_PIN H26 [get_ports DDR4_REFCLK_C1_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports DDR4_REFCLK_C1_clk_p]

set_property PACKAGE_PIN J16 [get_ports DDR4_REFCLK_C2_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports DDR4_REFCLK_C2_clk_p]

set_property PACKAGE_PIN AY13 [get_ports DDR4_REFCLK_C3_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports DDR4_REFCLK_C3_clk_p]

############## ASYNC clock group #################
##################################################
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks DDR4_REFCLK_C1_clk_p] \
    -group [get_clocks -include_generated_clocks DDR4_REFCLK_C2_clk_p] \
    -group [get_clocks -include_generated_clocks DDR4_REFCLK_C3_clk_p]
