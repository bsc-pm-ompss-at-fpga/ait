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

module bsc_axiu_streamToHsAdapter #(
    parameter USE_BUFFER = 0
)
(
    input aclk,
    input aresetn,

    input [63:0] inStream_tdata,
    input        inStream_tvalid,
    output       inStream_tready,

    output [63:0] out_hs,
    output        out_hs_ap_vld,
    input         out_hs_ap_ack
);

    if (USE_BUFFER) begin

    localparam IDLE = 0;
    localparam WAIT_ACK = 1;

    reg [0:0] state;
    reg [63:0] buf_data;

    assign inStream_tready = state == IDLE;

    assign out_hs_ap_vld = state == WAIT_ACK;
    assign out_hs = buf_data;

    always @(posedge aclk) begin

        case (state)

            IDLE: begin
                buf_data <= inStream_tdata;

                if (inStream_tvalid) begin
                    state <= WAIT_ACK;
                end
            end

            WAIT_ACK: begin
                if (out_hs_ap_ack) begin
                    state <= IDLE;
                end
            end

        endcase

        if (!aresetn) begin
            state <= IDLE;
        end
    end

    end else begin

    assign out_hs_ap_vld = inStream_tvalid;
    assign out_hs = inStream_tdata;

    assign inStream_tready = out_hs_ap_ack;

    end

endmodule
