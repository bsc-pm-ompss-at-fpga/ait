###############################################################################
#
#     File Name: bitstream-admpcie7v3.xdc
#         Model: syn (Synthesisable)
#
#  Dependencies:
#
#       Company: Alpha Data
#        Design:
#
#   Description: Additional Vivado constraints specific to ADM-PCIE-7V3.
#
#   Limitations:
#
#         Notes:
#
#    Disclaimer: THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY
#                WHATSOEVER AND ALPHA DATA SPECIFICALLY DISCLAIMS ANY
#                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
#                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
#
#                Copyright (C) 2014 Alpha Data, All rights reserved
#
#     Revisions: 0.1, KDC, 09 Apr 2014: Initial version
#
###############################################################################

# SelectMap port must not persist after configuration
set_property BITSTREAM.CONFIG.PERSIST {No} [ current_design ]

# Configuration from G18 Flash as per XAPP587
set_property BITSTREAM.STARTUP.STARTUPCLK {Cclk} [ current_design ]
set_property BITSTREAM.CONFIG.BPI_1ST_READ_CYCLE {1} [ current_design ]
set_property BITSTREAM.CONFIG.BPI_PAGE_SIZE {1} [ current_design ]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE {Type1} [ current_design ]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {div-1} [ current_design ]
set_property BITSTREAM.CONFIG.CONFIGRATE {3} [ current_design ]

# Set CFGBVS to GND to match schematics
set_property CFGBVS {GND} [ current_design ]

# Set CONFIG_VOLTAGE to 1.8V to match schematics
set_property CONFIG_VOLTAGE {1.8} [ current_design ]
