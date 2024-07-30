# Bridge to host
# These should be placed near PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp { \
    .*/bridge_to_host/QDMA_M_AXI_LITE_Inter \
    .*/bridge_to_host/QDMA \
}]

# Hardware Runtime
# Place in center SLR in order to minimize SLR crossings
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
    Hardware_Runtime \
}]

# Interconnection to memory
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical { \
    S_AXI_Inter \
}]

# Misc.
# These are placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical { \
    M_AXI_Inter \
    bitInfo \
    bitInfo_BRAM_Ctrl \
    managed_reset \
}]

## Memory
# DDR 0
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_0]

# DDR 1
add_cells_to_pblock [get_pblocks slr1_pblock] [get_cells -hierarchical -regexp .*/bridge_to_host/memory/DDR_1]

# Improve QDMA floorplanning
create_pblock qdma_pcie
resize_pblock [get_pblocks qdma_pcie] -add {CLOCKREGION_X7Y3:CLOCKREGION_X7Y0}
add_cells_to_pblock [get_pblocks qdma_pcie] [get_cells -hierarchical -filter NAME =~ */QDMA/QDMA/inst/pcie4c_ip_i]
