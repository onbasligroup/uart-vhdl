
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
    PARITY_BIT  : string  := "none"  -- valid for "none", "even", "odd"
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
  constant start_sample : integer := count_num/2;
  constant data_sample  : integer := count_num - 1;

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

  function parity_match(data : std_logic_vector(7 downto 0); parity : std_logic; mode : string) return boolean is
    variable x : std_logic := xor_reduce(data);
  begin
    if (mode = "odd") or (mode = "ODD") then
      return parity = not x;
    end if;
    return parity = x;
  end function;

  signal rx_meta : std_logic;
  signal rx_sync : std_logic;
  signal rx_prev : std_logic;

  type rx_state_type is (idle, startbit, databits, paritybit, stopbit);
  signal rx_state : rx_state_type;

  signal sample_counter : integer range 0 to data_sample;
  signal parity_ok : std_logic;

  signal rx_reg : std_logic_vector(7 downto 0);
  signal bit_counter : integer range 0 to 7;

begin

  -- Receiver
  process(i_clk, i_rst)
    variable do_sample : boolean;
    variable sampled_bit : std_logic;
  begin
    if(i_rst = '1') then
      rx_meta <= '1';
      rx_sync <= '1';
      rx_prev <= '1';
      rx_state <= idle;
      sample_counter <= 0;
      parity_ok <= '1';
      o_valid <= '0';
      o_data <= (others => '0');
      o_busy <= '0';
      bit_counter <= 0;
      rx_reg <= (others => '0');
    elsif(i_clk'event and i_clk = '1') then
      rx_meta <= i_rx;
      rx_sync <= rx_meta;
      rx_prev <= rx_sync;
      sampled_bit := rx_sync;
      do_sample := false;

      o_valid <= '0';
      if(rx_state = idle) then
        o_busy <= '0';
      else
        o_busy <= '1';
      end if;

      case( rx_state ) is
        when idle =>
          if(rx_prev = '1' and rx_sync = '0') then
            sample_counter <= 0;
            parity_ok <= '1';
            bit_counter <= 0;
            rx_state <= startbit;
            o_busy <= '1';
          end if;

        when startbit =>
          if(sample_counter = start_sample) then
            sample_counter <= 0;
            if(sampled_bit = '0') then
              bit_counter <= 0;
              rx_state <= databits;
            else
              rx_state <= idle;
            end if;
          else
            sample_counter <= sample_counter + 1;
          end if;

        when databits =>
          if(sample_counter = data_sample) then
            sample_counter <= 0;
            do_sample := true;
          else
            sample_counter <= sample_counter + 1;
          end if;

          if(do_sample) then
            rx_reg(bit_counter) <= sampled_bit;
            if(bit_counter = 7) then
              bit_counter <= 0;
              if(parity_enabled(PARITY_BIT)) then
                rx_state <= paritybit;
              else
                rx_state <= stopbit;
              end if;
            else
              bit_counter <= bit_counter + 1;
            end if;
          end if;

        when paritybit =>
          if(sample_counter = data_sample) then
            sample_counter <= 0;
            if(parity_match(rx_reg, sampled_bit, PARITY_BIT)) then
              parity_ok <= '1';
            else
              parity_ok <= '0';
            end if;
            rx_state <= stopbit;
          else
            sample_counter <= sample_counter + 1;
          end if;

        when stopbit =>
          if(sample_counter = data_sample) then
            sample_counter <= 0;
            if(sampled_bit = '1' and parity_ok = '1') then
              o_data <= rx_reg;
              o_valid <= '1';
            end if;
            rx_state <= idle;
          else
            sample_counter <= sample_counter + 1;
          end if;

        when others =>
          rx_state <= idle;
      end case;
    end if;
  end process;

end architecture;
