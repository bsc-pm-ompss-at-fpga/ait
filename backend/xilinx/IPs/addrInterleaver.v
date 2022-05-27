/*------------------------------------------------------------------------*/
/*    (C) Copyright 2017-2022 Barcelona Supercomputing Center             */
/*                            Centro Nacional de Supercomputacion         */
/*                                                                        */
/*    This file is part of OmpSs@FPGA toolchain.                          */
/*                                                                        */
/*    This code is free software; you can redistribute it and/or modify   */
/*    it under the terms of the GNU Lesser General Public License as      */
/*    published by the Free Software Foundation; either version 3 of      */
/*    the License, or (at your option) any later version.                 */
/*                                                                        */
/*    OmpSs@FPGA toolchain is distributed in the hope that it will be     */
/*    useful, but WITHOUT ANY WARRANTY; without even the implied          */
/*    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    */
/*    See the GNU Lesser General Public License for more details.         */
/*                                                                        */
/*    You should have received a copy of the GNU Lesser General Public    */
/*    License along with this code. If not, see <www.gnu.org/licenses/>.  */
/*------------------------------------------------------------------------*/

`timescale 1ns / 1ps

`undef __ENABLE__

module addrInterleaver#(
`ifdef __ENABLE__
    parameter NUM_BANKS = 4,
    parameter STRIDE = 64'h2000, //8K
    parameter BANK_SIZE = 64'h400000000, //16G
    parameter BASE_ADDR = 64'h0,
`endif
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 4
)
(

  input wire AXI_aclk,
  input wire AXI_aresetn,

  // S_AXI interface port
  // Write address channel
  input [(ADDR_WIDTH-1):0] S_AXI_awaddr, // Write address (optional)
  input [7:0]              S_AXI_awlen, // Burst length (optional)
  input [2:0]              S_AXI_awsize, // Burst size (optional)
  input [1:0]              S_AXI_awburst, // Burst type (optional)
  input [1:0]              S_AXI_awlock, // Lock type (optional)
  input [3:0]              S_AXI_awcache, // Cache type (optional)
  input [2:0]              S_AXI_awprot, // Protection type (optional)
  input [3:0]              S_AXI_awregion, // Write address slave region (optional)
  input [3:0]              S_AXI_awqos, // Transaction Quality of Service token (optional)
  input [(ID_WIDTH-1):0]   S_AXI_awid, // Write address id
  input                    S_AXI_awvalid, // Write address valid (optional)
  output                   S_AXI_awready, // Write address ready (optional)

  // Write data channel
  input [(DATA_WIDTH-1):0] S_AXI_wdata, // Write data (optional)
  input [63:0]             S_AXI_wstrb, // Write strobes (optional)
  input                    S_AXI_wlast, // Write last beat (optional)
  input                    S_AXI_wvalid, // Write valid (optional)
  output                   S_AXI_wready, // Write ready (optional)

  // Write response channel
  output [1:0]            S_AXI_bresp, // Write response (optional)
  output [(ID_WIDTH-1):0] S_AXI_bid, // Write response id (optional)
  output                  S_AXI_bvalid, // Write response valid (optional)
  input                   S_AXI_bready, // Write response ready (optional)

  // Read address channel
  input [(ADDR_WIDTH-1):0] S_AXI_araddr, // Read address (optional)
  input [7:0]              S_AXI_arlen, // Burst length (optional)
  input [2:0]              S_AXI_arsize, // Burst size (optional)
  input [1:0]              S_AXI_arburst, // Burst type (optional)
  input [1:0]              S_AXI_arlock, // Lock type (optional)
  input [3:0]              S_AXI_arcache, // Cache type (optional)
  input [2:0]              S_AXI_arprot, // Protection type (optional)
  input [3:0]              S_AXI_arregion, // Read address slave region (optional)
  input [3:0]              S_AXI_arqos, // Quality of service token (optional)
  input [(ID_WIDTH-1):0]   S_AXI_arid, // Read address id
  input                    S_AXI_arvalid, // Read address valid (optional)
  output                   S_AXI_arready, // Read address ready (optional)

  // Read data channel
  output [(DATA_WIDTH-1):0] S_AXI_rdata, // Read data (optional)
  output [1:0]              S_AXI_rresp, // Read response (optional)
  output                    S_AXI_rlast, // Read last beat (optional)
  output [(ID_WIDTH-1):0]   S_AXI_rid, // Read id (optional)
  output                    S_AXI_rvalid, // Read valid (optional)
  input                     S_AXI_rready, // Read ready (optional)

  // M_AXI interface port
  // Write address channel
  output [(ADDR_WIDTH-1):0] M_AXI_awaddr, // Write address (optional)
  output [7:0]              M_AXI_awlen, // Burst length (optional)
  output [2:0]              M_AXI_awsize, // Burst size (optional)
  output [1:0]              M_AXI_awburst, // Burst type (optional)
  output [1:0]              M_AXI_awlock, // Lock type (optional)
  output [3:0]              M_AXI_awcache, // Cache type (optional)
  output [2:0]              M_AXI_awprot, // Protection type (optional)
  output [3:0]              M_AXI_awregion, // Write address slave region (optional)
  output [3:0]              M_AXI_awqos, // Transaction Quality of Service token (optional)
  output [(ID_WIDTH-1):0]   M_AXI_awid, // Write address id
  output                    M_AXI_awvalid, // Write address valid (optional)
  input                     M_AXI_awready, // Write address ready (optional)

  // Write data channel
  output [(DATA_WIDTH-1):0] M_AXI_wdata, // Write data (optional)
  output [63:0]             M_AXI_wstrb, // Write strobes (optional)
  output                    M_AXI_wlast, // Write last beat (optional)
  output                    M_AXI_wvalid, // Write valid (optional)
  input                     M_AXI_wready, // Write ready (optional)

  // Write response channel
  input [1:0]            M_AXI_bresp, // Write response (optional)
  input [(ID_WIDTH-1):0] M_AXI_bid, // Write response id (optional)
  input                  M_AXI_bvalid, // Write response valid (optional)
  output                 M_AXI_bready, // Write response ready (optional)

  // Read address channel
  output [(ADDR_WIDTH-1):0] M_AXI_araddr, // Read address (optional)
  output [7:0]              M_AXI_arlen, // Burst length (optional)
  output [2:0]              M_AXI_arsize, // Burst size (optional)
  output [1:0]              M_AXI_arburst, // Burst type (optional)
  output [1:0]              M_AXI_arlock, // Lock type (optional)
  output [3:0]              M_AXI_arcache, // Cache type (optional)
  output [2:0]              M_AXI_arprot, // Protection type (optional)
  output [3:0]              M_AXI_arregion, // Read address slave region (optional)
  output [3:0]              M_AXI_arqos, // Quality of service token (optional)
  output [(ID_WIDTH-1):0]   M_AXI_arid, // Read address id
  output                    M_AXI_arvalid, // Read address valid (optional)
  input                     M_AXI_arready, // Read address ready (optional)

  // Read data channel
  input [(DATA_WIDTH-1):0] M_AXI_rdata, // Read data (optional)
  input [1:0]              M_AXI_rresp, // Read response (optional)
  input                    M_AXI_rlast, // Read last beat (optional)
  input [(ID_WIDTH-1):0]   M_AXI_rid, // Read id (optional)
  input                    M_AXI_rvalid, // Read valid (optional)
  output                   M_AXI_rready // Read ready (optional)
);

