library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;
library work;

entity themashallah_exdes is
--   generic (
--        USE_ATG : integer range 0 to 1 := 0
--   );
   port (
--         clk_in1_p : in std_logic;
--         clk_in1_n : in std_logic;
         clk_100mhz : in std_logic;
--         reset : in std_logic;
--         start : in std_logic;
         rx : in std_logic;
         tx : out std_logic
--         clk_out : out std_logic;
--         lck_out : out std_logic
         
         );


end entity;

architecture impl of themashallah_exdes is

-- Pragma Added to supress synth warnings
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of impl : architecture is "yes";


--component clock_gen is
--     port (
--           clk_in1_p : in std_logic;
--           clk_in1_n : in std_logic;
--           reset    : in std_logic;
--           locked   : out std_logic;
--           clock_lite : out std_logic;
--           clock : out std_logic
--          );

--end component;

component themashallah is
  PORT (
-- System signals
      s_axi_aclk           : in  std_logic;
      s_axi_aresetn         : in  std_logic;
      interrupt             : out std_logic;

-- AXI signals
      s_axi_awaddr          : in  std_logic_vector
                              (3 downto 0);
      s_axi_awvalid         : in  std_logic;
      s_axi_awready         : out std_logic;
      s_axi_wdata           : in  std_logic_vector
                              (31 downto 0);
      s_axi_wstrb           : in  std_logic_vector
                              (3 downto 0);
      s_axi_wvalid          : in  std_logic;
      s_axi_wready          : out std_logic;
      s_axi_bresp           : out std_logic_vector(1 downto 0);
      s_axi_bvalid          : out std_logic;
      s_axi_bready          : in  std_logic;
      s_axi_araddr          : in  std_logic_vector
                              (3 downto 0);
      s_axi_arvalid         : in  std_logic;
      s_axi_arready         : out std_logic;
      s_axi_rdata           : out std_logic_vector
                              (31 downto 0);
      s_axi_rresp           : out std_logic_vector(1 downto 0);
      s_axi_rvalid          : out std_logic;
      s_axi_rready          : in  std_logic;

-- UARTLite Interface Signals
      rx                    : in  std_logic;
      tx                    : out std_logic
   );
end component;


component axi_traffic_gen_0 is 
  port (
  s_axi_aclk : in std_logic;
  s_axi_aresetn : in std_logic;
  m_axi_lite_ch1_awaddr : out std_logic_vector (31 downto 0);
  m_axi_lite_ch1_awprot : out std_logic_vector (2 downto 0);
  m_axi_lite_ch1_awvalid : out std_logic;
  m_axi_lite_ch1_awready : in std_logic;
  m_axi_lite_ch1_wdata : out std_logic_vector (31 downto 0);
  m_axi_lite_ch1_wstrb : out std_logic_vector (3 downto 0);
  m_axi_lite_ch1_wvalid : out std_logic;
  m_axi_lite_ch1_wready : in std_logic;
  m_axi_lite_ch1_bresp : in std_logic_vector (1 downto 0);
  m_axi_lite_ch1_bvalid : in std_logic;
  m_axi_lite_ch1_bready : out std_logic;
  m_axi_lite_ch1_araddr : out std_logic_vector (31 downto 0);
  m_axi_lite_ch1_arvalid : out std_logic;
  m_axi_lite_ch1_arready : in std_logic;
  m_axi_lite_ch1_rdata : in std_logic_vector (31 downto 0);
  m_axi_lite_ch1_rvalid : in std_logic;
  m_axi_lite_ch1_rready : out std_logic;
  m_axi_lite_ch1_rresp : in std_logic_vector (1 downto 0);
  done : out std_logic;
  status : out std_logic_vector (31 downto 0)
);
end component;




signal    m_axi_lite_awready          :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_awvalid          :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_awaddr           :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    m_axi_lite_wready           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_wvalid           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_wdata            :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    m_axi_lite_bready           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_bvalid           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_bresp            :  std_logic_vector(1 downto 0)      ;-- AXI4-Lite
signal    s_axi_lite_arready          :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_arvalid          :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_araddr           :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    s_axi_lite_rready           :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_rvalid           :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_rdata            :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    s_axi_lite_rresp            :  std_logic_vector(1 downto 0)      ;-- AXI4-Lite

  signal clock_lite : std_logic;
  signal clock : std_logic;
  signal locked : std_logic;
  signal reset_lock : std_logic;

