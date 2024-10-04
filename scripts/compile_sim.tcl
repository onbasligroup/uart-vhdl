
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

vcom -work work sim/uart_tb.vhd

vsim -t ps -novopt uart_tb
source wave.do