
-- ===============================================================================================
-- (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
-- All rights reserved.
-- ===============================================================================================
-- Creator: bugra
-- ===============================================================================================
-- Project           : uart-vhdl
-- File ID           : uart_tb
-- Design Unit Name  :
-- Description       : Testbench for both uart_rx and uart_tx modules
-- Comments          :
-- Revision          : %%
-- Last Changed Date : %%
-- Last Changed By   : %%
-- Designer
--          Name     : Bugra Tufan
--          E-mail   : btufan21@ku.edu.tr
-- ===============================================================================================

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.golden_uart_comp.all;
use work.uart_rx_comp.all;

entity uart_tb is
end entity;

architecture arch of uart_tb is
  signal clk   : std_logic;
  signal rst_n : std_logic;
  signal rst   : std_logic;

  signal golden_uart_txd : std_logic;
begin

  -- Create 100 MHz clock
  process
  begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;

  -- Create active-low reset signal for 100 ns
  process
  begin
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait;
  end process;

  rst <= not rst_n;
  golden : golden_uart generic map(
      CLK_FREQ    => 100e6,   -- set system clock frequency in Hz
      BAUD_RATE   => 115200   -- baud rate value
  )
  port map (
      CLK      => clk,
      RST_N    => rst_n,
      -- UART INTERFACE
      UART_TXD => golden_uart_txd,
      UART_RXD => '1',
      -- USER DATA INPUT INTERFACE
      DATA_IN     => "01010101",
      DATA_SEND   => '1'
  );


  uart_rx_inst : uart_rx port map(
    i_clk   => clk,
    i_rst   => rst,
    i_rx    => golden_uart_txd
  );

end architecture;
