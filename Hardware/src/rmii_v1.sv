// Bohdan Purtell
// University of Florida
// Description: RMII interface (SHIM)

module rmii_v1 #(
  parameter int WIDTH = 64,
  parameter int MIN_FRAME_BYTES = 64
) (
  input logic clk,
  input logic rst,


  // RMII interface
  input logic [1:0] RXD,
  input logic CRS_DV,

  output logic TX_EN,
  output logic [1:0] TXD,

  // AXIS interface
  output logic [7:0] tx_tdata,
  output logic tx_tvalid,
  input logic tx_tready,

  input logic [7:0] rx_tdata,
  input logic rx_tvalid,
  output logic rx_tready

);

  typedef enum {
    IDLE,
    PREAMBLE, // 7B: 0x55
    SFD, // 0xD5
    PAYLOAD, // 
    PAD, 
    FCS,
    IFG

  } tx_state_t;


  tx_state_t tx_current_state, tx_next_state;

  // state reg
  always_ff @(posedge clk)
  begin
    if (rst)
      tx_current_state = IDLE;
    else
      tx_current_state = tx_next_state;
  end


  logic [7:0] send_byte;
  logic [2:0] byte_ptr;
  logic [1:0] next_byte_ptr;

  assign tx_tdata = send_byte;

  // logic [2:0] preamble_cnt;

  always_ff @(posedge clk)
  begin
    if (rst) begin
      byte_ptr <= 0;
      send_byte <= 0;
      next_byte_ptr <= 0;
    end else begin
      tx_tvalid <= 0;
      // maybe latching on send_byte and byte_ptr?

      if (CRS_DV) begin
        send_byte[byte_ptr] <= RXD[0];
        send_byte[byte_ptr + 1] <= RXD[1];
        byte_ptr <= byte_ptr + 2'd2;

        if(byte_ptr == 6) begin
          tx_tvalid <= 1;
        end
      end
    end

  end




endmodule

