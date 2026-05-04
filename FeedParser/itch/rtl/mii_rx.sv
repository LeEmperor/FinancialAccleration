// MII RX Path
// limitation of only grabbing first 24 bytes of payload

module mii_rx #( 
  parameter int CAPTURE_BYTES = 24
) (
  input wire rx_clk,
  input wire reset,

  input wire rx_dv,
  input wire rx_er,
  input wire [3:0] rxd,

  input wire frame_ack,
  output logic frame_done,
  output logic [7:0] frame_bytes [CAPTURE_BYTES]
);

typedef enum logic [1:0] {
  IDLE,
  PREAMBLE,
  FRAME_DATA,
  DONE
} state_t;

state_t state;

logic nibble_hi;
logic [3:0] lo_nibble;
logic [$clog2(CAPTURE_BYTES) - 1 : 0] byte_idx;

always_ff @(posedge rx_clk)
begin
  if (reset) begin
  end else begin
    case (state)
      IDLE : begin
        if (rx_dv && !rx_er) begin
          state <= PREAMBLE;
        end else begin
          state <= IDLE;
        end
      end

      PREAMBLE  : begin
        if (!rx_dv || rx_er) begin
          state <= IDLE;
        end else if (rxd == 4'h0) begin
          state <= FRAME_DATA;
          nibble_hi <= 0;
          byte_idx <= 0;
        end else begin
          state <= PREAMBLE;
        end
      end

      FRAME_DATA : begin
        if (!rx_dv || rx_er) begin
          state <= IDLE;
        end else if (!nibble_hi) begin
          lo_nibble <= rxd;
          nibble_hi <= 1;
          state <= FRAME_DATA;
        end else begin
          frame_bytes[byte_idx] <= {rxd, lo_nibble};
          nibble_hi <= 0;

          if (byte_idx == CAPTURE_BYTES[$clog2(CAPTURE_BYTES) - 1 : 0] - 1) begin
            state <= DONE;
            frame_done <= 1;
          end else begin
            byte_idx <= byte_idx + 1;
            state <= FRAME_DATA;
          end
        end
      end

      DONE : begin
        if (frame_ack) begin
          frame_done <= 0;
          state <= IDLE;
        end else begin
          state <= DONE;
        end
      end
    endcase
  end
end

endmodule

