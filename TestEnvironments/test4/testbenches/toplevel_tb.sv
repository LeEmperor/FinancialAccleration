// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module toplevel_tb();

    // control
  logic t_clk;
  logic t_rst;
  logic clk_en;

  // monitor
  wire [15:0] t_leds_red;
  wire [7:0] t_leds_green;

  // probe
  logic t_datain;
  logic t_en;
  logic [17:0] t_switches;

  // dut
  toplevel_test4 dut (
    // Clocks
    .CLOCK_50   (t_clk),
    .CLOCK2_50  (),
    .CLOCK3_50  (),

    // LEDs
    .LEDG       (t_leds_green),
    .LEDR       (t_leds_red),

    // Keys / Switches
    .KEY        (),
    .SW         (t_switches[17:0]),

    // Seven-seg
    .HEX0       (),
    .HEX1       (),
    .HEX2       (),
    .HEX3       (),
    .HEX4       (),
    .HEX5       (),
    .HEX6       (),
    .HEX7       ()
  );
  initial begin : CLK_GEN
      t_clk = 0;
      forever #5 t_clk = ~t_clk & clk_en;
  end

  initial
      begin
        // preload memory
        // $readmemh();

          // populate test vectors
          t_switches = 0;
          clk_en = 1;
          #10

          t_switches[17] = 1;
          #10

          t_switches[17] = 0;
          #10

          #500

          clk_en = 0;
          disable CLK_GEN;

      end
endmodule

