/*------------------------------------------------------------------------*/
/*    (C) Copyright 2017-2024 Barcelona Supercomputing Center             */
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

`undef __ENABLE__
`define __ADDR_WIDTH__ 64


`ifdef __ENABLE__
module bsc_axiu_addrInterleaver #(
    parameter NUM_BANKS = 4,
    parameter STRIDE = `__ADDR_WIDTH__'h2000, //8K
    parameter BANK_SIZE = `__ADDR_WIDTH__'h400000000, //16G
    parameter BASE_ADDR = `__ADDR_WIDTH__'h0
)
`else
module bsc_axiu_addrInterleaver
`endif
(
    input wire [(`__ADDR_WIDTH__-1):0] in_addr,

    output wire [(`__ADDR_WIDTH__-1):0] out_addr
);

    reg [(`__ADDR_WIDTH__-1):0] r_out_addr;

`ifdef __ENABLE__
    localparam NUM_SELECTOR_BITS = $clog2(NUM_BANKS);
    localparam SRC_SELECTOR_BIT = $clog2(STRIDE);
    localparam DST_SELECTOR_BIT = $clog2(BANK_SIZE);
`endif

    assign out_addr = r_out_addr;

    // Only interleave addresses within DDR address space
    always @(*) begin
    `ifdef __ENABLE__
        if (in_addr < BASE_ADDR + BANK_SIZE*NUM_BANKS) begin
            r_out_addr <= {in_addr[(`__ADDR_WIDTH__-1)                  : DST_SELECTOR_BIT+NUM_SELECTOR_BITS],
                           in_addr[SRC_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT],
                           in_addr[DST_SELECTOR_BIT+NUM_SELECTOR_BITS-1 : SRC_SELECTOR_BIT+NUM_SELECTOR_BITS],
                           in_addr[SRC_SELECTOR_BIT-1                   : 0]};
        end
        else begin
            r_out_addr <= in_addr;
        end
    `else
        r_out_addr <= in_addr;
    `endif
    end

endmodule

