# uart-vhdl
UART implementation in VHDL 

## UART_RX Module

#### Generic and Port Description
| Generic Name | Data Type | Comment
| ------ | ------ | ------ |
| CLK_FREQ  | integer | Set system clock frequency in Hz (Default: 100 MHz)
| BAUD_RATE | integer | Baudrate value
| PARITY_BIT| string  | valid for "none" only! 

| Port Name | Data Type | Direction | Comment
| ------ | ------ | ------ | ----- |
| i_clk  | std_logic | input | clock
| i_rst | std_logic | input  | reset (active high)
| i_rx| std_logic | input | uart rx pin
| o_data| std_logic | output | received data
| o_valid| std_logic | output | '1' when data received else '0' 
| o_busy| std_logic | output | '1' during the receiving process else '0'


## UART_TX Module

#### Generic and Port Description
| Generic Name | Data Type | Comment
| ------ | ------ | ------ |
| CLK_FREQ  | integer | Set system clock frequency in Hz (Default: 100 MHz)
| BAUD_RATE | integer | Baudrate value
| PARITY_BIT| string  | valid for "none" only! 

| Port Name | Data Type | Direction | Comment
| ------ | ------ | ------ | ----- |
| i_clk  | std_logic | input | clock
| i_rst | std_logic | input  | reset (active high)
| i_data| std_logic | input | data to be sent
| i_valid| std_logic | input | set '1' if i_data is valid else '0' 
| o_tx| std_logic | output | uart tx pin
| o_busy| std_logic | output | '1' during the transmission process else '0'

#### Timing diagram 
![Timing diagram for uart_tx module](https://raw.githubusercontent.com/onbasligroup/uart-vhdl/main/docs/img/tx.png)

Warning! You cannot send multiple data one after another. You can use the condition below on your code.

```
if(uart_tx_busy = '0' and uart_tx_valid = '0') then
  uart_tx_data <= <YOUR DATA>;
  uart_tx_valid <= '1';
else
  uart_tx_valid <= '0';
end if;
```
## Directory Tree
```
├── hdl
│   ├── uart_rx_comp.vhd      -- UART rx component package. You can check sim/tb/uart_tb.vhd for usage.
│   ├── uart_rx.vhd           -- UART rx module.
│   ├── uart_tx_comp.vhd      -- UART tx component package. You can check sim/tb/uart_tb.vhd for usage.
│   └── uart_tx.vhd           -- UART tx module.
└── sim
    ├── scripts
    │   ├── run_sim.tcl       -- Simulation script for 3. party simulator.
    └── tb
        └── uart_tb.vhd       -- Example usage for both tx and rx modules. (Testbench)
```

This project is under development!
