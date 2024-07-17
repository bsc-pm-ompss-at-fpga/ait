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

module bsc_axiu_axis_tid_demux (
    input clk,

    input [63:0] s_tdata,
    input  [0:0] s_tid,
    input        s_tvalid,
    input        m0_tready,
    input        m1_tready,

    output [63:0] m0_tdata,
    output [63:0] m1_tdata,
    output        m0_tvalid,
    output        m1_tvalid,
    output        s_tready
);

    assign m0_tvalid = s_tvalid && s_tid == 1'b0;
    assign m1_tvalid = s_tvalid && s_tid == 1'b1;

    assign m0_tdata = s_tdata;
    assign m1_tdata = s_tdata;

    assign s_tready = s_tid == 1'b0 ? m0_tready : m1_tready;

endmodule
