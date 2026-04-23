import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_rx.value = 1
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


async def drive_uart_byte(dut, value: int):
    bits = [0] + [(value >> bit) & 1 for bit in range(8)] + [1]
    for b in bits:
        dut.i_rx.value = b
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)


@cocotb.test()
async def test_rx_single_byte(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payload = 0x3C
    await drive_uart_byte(dut, payload)

    got = None
    for _ in range(2000):
        await RisingEdge(dut.i_clk)
        if int(dut.o_valid.value) == 1:
            got = int(dut.o_data.value)
            break

    assert got is not None, "RX did not assert valid"
    assert got == payload, f"RX payload mismatch expected=0x{payload:02X}, got=0x{got:02X}"
