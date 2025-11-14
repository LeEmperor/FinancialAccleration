//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.1 (lin64) Build 6140274 Wed May 21 22:58:25 MDT 2025
//Date        : Sun Oct 19 16:45:10 2025
//Host        : wayne running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target toplevel_bdf_wrapper.bd
//Design      : toplevel_bdf_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module toplevel_bdf_wrapper
   (CLK_100MHZ,
    SW,
    UART_RXD,
    UART_TXD);
  input CLK_100MHZ;
  input [15:0]SW;
  input UART_RXD;
  output UART_TXD;

  wire CLK_100MHZ;
  wire [15:0]SW;
  wire UART_RXD;
  wire UART_TXD;

  toplevel_bdf toplevel_bdf_i
       (.CLK_100MHZ(CLK_100MHZ),
        .SW(SW),
        .UART_RXD(UART_RXD),
        .UART_TXD(UART_TXD));
endmodule
