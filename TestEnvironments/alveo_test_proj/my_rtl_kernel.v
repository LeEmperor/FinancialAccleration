// ============================================================================
// Minimal RTL Kernel for Vitis (AXI4-Lite Control Only)
// ap_ctrl_hs handshake: ap_start / ap_done / ap_idle / ap_ready
// ============================================================================
module my_kernel (
  input         ap_clk,
  input         ap_rst_n,

  // AXI4-Lite slave interface for control and arguments
  input  [4:0]  s_axi_control_AWADDR,
  input         s_axi_control_AWVALID,
  output        s_axi_control_AWREADY,
  input  [31:0] s_axi_control_WDATA,
  input  [3:0]  s_axi_control_WSTRB,
  input         s_axi_control_WVALID,
  output        s_axi_control_WREADY,
  output [1:0]  s_axi_control_BRESP,
  output        s_axi_control_BVALID,
  input         s_axi_control_BREADY,
  input  [4:0]  s_axi_control_ARADDR,
  input         s_axi_control_ARVALID,
  output        s_axi_control_ARREADY,
  output [31:0] s_axi_control_RDATA,
  output [1:0]  s_axi_control_RRESP,
  output        s_axi_control_RVALID,
  input         s_axi_control_RREADY
);

  // -------------------------------------------------------------
  // AXI-lite register bank: [0x10] -> input N, [0x18] -> result
  // -------------------------------------------------------------
  reg [31:0] reg_n      = 0;
  reg [31:0] reg_result = 0;

  // Basic handshake registers
  reg ap_start = 0;
  reg ap_done  = 0;
  reg ap_idle  = 1;

  // Simple AXI4-Lite slave skeleton
  // (For a bringup, we just model one 32-bit write and read register space)
  assign s_axi_control_AWREADY = s_axi_control_AWVALID;
  assign s_axi_control_WREADY  = s_axi_control_WVALID;
  assign s_axi_control_BRESP   = 2'b00;
  assign s_axi_control_BVALID  = s_axi_control_WVALID;
  assign s_axi_control_ARREADY = s_axi_control_ARVALID;
  assign s_axi_control_RRESP   = 2'b00;
  assign s_axi_control_RVALID  = s_axi_control_ARVALID;
  assign s_axi_control_RDATA   = (s_axi_control_ARADDR[4:2] == 3'b010) ? reg_n :
                                 (s_axi_control_ARADDR[4:2] == 3'b011) ? reg_result :
                                 32'hDEADBEEF;

  // Capture N when written to 0x10
  always @(posedge ap_clk) begin
    if (!ap_rst_n) begin
      reg_n <= 0;
    end else if (s_axi_control_WVALID && s_axi_control_AWADDR[4:2] == 3'b010) begin
      reg_n <= s_axi_control_WDATA;
    end
  end

  // -------------------------------------------------------------
  // Simple FSM: count to N, set result = N, assert done
  // -------------------------------------------------------------
  reg [31:0] counter = 0;
  always @(posedge ap_clk) begin
    if (!ap_rst_n) begin
      counter   <= 0;
      ap_start  <= 0;
      ap_done   <= 0;
      ap_idle   <= 1;
      reg_result <= 0;
    end else begin
      if (s_axi_control_WVALID && s_axi_control_AWADDR[4:2] == 3'b000)
        ap_start <= s_axi_control_WDATA[0]; // host writes ap_start

      if (ap_start && ap_idle) begin
        ap_idle <= 0;
        ap_done <= 0;
        counter <= 0;
      end else if (!ap_idle) begin
        if (counter < reg_n)
          counter <= counter + 1;
        else begin
          ap_done    <= 1;
          ap_idle    <= 1;
          reg_result <= reg_n;
          ap_start   <= 0;
        end
      end
    end
  end
endmodule

