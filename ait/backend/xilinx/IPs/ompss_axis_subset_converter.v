module ompss_axis_subset_converter #(
    parameter ID_WIDTH = 1,
    parameter [ID_WIDTH-1:0] ID = 0
) (
    input clk,
    input aresetn,
    input S_AXIS_tvalid,
    output S_AXIS_tready,
    input [63:0] S_AXIS_tdata,
    input [1:0] S_AXIS_tdest,
    input S_AXIS_tlast,

    output M_AXIS_tvalid,
    input M_AXIS_tready,
    output [63:0] M_AXIS_tdata,
    output [1:0] M_AXIS_tdest,
    output [ID_WIDTH-1:0] M_AXIS_tid,
    output M_AXIS_tlast
);

    assign M_AXIS_tvalid = S_AXIS_tvalid;
    assign S_AXIS_tready = M_AXIS_tready;
    assign M_AXIS_tdata = S_AXIS_tdata;
    assign M_AXIS_tdest = S_AXIS_tdest;
    assign M_AXIS_tlast = S_AXIS_tlast;
    assign M_AXIS_tid = ID;

endmodule
