// Bohdan Purtell
// University of Florida
// Alveo XRT Kernel Bringup

module rtl_toplevel (
  parameter int DATA_WIDTH = 32
) (
  input logic ap_clk,
  input logic ap_rst_n,
  input logic s_axi_control,

  input  [31:0] s_axi_control_AWADDR,
  input         s_axi_control_AWVALID,
  output        s_axi_control_AWREADY,
  input  [31:0] s_axi_control_WDATA,
  input  [3:0]  s_axi_control_WSTRB,
  input         s_axi_control_WVALID,
  output        s_axi_control_WREADY,
  output [1:0]  s_axi_control_BRESP,
  output        s_axi_control_BVALID,
  input         s_axi_control_BREADY,
  input  [31:0] s_axi_control_ARADDR,
  input         s_axi_control_ARVALID,
  output        s_axi_control_ARREADY,
  output [31:0] s_axi_control_RDATA,
  output [1:0]  s_axi_control_RRESP,
  output        s_axi_control_RVALID,
  input         s_axi_control_RREADY
);

logic [31:0] counter;
logic [31:0] counter_next;



endmodule

