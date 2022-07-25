# Set bitstream user ID
set_property BITSTREAM.CONFIG.USERID BITSTREAM_USERID [current_design]

# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Enable automatic over temperature shutdown
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

# Managed reset false path
set_false_path -through [get_pins */Hardware_Runtime/*_OmpSs_Manager/managed_aresetn]

# User clock location
set_property -dict {PACKAGE_PIN AV19 IOSTANDARD LVDS} [get_ports USER_SI570_CLOCK_clk_n]; # Bank 64 VCCO - VCC1V2 Net "USER_SI570_CLOCK_N"  - IO_L12N_T1U_N11_GC_64
set_property -dict {PACKAGE_PIN AU19 IOSTANDARD LVDS} [get_ports USER_SI570_CLOCK_clk_p]; # Bank 64 VCCO - VCC1V2 Net "USER_SI570_CLOCK_P"  - IO_L12P_T1U_N10_GC_64

create_clock -period 6.4 -name USER_SI570_CLOCK_clk_p [get_ports USER_SI570_CLOCK_clk_p]

