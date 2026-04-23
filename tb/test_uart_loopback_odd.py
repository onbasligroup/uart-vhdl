import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = 0
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


async def tx_byte(dut, value: int):
    for _ in range(5000):
        if int(dut.o_tx_busy.value) == 0:
            break
        await RisingEdge(dut.i_clk)
    else:
        raise AssertionError("TX ready timeout")
    dut.i_data.value = value
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0


async def wait_rx_byte(dut, timeout_cycles: int = 6000):
    for _ in range(timeout_cycles):
        await RisingEdge(dut.i_clk)
        if int(dut.o_rx_valid.value) == 1:
            return int(dut.o_rx_data.value)
    raise AssertionError("RX timeout")


@cocotb.test()
async def test_loopback_odd_stress(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    random.seed(29)
    payloads = [random.randrange(0, 256) for _ in range(64)]

    for value in payloads:
        await tx_byte(dut, value)
        got = await wait_rx_byte(dut)
        assert got == value, f"Loopback mismatch expected=0x{value:02X}, got=0x{got:02X}"
