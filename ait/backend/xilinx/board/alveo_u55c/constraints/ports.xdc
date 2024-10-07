# sysclk0 differential clock
set_property PACKAGE_PIN BK44     [get_ports {sysclk0_clk_n}]           ;# Bank  65 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_A11_D27_65
set_property IOSTANDARD  LVDS     [get_ports {sysclk0_clk_n}]           ;# Bank  65 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_A11_D27_65
set_property PACKAGE_PIN BK43     [get_ports {sysclk0_clk_p}]           ;# Bank  65 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_A10_D26_65
set_property IOSTANDARD  LVDS     [get_ports {sysclk0_clk_p}]           ;# Bank  65 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_A10_D26_65

# sysclk1 differential clock
set_property PACKAGE_PIN BL10     [get_ports {sysclk1_clk_n}]           ;# Bank  68 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_68
set_property IOSTANDARD  LVDS     [get_ports {sysclk1_clk_n}]           ;# Bank  68 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_68
set_property PACKAGE_PIN BK10     [get_ports {sysclk1_clk_p}]           ;# Bank  68 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_68
set_property IOSTANDARD  LVDS     [get_ports {sysclk1_clk_p}]           ;# Bank  68 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_68

# pcie_refclk
set_property PACKAGE_PIN AR14     [get_ports {pcie_refclk_clk_n}]       ;# Bank 225                  - MGTREFCLK0N_225
set_property PACKAGE_PIN AR15     [get_ports {pcie_refclk_clk_p}]       ;# Bank 225                  - MGTREFCLK0P_225
create_clock -name pcie_refclk -period 10 [get_ports {pcie_refclk_clk_p}]

# pcie_perstn
set_property PACKAGE_PIN BF41     [get_ports {pcie_perstn}]             ;# Bank  65 VCCO - VCC1V8   - IO_T3U_N12_PERSTN0_65
set_property IOSTANDARD  LVCMOS18 [get_ports {pcie_perstn}]             ;# Bank  65 VCCO - VCC1V8   - IO_T3U_N12_PERSTN0_65

# HBM_CATTRIP
set_property PACKAGE_PIN BE45     [get_ports {HBM_CATTRIP}]             ;# Bank  65 VCCO - VCC1V8   - IO_L22P_T3U_N6_DBC_AD0P_D04_65
set_property IOSTANDARD  LVCMOS18 [get_ports {HBM_CATTRIP}]             ;# Bank  65 VCCO - VCC1V8   - IO_L22P_T3U_N6_DBC_AD0P_D04_65

#QSFP0 refclk
set_property PACKAGE_PIN AD43 [get_ports QSFP0_CLK_clk_n]
set_property PACKAGE_PIN AD42 [get_ports QSFP0_CLK_clk_p]
