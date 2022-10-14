module axis_tid_demux (
    input clk,
    input s_tvalid,
    output s_tready,
    input [63:0] s_tdata,
    input [0:0] s_tid,
    output m0_tvalid,
    input m0_tready,
    output [63:0] m0_tdata,
    output m1_tvalid,
    input m1_tready,
    output [63:0] m1_tdata
);

    assign m0_tvalid = s_tvalid && s_tid == 1'b0;
    assign m1_tvalid = s_tvalid && s_tid == 1'b1;
    assign m0_tdata = s_tdata;
    assign m1_tdata = s_tdata;
    assign s_tready = s_tid == 1'b0 ? m0_tready : m1_tready;

endmodule
