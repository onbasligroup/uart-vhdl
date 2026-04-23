
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
  constant baud_last : integer := count_num - 1;

  function xor_reduce(data : std_logic_vector(7 downto 0)) return std_logic is
    variable tmp : std_logic := '0';
  begin
    for i in data'range loop
      tmp := tmp xor data(i);
    end loop;
    return tmp;
  end function;

  function parity_enabled(mode : string) return boolean is
  begin
    return (mode = "even") or (mode = "odd") or (mode = "EVEN") or (mode = "ODD");
  end function;

  function parity_bit_of(data : std_logic_vector(7 downto 0); mode : string) return std_logic is
    variable p : std_logic := xor_reduce(data);
  begin
    if (mode = "odd") or (mode = "ODD") then
      return not p;
    end if;
    return p;
  end function;

  signal baud_counter : integer range 0 to baud_last;

  type tx_state_type is (idle, sync, startbit, databits, paritybit, stopbit);
  signal tx_state : tx_state_type;

  signal tx_reg : std_logic_vector(7 downto 0);
  signal parity_reg : std_logic;

  signal bit_counter : integer range 0 to 7;
begin

  -- Transmitter
  process(i_clk, i_rst)
    variable baud_tick : boolean;
  begin
    if(i_rst = '1') then
      tx_state <= idle;
      bit_counter <= 0;
      baud_counter <= 0;
      tx_reg <= (others => '0');
      parity_reg <= '0';
      o_busy <= '0';
      o_tx <= '1';
    elsif(i_clk = '1' and i_clk'event) then
      baud_tick := false;

      if(tx_state /= idle) then
        if(baud_counter = baud_last) then
          baud_counter <= 0;
          baud_tick := true;
        else
          baud_counter <= baud_counter + 1;
        end if;
      else
        baud_counter <= 0;
      end if;

      case( tx_state ) is
        when idle =>
          o_busy <= '0';
          o_tx <= '1';
          if(i_valid = '1') then
            tx_reg <= i_data;
            parity_reg <= parity_bit_of(i_data, PARITY_BIT);
            tx_state <= sync;
            o_busy <= '1';
          end if;
        when sync =>
          o_busy <= '1';
          o_tx <= '1';
          if(baud_tick) then
            tx_state <= startbit;
          end if;
        when startbit =>
          o_busy <= '1';
          o_tx <= '0';
          if(baud_tick) then
            bit_counter <= 0;
            tx_state <= databits;
          end if;
        when databits =>
          o_busy <= '1';
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

          if(baud_tick) then
            if(bit_counter = 7) then
              bit_counter <= 0;
              if(parity_enabled(PARITY_BIT)) then
                tx_state <= paritybit;
              else
                tx_state <= stopbit;
              end if;
            else
              bit_counter <= bit_counter + 1;
            end if;
          end if;

        when paritybit =>
          o_busy <= '1';
          o_tx <= parity_reg;
          if(baud_tick) then
            tx_state <= stopbit;
          end if;

        when stopbit =>
          o_busy <= '1';
          o_tx <= '1';
          if(baud_tick) then
            tx_state <= idle;
          end if;

        when others =>
          tx_state <= idle;
          o_busy <= '0';
          o_tx <= '1';
      end case;
    end if;
  end process;

end architecture;
