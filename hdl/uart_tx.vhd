
-- ===============================================================================================
-- (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
-- All rights reserved.
-- ===============================================================================================
-- Creator: bugra
-- ===============================================================================================
-- Project           : uart-vhdl
-- File ID           : uart_tx
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

entity uart_tx is
  generic(
    PARITY_BIT : string := "none" -- valid for "none", "even", "odd"
  );
  port (
    i_clk   : std_logic;
    i_rst   : std_logic;
    i_data  : std_logic_vector(7 downto 0);
    i_valid : std_logic;
    o_busy  : std_logic;
    o_tx    : std_logic
  );
end entity;

architecture arch of uart_tx is

begin

end architecture;
