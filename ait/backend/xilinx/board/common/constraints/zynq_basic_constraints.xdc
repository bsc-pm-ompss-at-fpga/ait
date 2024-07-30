# Set bitstream user ID
set_property BITSTREAM.CONFIG.USERID BITSTREAM_USERID [current_design]

# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Enable automatic over temperature shutdown
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
