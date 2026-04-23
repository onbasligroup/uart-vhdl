import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = 0
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


@cocotb.test()
async def test_tx_frame_format(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payload = 0xA5

    while int(dut.o_busy.value) == 1:
        await RisingEdge(dut.i_clk)

    dut.i_data.value = payload
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0

    for _ in range(BIT_CYCLES + BIT_CYCLES // 2):
        await RisingEdge(dut.i_clk)

    observed = []
    for _ in range(10):
        observed.append(int(dut.o_tx.value))
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)

    expected = [0] + [(payload >> bit) & 1 for bit in range(8)] + [1]
    assert observed == expected, f"TX frame mismatch expected={expected} observed={observed}"
