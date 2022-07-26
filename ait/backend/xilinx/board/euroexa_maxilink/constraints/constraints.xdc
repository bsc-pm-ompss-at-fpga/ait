
# Board Reset Button  Right(SW9)

# board_300_MHz_clk

# GPIO_LED pins (for future use)
#set_property PACKAGE_PIN P20 [get_ports 2]
#set_property IOSTANDARD LVCMOS18 [get_ports 2]
#set_property PACKAGE_PIN P21 [get_ports 3]
#set_property IOSTANDARD LVCMOS18 [get_ports 3]
#set_property PACKAGE_PIN N22 [get_ports 4]
#set_property IOSTANDARD LVCMOS18 [get_ports 4]
#set_property PACKAGE_PIN M22 [get_ports 5]
#set_property IOSTANDARD LVCMOS18 [get_ports 5]
#set_property PACKAGE_PIN R23 [get_ports 6]
#set_property IOSTANDARD LVCMOS18 [get_ports 6]
#set_property PACKAGE_PIN P23 [get_ports 7]
#set_property IOSTANDARD LVCMOS18 [get_ports 7]

##GTH pins (BANK 228) clk0

### GTH pins (BANK 228)
###
### GHT0 --> DP0 --> SFP_3
#set_property PACKAGE_PIN E4 [get_ports {MASTER_GT_SERIAL_RX_rxp[0]}]

### GHT1 --> DP1 --> SFP_1
#set_property PACKAGE_PIN D2 [get_ports {MASTER_GT_SERIAL_RX_rxp[1]}]

### GHT2 --> DP2 --> SFP_4
#set_property PACKAGE_PIN B2 [get_ports {SLAVE_GT_SERIAL_RX_rxp[0]}]

### GHT3 --> DP3 --> SFP_5
#set_property PACKAGE_PIN A4 [get_ports {SLAVE_GT_SERIAL_RX_rxp[1]}]

# WORKING FMC HitechGlobal Daughtercard
#set_property PACKAGE_PIN U26 [get_ports {o_clk_sel_A13[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_clk_sel_A13[0]}]
#set_property PACKAGE_PIN V26 [get_ports {o_oe_A12[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_oe_A12[0]}]


#######   VU9-->ZU9 SLOW_SIG pins    ##############
##################################################
#SLOW_SIG pins:
# P_0 -> BE8
# N_0 -> BF8
# P_1 -> BD10
# N_1 -> BE10
# P_2 -> BE7
# N_2 -> BF7
# P_3 -> BC7
# N_3 -> BD7


#N_0
#set_property PACKAGE_PIN BF8 [get_ports {o_virtex_cdma_introut_0}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_cdma_introut_0}]
#N_1
#set_property PACKAGE_PIN BE10 [get_ports {o_virtex_cdma_introut_1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_cdma_introut_1}]

### RFU accelerator interrupts...
##P_2
#set_property PACKAGE_PIN BE7 [get_ports {o_virtex_accelerator_introut_0}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_accelerator_introut_0}]
##P_3
#set_property PACKAGE_PIN BC7 [get_ports {o_virtex_accelerator_introut_1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_accelerator_introut_1}]
##N_2
#set_property PACKAGE_PIN BF7 [get_ports {o_virtex_accelerator_introut_2}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_accelerator_introut_2}]
##N_3
#set_property PACKAGE_PIN BD7 [get_ports {o_virtex_accelerator_introut_3}]
#set_property IOSTANDARD LVCMOS18 [get_ports {o_virtex_accelerator_introut_3}]

######################################################################################
######################################################################################
######################################################################################
## for the Kintex to VU9 design, augmented with (part of) topic's DDR infrastructure
## 224_0

## GTH pins BANK 225 clk0
set_property PACKAGE_PIN AT11 [get_ports {Q225_REFCLK0_clk_p[0]}]
#create_clock -period 6.400 -name Q225_REFCLK0_clk_p -waveform {0.000 3.200} [get_ports Q225_REFCLK0_clk_p]


# SLOW_SIG_P[0]
# SLOW_SIG_P[1]
#set_property PACKAGE_PIN BD10 [get_ports ZU_VU_link_rstn_i]
# SLOW_SIG_P[2]

########## VU9 LOGIC CLOCK #########
set_property PACKAGE_PIN BA12 [get_ports {vu9_logic_clock_clk_p[0]}]

########## DDR CLOCKS #########

#set_property PACKAGE_PIN AY13 [get_ports {uDIMM_DDR4_C3_REFCLK_clk_p[0]}]

#set_property PACKAGE_PIN J16 [get_ports uDIMM_DDR4_C2_REFCLK_clk_p]
#set_property IOSTANDARD DIFF_SSTL12 [get_ports uDIMM_DDR4_C2_REFCLK_clk_p]

############ VU9_RESET (low active) ############
#set_property PACKAGE_PIN AU13 [get_ports n_cb_rst_vu9]

########  VU9: another external reset    ######
###### we prefer to use it as active low ######
set_property PACKAGE_PIN AW14 [get_ports vu9_board_rst]


#set_property IOSTANDARD LVCMOS18 [get_ports VU9_SW_RST]
#set_property PACKAGE_PIN AW14 [get_ports VU9_SW_RST]

# Create clock for VU9 LOGIC CLOCK

############### ASYNC clock group #################
###################################################
#set_clock_groups -asynchronous #    -group [get_clocks -include_generated_clocks aurora_user_clk] #    -group [get_clocks -include_generated_clocks {vu9_logic_clock clk_100_crdb_xcvu_pt_clk_wiz_0_0 axi_clk aurora_init_clk}] #    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C1_REFCLK_clk_p] #    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C2_REFCLK_clk_p] #    -group [get_clocks -include_generated_clocks uDIMM_DDR4_C3_REFCLK_clk_p]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]





####################################################################################
# Constraints from file : 'io_ddr4_c1.xdc'
####################################################################################


####################################################################################
# Constraints from file : 'virtex_euroexa_bd_auto_cc_0_clocks.xdc'
####################################################################################


create_clock -period 10.000 -name Q225_REFCLK0_clk_p -waveform {0.000 5.000} [get_ports Q225_REFCLK0_clk_p]
#set_property IOSTANDARD LVCMOS18 [get_ports ZU_VU_link_rstn_i]
#set_property PULLUP true [get_ports ZU_VU_link_rstn_i]
set_property IOSTANDARD LVDS [get_ports {vu9_logic_clock_clk_p[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports n_cb_rst_vu9]
#set_property PULLUP true [get_ports n_cb_rst_vu9]
set_property IOSTANDARD LVCMOS18 [get_ports vu9_board_rst]
set_property PULLUP true [get_ports vu9_board_rst]
create_clock -period 3.333 -name vu9_logic_clock [get_ports {vu9_logic_clock_clk_p[0]}]
set_false_path -from [get_clocks vu9_logic_clock] -to [get_clocks  -of_objects [ get_pins -of_objects  [get_cells -hierarchical -filter {NAME =~*xilinx_gty} ] -filter {NAME=~*tx_usrclk2_out[0]} ]]

####################################################################################
# Constraints from file : 'ddr_clocking.xdc'
####################################################################################

set_false_path -from [get_clocks  -of_objects [ get_pins -of_objects  [get_cells -hierarchical -filter {NAME =~*xilinx_gty} ] -filter {NAME=~*rx_usrclk2_out[0]} ]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

# Enable automatic overtemperature shutdown
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
