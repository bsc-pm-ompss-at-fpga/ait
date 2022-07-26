########## DDR CLOCKS #########
set_property PACKAGE_PIN H26 [get_ports uDIMM_DDR4_C1_REFCLK_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports uDIMM_DDR4_C1_REFCLK_clk_p]

set_property PACKAGE_PIN AY13 [get_ports uDIMM_DDR4_C3_REFCLK_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports uDIMM_DDR4_C3_REFCLK_clk_p]

set_property PACKAGE_PIN J16 [get_ports uDIMM_DDR4_C2_REFCLK_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports uDIMM_DDR4_C2_REFCLK_clk_p]

############## ASYNC clock group #################
##################################################
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C1_REFCLK_clk_p] \
    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C2_REFCLK_clk_p] \
    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C3_REFCLK_clk_p] 