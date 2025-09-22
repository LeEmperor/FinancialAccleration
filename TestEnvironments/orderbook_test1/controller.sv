// Bohdan Purtell
// University of Florida
// Controller for Orderbook

module controller # (
  parameter int packet_width = 32,
  parameter int book_count = 10
) (

  input logic clk, rst, en,
  output logic dataout,

  input logic [packet_width - 1 : 0] header,

  input logic [31:0] indata,
  input logic sop,
  input logic eop,

  output logic [book_count - 1 : 0] buyside_valid_array,
  output logic [book_count - 1 : 0] sellside_valid_array,

  output logic wren
);

typedef enum {
  idle,
  compute,
  done
} state_t;

typedef enum logic {
  buy = 0,
  sell = 1
} side_t;
state_t current_state, next_state;

logic [7:0] item_type;
logic side;
logic [15:0] ticker_id;

assign side = ((indata[20]) ? buy : sell) & (sop);

always_ff @(posedge clk)
begin
  if (rst) begin
    current_state <= idle;
  end begin
    current_state <= next_state;
  end
end

always_comb
begin
  // defaults
  buyside_valid_array = 0;
  sellside_valid_array = 0;

  // case (item_type)
  //   (8'h10) : begin // create order
  //
  //   end
  //
  //   (8'h15) : begin // remove order
  //
  //   end
  //   default : begin
  //   end
  // endcase

  case (ticker_id) 
    (16'h4141504C) : begin

    end
  endcase
end

endmodule

