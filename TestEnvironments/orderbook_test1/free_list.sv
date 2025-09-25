module free_list # (
  parameter int levels = 5, 
  parameter int slots = 8,
  parameter int level_width = $clog2(levels),
  parameter int slot_width = $clog2(slots)
) (  
  input logic clk, rst, en,

  input logic alloc_req, // me donner un neu slot
  output logic [15:0] alloc_slot_idx, // le slot qu'on donner

  input logic free_req, // on va rendre un slot (signal)
  input logic [15:0] free_slot_idx // slot de rendre 
);

  logic wire_push;
  logic wire_pop;
  logic [15:0] wire_indata;
  logic [15:0] wire_outdata;

  stack # (
    .depth(16),
    .width(5) // quand c'est 5??????????? (4 voudrait fonctionner, mais pas)
  ) main_stack (
    .clk(clk),
    .rst(rst),
    .en(en),

    .push(wire_push),
    .pop(wire_pop),

    .indata(wire_indata),
    .outdata(wire_outdata),

    .empty(),
    .full()
  );

  typedef enum {
    idle,
    preload,
    run
  } state_t;

  state_t current_state, next_state;

  logic [3:0] preload_counter;
  logic [3:0] preload_counter_next;

// reg proc
  always_ff @(posedge clk)
  begin
    if (rst) begin
      current_state <= idle;
      preload_counter <= 0;
    end else if (en) begin
      current_state <= next_state;
      preload_counter <= preload_counter_next;
    end
  end

  // next state logic
  always_comb
  begin
    // defaults
    next_state = current_state;
    preload_counter_next = preload_counter;
    wire_push = 0;
    wire_pop = 0;
    wire_indata = 0;

    unique case (current_state)
      (idle) : begin
        if (en) begin
          next_state = preload;
        end
      end

      (preload) : begin
        wire_indata = preload_counter;
        wire_push = 1;
        if (preload_counter == 4'b1111) begin
          next_state = run;
        end else begin
          preload_counter_next = preload_counter + 1;
        end
      end

      (run) : begin
        wire_indata = free_slot_idx;
        wire_pop = alloc_req;
        wire_push = free_req;
        alloc_slot_idx = wire_outdata;
      end
    endcase

  end

endmodule

