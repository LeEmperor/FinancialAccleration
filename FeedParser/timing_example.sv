module timing_example (
    input  wire        clk,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    // Input register
    reg [7:0] r0;

    // Some combinational mess between r0 and dout
    wire [7:0] t0, t1, t2, t3;

    assign t0 = ~r0;                    // invert
    assign t1 = t0 ^ 8'hA5;             // xor with constant
    assign t2 = {t1[6:0], t1[7]} + 8'h3C; // rotate + add constant
    assign t3 = {t2[0], t2[7:1]};       // another rotate

    // Output register
    always @(posedge clk) begin
        r0   <= din;
        dout <= t3;
    end

endmodule