`ifdef __ENABLE__
    localparam NUM_SELECTOR_BITS = $clog2(NUM_BANKS);
    localparam SRC_SELECTOR_BIT = $clog2(STRIDE);
    localparam DST_SELECTOR_BIT = $clog2(BANK_SIZE);
`endif

    // Write address channel
    assign M_AXI_awlen    = S_AXI_awlen;
    assign M_AXI_awsize   = S_AXI_awsize;
    assign M_AXI_awburst  = S_AXI_awburst;
    assign M_AXI_awlock   = S_AXI_awlock;
    assign M_AXI_awcache  = S_AXI_awcache;
    assign M_AXI_awprot   = S_AXI_awprot;
    assign M_AXI_awregion = S_AXI_awregion;
    assign M_AXI_awqos    = S_AXI_awqos;
    assign M_AXI_awid     = S_AXI_awid;
    assign M_AXI_awvalid  = S_AXI_awvalid;
    assign M_AXI_awready  = S_AXI_awready;

    // Write data channel
    assign M_AXI_wdata  = S_AXI_wdata;
    assign M_AXI_wstrb  = S_AXI_wstrb;
    assign M_AXI_wlast  = S_AXI_wlast;
    assign M_AXI_wvalid = S_AXI_wvalid;
    assign M_AXI_wready = S_AXI_wready;

    // Write response channel
    assign M_AXI_bresp  = S_AXI_bresp;
    assign M_AXI_bid    = S_AXI_bid;
    assign M_AXI_bvalid = S_AXI_bvalid;
    assign M_AXI_bready = S_AXI_bready;

    // Read address channel
    assign M_AXI_arlen    = S_AXI_arlen;
    assign M_AXI_arsize   = S_AXI_arsize;
    assign M_AXI_arburst  = S_AXI_arburst;
    assign M_AXI_arlock   = S_AXI_arlock;
    assign M_AXI_arcache  = S_AXI_arcache;
    assign M_AXI_arprot   = S_AXI_arprot;
    assign M_AXI_arregion = S_AXI_arregion;
    assign M_AXI_arqos    = S_AXI_arqos;
    assign M_AXI_arid     = S_AXI_arid;
    assign M_AXI_arvalid  = S_AXI_arvalid;
    assign M_AXI_arready  = S_AXI_arready;

    // Read data channel
    assign M_AXI_rdata  = S_AXI_rdata;
    assign M_AXI_rresp  = S_AXI_rresp;
    assign M_AXI_rlast  = S_AXI_rlast;
    assign M_AXI_rid    = S_AXI_rid;
    assign M_AXI_rvalid = S_AXI_rvalid;
    assign M_AXI_rready = S_AXI_rready;

    reg [(ADDR_WIDTH-1):0] r_awaddr;
    reg [(ADDR_WIDTH-1):0] r_araddr;

    assign M_AXI_awaddr = r_awaddr;
    assign M_AXI_araddr = r_araddr;

	// awaddr signal
    // Only interleave addresses within DDR address space
    always @(*) begin
    `ifdef __ENABLE__
        if (S_AXI_awaddr < BASE_ADDR + BANK_SIZE*NUM_BANKS) begin
            r_awaddr <= {S_AXI_awaddr[(ADDR_WIDTH-1)                       : DST_SELECTOR_BIT+NUM_SELECTOR_BITS],
                         S_AXI_awaddr[SRC_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT],
                         S_AXI_awaddr[DST_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT+NUM_SELECTOR_BITS],
                         S_AXI_awaddr[SRC_SELECTOR_BIT-1                   : 0]};
        end
        else begin
            r_awaddr <= S_AXI_awaddr;
        end
    `else
        r_awaddr <= S_AXI_awaddr;
    `endif
    end

	// araddr signal
    // Only interleave addresses within DDR address space
    always @(*) begin
    `ifdef __ENABLE__
        if (S_AXI_araddr < BASE_ADDR + BANK_SIZE*NUM_BANKS) begin
            r_araddr <= {S_AXI_araddr[(ADDR_WIDTH-1)                       : DST_SELECTOR_BIT+NUM_SELECTOR_BITS],
                         S_AXI_araddr[SRC_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT],
                         S_AXI_araddr[DST_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT+NUM_SELECTOR_BITS],
                         S_AXI_araddr[SRC_SELECTOR_BIT-1                   : 0]};
        end
        else begin
            r_araddr <= S_AXI_araddr;
        end
    `else
        r_araddr <= S_AXI_araddr;
    `endif
    end
endmodule