---
signal awlen : std_logic_vector (7 downto 0);
signal awvalid : std_logic;
signal init_done : std_logic; 
signal counter : std_logic_vector (7 downto 0);
signal wvalid : std_logic;
---

signal pass : std_logic;
signal fail : std_logic;
signal cdma_intr : std_logic;
signal done_int : std_logic;
signal atg_done : std_logic;
signal atg_status : std_logic_vector (31 downto 0);


begin

--CLOCK_GEN_INST : clock_gen 
--         port map (
--           clk_in1_p => clk_in1_p,
--           clk_in1_n => clk_in1_n,
--           reset    => reset,
--           locked   => locked,  
--           clock_lite => clock_lite,
--           clock => clock);      

--reset_lock <= locked;
--lck_out <= locked;
--clk_out <= clock_lite;

ATG1:  axi_traffic_gen_0 
   port map (
--    s_axi_aclk         => clock_lite,
    s_axi_aclk         => clk_100mhz,
    s_axi_aresetn      => reset_lock,
    m_axi_lite_ch1_awaddr   => m_axi_lite_awaddr,
    m_axi_lite_ch1_awprot   => open,
    m_axi_lite_ch1_awvalid  => m_axi_lite_awvalid,
    m_axi_lite_ch1_awready  => m_axi_lite_awready,
    m_axi_lite_ch1_wdata    => m_axi_lite_wdata,
    m_axi_lite_ch1_wstrb    => open,
    m_axi_lite_ch1_wvalid   => m_axi_lite_wvalid,
    m_axi_lite_ch1_wready   => m_axi_lite_wready,
    m_axi_lite_ch1_bresp    => m_axi_lite_bresp,
    m_axi_lite_ch1_bvalid   => m_axi_lite_bvalid,
    m_axi_lite_ch1_bready   => m_axi_lite_bready,
    m_axi_lite_ch1_araddr   => s_axi_lite_araddr,
    m_axi_lite_ch1_arvalid  => s_axi_lite_arvalid,
    m_axi_lite_ch1_arready  => s_axi_lite_arready,
    m_axi_lite_ch1_rdata    => s_axi_lite_rdata,
    m_axi_lite_ch1_rvalid   => s_axi_lite_rvalid,
    m_axi_lite_ch1_rready   => s_axi_lite_rready,
    m_axi_lite_ch1_rresp    => s_axi_lite_rresp,
    done                    => atg_done,
    status                  => atg_status
  );

DUT : themashallah
    PORT MAP (
    interrupt     => open,       
--    s_axi_aclk       => clock_lite,
    s_axi_aclk       => clk_100mhz,
    s_axi_aresetn    => reset_lock,
    s_axi_awaddr     => m_axi_lite_awaddr (3 downto 0),
    s_axi_awvalid    => m_axi_lite_awvalid,
    s_axi_awready    => m_axi_lite_awready,
    s_axi_wdata      => m_axi_lite_wdata,
    s_axi_wstrb      => "1111",
    s_axi_wvalid     => m_axi_lite_wvalid,
    s_axi_wready     => m_axi_lite_wready,
    s_axi_bresp      => m_axi_lite_bresp,
    s_axi_bvalid     => m_axi_lite_bvalid,
    s_axi_bready     => m_axi_lite_bready,
    s_axi_araddr     => s_axi_lite_araddr (3 downto 0),
    s_axi_arvalid    => s_axi_lite_arvalid,
    s_axi_arready    => s_axi_lite_arready,
    s_axi_rdata      => s_axi_lite_rdata,
    s_axi_rresp      => s_axi_lite_rresp,
    s_axi_rvalid     => s_axi_lite_rvalid,
    s_axi_rready     => s_axi_lite_rready,
    rx               => rx,    -- these will go to board 
    tx               => tx
    );




end impl;

