library ieee;
use ieee.std_logic_1164.all;

entity uart_rx_odd_wrap is
  generic (
    G_CLK_FREQ  : integer := 1000000;
    G_BAUD_RATE : integer := 10000
  );
  port (
    i_clk   : in  std_logic;
    i_rst   : in  std_logic;
    i_rx    : in  std_logic;
    o_data  : out std_logic_vector(7 downto 0);
    o_valid : out std_logic;
    o_busy  : out std_logic
  );
end entity;

architecture rtl of uart_rx_odd_wrap is
begin
  u_rx: entity work.uart_rx
    generic map (
      CLK_FREQ   => G_CLK_FREQ,
      BAUD_RATE  => G_BAUD_RATE,
      PARITY_BIT => "odd"
    )
    port map (
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_rx    => i_rx,
      o_data  => o_data,
      o_valid => o_valid,
      o_busy  => o_busy
    );
end architecture;
