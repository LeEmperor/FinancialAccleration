// Bohdan Purtell
// University of Florida
// Description: Test Source (avec Eth)

module eth_source (
  // clk and rst
  input logic clk_hifreq, rst,

  // avalon-st bus
  output logic [15:0] data_out,
  output logic valid,
  input logic ready,

  //////////// Ethernet 0 //////////
  output ENET0_GTX_CLK,
  input ENET0_INT_N,
  input ENET0_LINK100,
  output ENET0_MDC,
  inout ENET0_MDIO,
  output ENET0_RST_N,
  input ENET0_RX_CLK,
  input ENET0_RX_COL,
  input ENET0_RX_CRS,
  input [3:0] ENET0_RX_DATA,
  input ENET0_RX_DV,
  input ENET0_RX_ER,
  input ENET0_TX_CLK,
  output [3:0] ENET0_TX_DATA,
  output ENET0_TX_EN,
  output ENET0_TX_ER,
  input ENETCLK_25
);

// ethernet instantiation
ethernet_ip_folder eth1 (


);

endmodule

