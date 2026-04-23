import cocotb
from cocotb.clock import Clock

from uart_test_utils import BIT_CYCLES, CLK_NS, drive_line_level, drive_uart_frame, reset_rx_dut, wait_cycles, wait_valid_data


@cocotb.test()
async def test_rx_idle_line_stays_quiet(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_rx_dut(dut)

    await drive_line_level(dut, 1, BIT_CYCLES * 12)
    got = await wait_valid_data(dut, timeout_cycles=50)
    assert got is None, "RX asserted valid while line was idle"


@cocotb.test()
async def test_rx_rejects_short_start_glitch(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_rx_dut(dut)

    await drive_line_level(dut, 0, BIT_CYCLES // 4)
    await drive_line_level(dut, 1, BIT_CYCLES * 2)

    got = await wait_valid_data(dut, timeout_cycles=BIT_CYCLES * 2)
    assert got is None, "RX accepted a short start glitch as a frame"


@cocotb.test()
async def test_rx_false_start_then_good_frame(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_rx_dut(dut)

    await drive_line_level(dut, 0, BIT_CYCLES // 3)
    await drive_line_level(dut, 1, BIT_CYCLES)
    payload = 0xC9
    await drive_uart_frame(dut, payload)

    got = await wait_valid_data(dut)
    assert got == payload, f"RX failed to recover after false start, got {got}"


@cocotb.test()
async def test_rx_recovers_after_mid_frame_reset(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_rx_dut(dut)

    payload = 0x5A
    dut.i_rx.value = 0
    await wait_cycles(dut.i_clk, BIT_CYCLES)
    for bit in [(payload >> idx) & 1 for idx in range(4)]:
        dut.i_rx.value = bit
        await wait_cycles(dut.i_clk, BIT_CYCLES)

    dut.i_rst.value = 1
    await wait_cycles(dut.i_clk, 2)
    dut.i_rst.value = 0
    dut.i_rx.value = 1
    await wait_cycles(dut.i_clk, BIT_CYCLES * 2)

    got = await wait_valid_data(dut, timeout_cycles=BIT_CYCLES * 2)
    assert got is None, "RX produced stale data after reset in the middle of a frame"

    next_payload = 0xA6
    await drive_uart_frame(dut, next_payload)
    got = await wait_valid_data(dut)
    assert got == next_payload, f"RX did not recover after reset, got {got}"


@cocotb.test()
async def test_rx_accepts_small_baud_mismatch(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_rx_dut(dut)

    for bit_cycles, payload in [(99, 0x33), (101, 0xCC)]:
        await drive_uart_frame(dut, payload, bit_cycles=bit_cycles)
        got = await wait_valid_data(dut, timeout_cycles=BIT_CYCLES * 30)
        assert got == payload, f"RX failed small baud mismatch test bit_cycles={bit_cycles}, got {got}"
