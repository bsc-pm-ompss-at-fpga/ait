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
	reset_AND \
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
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	bridge_to_host/DDR_S_AXI_Inter \
	bridge_to_host/DDR_S_AXI_CTRL_Inter \
	bridge_to_host/IBUFDSGTE_225 \
	bridge_to_host/const_1 \
	bridge_to_host/peripherals \
	bridge_to_host/maxilink \
	bridge_to_host/proc_sys_reset_100 \
	bridge_to_host/proc_sys_reset_150 \
	bridge_to_host/proc_sys_reset_300 \
	bridge_to_host/proc_sys_reset_board_clock_300 \
	bridge_to_host/memory/init_calib_complete_concat \
	IBUFDS \
}]

## Memory
# DDR 1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {bridge_to_host/memory/DDR_1}]

# DDR 2
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells {bridge_to_host/memory/DDR_2}]

# DDR 3
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells {bridge_to_host/memory/DDR_3}]
