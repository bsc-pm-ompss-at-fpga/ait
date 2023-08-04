# Create SLR
create_pblock slr0_pblock
create_pblock slr1_pblock
create_pblock slr2_pblock
create_pblock slr3_pblock

# Set sizes
resize_pblock [get_pblocks slr0_pblock] -add {SLR0}
set_property IS_SOFT TRUE [get_pblocks slr0_pblock]

resize_pblock [get_pblocks slr1_pblock] -add {SLR1}
set_property IS_SOFT TRUE [get_pblocks slr1_pblock]

resize_pblock [get_pblocks slr2_pblock] -add {SLR2}
set_property IS_SOFT TRUE [get_pblocks slr2_pblock]

resize_pblock [get_pblocks slr3_pblock] -add {SLR3}
set_property IS_SOFT TRUE [get_pblocks slr3_pblock]
