
create_clock -period 10 -name mgtrefclk [get_ports mgtrefclk]
create_clock -period 6.667 -name clk_freerun_in [get_ports clk_freerun_in]

create_clock -period 6.667 -name zu9_cci_clk [get_ports zu9_cci_clk]

create_clock -period 3.333 -name zu9_axi_clk [get_ports zu9_axi_clk]

