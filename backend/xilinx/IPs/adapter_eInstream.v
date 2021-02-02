/*------------------------------------------------------------------------*/
/*    (C) Copyright 2017-2021 Barcelona Supercomputing Center             */
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

module adapter_eInstream #(
    parameter USE_BUFFER = 0
)
(
    input clk,
    input aresetn,
    output [7:0] out_V,
    output out_V_ap_vld,
    input out_V_ap_ack,
    input in_r_tvalid,
    output in_r_tready,
    input [7:0] in_r_tdata
);

    if (USE_BUFFER) begin

    localparam IDLE = 0;
    localparam WAIT_ACK = 1;
    
    reg [0:0] state;
    reg [7:0] buf_data;
    
    assign in_r_tready = state == IDLE;
    
    assign out_V_ap_vld = state == WAIT_ACK;
    assign out_V = buf_data;
    
    always @(posedge clk) begin
    
        case (state)
        
            IDLE: begin
                buf_data <= in_r_tdata;
                if (in_r_tvalid) begin
                    state <= WAIT_ACK;
                end
            end
            
            WAIT_ACK: begin
                if (out_V_ap_ack) begin
                    state <= IDLE;
                end
            end
        
        endcase
        
        if (!aresetn) begin
            state <= IDLE;
        end
    
    end
    
    end else begin
    
    assign out_V_ap_vld = in_r_tvalid;
    assign out_V = in_r_tdata;
    
    assign in_r_tready = out_V_ap_ack;
    
    end
    
endmodule
