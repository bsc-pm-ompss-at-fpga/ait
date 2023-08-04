# User clock location
set_property -dict {PACKAGE_PIN AV19 IOSTANDARD LVDS} [get_ports USER_SI570_CLOCK_clk_n]; # Bank 64 VCCO - VCC1V2 Net "USER_SI570_CLOCK_N"  - IO_L12N_T1U_N11_GC_64
set_property -dict {PACKAGE_PIN AU19 IOSTANDARD LVDS} [get_ports USER_SI570_CLOCK_clk_p]; # Bank 64 VCCO - VCC1V2 Net "USER_SI570_CLOCK_P"  - IO_L12P_T1U_N10_GC_64

create_clock -period 6.4 -name USER_SI570_CLOCK_clk_p [get_ports USER_SI570_CLOCK_clk_p]
