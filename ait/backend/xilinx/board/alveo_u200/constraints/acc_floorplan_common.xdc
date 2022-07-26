##SLR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_0_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_0.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_auto_src.*} }]

##SLR 1-0
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_0_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_0.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_auto_dest.*} }]

##SLR 1-2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_2_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_2.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_auto_dest.*} }]

##SLR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_2_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_acc_1_2.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

# AXI-Stream
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_auto_src.*} }]
