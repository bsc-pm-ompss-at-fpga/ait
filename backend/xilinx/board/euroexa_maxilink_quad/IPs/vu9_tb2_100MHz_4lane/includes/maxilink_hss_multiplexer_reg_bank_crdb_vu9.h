/**
 * Diagnostic register types.
 */

`ifndef CRDB_VU9_MAXILINK_HSS_MUTLIPLEXER_REG_BANK_H
`define CRDB_VU9_MAXILINK_HSS_MUTLIPLEXER_REG_BANK_H

`define CRDB_VU9_REGA_BITS       13
`define CRDB_VU9_REGD_BITS       32
// Version identifier for module (deprecated -- moved to the top-level reg bank)
`define CRDB_VU9_HSS_MULTIPLEXER_VERSION 24'h000000

// Protocol Version Identifier (checked at time of handshake)
`define CRDB_VU9_PROTOCOL_VERSION 8'h03

`define CRDB_VU9_VERS_REG                     13'h0   // (RO) Version: top 24 bits: Module btm 8 bits: Protocol
`define CRDB_VU9_CRCE_REG                    13'h4    // (RO) CRC error counter
`define CRDB_VU9_FRME_REG                    13'h8    // (RO) Frame error counter
`define CRDB_VU9_BUSY_REG                    13'hc    // (RO) Packet dispatcher busy counter
`define CRDB_VU9_LNAK_REG                    13'h10    // (RO) Local nack'd frame counter
`define CRDB_VU9_RNAK_REG                    13'h14    // (RO) Remote nack counter
`define CRDB_VU9_LACK_REG                    13'h18    // (RO) Local ack'd frame counter
`define CRDB_VU9_RACK_REG                    13'h1c    // (RO) Remote ack counter
`define CRDB_VU9_LOOC_REG                    13'h20    // (RO) Local out-of-credit counter
`define CRDB_VU9_ROOC_REG                    13'h24    // (RO) Remote out-of-credit counter
`define CRDB_VU9_CRDT_REG                    13'h28    // (RO) Credit
`define CRDB_VU9_SFRM_REG                    13'h2c    // (RO) Frame assembler valid sent frame counter
`define CRDB_VU9_TFRM_REG                    13'h30    // (RO) Frame transmitter frame counter
`define CRDB_VU9_DFRM_REG                    13'h34    // (RO) Frame disassembler valid frame counter
`define CRDB_VU9_RFRM_REG                    13'h38    // (RO) Packet dispatcher valid receieved frame counter
`define CRDB_VU9_EMPT_REG                    13'h3c    // (RO) Empty frame assembler queues
`define CRDB_VU9_FULL_REG                    13'h40    // (RO) Full frame assembler queues
`define CRDB_VU9_CFCL_REG                    13'h44    // (RO) Local channel flow control status
`define CRDB_VU9_CFCR_REG                    13'h48    // (RO) Remote channel flow control status
`define CRDB_VU9_HAND_REG                    13'h4c    // (RO) Handshake: bit 0: complete bit
`define CRDB_VU9_FRM_ERROR_COUNT_REG                  13'h50   // (RW) Frame Error Count before Restart 
`define CRDB_VU9_FRM_ERROR_INCREMENT_REG                  13'h54   // (RW) Frame Error Incrment before Restart  
`define CRDB_VU9_CRC_ERROR_COUNT_REG                  13'h58   // (RW) CRC Error Count before Restart 
`define CRDB_VU9_CRC_ERROR_INCREMENT_REG                  13'h5c   // (RW) CRC Error Incrment before Restart  
`define CRDB_VU9_RECO_REG                    13'h60    // (RO) Link reconnection counter
`define CRDB_VU9_RECO_TIMEOUT_REG                    13'h64    // (RO) Link reconnection timeout counter
`define CRDB_VU9_CH0_HNDSHK_TIMEOUT_REG                    13'h68    // (RO) Channel 0  Handshake breakdown timeout counter
`define CRDB_VU9_CH1_HNDSHK_TIMEOUT_REG                    13'h6c    // (RO) Channel 1  Handshake breakdown timeout counter
`define CRDB_VU9_CH2_HNDSHK_TIMEOUT_REG                    13'h70    // (RO) Channel 2  Handshake breakdown timeout counter
`define CRDB_VU9_CH3_HNDSHK_TIMEOUT_REG                    13'h74    // (RO) Channel 3  Handshake breakdown timeout counter
`define CRDB_VU9_CH0_BTLK_TIMEOUT_REG                    13'h78    // (RO) Channel 0  Bitlock timeout counter
`define CRDB_VU9_CH1_BTLK_TIMEOUT_REG                    13'h7c    // (RO) Channel 1  Bitlock timeout counter
`define CRDB_VU9_CH2_BTLK_TIMEOUT_REG                    13'h80    // (RO) Channel 2  Bitlock timeout counter
`define CRDB_VU9_CH3_BTLK_TIMEOUT_REG                    13'h84    // (RO) Channel 3  Bitlock timeout counter
`define CRDB_VU9_CH0_SYNC_ERROR_REG      13'h88    // (RW) Channel 0 Sync Error Count
`define CRDB_VU9_CH1_SYNC_ERROR_REG      13'h8c    // (RW) Channel 1 Sync Error Count
`define CRDB_VU9_CH2_SYNC_ERROR_REG      13'h90    // (RW) Channel 2 Sync Error Count
`define CRDB_VU9_CH3_SYNC_ERROR_REG      13'h94    // (RW) Channel 3 Sync Error Count
`define CRDB_VU9_EYESCAN_ALIGNMENT_REG                    13'h98    // (RO) Eyescan Alignment counter
`define CRDB_VU9_EYESCAN_UNALIGNED_REG                    13'h9c    // (RO) Eyescan Unaligned counter
`define CRDB_VU9_EYESCAN_COUNT_REG                    13'ha0    // (RO) Eyescans Performed counter
`define CRDB_VU9_STOP_REG                    13'ha4    // (RW) 1 = Stop sending data frames (NB: Will still receive them)
`define CRDB_VU9_CLKC_REG                    13'ha8    // (RW) Clock Correction Interval
`define CRDB_VU9_BOND_REG                    13'hac    // (RW) Channel Bond Interval
`define CRDB_VU9_EIEOS_REG                   13'hb0    // (RW) Initial EIEOS Interval
`define CRDB_VU9_HANDSHAKE_REG               13'hb4    // (RW) Handshake Phase Count
`define CRDB_VU9_ALIGNMENT_REG               13'hb8    // (RW) Symbol Alignment Lock Count
`define CRDB_VU9_INITIAL_CH0_DEEMPH_REG      13'hbc    // (RW) Initial Deemph (CH0)
`define CRDB_VU9_INITIAL_CH1_DEEMPH_REG      13'hc0    // (RW) Initial Deemph (CH1)
`define CRDB_VU9_INITIAL_CH2_DEEMPH_REG      13'hc4    // (RW) Initial Deemph (CH2)
`define CRDB_VU9_INITIAL_CH3_DEEMPH_REG      13'hc8    // (RW) Initial Deemph (CH3)
`define CRDB_VU9_SCRAMBLER_CH0_INIT_REG      13'hcc    // (RW) Scrambler Init (CH0)
`define CRDB_VU9_SCRAMBLER_CH1_INIT_REG      13'hd0    // (RW) Scrambler Init (CH1)
`define CRDB_VU9_SCRAMBLER_CH2_INIT_REG      13'hd4    // (RW) Scrambler Init (CH2)
`define CRDB_VU9_SCRAMBLER_CH3_INIT_REG      13'hd8    // (RW) Scrambler Init (CH3)
`define CRDB_VU9_BITLOCK_TIMEOUT_REG             13'hdc    // (RW) Bitlock Timeout
`define CRDB_VU9_RECONNECT_COUNT_REG                  13'he0   // (RW) Reconnect Count 
`define CRDB_VU9_ALIGNED_UPTIME_REG                  13'he4   // (RW) Reconnect Count 
`define CRDB_VU9_HANDSHAKE_BREAKDOWN_REG                  13'he8   // (RW) Reconnect Count 
`define CRDB_VU9_ALIGNMENT_COUNTER_REG             13'hec    // (RW) Bitlock Timeout
`define CRDB_VU9_ALIGNING_TIMER_REG                  13'hf0   // (RW) Error Rate 
`define CRDB_VU9_SYNC_ERROR_COUNT_REG                  13'hf4   // (RW) Error Rate 
`define CRDB_VU9_SYNC_ERROR_INCREMENT_REG                  13'hf8   // (RW) Error Rate 
`define CRDB_VU9_EIEOS_INTERVAL_REG                  13'hfc   // (RW) Error Rate 
`define CRDB_VU9_EIEOS_RETRY_REG                  13'h100   // (RW) Error Rate 
`define CRDB_VU9_INITIAL_RATE_REG             13'h104    // (RW) Initial Rate
`define CRDB_VU9_INITIAL_RATE_TIMEOUT_REG             13'h108    // (RW) Initial Rate Timeout 
`define CRDB_VU9_DATAPATH_TIMEOUT_REG             13'h10c    // (RW) Timeout Retry Count
`define CRDB_VU9_PLL_TIMEOUT_REG                  13'h110    // (RW) Timeout Retry Count
`define CRDB_VU9_RESET_TIMEOUT_REG             13'h114    // (RW) Reset Timeout Count
`define CRDB_VU9_RESET_INITIALISE_REG             13'h118    // (RW) Wait for initialisation after reset
`define CRDB_VU9_HANDSHAKE_COMMIT_REG             13'h11c    // (RW) Handshake Variable Commit Count
`define CRDB_VU9_HANDSHAKE_RESET_REG             13'h120    // (RW) Handshake Variable Reset Count
`define CRDB_VU9_TARGET_RATE_REG             13'h124    // (RW) Target Rate
`define CRDB_VU9_CURRENT_RATE_REG             13'h128    // (R) Target Rate
`define CRDB_VU9_CHANNEL_ENABLE_REG                13'h12c    // (RW) Enabled Channels
`define CRDB_VU9_ENABLED_CHANNELS_REG                13'h130    // (R) Enabled Channels
`define CRDB_VU9_PARTIAL_BITLOCK_REG                13'h134    // (RW) Allow partial bit lock for targe rate
`define CRDB_VU9_EYESCAN_DEEMPH_COUNT_REG               13'h138    // (RW) Number of Handshakes before Triggering Eyescan
`define CRDB_VU9_EQUALIZATION_REG            13'h13c    // (RW) Perform Equalization in Handshake
`define CRDB_VU9_OFFSET_REG            13'h140    // (RW) Perform Offset Calibration in Handshake
`define CRDB_VU9_NAK_INTERVAL_REG            13'h144    // (RW) Minimum Interval between sucessives NAKs
`define CRDB_VU9_INTRATILE_PORT_REG                    13'h148   // (RW) INFN Intratile Port ID
`define CRDB_VU9_EXANET_ADDRESS_REG                    13'h14c    // (RW) EXANET Adress of Local Node
`define CRDB_VU9_UNIMEM_BASE_ADDRESS_REG               13'h150    // (RW) AXI Base Address of UNIMEM FROM
`define CRDB_VU9_IPV4_AXISTREAM_FIELDS_REG               13'h154    // (RW) AXI Base Address of UNIMEM FROM
`define CRDB_VU9_EYESCAN_BER_RATE_REG               13'h158    // (RW) EYSCAN BER RATE SETTING
`define CRDB_VU9_EYESCAN_VERT_RANGE_REG               13'h15c    // (RW) EYSCAN VERTICAL RANGE SETTING
`define CRDB_VU9_RX_LPE_DFE_REG               13'h160    // (RW) RX LPE or DFE equalisation
`define CRDB_VU9_EYESCAN_WAIT_COUNT_REG               13'h164    // (RW) EYESCAN Wait State count
`define CRDB_VU9_EYESCAN_REALIGN_COUNT_REG               13'h168    // (RW) EYESCAN Realignmet count
`define CRDB_VU9_PHY_RESET                      13'h16c    // (RW) Reset Phy
`define CRDB_VU9_HANDSHAKE_RESTART           13'h170    // (RW) Restart Handshake


`endif

