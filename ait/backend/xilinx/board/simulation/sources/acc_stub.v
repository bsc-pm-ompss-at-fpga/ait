
module acc_stub #(
    parameter WAIT_TIME = 100,
    parameter STORE_PTID = 1
) (
    input clk,
    input rstn,
    input inStream_tvalid,
    output inStream_tready,
    input inStream_tlast,
    input [63:0] inStream_tdata,
    output outStream_tvalid,
    input outStream_tready,
    output [63:0] outStream_tdata,
    output [1:0] outStream_tdest,
    output outStream_tlast
);

    localparam IDLE = 0;
    localparam READ_TID = 1;
    localparam READ_PTID = 2;
    localparam READ_ARGS = 3;
    localparam WAIT = 4;
    localparam WRITE_COMMAND = 5;
    localparam WRITE_TID = 6;
    localparam WRITE_PTID = 7;
    
    reg [3:0] state;
    reg [31:0] count;
    reg [63:0] tid;
    reg [63:0] ptid;
    reg [63:0] outPort;
    
    assign inStream_tready = state == IDLE || state == READ_TID || state == READ_PTID || state == READ_ARGS;
    assign outStream_tvalid = state == WRITE_COMMAND || state == WRITE_TID || state == WRITE_PTID;
    assign outStream_tlast = STORE_PTID ? state == WRITE_PTID : state == WRITE_TID;
    assign outStream_tdest = 2'd0;
    assign outStream_tdata = outPort;
    
    always @(*) begin
        outPort = tid;
        if (state == WRITE_COMMAND) begin
            outPort = 64'd3;
        end else if (STORE_PTID && state == WRITE_PTID) begin
            outPort = ptid;
        end
    end
    
    always @(posedge clk) begin
    
        case (state)
        
            IDLE: begin
                count <= 0;
                if (inStream_tvalid) begin
                    state <= READ_TID;
                end
            end
            
            READ_TID: begin
                tid <= inStream_tdata;
                if (inStream_tvalid) begin
                    state <= STORE_PTID ? READ_PTID : READ_ARGS;
                end
            end
            
            READ_PTID: begin
                ptid <= inStream_tdata;
                if (inStream_tvalid) begin
                    state <= READ_ARGS;
                end
            end
            
            READ_ARGS: begin
                if (inStream_tvalid && inStream_tlast) begin
                    state <= WAIT;
                end
            end
            
            WAIT: begin
                count <= count+1;
                if (count == WAIT_TIME) begin
                    state <= WRITE_COMMAND;
                end
            end
            
            WRITE_COMMAND: begin
                if (outStream_tready) begin
                    state <= WRITE_TID;
                end
            end
            
            WRITE_TID: begin
                if (outStream_tready) begin
                    state <= STORE_PTID ? WRITE_PTID : IDLE;
                end
            end
        
            WRITE_PTID: begin
                if (outStream_tready) begin
                    state <= IDLE;
                end
            end
            
        endcase
    
        if (!rstn) begin
            state <= IDLE;
        end
    end

endmodule
