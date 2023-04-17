# sysclk0 differential clock
set_property PACKAGE_PIN BJ44       [ get_ports  {sysclk0_clk_n} ]  ;# Bank  65 VCCO - VCC1V2 Net "SYSCLK0_N"   - IO_L12N_T1U_N11_GC_A09_D25_65
set_property IOSTANDARD  LVDS       [ get_ports  {sysclk0_clk_n} ]  ;# Bank  65 VCCO - VCC1V2 Net "SYSCLK0_N"   - IO_L12N_T1U_N11_GC_A09_D25_65
set_property PACKAGE_PIN BJ43       [ get_ports  {sysclk0_clk_p} ]  ;# Bank  65 VCCO - VCC1V2 Net "SYSCLK0_P"   - IO_L12P_T1U_N10_GC_A08_D24_65
set_property IOSTANDARD  LVDS       [ get_ports  {sysclk0_clk_p} ]  ;# Bank  65 VCCO - VCC1V2 Net "SYSCLK0_P"   - IO_L12P_T1U_N10_GC_A08_D24_65
set_property DQS_BIAS    TRUE       [ get_ports  {sysclk0_clk_p} ]  ;# Bank  65 VCCO - VCC1V2 Net "SYSCLK0_P"   - IO_L12P_T1U_N10_GC_A08_D24_65

# sysclk1 differential clock
set_property PACKAGE_PIN BJ6        [ get_ports  {sysclk1_clk_n} ]  ;# Bank  69 VCCO - VCC1V2 Net "SYSCLK1_N"   - IO_L13N_T2L_N1_GC_QBC_69
set_property IOSTANDARD  LVDS       [ get_ports  {sysclk1_clk_n} ]  ;# Bank  69 VCCO - VCC1V2 Net "SYSCLK1_N"   - IO_L13N_T2L_N1_GC_QBC_69
set_property PACKAGE_PIN BH6        [ get_ports  {sysclk1_clk_p} ]  ;# Bank  69 VCCO - VCC1V2 Net "SYSCLK1_P"   - IO_L13P_T2L_N0_GC_QBC_69
set_property IOSTANDARD  LVDS       [ get_ports  {sysclk1_clk_p} ]  ;# Bank  69 VCCO - VCC1V2 Net "SYSCLK1_P"   - IO_L13P_T2L_N0_GC_QBC_69
set_property DQS_BIAS    TRUE       [ get_ports  {sysclk1_clk_p} ]  ;# Bank  69 VCCO - VCC1V2 Net "SYSCLK1_P"   - IO_L13P_T2L_N0_GC_QBC_69

# HBM_CATTRIP
set_property PACKAGE_PIN D32        [ get_ports {HBM_CATTRIP} ]     ;# Bank  75 VCCO - VCC1V8                   - IO_L17P_T2U_N8_AD10P_75
set_property IOSTANDARD  LVCMOS18   [ get_ports {HBM_CATTRIP} ]     ;# Bank  75 VCCO - VCC1V8                   - IO_L17P_T2U_N8_AD10P_75
set_property PULLDOWN    TRUE       [ get_ports {HBM_CATTRIP} ]     ;# Bank  75 VCCO - VCC1V8                   - IO_L17P_T2U_N8_AD10P_75
