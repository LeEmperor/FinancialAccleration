// Bohdan Purtell
// University of Florida
// Description: Il y a besoin d'un façon de configurer le MAC

module tse_config_v1 # (
  parameter int WIDTH = 64
) (
  // ctrl
  input logic clk, rst,

  // aux control de eth MAC
  input logic [31:0] reg_data_out,  // MAC -> control
  input logic reg_busy,      // MAC -> control

  output logic [31:0] reg_data_in, // control-data      -> MAC
  output logic [7:0] reg_addr,     // control-addr      -> MAC
  output logic reg_rd,       // control-read_en   -> MAC
  output logic reg_wr,        // control-wrrite_en -> MAC

  // mac et le configuration pour ça
  input logic [47:0] data_mac, // le mac adresse
  input logic [7:0] addr_mac_lo, // l'adresse de mac (sous)
  input logic [7:0] addr_mac_hi, // l'adresse de mac (ciel)

  // configuration pour le MAC mode
  input logic [7:0] addr_config, // l'adresse de config regs
  input logic [31:0] data_config // le data pour config
);

typedef enum {
  IDLE,
  WRITE_MAC_UPPER,
  WRITE_MAC_LOWER,
  WRITE_CONFIG,
  WAIT,
  DONE
} state_t;

state_t current_state, next_state;

// reg proc
always_ff @(posedge clk)
begin
  if (rst) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end


// next state mealy
always_comb
begin
  // defaults
  reg_data_in = 0;
  reg_addr = 0;
  reg_rd = 0;
  reg_wr = 0;
  next_state = current_state;

  unique case (current_state)
    IDLE : begin

    end

    WRITE_MAC_LOWER : begin
      if (!reg_busy) begin
        reg_addr = addr_mac_lo;
        reg_data_in = {data_mac[31:0]};
        reg_wr = 1;

        next_state = WRITE_MAC_UPPER;
      end
    end

    WRITE_MAC_UPPER : begin
      if (!reg_busy) begin
        reg_addr = addr_mac_hi;
        reg_data_in = {16'b0, data_mac[47:32]};
        reg_wr = 1;

        next_state = WRITE_CONFIG;
      end
    end

    WRITE_CONFIG : begin
      if (!reg_busy) begin
        reg_addr = addr_config;
        reg_data_in = data_config;
        reg_wr = 1;

        next_state = WAIT;
      end
    end

    WAIT : begin
      if (!reg_busy) begin
        next_state = DONE;
      end
    end

    DONE : begin

    end

  endcase
end

endmodule

