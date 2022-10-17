##SLR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_slave.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_master.*} }]

##SLR 1-0
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_master.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_slave.*} }]

##SLR 1-2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_master.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_slave.*} }]

##SLR 1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {*/Hardware_Runtime */M_AXI_master_Inter */S_AXI_data_control_coherent_Inter */bitInfo */bitInfo_BRAM_Ctrl */bridge_to_host/DDR_S_AXI_Inter */clock_generator */IBUFDS */processor_system_reset }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -quiet [list */bridge_to_host/AND_1 */bridge_to_host/AND_2 */bridge_to_host/DDR/DDR_1 */bridge_to_host/DDR/DDR_3 */bridge_to_host/DDR/DDR4_S_AXI_CTRL_Inter */bridge_to_host/DDR_S_AXI_Inter */bridge_to_host/IBUFDSGTE_225 */bridge_to_host/VIO_old_ZU_VU_link_rstn_i */bridge_to_host/axi_bram_ctrl_0 */bridge_to_host/axi_gpio_0 */bridge_to_host/axi_interconnect_0 */bridge_to_host/axi_register_slice_0 */bridge_to_host/axi_register_slice_1 */bridge_to_host/axi_register_slice_2 */bridge_to_host/blk_mem_gen_0 */bridge_to_host/cdma_hier_0 */bridge_to_host/cdma_hier_1 */bridge_to_host/const_0 */bridge_to_host/const_000 */bridge_to_host/const_1 */bridge_to_host/jtag_axi_0 */bridge_to_host/maxilink_xilinx_axi_0 */bridge_to_host/proc_sys_reset_100 */bridge_to_host/proc_sys_reset_150 */bridge_to_host/proc_sys_reset_300 */bridge_to_host/proc_sys_reset_board_clock_300 */bridge_to_host/util_BUFG_GT_0 */bridge_to_host/util_vector_logic_0 */bridge_to_host/vio_0 */bridge_to_host/xlconcat_0 */bridge_to_host/DDR/DDR_2/DDR4_S_AXI_regslice */bridge_to_host/DDR/calib_complete_concat ]]

##SLR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_slave.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_master.*} }]

#DDR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -quiet [list */bridge_to_host/DDR/DDR_2/DDR4 */bridge_to_host/DDR/DDR_2/DDR4_proc_sys_reset ] ]
