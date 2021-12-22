#SLR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_0_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_0.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

#srteams
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_slave.*} }]
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_master.*} }]


#SLR 1-0
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_0_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_0_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_0.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_0.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_0/.*slr_master.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_0_1/.*slr_slave.*} }]


#SLR 1-2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_2_1.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_2.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_master.*} }]
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_slave.*} }]

#SLR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_2_1.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_src.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_2_1.*(\.b_auto|\.r_auto)/slr_auto_dest.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_2.*(\.ar_auto|\.aw_auto|\.w_auto)/slr_auto_dest.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*_slr_1_2.*(\.b_auto|\.r_auto)/slr_auto_src.*} }]

add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_in_1_2/.*slr_slave.*} }]
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp -filter { NAME =~ {.*axis_regSlice_out_2_1/.*slr_master.*} }]

]]

