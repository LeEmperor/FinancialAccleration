// Bohdan Purtell
// University of Florida
// Eth0 ISE Config

module eth0_config (

  input logic clk_hifreq,
  input logic rst,

  input logic busy,
  output logic [7:0] reg_addr,
  output logic [31:0] data_out,
  output logic wren
);

typedef enum {
  IDLE,
  WAITING,

  // command_config reg 0x02
  DISABLE,

  // 0x03 & 4
  MAC1,
  MAC2,

  // command_config reg 0x02
  PROMIS_EN,
  PADDING_EN, // remover le padding des frames reçus

  ENABLE,
  DONE

} state_t;
state_t current_state, next_state;

logic [31:0] maclower = {32'h17231C00};
logic [31:0] mac_upper = {32'hCB4A};

logic clk_half;

clk_div2 clkhalf (
  .clk50(clk_hifreq),
  .clk1(),
  .rst(rst),
  .pulse(clk_half)
);

// reg proc
always_ff @(posedge clk_half)
begin
  if (rst) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

// next_state logic
always_comb
begin
  // default
  next_state = current_state;
  data_out = 0;

  unique case (current_state)
    IDLE : begin
      if (!busy) begin
        next_state = WAITING;
      end
    end

    WAITING : begin
      if (!busy) begin
        next_state = DISABLE;
      end
    end

    DISABLE : begin
      if (!busy) begin
        data_out = data_out || {0 << 32};
        data_out = data_out || {0 << 31};

        next_state = MAC1;
      end
    end

    MAC1 : begin
      if (!busy) begin
        data_out = MAC1;
        next_state = MAC2;
      end
    end

    MAC2 : begin
      if (!busy) begin
        data_out = MAC2;
        next_state = ENABLE;
      end
    end

    ENABLE : begin
      if (!busy) begin
        data_out = {1 << 32} || {1 << 31};
        next_state = DONE;
      end
    end

    DONE : begin
    end

  endcase
end

endmodule

