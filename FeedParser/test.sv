module struct_pipeline_test (
  input logic clk, rst,

  input logic [63:0] data_bus,

  output logic a
);

typedef struct packed {
  logic data1;
  logic data2;
  logic data3;
  logic data4;

  // logic [31:0] funky_line;
} pipeline_state_t;

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

typedef enum {
  DEFAULT,

  READING_BIT1,
  READING_BIT2,
  READING_BIT3,
  READING_BIT4,

  READING_BIT5,
  READING_BIT6,
  READING_BIT7,
  READING_BIT8,

  READING_BIT9,
  READING_BIT10,
  READING_BIT11,
  READING_BIT12,

  READING_BIT13,
  READING_BIT14,
  READING_BIT15,
  READING_BIT16,

  DONE,

  BRUH
} parser_state_t;

parser_state_t current_state;
parser_state_t next_state;

// pipeline advancedment
always_ff @(posedge clk)
begin
  if (rst) begin
    stage1 <= 0;
    stage2 <= 0;
    stage3 <= 0;
    stage4 <= 0;
    counter_offset <= 0;
    current_state <= DEFAULT;
  end else begin
    stage1 <= stage1_next;
    stage2 <= stage2_next;
    stage3 <= stage3_next;
    stage4 <= stage4_next;
    counter_offset <= counter_offset_next;
    current_state <= next_state;
  end
end


function automatic void parse_bit (
  input logic in_bit,
  inout parser_state_t pstate,

  inout logic debug_flag1,
  inout logic debug_flag2,
  inout logic debug_flag3
);


  case(pstate) 
    DEFAULT : begin  
      pstate = (in_bit) ? READING_BIT1 : DEFAULT;
      $display("default state read");
    end

    READING_BIT1 : pstate = (in_bit) ? READING_BIT2 : DEFAULT;
    READING_BIT2 : pstate = (in_bit) ? READING_BIT3 : DEFAULT;
    READING_BIT3 : begin
      pstate = (in_bit) ? READING_BIT4 : DEFAULT;
      debug_flag1 = 1;
    end
    READING_BIT4 : pstate = (in_bit) ? READING_BIT5 : DEFAULT;
    READING_BIT5 : pstate = (in_bit) ? READING_BIT6 : DEFAULT;
    READING_BIT6 : pstate = (in_bit) ? READING_BIT7 : DEFAULT;
    READING_BIT7 : pstate = (in_bit) ? READING_BIT8 : DEFAULT;
    READING_BIT8 : pstate = (in_bit) ? READING_BIT9 : DEFAULT;
    READING_BIT9 : pstate = (in_bit) ? READING_BIT10 : DEFAULT;
    READING_BIT10 : pstate = (in_bit) ? READING_BIT11 : DEFAULT;
    READING_BIT11 : pstate = (in_bit) ? READING_BIT12 : DEFAULT;
    READING_BIT12 : pstate = (in_bit) ? READING_BIT13 : DEFAULT;

    READING_BIT13 : begin 
      pstate = (in_bit) ? READING_BIT14 : DEFAULT;
      debug_flag3 = 1;
    end

    READING_BIT14 : pstate = (in_bit) ? READING_BIT15 : DEFAULT;

    READING_BIT15 : begin 
      pstate = (in_bit) ? READING_BIT16 : DEFAULT;
      debug_flag2 = 1;
    end

    READING_BIT16 : pstate = (in_bit) ? DONE : DEFAULT;

    default : begin // seul pour DONE
      debug_flag1 = 1;
      pstate = DEFAULT;
    end
  endcase

endfunction

logic debug1;
logic debug2;
logic debug3;

// logic [7:0] data_wire1;
// logic [7:0] data_wire2;
// logic [7:0] data_wire2;

// next state logic
always_comb
begin
  stage2_next = stage1;
  stage3_next = stage2;
  stage4_next = stage3;
  stage1_next = 0;
  debug1 = 0;
  debug2 = 0;
  debug3 = 0;

  for(int i = counter_offset; i < counter_offset + 4; i++) begin
    $display("using bit: %0d", i);
    $display("counter offset: %0d", counter_offset);
    parse_bit(
      data_bus[i],
      next_state,
      debug1,
      debug2,
      debug3
    );

    if (counter_offset >= 16) begin
      counter_offset_next = 0;
    end else begin
      counter_offset_next = counter_offset + 4;
    end
  end

  stage1_next.data1 = debug1;
  stage1_next.data2 = debug2;
  stage1_next.data3 = debug3;

end

endmodule

