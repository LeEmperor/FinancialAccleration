// Bohdan Purtell
// University of Florida
// Description: Module pour MAC RX et EThernet Decoder
// STATUS: basic parsing tested, tvalid assertions not yet

module RX_MAC_v1 #(
  parameter int WIDTH = 64
) (
  input logic clk, rst,

  input logic [7:0] rx_datain,
  input logic rx_tlast,
  output logic [7:0] tx_dataout,
  output logic tx_tlast
);


typedef enum {
  IDLE,
  EATING_PREAMBLE,
  HEADER_PARSING,
  IN_PAYLOAD,
  DONE
} rx_state_t;

rx_state_t rx_current_state, rx_next_state;

logic [47:0] dest_mac;
logic [47:0] src_mac;
logic [15:0] type_length;

localparam PREAMBLE_JUMBLE = 8'h55;
localparam START_FRAME_DELIMITER = 8'hDF;

logic [2:0] counter_bruh;
logic [63:0] whole_frame;
logic [7:0] frame_index;

logic [13:0] buffer;
logic [3:0] buffer_index;

// next state logic
always_ff @(posedge clk or posedge rst)
begin
  if (rst) begin
    rx_current_state <= IDLE;
    counter_bruh <= 0;
    frame_index <= 0;
  end else begin
    rx_current_state <= rx_next_state;
  end
end

// next_state logic
always_comb
begin
  // defautls
  rx_next_state = rx_current_state;
  tx_dataout = 0;

  unique case(rx_current_state)
    IDLE : begin
      if (rx_datain == PREAMBLE_JUMBLE)
        rx_next_state = EATING_PREAMBLE;
    end

    EATING_PREAMBLE : begin
      if (rx_datain == START_FRAME_DELIMITER)
          rx_next_state = HEADER_PARSING;
    end

    HEADER_PARSING : begin
      buffer[buffer_index] = rx_datain;
      buffer_index = buffer_index + 1;
      if (buffer_index == 5) begin
        // dest mac found
      end

      if (buffer_index == 11) begin
        // source mac found
      end

      if (buffer_index == 13) begin
        // type/length found, also moveto payload parsing
        buffer = 0;
        buffer_index = 0;
        rx_next_state = IN_PAYLOAD;
      end
    end

    IN_PAYLOAD : begin
      if(rx_tlast) begin
        rx_next_state = IDLE;
        buffer = 0;
        buffer_index = 0;
      end else begin
        tx_dataout = rx_datain;
        buffer[buffer_index] = rx_datain;
        buffer_index = buffer_index + 1;
      end
    end

  endcase

end

endmodule

