# Static logic
## Hardware Runtime
### Place in center SLR in order to minimize SLR crossings
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical Hardware_Runtime]

## Bridge to host
### Should be placed near PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical bridge_to_host]

## Interconnection from host
### These should be placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp {.*master_Inter(_[0-9]*)*}]

## Misc.
### These should be placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical { \
	bitinfo \
	bitInfo_BRAM_Ctrl \
	managed_reset \
}]

## Memory
### HBM
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical memory]

## Interconnection to memory
### These should be placed in the same SLR as memory
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp {.*slave_Inter(_[0-9]*)*}]

## Improve QDMA floorplanning
create_pblock qdma_pcie
resize_pblock [get_pblocks qdma_pcie] -add {CLOCKREGION_X7Y3:CLOCKREGION_X7Y0}
add_cells_to_pblock [get_pblocks qdma_pcie] [get_cells */bridge_to_host/QDMA/QDMA/inst/pcie4c_ip_i]
