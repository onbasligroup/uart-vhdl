
-- ===============================================================================================
-- (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
-- All rights reserved.
-- ===============================================================================================
-- Creator: bugra
-- ===============================================================================================
-- Project           : uart-vhdl
-- File ID           : uart_tx_comp
-- Design Unit Name  :
-- Description       :
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

package uart_tx_comp is
    component uart_tx is
      generic(
        CLK_FREQ    : integer := 100e6;  -- set system clock frequency in Hz
        BAUD_RATE   : integer := 115200; -- baud rate value
        PARITY_BIT  : string  := "none"  -- valid for "none", "even", "odd"
      );
      port (
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_data  : in std_logic_vector(7 downto 0);
        i_valid : in std_logic;
        o_tx    : out std_logic;
        o_busy  : out std_logic
      );
    end component;
end package;
