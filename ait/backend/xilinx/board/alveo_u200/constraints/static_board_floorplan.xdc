## Static logic
# Hardware Runtime
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	Hardware_Runtime \
}]

# Interconnection to memory
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	S_AXI_Inter \
}]

# Misc.
# These should be placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	M_AXI_Inter \
	bitInfo \
	bitInfo_BRAM_Ctrl \
	managed_reset \
}]

# Main clock and reset
# These should be placed in the same SLR as the external clock
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	clock_generator \
	processor_system_reset \
}]

# Bridge to host
# These should be placed near PCIe
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp { \
	.*/bridge_to_host/QDMA_M_AXI_LITE_Inter \
	.*/bridge_to_host/DDR_S_AXI_Inter \
	.*/bridge_to_host/QDMA \
}]

## Memory
# DDR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_0]

# DDR 1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_1]

# DDR 2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_2]

# DDR 3
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_3]
