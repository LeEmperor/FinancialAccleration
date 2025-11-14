// Bohdan Purtell
// University of Florida
// IP AXI-UART stuff

module test_module #(
  parameter int DATA_WIDTH = 32
) (
  // debug probes
  input logic debug_launch_write,
  input logic debug_launch_read,

  input  logic         aclk,
  input  logic         aresetn,

  // AXI4-Lite Master Write Address
  output logic [31:0]  M_AXI_AWADDR,
  output logic         M_AXI_AWVALID,
  input  logic         M_AXI_AWREADY,

  // AXI4-Lite Master Write Data
  output logic [31:0]  M_AXI_WDATA,
  output logic [3:0]   M_AXI_WSTRB,
  output logic         M_AXI_WVALID,
  input  logic         M_AXI_WREADY,

  // AXI4-Lite Master Write Response
  input  logic [1:0]   M_AXI_BRESP,
  input  logic         M_AXI_BVALID,
  output logic         M_AXI_BREADY,

  // AXI4-Lite Master Read Address
  output logic [31:0]  M_AXI_ARADDR,
  output logic         M_AXI_ARVALID,
  input  logic         M_AXI_ARREADY,

  // AXI4-Lite Master Read Data
  input  logic [31:0]  M_AXI_RDATA,
  input  logic [1:0]   M_AXI_RRESP,
  input  logic         M_AXI_RVALID,
  output logic         M_AXI_RREADY
);

typedef enum {
  IDLE,
  AXI_WRITE_ADDR,
  AXI_WRITE_DATA,
  AXI_WRITE_RESPONSE,
  AXI_READ_ADDR,
  AXI_READ_DATA
} axi_t;

axi_t axi_state, axi_state_next; 

logic axi_do_write;
logic axi_do_read;

logic [31:0] write_addr;
logic [31:0] read_addr;

logic [31:0] write_data;
logic [31:0] read_data;

logic launch_write;
logic launch_read;

localparam logic [31:0] uart_base_addr    = 32'h0;
localparam logic [31:0] rx_fifo_offset    = 32'h0;
localparam logic [31:0] tx_fifo_offset    = 32'h4;
localparam logic [31:0] status_reg_offset = 32'h8;
localparam logic [31:0] ctrl_reg_offset   = 32'hC;

always_ff @(posedge aclk) 
begin
  if (aresetn) begin
    axi_state <= IDLE;
  end else begin
    axi_state <= axi_state_next;
  end
end

always_comb
begin
  axi_state_next = axi_state;
  case(axi_state)
    IDLE : begin
      if (debug_launch_write) axi_state_next = AXI_WRITE_ADDR;
      if (debug_launch_read) axi_state_next = AXI_READ_ADDR;
    end

    AXI_WRITE_ADDR : begin
      M_AXI_AWADDR = write_addr; 
      M_AXI_AWVALID = 1;
      axi_state_next = AXI_WRITE_DATA;
    end

    AXI_WRITE_DATA : begin
      if (M_AXI_AWREADY) begin // assumer que c'est valide
        // handshake complete
        M_AXI_WDATA = write_data;
        M_AXI_WSTRB = 'hF;
        M_AXI_WVALID = 1;
        axi_state_next = AXI_WRITE_RESPONSE;
      end
    end

    AXI_WRITE_RESPONSE : begin
      // if (BVALID && (BRESP == 2'b00)) begin
      //
      // end
      if (M_AXI_WREADY) begin

      end
    end

    AXI_READ_ADDR : begin
      if (M_AXI_ARREADY) begin
        axi_state_next = AXI_READ_DATA;
      end
    end

    AXI_READ_DATA : begin
      if (M_AXI_RVALID) begin
        read_data = M_AXI_RDATA;
        axi_state_next = IDLE;
      end
    end

    default : begin

    end
  endcase
end


// typedef enum {
//   IDLE,
//   RESET_FIFOS,
//   GET_FULL_STATUS,
//
// } state_t;
//
// state_t current_state, next_state;
//
// always_ff @(posedge clk)
// begin
//   if (rst) begin
//   end else begin 
//     case (current_state)
//       IDLE : begin 
//         current_state <= RESET_FIFOS;
//       end
//
//       RESET_FIFOS : begin
//         write_addr <= 32'h8;
//         write_data <= 32'b11;
//         launch_write <= 1;
//         current_state <= GET_FULL_STATUS; 
//       end
//
//       GET_FULL_STATUS : begin
//         write_addr <= 32'h4;
//         launch_read <= 1;
//         current_state <= SEND_HELLO;
//       end
//
//       SEND_HELLO : begin
//         write_addr <= 32'h0;
//         write_data <= 32'h61; // ascii 'a'
//         launch_write <= 1;
//         current_state <= GET_FULL_STATUS;
//       end
//     endcase
//   end
// end
//
//

endmodule

