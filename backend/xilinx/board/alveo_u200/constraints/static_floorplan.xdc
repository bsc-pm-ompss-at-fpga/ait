##SLR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

#DDR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells {*/bridge_to_host/DDR/DDR_0 */bridge_to_host/DDR/DDR_0_procSysRst}]

##SLR 1-0
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_0_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_0.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

##SLR 1-2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

# Static stuff
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {*/Hardware_Runtime */M_AXI_master_Inter */S_AXI_data_control_coherent_Inter */bitInfo */bitInfo_BRAM_Ctrl */bridge_to_host/QDMA_M_AXI_LITE_Inter */bridge_to_host/DDR_S_AXI_Inter */bridge_to_host/QDMA */processor_system_reset}]

#DDR 1-2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {*/bridge_to_host/DDR/DDR_1 */bridge_to_host/DDR/DDR_1_procSysRst}]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {*/bridge_to_host/DDR/DDR_2 */bridge_to_host/DDR/DDR_2_procSysRst}]

##SLR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_2_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_static_1_2.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

#DDR 3
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells {*/bridge_to_host/DDR/DDR_3 */bridge_to_host/DDR/DDR_3_procSysRst}]
