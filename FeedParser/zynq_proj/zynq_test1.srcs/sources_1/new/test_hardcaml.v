module FDRE_test (
    en,
    rst,
    clk,
    d,
    q
);

    input en;
    input rst;
    input clk;
    input d;
    output q;

    wire _7;
    reg _8;
    assign _7 = 1'b0;
    always @(posedge clk) begin
        if (rst)
            _8 <= _7;
        else
            if (en)
                _8 <= d;
    end
    assign q = _8;

endmodule
