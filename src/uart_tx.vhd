
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

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
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
end entity;

architecture arch of uart_tx is
  constant count_num : integer := CLK_FREQ/BAUD_RATE;
  signal sampling_counter : std_logic_vector(31 downto 0);
  signal send_rq : std_logic;

  type tx_state_type is (idle, sync, startbit, databits, paritybit, stopbit);
  signal tx_state : tx_state_type;

  signal tx_reg : std_logic_vector(7 downto 0);

  signal bit_counter : integer range 0 to 7;
begin

  -- Transmitter
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      tx_state <= idle;
      bit_counter <= 0;
      o_tx <= '1';
    elsif(i_clk = '1' and i_clk'event) then
      case( tx_state ) is
        when idle =>
          if(i_valid = '1') then
            tx_reg <= i_data;
            tx_state <= sync;
          end if;
          o_tx <= '1';
        when sync =>
          if(send_rq = '1') then
            tx_state <= startbit;
          end if;
          o_tx <= '1';
        when startbit =>
          bit_counter <= 0;
          if(send_rq = '1') then
            tx_state <= databits;
          end if;
          o_tx <= '0';
        when databits =>
          if(send_rq = '1' and bit_counter /= 7) then
            bit_counter <= bit_counter + 1;
          elsif(send_rq = '1' and bit_counter = 7) then
            bit_counter <= 0;
            tx_state <= stopbit;
          end if;
          case( bit_counter ) is
            when 0 => o_tx <= tx_reg(0);
            when 1 => o_tx <= tx_reg(1);
            when 2 => o_tx <= tx_reg(2);
            when 3 => o_tx <= tx_reg(3);
            when 4 => o_tx <= tx_reg(4);
            when 5 => o_tx <= tx_reg(5);
            when 6 => o_tx <= tx_reg(6);
            when 7 => o_tx <= tx_reg(7);
            when others =>
          end case;
        when paritybit => tx_state <= idle;
        when stopbit =>
          if(send_rq = '1') then
            tx_state <= idle;
          end if;
          o_tx <= '1';
        when others => o_tx <= '1';
      end case;
    end if;
  end process;

  -- Create read request
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      send_rq <= '1';
      sampling_counter <= (others => '0');
    elsif(i_clk'event and i_clk = '1') then
      if(sampling_counter = std_logic_vector(to_unsigned(count_num,sampling_counter'length))) then
        send_rq <= '1';
        sampling_counter <= (others => '0');
      else
        send_rq <= '0';
        sampling_counter <= std_logic_vector(unsigned(sampling_counter) + 1);
      end if;
    end if;
  end process;

end architecture;
