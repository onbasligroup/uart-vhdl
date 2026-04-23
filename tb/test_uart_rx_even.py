import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_NS = 100
BIT_CYCLES = 100


def even_parity_bit(value: int) -> int:
    return bin(value).count("1") % 2


async def reset_dut(dut):
    dut.i_rst.value = 1
    dut.i_rx.value = 1
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)


async def drive_even_frame(dut, payload: int, parity_override=None, stop_bit=1):
    parity = even_parity_bit(payload) if parity_override is None else parity_override
    bits = [0] + [(payload >> bit) & 1 for bit in range(8)] + [parity, stop_bit]
    for bit in bits:
        dut.i_rx.value = bit
        for _ in range(BIT_CYCLES):
            await RisingEdge(dut.i_clk)


async def wait_valid_data(dut, timeout_cycles: int = 3500):
    for _ in range(timeout_cycles):
        await RisingEdge(dut.i_clk)
        if int(dut.o_valid.value) == 1:
            return int(dut.o_data.value)
    return None


@cocotb.test()
async def test_rx_even_parity_accepts_good_frames(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payloads = [0x00, 0x11, 0x2A, 0x7F, 0xA5]
    for payload in payloads:
        await drive_even_frame(dut, payload)
        got = await wait_valid_data(dut)
        assert got == payload


@cocotb.test()
async def test_rx_even_parity_rejects_bad_parity(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_dut(dut)

    payload = 0x4D
    good = even_parity_bit(payload)
    await drive_even_frame(dut, payload, parity_override=1 - good)
    got = await wait_valid_data(dut)
    assert got is None, "RX accepted even-parity frame with wrong parity bit"
