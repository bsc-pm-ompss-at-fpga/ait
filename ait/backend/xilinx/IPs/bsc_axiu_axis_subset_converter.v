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

module bsc_axiu_axis_subset_converter #(
    parameter ID_WIDTH = 1,
    parameter [ID_WIDTH-1:0] ID = 0
) (
    input clk,
    input aresetn,

    input [63:0] S_AXIS_tdata,
    input  [1:0] S_AXIS_tdest,
    input        S_AXIS_tlast,
    input        S_AXIS_tvalid,
    input        M_AXIS_tready,

    output         [63:0] M_AXIS_tdata,
    output          [1:0] M_AXIS_tdest,
    output [ID_WIDTH-1:0] M_AXIS_tid,
    output                M_AXIS_tlast,
    output                M_AXIS_tvalid,
    output                S_AXIS_tready
);

    assign M_AXIS_tdata  = S_AXIS_tdata;
    assign M_AXIS_tdest  = S_AXIS_tdest;
    assign M_AXIS_tid    = ID;
    assign M_AXIS_tlast  = S_AXIS_tlast;
    assign M_AXIS_tvalid = S_AXIS_tvalid;
    assign S_AXIS_tready = M_AXIS_tready;

endmodule
