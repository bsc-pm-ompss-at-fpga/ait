
module spawn_queues_sim #(
    parameter SI_OFFSET = 0,
    parameter SO_OFFSET = 0,
    parameter SI_LEN = 0,
    parameter SO_LEN = 0
) (
    input clk,
    input rstn,
    output logic [31:0] m_axi_araddr,
    output [2:0] m_axi_arprot,
    input m_axi_arready,
    output logic m_axi_arvalid,
    output logic [31:0] m_axi_awaddr,
    output [2:0] m_axi_awprot,
    input m_axi_awready,
    output logic m_axi_awvalid,
    output m_axi_bready,
    input [1:0] m_axi_bresp,
    input m_axi_bvalid,
    input [63:0] m_axi_rdata,
    output m_axi_rready,
    input [1:0] m_axi_rresp,
    input m_axi_rvalid,
    output logic [63:0] m_axi_wdata,
    input m_axi_wready,
    output logic [7:0] m_axi_wstrb,
    output logic m_axi_wvalid
);

    localparam VALID = 8'h80;
    localparam INVALID = 8'h00;
    localparam VALID_L = 56;
    localparam VALID_H = 63;

    localparam NARGS_OFFSET = 8;
    localparam NDEPS_OFFSET = 16;
    localparam NCOPS_OFFSET = 24;
    
    localparam COPS_NWORDS = 2;
    
    localparam NEW_TASK_CONST_WORDS = 4;
    
    localparam TID_IDX = 1;
    localparam PTID_IDX = 2;

    reg [63:0] tid;
    reg [63:0] ptid;
    
    int so_idx = 0;
    int si_idx = 0;
    int nslots;
    
    bit data_sent = 0, addr_sent = 0;
    
    int count;

    enum {
        IDLE,
        ADDR_HEADER_SO,
        READ_HEADER_SO,
        ADDR_TID_SO,
        READ_TID_SO,
        ADDR_PTID_SO,
        READ_PTID_SO,
        CLEAR_SLOT,
        WAIT_CLEAR_SLOT_WRESP,
        WRITE_HEADER_SO,
        WAIT_HEADER_WRESP_SO,
        WAIT_TIME,
        ADDR_HEADER_SI,
        READ_HEADER_SI,
        WRITE_TID_SI,
        WAIT_TID_WRESP_SI,
        WRITE_PTID_SI,
        WAIT_PTID_WRESP_SI,
        WRITE_HEADER_SI,
        WAIT_HEADER_WRESP_SI
    } state;
    
    assign m_axi_arprot = 0;
    assign m_axi_awprot = 0;
    assign m_axi_rready = state == READ_HEADER_SO || state == READ_TID_SO || state == READ_PTID_SO || state == READ_HEADER_SI;
    assign m_axi_bready = state == WAIT_CLEAR_SLOT_WRESP || state == WAIT_HEADER_WRESP_SO || state == WAIT_TID_WRESP_SI || state == WAIT_PTID_WRESP_SI || state == WAIT_HEADER_WRESP_SI;
    
    always_comb begin
        m_axi_arvalid = 0;
        m_axi_awvalid = 0;
        m_axi_wvalid = 0;
        m_axi_araddr = 'X;
        m_axi_awaddr = 'X;
        m_axi_wdata = 'X;
        m_axi_wstrb = 'X;
        
        
        case (state)
        
            ADDR_HEADER_SO: begin
                m_axi_arvalid = 1;
                m_axi_araddr = SO_OFFSET + (so_idx%SO_LEN)*8;
            end
            
            ADDR_TID_SO: begin
                m_axi_arvalid = 1;
                m_axi_araddr = SO_OFFSET + ((so_idx + TID_IDX)%SO_LEN)*8;
            end
            
            ADDR_PTID_SO: begin
                m_axi_arvalid = 1;
                m_axi_araddr = SO_OFFSET + ((so_idx + PTID_IDX)%SO_LEN)*8;
            end
            
            CLEAR_SLOT: begin
                m_axi_awvalid = !addr_sent;
                m_axi_wvalid = !data_sent;
                m_axi_awaddr = SO_OFFSET + ((so_idx + (nslots - count))%SO_LEN)*8;
                m_axi_wdata = 0;
                m_axi_wstrb = 8'h80;
            end
        
            WRITE_HEADER_SO: begin
                m_axi_awvalid = !addr_sent;
                m_axi_wvalid = !data_sent;
                m_axi_awaddr = SO_OFFSET + (so_idx%SO_LEN)*8;
                m_axi_wdata = 0;
                m_axi_wstrb = 8'h80;
            end
        
            ADDR_HEADER_SI: begin
                m_axi_arvalid = 1;
                m_axi_araddr = SI_OFFSET + (si_idx%SI_LEN)*8;
            end
            
            WRITE_TID_SI: begin
                m_axi_awvalid = !addr_sent;
                m_axi_wvalid = !data_sent;
                m_axi_awaddr = SI_OFFSET + ((si_idx + TID_IDX)%SI_LEN)*8;
                m_axi_wdata = tid;
                m_axi_wstrb = 8'hFF;
            end
            
            WRITE_PTID_SI: begin
                m_axi_awvalid = !addr_sent;
                m_axi_wvalid = !data_sent;
                m_axi_awaddr = SI_OFFSET + ((si_idx + PTID_IDX)%SI_LEN)*8;
                m_axi_wdata = ptid;
                m_axi_wstrb = 8'hFF;
            end
            
            WRITE_HEADER_SI: begin
                m_axi_awvalid = !addr_sent;
                m_axi_wvalid = !data_sent;
                m_axi_awaddr = SI_OFFSET + (si_idx%SI_LEN)*8;
                m_axi_wdata[VALID_H:VALID_L] = VALID;
                m_axi_wstrb = 8'hFF;
            end
        
        endcase
        
    end
    
    always_ff @(posedge clk) begin
        
        case (state)
        
            IDLE: begin
                state <= ADDR_HEADER_SO;
            end
            
            ADDR_HEADER_SO: begin
                if (m_axi_arready) begin
                    state <= READ_HEADER_SO;
                end
            end
            
            READ_HEADER_SO: begin
                if (m_axi_rvalid) begin
                    count <= NEW_TASK_CONST_WORDS + m_axi_rdata[NARGS_OFFSET +: 8] + m_axi_rdata[NDEPS_OFFSET +: 8] + m_axi_rdata[NCOPS_OFFSET +: 8]*COPS_NWORDS - 1; //The header is cleared in a different state
                    if (m_axi_rdata[VALID_H:VALID_L] == VALID) begin
                        state <= ADDR_TID_SO;
                    end else begin
                        state <= ADDR_HEADER_SO;
                    end
                end
            end
            
            ADDR_TID_SO: begin
                if (m_axi_arready) begin
                    nslots = count+1;
                    state <= READ_TID_SO;
                end
            end
            
            READ_TID_SO: begin
                if (m_axi_rvalid) begin
                    tid <= m_axi_rdata;
                    state <= ADDR_PTID_SO;
                end
            end
            
            ADDR_PTID_SO: begin
                if (m_axi_arready) begin
                    state <= READ_PTID_SO;
                end
            end
            
            READ_PTID_SO: begin
                if (m_axi_rvalid) begin
                    ptid <= m_axi_rdata;
                    state <= CLEAR_SLOT;
                end
            end
        
            CLEAR_SLOT: begin
                if ((!data_sent && !addr_sent && m_axi_awready && m_axi_wready) ||
                    (!data_sent &&  addr_sent && m_axi_wready) ||
                    ( data_sent && !addr_sent && m_axi_awready)) begin
                    data_sent <= 0;
                    addr_sent <= 0;
                    state <= WAIT_CLEAR_SLOT_WRESP;
                end else if (m_axi_awready) begin
                    addr_sent <= 1;
                end else if (m_axi_wready) begin
                    data_sent <= 1;
                end
            end
            
            WAIT_CLEAR_SLOT_WRESP: begin
                if (m_axi_bvalid) begin
                    --count;
                    if (count == 0) begin
                        state <= WRITE_HEADER_SO;
                    end else begin
                        state <= CLEAR_SLOT;
                    end
                end
            end
            
            WRITE_HEADER_SO: begin
                if ((!data_sent && !addr_sent && m_axi_awready && m_axi_wready) ||
                    (!data_sent &&  addr_sent && m_axi_wready) ||
                    ( data_sent && !addr_sent && m_axi_awready)) begin
                    data_sent <= 0;
                    addr_sent <= 0;
                    state <= WAIT_HEADER_WRESP_SO;
                end else if (m_axi_awready) begin
                    addr_sent <= 1;
                end else if (m_axi_wready) begin
                    data_sent <= 1;
                end
            end
            
            WAIT_HEADER_WRESP_SO: begin
                if (m_axi_bvalid) begin
                    count = $urandom_range(1, 100);
                    so_idx += nslots;
                    state <= WAIT_TIME;
                end
            end
            
            WAIT_TIME: begin
                --count;
                if (count == 0) begin
                    state <= ADDR_HEADER_SI;
                end
            end
            
            ADDR_HEADER_SI: begin
                if (m_axi_arready) begin
                    state <= READ_HEADER_SI;
                end
            end
            
            READ_HEADER_SI: begin
                if (m_axi_rvalid) begin
                    if (m_axi_rdata[VALID_H:VALID_L] == INVALID) begin
                        state <= WRITE_TID_SI;
                    end else begin
                        state <= ADDR_HEADER_SI;
                    end
                end
            end
            
            WRITE_TID_SI: begin
                if ((!data_sent && !addr_sent && m_axi_awready && m_axi_wready) ||
                    (!data_sent &&  addr_sent && m_axi_wready) ||
                    ( data_sent && !addr_sent && m_axi_awready)) begin
                    data_sent <= 0;
                    addr_sent <= 0;
                    state <= WAIT_TID_WRESP_SI;
                end else if (m_axi_awready) begin
                    addr_sent <= 1;
                end else if (m_axi_wready) begin
                    data_sent <= 1;
                end
            end
            
            WAIT_TID_WRESP_SI: begin
                if (m_axi_bvalid) begin
                    state <= WRITE_PTID_SI;
                end
            end
            
            WRITE_PTID_SI: begin
                if ((!data_sent && !addr_sent && m_axi_awready && m_axi_wready) ||
                    (!data_sent &&  addr_sent && m_axi_wready) ||
                    ( data_sent && !addr_sent && m_axi_awready)) begin
                    data_sent <= 0;
                    addr_sent <= 0;
                    state <= WAIT_PTID_WRESP_SI;
                end else if (m_axi_awready) begin
                    addr_sent <= 1;
                end else if (m_axi_wready) begin
                    data_sent <= 1;
                end
            end
            
            WAIT_PTID_WRESP_SI: begin
                if (m_axi_bvalid) begin
                    state <= WRITE_HEADER_SI;
                end
            end
            
            WRITE_HEADER_SI: begin
                if ((!data_sent && !addr_sent && m_axi_awready && m_axi_wready) ||
                    (!data_sent &&  addr_sent && m_axi_wready) ||
                    ( data_sent && !addr_sent && m_axi_awready)) begin
                    data_sent <= 0;
                    addr_sent <= 0;
                    state <= WAIT_HEADER_WRESP_SI;
                end else if (m_axi_awready) begin
                    addr_sent <= 1;
                end else if (m_axi_wready) begin
                    data_sent <= 1;
                end
            end
            
            WAIT_HEADER_WRESP_SI: begin
                if (m_axi_bvalid) begin
                    si_idx += 3;
                    state <= ADDR_HEADER_SO;
                end
            end
        
        endcase
    
        if (!rstn) begin
            state <= IDLE;
        end
    end

endmodule
