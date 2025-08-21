// Bohdan Purtell
// University of Florida
// Basic test modules for modports and AXI-stream interfacing

module producer_v1 #(
  parameter int WIDTH = 64
) (
  input logic clk, rst,
  AXIS_interface.sender_v1 axis_bus
);

// payload
  // byte  0   : msg_type     (8  bits)
  // bytes 1-3 : symbol_id    (24 bits)
  // bytes 4-7 : price_q16_16 (32 bits, signed fixed point)


  always_ff @(posedge clk, posedge rst)
  begin
    if (rst) begin
      axis_bus.t_valid <= 0;
      axis_bus.t_data <= 0;
      axis_bus.t_last <= 0;
      axis_bus.byte_enable <= 0;
    end else begin
      // when ready, set the bus items
      if (axis_bus.t_ready) begin
        axis_bus.t_valid <= 1;
        axis_bus.t_data <= 64'hDEADBEEF_F00DBABE;
        axis_bus.t_last <= 1;
        axis_bus.byte_enable <= 1;
      end

      // handshake?
      if (axis_bus.byte_enable && axis_bus.t_ready) begin
        axis_bus.byte_enable <= 0;
      end
    end
  end
endmodule

module consumer_v1 #(
  parameter int WIDTH = 64
) (
  input logic clk, rst,
  output logic [WIDTH - 1 : 0] out1_reg,
  AXIS_interface.receiver_v1 axis_bus
);

  // handshake process
  always_ff @(posedge clk, posedge rst)
  begin
    if (rst) begin
      axis_bus.t_ready <= 0;
    end else begin
      axis_bus.t_ready <= 1;
    end
  end
  
  always_ff @(posedge clk) 
  begin
    if (axis_bus.t_valid && axis_bus.t_ready) begin
      out1_reg <= axis_bus.t_data;
    end
  end

endmodule

