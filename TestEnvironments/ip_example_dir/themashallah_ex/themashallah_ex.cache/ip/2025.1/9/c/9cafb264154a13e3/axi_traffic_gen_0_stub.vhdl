-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.1 (lin64) Build 6140274 Wed May 21 22:58:25 MDT 2025
-- Date        : Sun Oct 19 19:04:08 2025
-- Host        : wayne running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ axi_traffic_gen_0_stub.vhdl
-- Design      : axi_traffic_gen_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7s50csga324-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    s_axi_aclk : in STD_LOGIC;
    s_axi_aresetn : in STD_LOGIC;
    m_axi_lite_ch1_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_lite_ch1_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_lite_ch1_awvalid : out STD_LOGIC;
    m_axi_lite_ch1_awready : in STD_LOGIC;
    m_axi_lite_ch1_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_lite_ch1_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_lite_ch1_wvalid : out STD_LOGIC;
    m_axi_lite_ch1_wready : in STD_LOGIC;
    m_axi_lite_ch1_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_lite_ch1_bvalid : in STD_LOGIC;
    m_axi_lite_ch1_bready : out STD_LOGIC;
    m_axi_lite_ch1_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_lite_ch1_arvalid : out STD_LOGIC;
    m_axi_lite_ch1_arready : in STD_LOGIC;
    m_axi_lite_ch1_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_lite_ch1_rvalid : in STD_LOGIC;
    m_axi_lite_ch1_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_lite_ch1_rready : out STD_LOGIC;
    done : out STD_LOGIC;
    status : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "axi_traffic_gen_0,axi_traffic_gen_v3_0_21_top,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "axi_traffic_gen_0,axi_traffic_gen_v3_0_21_top,{x_ipProduct=Vivado 2025.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=axi_traffic_gen,x_ipVersion=3.0,x_ipCoreRevision=21,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_FAMILY=spartan7,C_BASEADDR=0x00000000,C_HIGHADDR=0x0000FFFF,C_ZERO_INVALID=1,C_NO_EXCL=0,C_S_AXI_DATA_WIDTH=32,C_S_AXI_AWUSER_WIDTH=8,C_S_AXI_ARUSER_WIDTH=8,C_S_AXI_ID_WIDTH=1,C_M_AXI_THREAD_ID_WIDTH=1,C_M_AXI_DATA_WIDTH=32,C_M_AXI_ADDR_WIDTH=32,C_M_AXI_AWUSER_WIDTH=8,C_M_AXI_ARUSER_WIDTH=8,C_AXIS1_HAS_TKEEP=1,C_AXIS1_HAS_TSTRB=1,C_AXIS2_HAS_TKEEP=0,C_AXIS2_HAS_TSTRB=0,C_AXIS_TDATA_WIDTH=32,C_AXIS_TUSER_WIDTH=8,C_AXIS_TID_WIDTH=8,C_AXIS_TDEST_WIDTH=8,C_ATG_BASIC_AXI4=0,C_ATG_REPEAT_TYPE=0,C_ATG_HLTP_MODE=0,C_ATG_STATIC=0,C_ATG_SYSTEM_INIT=0,C_ATG_SYSTEM_TEST=1,C_ATG_STREAMING=0,C_ATG_STREAMING_MST_ONLY=1,C_ATG_STREAMING_MST_LPBK=0,C_ATG_STREAMING_SLV_LPBK=0,C_ATG_STREAMING_MAX_LEN_BITS=16,C_ATG_STREAMING_MEM_FILE=no_mem_file_loaded,C_ATG_AXIS_DATA_GEN_TYPE=0,C_AXIS_SPARSE_EN=1,C_ATG_SLAVE_ONLY=0,C_ATG_STATIC_WR_ADDRESS=0x0000000012A00000,C_ATG_STATIC_RD_ADDRESS=0x0000000013A00000,C_ATG_STATIC_WR_HIGH_ADDRESS=0x0000000012A00FFF,C_ATG_STATIC_RD_HIGH_ADDRESS=0x0000000013A00FFF,C_ATG_STATIC_INCR=0,C_ATG_STATIC_EN_READ=1,C_ATG_STATIC_EN_WRITE=1,C_ATG_STATIC_FREE_RUN=1,C_ATG_STATIC_RD_PIPELINE=3,C_ATG_STATIC_WR_PIPELINE=3,C_ATG_STATIC_TRANGAP=0,C_ATG_STATIC_LENGTH=16,C_ATG_SYSTEM_INIT_DATA_MIF=axi_traffic_gen_0_data.mem,C_ATG_SYSTEM_INIT_ADDR_MIF=axi_traffic_gen_0_addr.mem,C_ATG_SYSTEM_INIT_CTRL_MIF=axi_traffic_gen_0_ctrl.mem,C_ATG_SYSTEM_INIT_MASK_MIF=axi_traffic_gen_0_mask.mem,C_ATG_MIF_DATA_DEPTH=16,C_ATG_MIF_ADDR_BITS=4,C_ATG_SYSTEM_CMD_MAX_RETRY=2147483647,C_ATG_SYSTEM_TEST_MAX_CLKS=2147483647,C_ATG_SYSTEM_MAX_CHANNELS=1,C_ATG_SYSTEM_CH1_LOW=0x00000000,C_ATG_SYSTEM_CH1_HIGH=0xFFFFFFFF,C_ATG_SYSTEM_CH2_LOW=0x00000100,C_ATG_SYSTEM_CH2_HIGH=0x000001FF,C_ATG_SYSTEM_CH3_LOW=0x00000200,C_ATG_SYSTEM_CH3_HIGH=0x000002FF,C_ATG_SYSTEM_CH4_LOW=0x00000300,C_ATG_SYSTEM_CH4_HIGH=0x000003FF,C_ATG_SYSTEM_CH5_LOW=0x00000400,C_ATG_SYSTEM_CH5_HIGH=0x000004FF,C_RAMINIT_CMDRAM0_F=axi_traffic_gen_0_default_cmdram.mem,C_RAMINIT_CMDRAM1_F=NONE,C_RAMINIT_CMDRAM2_F=NONE,C_RAMINIT_CMDRAM3_F=NONE,C_RAMINIT_SRAM0_F=axi_traffic_gen_0_default_mstram.mem,C_RAMINIT_PARAMRAM0_F=axi_traffic_gen_0_default_prmram.mem,C_RAMINIT_ADDRRAM0_F=axi_traffic_gen_0_default_addrram.mem,C_REPEAT_COUNT=254,C_STRM_DATA_SEED=0xABCD,C_AXI_WR_ADDR_SEED=0x7C9B,C_AXI_RD_ADDR_SEED=0x5A5A,C_READ_ONLY=0,C_WRITE_ONLY=0,ATG_VERSAL_400=0}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "yes";
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "s_axi_aclk,s_axi_aresetn,m_axi_lite_ch1_awaddr[31:0],m_axi_lite_ch1_awprot[2:0],m_axi_lite_ch1_awvalid,m_axi_lite_ch1_awready,m_axi_lite_ch1_wdata[31:0],m_axi_lite_ch1_wstrb[3:0],m_axi_lite_ch1_wvalid,m_axi_lite_ch1_wready,m_axi_lite_ch1_bresp[1:0],m_axi_lite_ch1_bvalid,m_axi_lite_ch1_bready,m_axi_lite_ch1_araddr[31:0],m_axi_lite_ch1_arvalid,m_axi_lite_ch1_arready,m_axi_lite_ch1_rdata[31:0],m_axi_lite_ch1_rvalid,m_axi_lite_ch1_rresp[1:0],m_axi_lite_ch1_rready,done,status[31:0]";
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of s_axi_aclk : signal is "xilinx.com:signal:clock:1.0 clock CLK";
  attribute X_INTERFACE_MODE : string;
  attribute X_INTERFACE_MODE of s_axi_aclk : signal is "slave";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of s_axi_aclk : signal is "XIL_INTERFACENAME clock, ASSOCIATED_BUSIF S_AXI:M_AXI:M_AXIS_MASTER:S_AXIS_MASTER:M_AXIS_SLAVE:S_AXIS_SLAVE:M_AXI_LITE_CH1:M_AXI_LITE_CH2:M_AXI_LITE_CH3:M_AXI_LITE_CH4:M_AXI_LITE_CH5, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s_axi_aresetn : signal is "xilinx.com:signal:reset:1.0 reset RST";
  attribute X_INTERFACE_MODE of s_axi_aresetn : signal is "slave";
  attribute X_INTERFACE_PARAMETER of s_axi_aresetn : signal is "XIL_INTERFACENAME reset, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_awaddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 AWADDR";
  attribute X_INTERFACE_MODE of m_axi_lite_ch1_awaddr : signal is "master";
  attribute X_INTERFACE_PARAMETER of m_axi_lite_ch1_awaddr : signal is "XIL_INTERFACENAME M_AXI_LITE_CH1, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 100000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_awprot : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 AWPROT";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_awvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 AWVALID";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_awready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 AWREADY";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_wdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 WDATA";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_wstrb : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 WSTRB";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_wvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 WVALID";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_wready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 WREADY";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_bresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 BRESP";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_bvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 BVALID";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_bready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 BREADY";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_araddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 ARADDR";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_arvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 ARVALID";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_arready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 ARREADY";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_rdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 RDATA";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_rvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 RVALID";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_rresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 RRESP";
  attribute X_INTERFACE_INFO of m_axi_lite_ch1_rready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE_CH1 RREADY";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "axi_traffic_gen_v3_0_21_top,Vivado 2025.1";
begin
end;
