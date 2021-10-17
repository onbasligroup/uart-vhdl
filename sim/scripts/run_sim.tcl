
## ===============================================================================================
## (C) COPYRIGHT 2020 Koç University - Magnonic and Photonic Devices Research Group
## All rights reserved.
## ===============================================================================================
## Creator: bugra
## ===============================================================================================
## Project           : uart-vhdl
## File ID           : uart_rx
## Design Unit Name  :
## Description       :
## Comments          :
## Revision          : %%
## Last Changed Date : %%
## Last Changed By   : %%
## Designer
##          Name     : Bugra Tufan
##          E-mail   : btufan21@ku.edu.tr
## ===============================================================================================


vcom -work work ../golden_uart/uart_parity.vhd
vcom -work work ../golden_uart/uart_tx.vhd
vcom -work work ../golden_uart/uart_rx.vhd
vcom -work work ../golden_uart/uart.vhd
vcom -work work ../golden_uart/uart_comp.vhd

vcom -work work ../../hdl/uart_rx.vhd
vcom -work work ../../hdl/uart_rx_comp.vhd

vcom -work work ../tb/uart_tb.vhd


vsim -t ps -novopt uart_tb
source wave.do
