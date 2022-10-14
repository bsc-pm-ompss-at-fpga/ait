
module cmd_in_queue_driver(
    input clk,
    input rstn,
    output [31:0] m_axi_araddr,
    output [2:0] m_axi_arprot,
    input m_axi_arready,
    output m_axi_arvalid,
    output [31:0] m_axi_awaddr,
    output [2:0] m_axi_awprot,
    input m_axi_awready,
    output m_axi_awvalid,
    output m_axi_bready,
    input [1:0] m_axi_bresp,
    input m_axi_bvalid,
    input [63:0] m_axi_rdata,
    output m_axi_rready,
    input [1:0] m_axi_rresp,
    input m_axi_rvalid,
    output [63:0] m_axi_wdata,
    input m_axi_wready,
    output [7:0] m_axi_wstrb,
    output m_axi_wvalid
);

    int fd;
    bit [31:0] addr;
    bit [63:0] data;
    
    enum {
        IDLE,
        READ_DATA,
        AW,
        W,
        B,
        FINISH
    } state;
    
    assign m_axi_arprot = '0;
    assign m_axi_awprot = '0;
    assign m_axi_arvalid = 0;
    assign m_axi_rready = 0;
    assign m_axi_awvalid = state == AW;
    assign m_axi_awaddr = addr;
    assign m_axi_wvalid = state == W;
    assign m_axi_wdata = data;
    assign m_axi_wstrb = 8'hFF;
    assign m_axi_bready = state == B;
    
    initial begin
        fd = $fopen("cmd_in_queue.mem", "r");
        assert (fd) else begin
            $error("Could not open mem file"); $fatal;
        end
    end
    
    always @(posedge clk) begin
        case (state)
        
            IDLE: begin
                state <= READ_DATA;
            end
            
            READ_DATA: begin
                if ($fscanf(fd, "%h %h", addr, data) == 2) begin
                    state <= AW;
                end else begin
                    $fclose(fd);
                    state <= FINISH;
                end
            end
            
            AW: begin
                if (m_axi_awready) begin
                    state <= W;
                end
            end
            
            W: begin
                if (m_axi_wready) begin
                    state <= B;
                end
            end
            
            B: begin
                if (m_axi_bvalid) begin
                    state <= READ_DATA;
                end
            end
            
            FINISH: begin
            
            end
        
        endcase
        
        if (!rstn) begin
            state <= IDLE;
        end
    end

endmodule
