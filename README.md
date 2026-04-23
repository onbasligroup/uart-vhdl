# uart-vhdl
UART implementation in VHDL.

This repository now includes a reproducible cocotb-based verification flow
for UART TX, UART RX, and TX->RX loopback scenarios.

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

#### Timing Diagram
![Timing diagram for uart_tx module](https://raw.githubusercontent.com/onbasligroup/uart-vhdl/main/docs/img/tx.png)

> Warning!: You cannot send multiple data one after another. You can use the condition below on your code.

```vhdl
if(uart_tx_busy = '0' and uart_tx_valid = '0') then
  uart_tx_data <= <YOUR DATA>;
  uart_tx_valid <= '1';
else
  uart_tx_valid <= '0';
end if;
```

## Directory Tree

```text
uart-vhdl/
├── src/
│   ├── uart_rx_comp.vhd
│   ├── uart_rx.vhd
│   ├── uart_tx_comp.vhd
│   └── uart_tx.vhd
├── tb/
│   ├── uart_tx_wrap.vhd
│   ├── uart_rx_wrap.vhd
│   ├── uart_loopback_wrap.vhd
│   ├── test_uart_tx.py
│   ├── test_uart_rx.py
│   └── test_uart_loopback.py
├── scripts/
│   ├── run_cocotb.py
│   ├── run_sim.tcl
│   ├── compile_src.tcl
│   └── compile_sim.tcl
├── Dockerfile
├── docker-run.sh
├── Makefile
└── .github/workflows/ci.yml
```

## Verification Flow

### Local prerequisites
- GHDL
- Python 3.10+
- pip packages from requirements.txt

### Run locally

```bash
python3 -m pip install -r requirements.txt
make cocotb-test
```

### Run in Docker

```bash
./docker-run.sh
# or
make docker-test
```

## CI/CD Policy

- Pushes to develop run the UART regression suite.
- Pull requests targeting main run the same suite.
- Pull requests to main are enforced to come only from develop.

This makes the develop -> main merge flow a hard quality gate with cocotb tests.

## Notes

- PARITY_BIT now supports "none", "even", and "odd" in both TX and RX modules.
- cocotb regression now runs parity-aware test suites, long stream loopback stress tests,
  false-start/glitch rejection tests, reset recovery tests, and small baud-mismatch RX checks.

This project is under development.
