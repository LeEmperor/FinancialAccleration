// Bohdan Purtell
// University of Florida

module controller (
  input logic clk_1,
  input logic clk_half,
  input logic clk_hifreq,
  input logic rst,
  input logic en,

  input logic rdy,
  output logic sop,
  output logic eop,
  output logic wren,
  output logic reg_wren,

  output logic rd_en
);

typedef enum {
  idle,
  write1,
  write2
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk_hifreq)
begin
  if (rst) begin
    current_state <= idle;
  end else begin
    if (en) begin
      current_state <= next_state;
    end
  end
end

always_comb
begin
  // defaults
  next_state = current_state;
  sop = 0;
  eop = 0;
  rd_en = 0;
  wren = 0;

  case (current_state) 
    idle : begin
      next_state = write1;
    end

    write1 : begin
      if (rdy) begin
        sop = 1;
        eop = 1;
        rd_en = 1;
        wren = 1;
      end

      next_state = write2;
    end

    write2 : begin
      next_state = idle;
    end

    default : begin
      // lmao
    end
  endcase;

end

endmodule


