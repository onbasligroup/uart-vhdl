
-- ===============================================================================================
-- (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
-- All rights reserved.
-- ===============================================================================================
-- Creator: bugra
-- ===============================================================================================
-- Project           : uart-vhdl
-- File ID           : uart_rx_comp
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

package uart_rx_comp is
    component uart_rx is
      generic(
        CLK_FREQ    : integer := 100e6;  -- set system clock frequency in Hz
        BAUD_RATE   : integer := 115200; -- baud rate value
        PARITY_BIT  : string  := "none"  -- valid for "none" for now. It is under development.
      );
      port (
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_rx    : in std_logic;
        o_data  : out std_logic_vector(7 downto 0);
        o_valid : out std_logic;
        o_busy  : out std_logic
      );
    end component;
end package;
