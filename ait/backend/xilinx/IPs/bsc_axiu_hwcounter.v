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

module bsc_axiu_hwcounter #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 3
  )
  (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI" *)
    input wire s_axi_aclk,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARADDR"  *) input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARVALID" *) input  wire                            s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARREADY" *) output wire                            s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RDATA"   *) output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RRESP"   *) output wire [1 : 0]                    s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RVALID"  *) output wire                            s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RREADY"  *) input  wire                            s_axi_rready
  );

  reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
  reg                            axi_arready;
  reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
  reg [1 : 0]                    axi_rresp;
  reg                            axi_rvalid;

  // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  // ADDR_LSB is used for addressing 32/64 bit registers/memories
  // ADDR_LSB = 2 for 32 bits (n downto 2)
  // ADDR_LSB = 3 for 64 bits (n downto 3)
  localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;

  reg [63:0] counter = 64'd0;
  wire slv_reg_rden;
  reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
  
  // I/O Connections assignments

  assign s_axi_arready = axi_arready;
  assign s_axi_rdata   = axi_rdata;
  assign s_axi_rresp   = axi_rresp;
  assign s_axi_rvalid  = axi_rvalid;

  // Implement axi_arready generation
  // axi_arready is asserted for one s_axi_aclk clock cycle when
  // S_AXI_ARVALID is asserted. axi_awready is
  // de-asserted when reset (active low) is asserted.
  // The read address is also latched when S_AXI_ARVALID is
  // asserted. axi_araddr is reset to zero on reset assertion.

  always @(posedge s_axi_aclk)
  begin
    if (~axi_arready && s_axi_arvalid)
    begin
      // indicates that the slave has acceped the valid read address
      axi_arready <= 1'b1;
      // Read address latching
      axi_araddr <= s_axi_araddr;
      end
    else
    begin
      axi_arready <= 1'b0;
    end
  end

  // Implement axi_arvalid generation
  // axi_rvalid is asserted for one s00_axi_aclk clock cycle when both
  // S_AXI_ARVALID and axi_arready are asserted. The slave registers
  // data are available on the axi_rdata bus at this instance. The
  // assertion of axi_rvalid marks the validity of read data on the
  // bus and axi_rresp indicates the status of read transaction.axi_rvalid
  // is deasserted on reset (active low). axi_rresp and axi_rdata are
  // cleared to zero on reset (active low).
  always @(posedge s_axi_aclk)
  begin
    if (axi_arready && s_axi_arvalid && ~axi_rvalid)
    begin
      // Valid read data is available at the read data bus
      axi_rvalid <= 1'b1;
      axi_rresp  <= 2'b0; // 'OKAY' response
    end
    else if (axi_rvalid && s_axi_rready)
    begin
      // Read data is accepted by the master
      axi_rvalid <= 1'b0;
    end
  end

    reg [31:0] upper;

  // Implement memory mapped register select and read logic generation
  // Slave register read enable is asserted when valid address is available
  // and the slave is ready to accept the read address.
  assign slv_reg_rden = axi_arready & s_axi_arvalid & ~axi_rvalid;
  always @(*)
  begin
    // Address decoding for reading registers
    case ( axi_araddr )
      3'b000   : reg_data_out <= counter[31:0];
      3'b100   : reg_data_out <= upper;
      default  : reg_data_out <= 0;
    endcase
  end

  // Output register or memory read data
  always @(posedge s_axi_aclk)
  begin
    // When there is a valid read address (S_AXI_ARVALID) with
    // acceptance of read address by the slave (axi_arready),
    // output the read data
    if (slv_reg_rden)
    begin
      upper <= counter[63:32];
      axi_rdata <= reg_data_out;     // register read data
    end
  end

  always @(posedge s_axi_aclk)
  begin
    counter <= counter + 1;
  end

endmodule
