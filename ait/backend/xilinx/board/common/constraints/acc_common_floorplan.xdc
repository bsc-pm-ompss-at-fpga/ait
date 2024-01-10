## SLR 0
# Master
add_cells_to_pblock -quiet [get_pblocks -quiet slr0_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_0_[0-9]/.*slr_master}]

# Slave
add_cells_to_pblock -quiet [get_pblocks -quiet slr0_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_[0-9]_0/.*slr_slave}]

## SLR 1
# Master
add_cells_to_pblock -quiet [get_pblocks -quiet slr1_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_1_[0-9]/.*slr_master}]

# Slave
add_cells_to_pblock -quiet [get_pblocks -quiet slr1_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_[0-9]_1/.*slr_slave}]

# Middle
add_cells_to_pblock -quiet [get_pblocks -quiet slr1_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_[02]_[02]/.*slr_middle}]

## SLR 2
# Master
add_cells_to_pblock -quiet [get_pblocks -quiet slr2_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_2_[0-9]/.*slr_master}]

# Slave
add_cells_to_pblock -quiet [get_pblocks -quiet slr2_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_[0-9]_2/.*slr_slave}]

## SLR 3
# Master
add_cells_to_pblock -quiet [get_pblocks -quiet slr3_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_3_[0-9]/.*slr_master}]

# Slave
add_cells_to_pblock -quiet [get_pblocks -quiet slr3_pblock] [get_cells -quiet -hierarchical -regexp {.*/acc_.*_regslice_slr_[0-9]_3/.*slr_slave}]
