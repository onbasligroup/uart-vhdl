
-- ===============================================================================================
-- (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
-- All rights reserved.
-- ===============================================================================================
-- Creator: bugra
-- ===============================================================================================
-- Project           : uart-vhdl
-- File ID           : uart_rx
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

entity uart_rx is
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
end entity;

architecture arch of uart_rx is
  constant count_num : integer := CLK_FREQ/BAUD_RATE;

  type rx_state_type is (idle, startbit, databits, paritybit, stopbit);
  signal rx_state : rx_state_type;

  type rd_rq_state_type is (idle, start_to_count, create_pulse);
  signal rd_rq_state : rd_rq_state_type;

  signal sampling_sync : std_logic;
  signal sampling_counter : std_logic_vector(31 downto 0);
  signal rd_rq : std_logic;

begin

  -- Sampling process
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      rx_state <= idle;
    elsif(i_clk'event and i_clk = '1') then
      case( rx_state ) is
        when idle =>
          if(i_rx = '0') then
            sampling_sync <= '1';
            rx_state <= startbit;
          else
            sampling_sync <= '0';
            rx_state <= idle;
          end if;
        when startbit =>
          sampling_sync <= '0';
        when databits =>
        when paritybit =>
        when stopbit =>
        when others =>

      end case;
    end if;
  end process;

  -- Create read request
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      rd_rq <= '1';
    elsif(i_clk'event and i_clk = '1') then
      if(sampling_sync = '1') then
        sampling_counter <= (others => '0');
      else
        if(sampling_counter = std_logic_vector(to_unsigned(count_num,sampling_counter'length))) then
          rd_rq <= '1';
          sampling_counter <= (others => '0');
        else
          rd_rq <= '0';
          sampling_counter <= std_logic_vector(unsigned(sampling_counter) + 1);
        end if;
      end if;
    end if;
  end process;

  -- -- Create read request with sampling delta
  -- process(i_clk, i_rst)
  -- begin
  --   if(i_rst = '1') then
  --   elsif(i_clk'event and i_clk = '1') then
  --
  --   end if;
  -- end process;
end architecture;
