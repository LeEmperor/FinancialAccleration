module uart_tx #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD_RATE   = 115200
) (
    input  logic       clk,
    input  logic       rst,

    input  logic [7:0] tx_data,
    input  logic       tx_valid,   // pulse high for 1 cycle when tx_data is valid
    output logic       tx_ready,   // high when ready to accept a new byte

    output logic       tx_serial,  // UART TX line
    output logic       tx_busy     // high while transmitting
);

    localparam int CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
    localparam int CTR_W        = (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [CTR_W-1:0] clk_count;
    logic [2:0]       bit_index;
    logic [7:0]       data_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= '0;
            bit_index <= '0;
            data_reg  <= '0;
            tx_serial <= 1'b1;
            tx_busy   <= 1'b0;
            tx_ready  <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_ready  <= 1'b1;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (tx_valid) begin
                        data_reg  <= tx_data;
                        tx_busy   <= 1'b1;
                        tx_ready  <= 1'b0;
                        state     <= START_BIT;
                    end
                end

                START_BIT: begin
                    tx_serial <= 1'b0; // start bit

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state     <= DATA_BITS;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    tx_serial <= data_reg[bit_index];

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state     <= STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    tx_serial <= 1'b1; // stop bit

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
