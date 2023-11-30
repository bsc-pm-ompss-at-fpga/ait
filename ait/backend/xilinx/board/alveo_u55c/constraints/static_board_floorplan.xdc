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

# Interconnection to HBM
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp { \
    .*/S_AXI_[0-9]{2}_Inter \
}]

# Misc.
# These are placed in the same SLR as PCIe
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical { \
    M_AXI_Inter \
    bitInfo \
    bitInfo_BRAM_Ctrl \
    reset_AND \
    managed_reset \
}]

## Memory
#HBM
add_cells_to_pblock [get_pblocks slr0_pblock] [get_cells -hierarchical -regexp { \
    .*/bridge_to_host/memory \
}]

# Improve QDMA floorplanning
create_pblock qdma_pcie
resize_pblock [get_pblocks qdma_pcie] -add {CLOCKREGION_X7Y3:CLOCKREGION_X7Y0}
add_cells_to_pblock [get_pblocks qdma_pcie] [get_cells -hierarchical -filter NAME =~ */QDMA/QDMA/inst/pcie4c_ip_i]
