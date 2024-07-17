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

module bsc_axiu_hsToStreamAdapter #(
    parameter USE_BUFFER = 0,
    parameter TID_WIDTH = 4,
    parameter ACCID = 0
)
(
    input       aclk,
    input       aresetn,

    input [67:0] in_hs,
    input        in_hs_ap_vld,
    output       in_hs_ap_ack,

    output [63:0] outStream_tdata,
    output [2:0]  outStream_tdest,
    output [TID_WIDTH-1:0]  outStream_tid,
    output        outStream_tlast,
    output        outStream_tvalid,
    input         outStream_tready
);

    if (USE_BUFFER) begin

    localparam IDLE = 0;
    localparam WAIT_READY = 1;

    reg [0:0] state;
    reg [63:0] buf_data;
    reg [2:0] buf_dest;
    reg buf_last;
    reg ack;

    assign outStream_tid = ACCID;
    assign outStream_tdata = buf_data;
    assign outStream_tlast = buf_last;
    assign outStream_tdest = buf_dest;
    assign outStream_tvalid = state == WAIT_READY;

    assign in_hs_ap_ack = ack;

    always @(posedge aclk) begin

        ack <= 0;

        case (state)

            IDLE: begin
                buf_last <= in_hs[0];
                buf_dest <= in_hs[3:1];
                buf_data <= in_hs[67:4];

                if (in_hs_ap_vld) begin
                    ack <= 1;
                    state <= WAIT_READY;
                end
            end

            WAIT_READY: begin
                if (outStream_tready) begin
                    state <= IDLE;
                end
            end

        endcase

        if (!aresetn) begin
            state <= IDLE;
        end
    end

    end else begin

    assign outStream_tid = ACCID;
    assign outStream_tdata = in_hs[67:4];
    assign outStream_tlast = in_hs[0];
    assign outStream_tdest = in_hs[3:1];
    assign outStream_tvalid = in_hs_ap_vld;

    assign in_hs_ap_ack = in_hs_ap_vld && outStream_tready;

    end

endmodule
