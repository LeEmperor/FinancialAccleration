// Bohdan Purtell UF Astera Labs Interview

`timescale 1 ns / 1 ps

import uvm_pkg::*;
import mux_tb_pkg::*;

module top();

  logic clk = 0;
  always #10 clk = ~clk;

  mux_if vif(clk);
  mux2 dut (
    .a(vif.a),
    .b(vif.b),
    .out(vif.out),
    .sel(vif.sel()
  );

  initial begin
    uvm_config_db#(virtual mux_if)::set(null, "uvm_test_top env agent", "vif", vif);

    run_test("mux test");
  end

endmodule

