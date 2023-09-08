set design_name ${argv}_design

create_bd_design $design_name

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 hwruntime_m_axi
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.DATA_WIDTH {64}] [get_bd_intf_ports hwruntime_m_axi]

create_bd_port -dir I -type clk clk
create_bd_port -dir I -type rst rstn
set_property CONFIG.ASSOCIATED_RESET {rstn} [get_bd_ports /clk]
set_property CONFIG.ASSOCIATED_BUSIF {hwruntime_m_axi} [get_bd_ports /clk]

set axi_stub [create_bd_cell -type ip -vlnv bsc:ompss:axi_stub:1.0 axi_stub_0]
set_property -dict [list CONFIG.AXI_ID_WIDTH [expr {max(int(ceil(log(${::AIT::num_accs})/log(2))), 1)}]] $axi_stub

connect_bd_net [get_bd_ports clk] [get_bd_pins axi_stub_0/aclk]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_stub_0/aresetn]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect S_AXI_0_Inter
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells S_AXI_0_Inter]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins S_AXI_0_Inter/M00_AXI] [get_bd_intf_pins axi_stub_0/s_axi]

connect_bd_net [get_bd_ports clk] [get_bd_pins S_AXI_0_Inter/ACLK] [get_bd_pins S_AXI_0_Inter/S00_ACLK] [get_bd_pins S_AXI_0_Inter/M00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins S_AXI_0_Inter/ARESETN] [get_bd_pins S_AXI_0_Inter/S00_ARESETN] [get_bd_pins S_AXI_0_Inter/M00_ARESETN]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect M_AXI_0_Inter
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells M_AXI_0_Inter]
connect_bd_intf_net [get_bd_intf_ports hwruntime_m_axi] -boundary_type upper [get_bd_intf_pins M_AXI_0_Inter/S00_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins M_AXI_0_Inter/ACLK] [get_bd_pins M_AXI_0_Inter/S00_ACLK] [get_bd_pins M_AXI_0_Inter/M00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins M_AXI_0_Inter/ARESETN] [get_bd_pins M_AXI_0_Inter/S00_ARESETN] [get_bd_pins M_AXI_0_Inter/M00_ARESETN]

add_files ./board/simulation/sources/sim_tb.sv ./board/simulation/sources/cmd_in_queue_driver.sv ./board/simulation/sources/acc_stub.v

set_property verilog_define DESIGN_NAME=${design_name}_wrapper [get_filesets sim_1]
set_property verilog_define DESIGN_NAME=${design_name}_wrapper [get_filesets sources_1]

