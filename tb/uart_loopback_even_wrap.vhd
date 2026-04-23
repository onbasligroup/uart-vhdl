library ieee;
use ieee.std_logic_1164.all;

entity uart_loopback_even_wrap is
  generic (
    G_CLK_FREQ  : integer := 1000000;
    G_BAUD_RATE : integer := 10000
  );
  port (
    i_clk      : in  std_logic;
    i_rst      : in  std_logic;
    i_data     : in  std_logic_vector(7 downto 0);
    i_valid    : in  std_logic;
    o_tx       : out std_logic;
    o_tx_busy  : out std_logic;
    o_rx_data  : out std_logic_vector(7 downto 0);
    o_rx_valid : out std_logic;
    o_rx_busy  : out std_logic
  );
end entity;

architecture rtl of uart_loopback_even_wrap is
  signal tx_line : std_logic;
begin
  u_tx: entity work.uart_tx
    generic map (
      CLK_FREQ   => G_CLK_FREQ,
      BAUD_RATE  => G_BAUD_RATE,
      PARITY_BIT => "even"
    )
    port map (
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_data,
      i_valid => i_valid,
      o_tx    => tx_line,
      o_busy  => o_tx_busy
    );

  u_rx: entity work.uart_rx
    generic map (
      CLK_FREQ   => G_CLK_FREQ,
      BAUD_RATE  => G_BAUD_RATE,
      PARITY_BIT => "even"
    )
    port map (
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_rx    => tx_line,
      o_data  => o_rx_data,
      o_valid => o_rx_valid,
      o_busy  => o_rx_busy
    );

  o_tx <= tx_line;
end architecture;
