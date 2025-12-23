// Bohdan Purtell
// University of Florida
// Testing Pipelining of the Parser

import types_pkg::*;
import parser_pkg::*;

module struct_pipeline_test (
  input logic clk, rst,
  input logic [511:0] data_bus,
  output logic a
);

pipeline_state_t stage1;
pipeline_state_t stage2;
pipeline_state_t stage3;
pipeline_state_t stage4;

pipeline_state_t stage1_next;
pipeline_state_t stage2_next;
pipeline_state_t stage3_next;
pipeline_state_t stage4_next;

logic [3:0] counter_offset;
logic [3:0] counter_offset_next;

// pipeline advancedment
always_ff @(posedge clk)
begin
  if (rst) begin
    stage1 <= 0;
    stage2 <= 0;
    stage3 <= 0;
    stage4 <= 0;
    counter_offset <= 0;
  end else begin
    stage1 <= stage1_next;
    stage2 <= stage2_next;
    stage3 <= stage3_next;
    stage4 <= stage4_next;
    counter_offset <= counter_offset_next;
  end
end

// byte array
byte unsigned bytes [0:63];

always_comb
begin
  for (int i = 0; i < 64; i++) begin
    bytes[i] = data_bus[i * 8 +: 8];
  end
end

event_t event_buf [10];
event_t new_event;

// next state logic
always_comb
begin
  stage2_next = stage1;
  stage3_next = stage2;
  stage4_next = stage3;
  stage1_next = 0;

  for(int i = counter_offset; i < counter_offset + 4; i++) begin
    $display("counter offset: %0d", counter_offset);

    parse_byte(
      bytes[i],
      stage1_next,
      event_buf,
      new_event
    );

    if (counter_offset >= 16) begin
      counter_offset_next = 0;
    end else begin
      counter_offset_next = counter_offset + 4;
    end
  end
end

endmodule

