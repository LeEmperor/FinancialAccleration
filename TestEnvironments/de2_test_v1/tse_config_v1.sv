// Bohdan Purtell
// University of Florida
// Description: Il y a besoin d'un façon de configurer le MAC
// STATUS: pas functionelle

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
  ENABLE_DATAPATH,
  DISABLE_DATAPATH,
  TIMING_LIMITS,
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


logic [31:0] disable_datapath_command = 32'h0080_2220; // clear TX/RX enables in command_config
logic [31:0] mac_lower = 32'h0;
logic [15:0] mac_upper = 16'h0;
logic eth_speed = 1;


localparam int TX_ENA_pos = 0;
localparam int RX_ENA_pos = 1;
localparam int ETH_SPEED_pos = 3;
localparam int PROMIS_EN_pos = 4;


// 0x03 for mac0
//

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
      if (!reg_busy) begin
        next_state = DISABLE_DATAPATH;
      end
    end

    // 0x02 = 0x0080_2220
    DISABLE_DATAPATH : begin
      if (!reg_busy) begin
        reg_addr = 'h2;
        // reg_data_in = 'h0080_2220;
        reg_data_in = 'h0;
        reg_wr = 1;

        next_state = WRITE_MAC_LOWER;
      end
    end

    // 0x03 = 0x017231C00
    WRITE_MAC_LOWER : begin
      if (!reg_busy) begin
        // reg_addr = addr_mac_lo;
        reg_addr = 'h3;
        // reg_data_in = {data_mac[31:0]};
        reg_data_in = 'h017231C00;;
        reg_wr = 1;

        next_state = WRITE_MAC_UPPER;
      end
    end

    // 0x04 = 0x0000_CB4A
    WRITE_MAC_UPPER : begin
      if (!reg_busy) begin
        // reg_addr = addr_mac_hi;
        // reg_data_in = {16'b0, data_mac[47:32]};
        reg_addr = 'h4;
        reg_data_in = 'h0000_CB4A;
        reg_wr = 1;

        next_state = TIMING_LIMITS;
      end
    end

    // 0x05 = 1518
    TIMING_LIMITS : begin
      if (!reg_busy) begin
        reg_addr = 'h5;
        reg_data_in = 'd1518;
        reg_wr = 1;

        // next_state = WRITE_CONFIG;
        next_state = ENABLE_DATAPATH;
      end
    end

    // 0x02 = 
    WRITE_CONFIG : begin
      if (!reg_busy) begin
        // reg_addr = addr_config;
        // reg_data_in = data_config;
        reg_addr = 'h2;
        reg_data_in = 0;
        reg_wr = 1;

        next_state = ENABLE_DATAPATH;
      end
    end

    // 0x02 = $0x02 || 0b1 >> 1
    ENABLE_DATAPATH : begin
      if(!reg_busy) begin
        reg_addr = 'h2;
        reg_data_in = {{27{1'b0}}, 1'b1, 2'h00, 1'b1, 1'b0};
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

