# Static logic
## Hardware Runtime
### Place in center SLR in order to minimize SLR crossings
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical Hardware_Runtime]

## Bridge to host
### Should be placed near PCIe
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical bridge_to_host]

## Interconnection from host
### These should be placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp {.*master_Inter(_[0-9]*)*}]

## Misc.
### These should be placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	bitinfo \
	bitInfo_BRAM_Ctrl \
	managed_reset \
}]

## Memory
### DDR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical DDR_0]

### DDR 1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical DDR_1]

### DDR 2
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical DDR_2]

### DDR 3
add_cells_to_pblock [get_pblocks slr2_pblock] [get_cells -hierarchical DDR_3]

## Interconnection to memory
### These should be placed in the same SLR as memory
### We put this in SLR1 as it is the middle SLR and it contains two DDR modules
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp {.*slave_Inter(_[0-9]*)*}]

## Main clock and reset
### These should be placed in the same SLR as the external clock
### We use USER_SI570_CLOCK which is in SLR1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
	clock_generator \
	system_reset \
}]

## Improve QDMA floorplanning
create_pblock qdma_pcie
resize_pblock [get_pblocks qdma_pcie] -add {CLOCKREGION_X5Y5:CLOCKREGION_X5Y9}
add_cells_to_pblock [get_pblocks qdma_pcie] [get_cells -hierarchical pcie4_ip_i]
