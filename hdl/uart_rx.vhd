
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

  signal rx_d1 : std_logic;

  type rx_state_type is (idle, startbit, databits, paritybit, reg2out, stopbit);
  signal rx_state : rx_state_type;

  type rd_rq_state_type is (idle, start_to_count, create_pulse);
  signal rd_rq_state : rd_rq_state_type;

  signal sampling_sync : std_logic;
  signal sampling_counter : std_logic_vector(31 downto 0);
  signal sampling_delta_counter : std_logic_vector(31 downto 0);
  signal rd_rq : std_logic;
  signal rd_rq_delta : std_logic;

  signal rx_reg : std_logic_vector(7 downto 0);
  signal bit_counter : std_logic_vector(2 downto 0);

begin

  -- Sampling process
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      rx_state <= idle;
      rx_d1 <= '0';
      o_valid <= '0';
      o_data <= (others => '0');
      bit_counter <= (others => '0');
      rx_reg <= (others => '0');
    elsif(i_clk'event and i_clk = '1') then
      rx_d1 <= i_rx;
      case( rx_state ) is
        when idle =>
          o_busy <= '0';
          if(i_rx = '0' and rx_d1 = '1') then
            sampling_sync <= '1';
            rx_state <= startbit;
            o_busy <= '1';
          else
            sampling_sync <= '0';
            rx_state <= idle;
          end if;
        when startbit =>
          sampling_sync <= '0';
          if(rd_rq = '1') then
            rx_state <= databits;
            bit_counter <= (others => '0');
          else
            rx_state <= startbit;
          end if;
        when databits =>
          if(rd_rq_delta = '1') then
            -- bit sampling
            case( bit_counter ) is
              when "000" => rx_reg(0) <= i_rx;
              when "001" => rx_reg(1) <= i_rx;
              when "010" => rx_reg(2) <= i_rx;
              when "011" => rx_reg(3) <= i_rx;
              when "100" => rx_reg(4) <= i_rx;
              when "101" => rx_reg(5) <= i_rx;
              when "110" => rx_reg(6) <= i_rx;
              when "111" => rx_reg(7) <= i_rx;
              when others =>
            end case;
          end if;
          if(rd_rq = '1') then
            -- counter controller
            if(bit_counter = "111") then
              rx_state <= reg2out;
              bit_counter <= (others => '0');
            else
              bit_counter <= std_logic_vector(unsigned(bit_counter) + 1);
            end if;

          end if;
        when reg2out =>
          rx_state <= stopbit;
          o_data <= rx_reg;
          o_valid <= '1';
        when paritybit => rx_state <= idle;
        when stopbit =>
          o_valid <= '0';
          if(rd_rq = '1') then
            rx_state <= idle;
          else
            rx_state <= stopbit;
          end if;
        when others =>
      end case;
    end if;
  end process;

  -- Create read request
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      rd_rq <= '1';
      sampling_counter <= (others => '0');
    elsif(i_clk'event and i_clk = '1') then
      if(sampling_sync = '1') then
        sampling_counter <= (others => '0');
      else
        if(sampling_counter = std_logic_vector(to_unsigned(count_num,sampling_counter'length))) then
          if(rx_state /= idle) then
            rd_rq <= '1';
          else
            rd_rq <= '0';
          end if;
          sampling_counter <= (others => '0');
        else
          rd_rq <= '0';
          sampling_counter <= std_logic_vector(unsigned(sampling_counter) + 1);
        end if;
      end if;
    end if;
  end process;

  -- Create read request with sampling delta
  process(i_clk, i_rst)
  begin
    if(i_rst = '1') then
      sampling_delta_counter <= (others => '0');
      rd_rq_state <= idle;
      rd_rq_delta <= '0';
    elsif(i_clk'event and i_clk = '1') then
      case( rd_rq_state ) is
        when idle =>
          rd_rq_delta <= '0';
          if(rd_rq = '1') then
            sampling_delta_counter <= (others => '0');
            rd_rq_state <= start_to_count;
          else
            rd_rq_state <= idle;
          end if;
        when start_to_count =>
          rd_rq_delta <= '0';
          if(sampling_delta_counter < std_logic_vector(to_unsigned(count_num/2,sampling_delta_counter'length))) then
            sampling_delta_counter <= std_logic_vector(unsigned(sampling_delta_counter) + 1);
            rd_rq_state <= start_to_count;
          else
            sampling_delta_counter <= (others => '0');
            rd_rq_state <= create_pulse;
          end if;
        when create_pulse =>
          rd_rq_delta <= '1';
          rd_rq_state <= idle;
        when others =>
      end case;
    end if;
  end process;

end architecture;
