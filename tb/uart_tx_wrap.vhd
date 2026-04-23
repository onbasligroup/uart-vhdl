library ieee;
use ieee.std_logic_1164.all;

entity uart_tx_wrap is
  generic (
    G_CLK_FREQ  : integer := 1000000;
    G_BAUD_RATE : integer := 10000
  );
  port (
    i_clk   : in  std_logic;
    i_rst   : in  std_logic;
    i_data  : in  std_logic_vector(7 downto 0);
    i_valid : in  std_logic;
    o_tx    : out std_logic;
    o_busy  : out std_logic
  );
end entity;

architecture rtl of uart_tx_wrap is
begin
  u_tx: entity work.uart_tx
    generic map (
      CLK_FREQ   => G_CLK_FREQ,
      BAUD_RATE  => G_BAUD_RATE,
      PARITY_BIT => "none"
    )
    port map (
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_data,
      i_valid => i_valid,
      o_tx    => o_tx,
      o_busy  => o_busy
    );
end architecture;
