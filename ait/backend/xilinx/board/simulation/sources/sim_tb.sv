
module sim_tb();

    reg clk;
    reg rstn;
    wire [31:0] hwruntime_m_axi_araddr;
    wire [2:0] hwruntime_m_axi_arprot;
    wire hwruntime_m_axi_arready;
    wire hwruntime_m_axi_arvalid;
    wire [31:0] hwruntime_m_axi_awaddr;
    wire [2:0] hwruntime_m_axi_awprot;
    wire hwruntime_m_axi_awready;
    wire hwruntime_m_axi_awvalid;
    wire hwruntime_m_axi_bready;
    wire [1:0] hwruntime_m_axi_bresp;
    wire hwruntime_m_axi_bvalid;
    wire [63:0] hwruntime_m_axi_rdata;
    wire hwruntime_m_axi_rready;
    wire [1:0] hwruntime_m_axi_rresp;
    wire hwruntime_m_axi_rvalid;
    wire [63:0] hwruntime_m_axi_wdata;
    wire hwruntime_m_axi_wready;
    wire [7:0] hwruntime_m_axi_wstrb;
    wire hwruntime_m_axi_wvalid;

    initial begin
        clk = 0;
        rstn = 0;
        #1000
        rstn = 1;
    end

    always begin
        #1
        clk = !clk;
    end
    
    cmd_in_queue_driver cmd_in_queue_driver_I (
        .clk(clk),
        .rstn(rstn),
        .m_axi_araddr(hwruntime_m_axi_araddr),
        .m_axi_arprot(hwruntime_m_axi_arprot),
        .m_axi_arready(hwruntime_m_axi_arready),
        .m_axi_arvalid(hwruntime_m_axi_arvalid),
        .m_axi_awaddr(hwruntime_m_axi_awaddr),
        .m_axi_awprot(hwruntime_m_axi_awprot),
        .m_axi_awready(hwruntime_m_axi_awready),
        .m_axi_awvalid(hwruntime_m_axi_awvalid),
        .m_axi_bready(hwruntime_m_axi_bready),
        .m_axi_bresp(hwruntime_m_axi_bresp),
        .m_axi_bvalid(hwruntime_m_axi_bvalid),
        .m_axi_rdata(hwruntime_m_axi_rdata),
        .m_axi_rready(hwruntime_m_axi_rready),
        .m_axi_rresp(hwruntime_m_axi_rresp),
        .m_axi_rvalid(hwruntime_m_axi_rvalid),
        .m_axi_wdata(hwruntime_m_axi_wdata),
        .m_axi_wready(hwruntime_m_axi_wready),
        .m_axi_wstrb(hwruntime_m_axi_wstrb),
        .m_axi_wvalid(hwruntime_m_axi_wvalid)
    );
    
    `DESIGN_NAME design_I (
        .clk(clk),
        .rstn(rstn),
        .hwruntime_m_axi_araddr(hwruntime_m_axi_araddr),
        .hwruntime_m_axi_arprot(hwruntime_m_axi_arprot),
        .hwruntime_m_axi_arready(hwruntime_m_axi_arready),
        .hwruntime_m_axi_arvalid(hwruntime_m_axi_arvalid),
        .hwruntime_m_axi_awaddr(hwruntime_m_axi_awaddr),
        .hwruntime_m_axi_awprot(hwruntime_m_axi_awprot),
        .hwruntime_m_axi_awready(hwruntime_m_axi_awready),
        .hwruntime_m_axi_awvalid(hwruntime_m_axi_awvalid),
        .hwruntime_m_axi_bready(hwruntime_m_axi_bready),
        .hwruntime_m_axi_bresp(hwruntime_m_axi_bresp),
        .hwruntime_m_axi_bvalid(hwruntime_m_axi_bvalid),
        .hwruntime_m_axi_rdata(hwruntime_m_axi_rdata),
        .hwruntime_m_axi_rready(hwruntime_m_axi_rready),
        .hwruntime_m_axi_rresp(hwruntime_m_axi_rresp),
        .hwruntime_m_axi_rvalid(hwruntime_m_axi_rvalid),
        .hwruntime_m_axi_wdata(hwruntime_m_axi_wdata),
        .hwruntime_m_axi_wready(hwruntime_m_axi_wready),
        .hwruntime_m_axi_wstrb(hwruntime_m_axi_wstrb),
        .hwruntime_m_axi_wvalid(hwruntime_m_axi_wvalid)
    );
    
endmodule
