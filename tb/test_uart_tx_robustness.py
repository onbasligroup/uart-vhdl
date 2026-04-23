import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from uart_test_utils import BIT_CYCLES, CLK_NS, reset_tx_dut, sample_tx_frame, tx_byte, wait_cycles


@cocotb.test()
async def test_tx_idles_high_after_reset(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_tx_dut(dut)

    await wait_cycles(dut.i_clk, BIT_CYCLES * 2)
    assert int(dut.o_tx.value) == 1, "TX line is not idle-high after reset"
    assert int(dut.o_busy.value) == 0, "TX busy is unexpectedly asserted while idle"


@cocotb.test()
async def test_tx_busy_covers_entire_frame(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_tx_dut(dut)

    await tx_byte(dut, 0x96)

    saw_busy = False
    for _ in range(BIT_CYCLES * 12):
        if int(dut.o_busy.value) == 1:
            saw_busy = True
            break
        await RisingEdge(dut.i_clk)

    assert saw_busy, "TX never asserted busy during frame transmission"

    for _ in range(BIT_CYCLES * 20):
        await RisingEdge(dut.i_clk)
        if int(dut.o_busy.value) == 0:
            break
    else:
        raise AssertionError("TX busy did not deassert after frame completion")

    assert int(dut.o_tx.value) == 1, "TX line did not return to idle high after frame"


@cocotb.test()
async def test_tx_reset_mid_frame_forces_idle(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_tx_dut(dut)

    await tx_byte(dut, 0xF0)

    for _ in range(BIT_CYCLES * 3):
        await RisingEdge(dut.i_clk)

    dut.i_rst.value = 1
    await wait_cycles(dut.i_clk, 2)
    assert int(dut.o_tx.value) == 1, "TX line did not return high during reset"
    assert int(dut.o_busy.value) == 0, "TX busy did not clear during reset"

    dut.i_rst.value = 0
    await wait_cycles(dut.i_clk, 2)
    assert int(dut.o_tx.value) == 1, "TX line did not remain idle after reset release"


@cocotb.test()
async def test_tx_ignores_new_request_while_busy(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_NS, units="ns").start())
    await reset_tx_dut(dut)

    first_payload = 0xA5
    await tx_byte(dut, first_payload)

    for _ in range(BIT_CYCLES * 2):
        await RisingEdge(dut.i_clk)

    dut.i_data.value = 0x3C
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0

    data_bits, _, stop = await sample_tx_frame(dut)
    assert data_bits == [(first_payload >> bit) & 1 for bit in range(8)]
    assert stop == 1

    await wait_cycles(dut.i_clk, BIT_CYCLES * 3)
    assert int(dut.o_tx.value) == 1, "TX started an unexpected second frame after busy-time request"
