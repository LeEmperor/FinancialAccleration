module fsm_test (
    rst,
    clk,
    go,
    done
);

    input rst;
    input clk;
    input go;
    output done;

    wire gnd;
    wire vdd;
    wire [1:0] _8;
    wire [1:0] _19;
    wire [1:0] _15;
    wire _16;
    wire [1:0] _17;
    wire [1:0] _13;
    wire _14;
    wire [1:0] _18;
    wire _12;
    wire [1:0] _20;
    wire [1:0] _4;
    reg [1:0] _10;
    wire _21;
    wire _23;
    wire _5;
    assign gnd = 1'b0;
    assign vdd = 1'b1;
    assign _8 = 2'b00;
    assign _19 = go ? _13 : _10;
    assign _15 = 2'b10;
    assign _16 = _10 == _15;
    assign _17 = _16 ? _8 : _10;
    assign _13 = 2'b01;
    assign _14 = _10 == _13;
    assign _18 = _14 ? _15 : _17;
    assign _12 = _10 == _8;
    assign _20 = _12 ? _19 : _18;
    assign _4 = _20;
    always @(posedge clk) begin
        if (rst)
            _10 <= _8;
        else
            _10 <= _4;
    end
    assign _21 = _10 == _15;
    assign _23 = _21 ? vdd : gnd;
    assign _5 = _23;
    assign done = _5;

endmodule