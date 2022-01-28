# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Enable automatic over temperature shutdown
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

# Managed reset false path
set_false_path -through [get_pins */Hardware_Runtime/*_OmpSs_Manager/managed_aresetn]
