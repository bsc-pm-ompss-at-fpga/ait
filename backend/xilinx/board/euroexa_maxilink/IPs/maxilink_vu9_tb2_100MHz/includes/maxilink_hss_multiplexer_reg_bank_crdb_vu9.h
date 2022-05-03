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

`define CRDB_VU9_VERS_REG                     13'h4   // (RO) Version: top 24 bits: Module btm 8 bits: Protocol
`define CRDB_VU9_CRCE_REG                    13'h8    // (RO) CRC error counter
`define CRDB_VU9_FRME_REG                    13'hc    // (RO) Frame error counter
`define CRDB_VU9_BUSY_REG                    13'h10    // (RO) Packet dispatcher busy counter
`define CRDB_VU9_LNAK_REG                    13'h14    // (RO) Local nack'd frame counter
`define CRDB_VU9_RNAK_REG                    13'h18    // (RO) Remote nack counter
`define CRDB_VU9_LACK_REG                    13'h1c    // (RO) Local ack'd frame counter
`define CRDB_VU9_RACK_REG                    13'h20    // (RO) Remote ack counter
`define CRDB_VU9_LOOC_REG                    13'h24    // (RO) Local out-of-credit counter
`define CRDB_VU9_ROOC_REG                    13'h28    // (RO) Remote out-of-credit counter
`define CRDB_VU9_CRDT_REG                    13'h2c    // (RO) Credit
`define CRDB_VU9_SFRM_REG                    13'h30    // (RO) Frame assembler valid sent frame counter
`define CRDB_VU9_TFRM_REG                    13'h34    // (RO) Frame transmitter frame counter
`define CRDB_VU9_DFRM_REG                    13'h38    // (RO) Frame disassembler valid frame counter
`define CRDB_VU9_RFRM_REG                    13'h3c    // (RO) Packet dispatcher valid receieved frame counter
`define CRDB_VU9_EMPT_REG                    13'h40    // (RO) Empty frame assembler queues
`define CRDB_VU9_FULL_REG                    13'h44    // (RO) Full frame assembler queues
`define CRDB_VU9_CFCL_REG                    13'h48    // (RO) Local channel flow control status
`define CRDB_VU9_CFCR_REG                    13'h4c    // (RO) Remote channel flow control status
`define CRDB_VU9_HAND_REG                    13'h50    // (RO) Handshake: bit 0: complete bit
`define CRDB_VU9_RECO_REG                    13'h54    // (RO) Link reconnection counter
`define CRDB_VU9_RECO_TIMEOUT_REG                    13'h58    // (RO) Link reconnection timeout counter
`define CRDB_VU9_CH0_HNDSHK_TIMEOUT_REG                    13'h5c    // (RO) Channel 0  Handshake breakdown timeout counter
`define CRDB_VU9_CH1_HNDSHK_TIMEOUT_REG                    13'h60    // (RO) Channel 1  Handshake breakdown timeout counter
`define CRDB_VU9_CH2_HNDSHK_TIMEOUT_REG                    13'h64    // (RO) Channel 2  Handshake breakdown timeout counter
`define CRDB_VU9_CH3_HNDSHK_TIMEOUT_REG                    13'h68    // (RO) Channel 3  Handshake breakdown timeout counter
`define CRDB_VU9_CH4_HNDSHK_TIMEOUT_REG                    13'h6c    // (RO) Channel 4  Handshake breakdown timeout counter
`define CRDB_VU9_CH5_HNDSHK_TIMEOUT_REG                    13'h70    // (RO) Channel 5  Handshake breakdown timeout counter
`define CRDB_VU9_CH0_BTLK_TIMEOUT_REG                    13'h74    // (RO) Channel 0  Bitlock timeout counter
`define CRDB_VU9_CH1_BTLK_TIMEOUT_REG                    13'h78    // (RO) Channel 1  Bitlock timeout counter
`define CRDB_VU9_CH2_BTLK_TIMEOUT_REG                    13'h7c    // (RO) Channel 2  Bitlock timeout counter
`define CRDB_VU9_CH3_BTLK_TIMEOUT_REG                    13'h80    // (RO) Channel 3  Bitlock timeout counter
`define CRDB_VU9_CH4_BTLK_TIMEOUT_REG                    13'h84    // (RO) Channel 4  Bitlock timeout counter
`define CRDB_VU9_CH5_BTLK_TIMEOUT_REG                    13'h88    // (RO) Channel 5  Bitlock timeout counter
`define CRDB_VU9_CH0_SYNC_ERROR_REG      13'h8c    // (RW) Channel 0 Sync Error Count
`define CRDB_VU9_CH1_SYNC_ERROR_REG      13'h90    // (RW) Channel 1 Sync Error Count
`define CRDB_VU9_CH2_SYNC_ERROR_REG      13'h94    // (RW) Channel 2 Sync Error Count
`define CRDB_VU9_CH3_SYNC_ERROR_REG      13'h98    // (RW) Channel 3 Sync Error Count
`define CRDB_VU9_CH4_SYNC_ERROR_REG      13'h9c    // (RW) Channel 4 Sync Error Count
`define CRDB_VU9_CH5_SYNC_ERROR_REG      13'ha0    // (RW) Channel 5 Sync Error Count
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
`define CRDB_VU9_INITIAL_CH4_DEEMPH_REG      13'hcc    // (RW) Initial Deemph (CH4)
`define CRDB_VU9_INITIAL_CH5_DEEMPH_REG      13'hd0    // (RW) Initial Deemph (CH5)
`define CRDB_VU9_SCRAMBLER_CH0_INIT_REG      13'hd4    // (RW) Scrambler Init (CH0)
`define CRDB_VU9_SCRAMBLER_CH1_INIT_REG      13'hd8    // (RW) Scrambler Init (CH1)
`define CRDB_VU9_SCRAMBLER_CH2_INIT_REG      13'hdc    // (RW) Scrambler Init (CH2)
`define CRDB_VU9_SCRAMBLER_CH3_INIT_REG      13'he0    // (RW) Scrambler Init (CH3)
`define CRDB_VU9_SCRAMBLER_CH4_INIT_REG      13'he4    // (RW) Scrambler Init (CH4)
`define CRDB_VU9_SCRAMBLER_CH5_INIT_REG      13'he8    // (RW) Scrambler Init (CH5)
`define CRDB_VU9_BITLOCK_TIMEOUT_REG             13'hec    // (RW) Bitlock Timeout
`define CRDB_VU9_RECONNECT_COUNT_REG                  13'hf0   // (RW) Reconnect Count 
`define CRDB_VU9_ALIGNED_UPTIME_REG                  13'hf4   // (RW) Reconnect Count 
`define CRDB_VU9_HANDSHAKE_BREAKDOWN_REG                  13'hf8   // (RW) Reconnect Count 
`define CRDB_VU9_ALIGNMENT_COUNTER_REG             13'hfc    // (RW) Bitlock Timeout
`define CRDB_VU9_ALIGNING_TIMER_REG                  13'h100   // (RW) Error Rate 
`define CRDB_VU9_EIEOS_INTERVAL_REG                  13'h104   // (RW) Error Rate 
`define CRDB_VU9_INITIAL_RATE_REG             13'h108    // (RW) Initial Rate
`define CRDB_VU9_INITIAL_RATE_TIMEOUT_REG             13'h10c    // (RW) Initial Rate
`define CRDB_VU9_TIMEOUT_RETRY_REG             13'h110    // (RW) Initial Rate
`define CRDB_VU9_RESET_TIMEOUT_REG             13'h114    // (RW) Initial Rate
`define CRDB_VU9_RESET_INITIALISE_REG             13'h118    // (RW) Initial Rate
`define CRDB_VU9_TARGET_RATE_REG             13'h11c    // (RW) Target Rate
`define CRDB_VU9_CURRENT_RATE_REG             13'h120    // (R) Target Rate
`define CRDB_VU9_UPSTREAM_REG                13'h124    // (R) Upstream Interface
`define CRDB_VU9_CHANNEL_ENABLE_REG                13'h128    // (RW) Enabled Channels
`define CRDB_VU9_ENABLED_CHANNELS_REG                13'h12c    // (R) Enabled Channels
`define CRDB_VU9_PARTIAL_BITLOCK_REG                13'h130    // (RW) Allow partial bit lock for targe rate
`define CRDB_VU9_BRUTE_FORCE_TX_REG               13'h134    // (RW) Brute force search of TX parameters
`define CRDB_VU9_EQUALIZATION_REG            13'h138    // (RW) Perform Equalization in Handshake
`define CRDB_VU9_OFFSET_REG            13'h13c    // (RW) Perform Offset Calibration in Handshake
`define CRDB_VU9_NAK_INTERVAL_REG            13'h140    // (RW) Minimum Interval between sucessives NAKs
`define CRDB_VU9_PHY_RESET                      13'h144    // (RW) Reset Phy
`define CRDB_VU9_HANDSHAKE_RESTART           13'h148    // (RW) Restart Handshake


`endif

